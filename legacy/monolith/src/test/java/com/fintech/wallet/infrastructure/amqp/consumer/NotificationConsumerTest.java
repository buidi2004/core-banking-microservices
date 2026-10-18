package com.fintech.wallet.infrastructure.amqp.consumer;

import com.fintech.wallet.domain.model.*;
import com.fintech.wallet.domain.port.out.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class NotificationConsumerTest {

    private NotificationPort notificationPort;
    private TransactionPersistencePort transactionPersistencePort;
    private WalletPersistencePort walletPersistencePort;
    private UserPersistencePort userPersistencePort;
    private StringRedisTemplate redisTemplate;
    private ValueOperations<String, String> valueOperations;
    private FcmNotificationPort fcmNotificationAdapter;

    private NotificationConsumer consumer;

    @BeforeEach
    void setUp() {
        notificationPort = mock(NotificationPort.class);
        transactionPersistencePort = mock(TransactionPersistencePort.class);
        walletPersistencePort = mock(WalletPersistencePort.class);
        userPersistencePort = mock(UserPersistencePort.class);
        redisTemplate = mock(StringRedisTemplate.class);
        valueOperations = mock(ValueOperations.class);
        fcmNotificationAdapter = mock(FcmNotificationPort.class);

        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        consumer = new NotificationConsumer(
                notificationPort,
                transactionPersistencePort,
                walletPersistencePort,
                userPersistencePort,
                redisTemplate,
                fcmNotificationAdapter
        );
    }

    @Test
    void receiveMessage_shouldSendBothWebSocketAndFcmWithExactMatchingFields() {
        String txId = "tx-001";
        String eventId = "evt-001";
        String sourceWalletId = "wallet-src";
        String targetWalletId = "wallet-dst";
        String sourceUserId = "user-sender";
        String targetUserId = "user-receiver";

        when(valueOperations.setIfAbsent(anyString(), anyString(), anyLong(), any(TimeUnit.class)))
                .thenReturn(Boolean.TRUE);

        Transaction tx = Transaction.createTransfer("req-123", sourceWalletId, targetWalletId, new Money(new BigDecimal("50000"), "VND"), "Trả tiền cà phê");
        tx.markSuccess();
        tx.setFeeAmount(new Money(BigDecimal.ZERO, "VND"));
        tx.setBalanceAfter(new Money(new BigDecimal("950000"), "VND"));
        tx.setReceiverBalanceAfter(new Money(new BigDecimal("250000"), "VND"));

        when(transactionPersistencePort.findTransactionById(tx.getId())).thenReturn(Optional.of(tx));

        Wallet srcWallet = new Wallet(sourceWalletId, sourceUserId, new Money(new BigDecimal("950000"), "VND"), Instant.now(), Instant.now(), 1L);
        Wallet dstWallet = new Wallet(targetWalletId, targetUserId, new Money(new BigDecimal("250000"), "VND"), Instant.now(), Instant.now(), 1L);
        when(walletPersistencePort.findWalletById(sourceWalletId)).thenReturn(Optional.of(srcWallet));
        when(walletPersistencePort.findWalletById(targetWalletId)).thenReturn(Optional.of(dstWallet));

        User srcUser = new User(sourceUserId, "0901111111", "Nguyễn Văn A", "hash", null, KycStatus.VERIFIED, Instant.now(), Instant.now());
        User dstUser = new User(targetUserId, "0902222222", "Trần Thị B", "hash", null, KycStatus.VERIFIED, Instant.now(), Instant.now());
        when(userPersistencePort.findUserById(sourceUserId)).thenReturn(Optional.of(srcUser));
        when(userPersistencePort.findUserById(targetUserId)).thenReturn(Optional.of(dstUser));

        TransactionEvent event = new TransactionEvent(eventId, tx.getId(), "TRANSFER", "SUCCESS", sourceWalletId, targetWalletId, new BigDecimal("50000"), "VND", Instant.now());

        consumer.receiveMessage(event);

        // 1. Verify WebSocket notifications sent for both sender and receiver (unchanged!)
        verify(notificationPort, times(1)).notifyTransactionCompleted(eq(tx), eq(srcWallet), eq(srcUser), eq(dstWallet), eq(dstUser));
        verify(notificationPort, times(1)).notifyTransactionCompleted(eq(tx), eq(dstWallet), eq(dstUser), eq(srcWallet), eq(srcUser));

        // 2. Verify FCM push sent for both sender and receiver
        ArgumentCaptor<Map<String, String>> dataCaptor = ArgumentCaptor.forClass(Map.class);
        verify(fcmNotificationAdapter, times(2)).sendPushNotification(anyString(), anyString(), anyString(), dataCaptor.capture());

        // Check sender FCM data payload
        Map<String, String> senderData = dataCaptor.getAllValues().get(0);
        assertEquals(tx.getId(), senderData.get("transactionId"));
        assertEquals("req-123", senderData.get("requestId"));
        assertEquals("TRANSFER_OUT", senderData.get("type"));
        assertEquals("SUCCESS", senderData.get("status"));
        assertEquals("wallet-src", senderData.get("walletId"));
        assertEquals("50000.00", senderData.get("transactionAmount"));
        assertEquals("50000.00", senderData.get("amount"));
        assertEquals("950000.00", senderData.get("newBalance"));
        assertEquals("VND", senderData.get("currency"));
        assertEquals("Trả tiền cà phê", senderData.get("note"));

        // Check receiver FCM data payload
        Map<String, String> receiverData = dataCaptor.getAllValues().get(1);
        assertEquals(tx.getId(), receiverData.get("transactionId"));
        assertEquals("TRANSFER_IN", receiverData.get("type"));
        assertEquals("wallet-dst", receiverData.get("walletId"));
        assertEquals("250000.00", receiverData.get("newBalance"));
    }
}

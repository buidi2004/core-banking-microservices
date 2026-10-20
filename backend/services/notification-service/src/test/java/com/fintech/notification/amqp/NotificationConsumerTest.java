package com.fintech.notification.amqp;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.notification.entity.Notification;
import com.fintech.notification.notification.EventIdempotencyStore;
import com.fintech.notification.notification.FcmPushSender;
import com.fintech.notification.notification.NotificationPayload;
import com.fintech.notification.notification.UserPhoneResolver;
import com.fintech.notification.notification.WebSocketNotifier;
import com.fintech.notification.service.NotificationService;
import com.fintech.wallet.domain.event.TransactionEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class NotificationConsumerTest {

    @Mock
    private NotificationService notificationService;

    @Mock
    private WebSocketNotifier webSocketNotifier;

    @Mock
    private FcmPushSender fcmPushSender;

    @Mock
    private UserPhoneResolver userPhoneResolver;

    private NotificationConsumer consumer;

    @BeforeEach
    void setUp() {
        consumer = new NotificationConsumer(new EventIdempotencyStore(), notificationService,
                webSocketNotifier, fcmPushSender, userPhoneResolver, new ObjectMapper());
    }

    private TransactionEvent transferEvent(String eventId) {
        TransactionEvent event = new TransactionEvent();
        event.setEventId(eventId);
        event.setTransactionId("tx-1");
        event.setType("TRANSFER");
        event.setStatus("SUCCESS");
        event.setSourceWalletId("wallet-A");
        event.setTargetWalletId("wallet-B");
        event.setSourceUserId("user-001");
        event.setTargetUserId("user-002");
        event.setSourcePhone("0900000001");
        event.setTargetPhone("0900000002");
        event.setAmount(BigDecimal.valueOf(150000));
        event.setFeeAmount(BigDecimal.valueOf(5000));
        event.setCurrency("VND");
        event.setSourceBalanceAfter(BigDecimal.valueOf(850000));
        event.setTargetBalanceAfter(BigDecimal.valueOf(150000));
        event.setNote("test transfer");
        event.setOccurredAt(Instant.parse("2026-10-18T05:00:00Z"));
        return event;
    }

    @Test
    void dispatchesNotificationsToSourceAndTarget() {
        consumer.onTransactionEvent(transferEvent("evt-1"));

        ArgumentCaptor<Notification> saved = ArgumentCaptor.forClass(Notification.class);
        verify(notificationService, times(2)).save(saved.capture());
        assertThat(saved.getAllValues())
                .extracting(Notification::getUserId)
                .containsExactlyInAnyOrder("user-001", "user-002");

        Notification source = saved.getAllValues().stream()
                .filter(n -> n.getUserId().equals("user-001")).findFirst().orElseThrow();
        Notification target = saved.getAllValues().stream()
                .filter(n -> n.getUserId().equals("user-002")).findFirst().orElseThrow();
        assertThat(source.getTitle()).contains("Chuyển tiền");
        assertThat(target.getTitle()).contains("Nhận tiền");
        assertThat(source.getBody()).contains("-155.000 VND").contains("850.000 VND");
        assertThat(source.getDataPayload()).contains("\"type\":\"TRANSFER_OUT\"").contains("\"newBalance\":\"850000\"");

        verify(webSocketNotifier).pushToWallet(eq("wallet-A"), any(NotificationPayload.class));
        verify(webSocketNotifier).pushToWallet(eq("wallet-B"), any(NotificationPayload.class));
        verify(webSocketNotifier).pushToUser(eq("user-001"), any(NotificationPayload.class));
        verify(webSocketNotifier).pushToUser(eq("user-002"), any(NotificationPayload.class));

        verify(fcmPushSender).sendPushNotification(eq("user-001"), anyString(), anyString(), anyMap());
        verify(fcmPushSender).sendPushNotification(eq("user-002"), anyString(), anyString(), anyMap());
    }

    @Test
    void ignoresDuplicateEventId() {
        TransactionEvent event = transferEvent("evt-dup");

        consumer.onTransactionEvent(event);
        consumer.onTransactionEvent(event);
        consumer.onTransactionEvent(event);

        verify(notificationService, times(2)).save(any(Notification.class));
        verify(fcmPushSender, times(2)).sendPushNotification(anyString(), anyString(), anyString(), anyMap());
    }

    @Test
    void processesEachDistinctEvent() {
        consumer.onTransactionEvent(transferEvent("evt-1"));
        consumer.onTransactionEvent(transferEvent("evt-2"));

        verify(notificationService, times(4)).save(any(Notification.class));
    }

    @Test
    void notifiesOnceWhenSourceAndTargetWalletAreEqual() {
        TransactionEvent event = transferEvent("evt-self");
        event.setTargetWalletId("wallet-A");
        event.setTargetUserId("user-001");

        consumer.onTransactionEvent(event);

        verify(notificationService, times(1)).save(any(Notification.class));
        verify(webSocketNotifier, times(1)).pushToWallet(eq("wallet-A"), any(NotificationPayload.class));
    }

    @Test
    void resetsIdempotencyWhenDispatchFailsSoEventCanBeRetried() {
        doThrow(new RuntimeException("FCM down"))
                .when(fcmPushSender).sendPushNotification(anyString(), anyString(), anyString(), anyMap());

        TransactionEvent event = transferEvent("evt-retry");
        assertThatThrownBy(() -> consumer.onTransactionEvent(event))
                .isInstanceOf(RuntimeException.class);

        doNothing().when(fcmPushSender).sendPushNotification(anyString(), anyString(), anyString(), anyMap());
        consumer.onTransactionEvent(event);

        verify(notificationService, times(3)).save(any(Notification.class));
    }

    @Test
    void ignoresNullOrIncompleteEvent() {
        consumer.onTransactionEvent(null);

        TransactionEvent withoutTxId = transferEvent("evt-x");
        withoutTxId.setTransactionId(null);
        consumer.onTransactionEvent(withoutTxId);

        verify(notificationService, never()).save(any(Notification.class));
    }

    @Test
    void buildsUserFacingPayloadWithCounterpartyAndNote() {
        consumer.onTransactionEvent(transferEvent("evt-body"));

        ArgumentCaptor<Notification> saved = ArgumentCaptor.forClass(Notification.class);
        verify(notificationService, times(2)).save(saved.capture());
        List<String> bodies = saved.getAllValues().stream().map(Notification::getBody).toList();
        assertThat(bodies).anySatisfy(body -> assertThat(body).contains("Đến: 0900000002").contains("ND: test transfer"));
        assertThat(bodies).anySatisfy(body -> assertThat(body).contains("Từ: 0900000001"));
    }

    @Test
    void fcmDataPayloadContainsCoreTransactionFields() {
        consumer.onTransactionEvent(transferEvent("evt-data"));

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, String>> dataCaptor = ArgumentCaptor.forClass(Map.class);
        verify(fcmPushSender).sendPushNotification(eq("user-001"), anyString(), anyString(), dataCaptor.capture());
        Map<String, String> data = dataCaptor.getValue();
        assertThat(data)
                .containsEntry("transactionId", "tx-1")
                .containsEntry("type", "TRANSFER_OUT")
                .containsEntry("status", "SUCCESS")
                .containsEntry("walletId", "wallet-A")
                .containsEntry("currency", "VND")
                .containsEntry("newBalance", "850000");
    }
}

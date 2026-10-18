package com.fintech.wallet.application.service;

import com.fintech.wallet.domain.exception.InvalidPinException;
import com.fintech.wallet.domain.model.Money;
import com.fintech.wallet.domain.model.Transaction;
import com.fintech.wallet.domain.model.TransactionStatus;
import com.fintech.wallet.domain.model.User;
import com.fintech.wallet.domain.model.Wallet;
import com.fintech.wallet.domain.port.out.BankGatewayPort;
import com.fintech.wallet.domain.port.out.NotificationPort;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fintech.wallet.presentation.response.TransferResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import com.fintech.wallet.domain.port.in.AuthUseCase;

import java.math.BigDecimal;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@org.springframework.context.annotation.Import(TransferFlowTestConfig.class)
@org.springframework.test.context.TestPropertySource(properties = {"management.health.redis.enabled=false"})
@Transactional
public class TransferFlowIntegrationTest {

    @Autowired
    private WalletService walletService;

    @Autowired
    private UserService userService;

    @Autowired
    private AuthUseCase authService;

    @MockBean
    private BankGatewayPort bankGatewayPort;

    @MockBean
    private NotificationPort notificationPort;
    
    @MockBean
    private com.fintech.wallet.domain.port.out.MoneyRequestPersistencePort moneyRequestPersistencePort;
    
    @MockBean
    private com.fintech.wallet.domain.port.out.BillProviderPort billProviderPort;
    
    @MockBean
    private com.fintech.wallet.domain.port.out.SessionStorePort sessionStorePort;

    @MockBean
    private org.springframework.data.redis.core.RedisTemplate<String, Object> redisTemplate;

    @MockBean
    private org.springframework.data.redis.core.StringRedisTemplate stringRedisTemplate;

    @MockBean
    private org.springframework.data.redis.connection.RedisConnectionFactory redisConnectionFactory;

    @MockBean
    private org.springframework.data.redis.connection.ReactiveRedisConnectionFactory reactiveRedisConnectionFactory;

    @MockBean
    private org.springframework.data.redis.core.RedisKeyValueAdapter redisKeyValueAdapter;

    @MockBean
    private org.springframework.data.redis.listener.RedisMessageListenerContainer redisMessageListenerContainer;

    private User sender;
    private User receiver;
    private Wallet senderWallet;
    private Wallet receiverWallet;

    @BeforeEach
    public void setup() {
        // Create Sender
        sender = authService.register("0900000001", "Sender", "password123");
        userService.setPin(sender.getId(), "123456");

        // Create Receiver
        receiver = authService.register("0900000002", "Receiver", "password123");
        userService.setPin(receiver.getId(), "654321");

        // Set KYC to verified to allow transactions
        userService.submitKyc(sender.getId(), "1111", "Sender", "2000-01-01", "f", "b", "s");
        userService.processKycWebhook(sender.getId(), com.fintech.wallet.domain.model.KycStatus.VERIFIED, null);
        userService.submitKyc(receiver.getId(), "2222", "Receiver", "2000-01-01", "f", "b", "s");
        userService.processKycWebhook(receiver.getId(), com.fintech.wallet.domain.model.KycStatus.VERIFIED, null);

        // Get Wallets (auto-created during registration)
        senderWallet = walletService.getWalletByUserIdAndCurrency(sender.getId(), "VND");
        receiverWallet = walletService.getWalletByUserIdAndCurrency(receiver.getId(), "VND");

        // Fund sender wallet directly via bank deposit flow
        String depositReqId = UUID.randomUUID().toString();
        Transaction depositTx = walletService.deposit(depositReqId, senderWallet.getId(), Money.of(new BigDecimal("1000000"), "VND"));

        // Refresh senderWallet to get the updated balance
        senderWallet = walletService.getWalletById(senderWallet.getId());
    }

    @Test
    public void testCompleteTransferFlow_Success() {
        String requestId = UUID.randomUUID().toString();
        Money transferAmount = Money.of(new BigDecimal("200000"), "VND");

        // Step 1: Init Transfer
        Transaction initTx = walletService.initTransfer(requestId, senderWallet.getId(), receiverWallet.getId(), "SENHONG", transferAmount, null);
        
        assertNotNull(initTx);
        assertEquals(TransactionStatus.PENDING_CONFIRMATION, initTx.getStatus());
        assertEquals(transferAmount.getAmount().stripTrailingZeros(), initTx.getAmount().getAmount().stripTrailingZeros());
        assertEquals("TRANSFER", initTx.getType().name());

        // Step 2: Confirm Transfer
        // Verify PIN first
        if (!userService.verifyPin(sender.getId(), "123456")) {
            throw new InvalidPinException("Invalid PIN");
        }
        
        Transaction confirmedTx = walletService.confirmTransfer(initTx.getId());

        assertNotNull(confirmedTx);
        assertEquals(TransactionStatus.SUCCESS, confirmedTx.getStatus());

        // Verify Balances
        Wallet updatedSenderWallet = walletService.getWalletById(senderWallet.getId());
        Wallet updatedReceiverWallet = walletService.getWalletById(receiverWallet.getId());

        assertEquals(new BigDecimal("50800000").stripTrailingZeros(), updatedSenderWallet.getBalance().getAmount().stripTrailingZeros());
        assertEquals(new BigDecimal("50200000").stripTrailingZeros(), updatedReceiverWallet.getBalance().getAmount().stripTrailingZeros());
    }

    @Test
    public void testCompleteTransferFlow_Failed_InvalidPin() {
        String requestId = UUID.randomUUID().toString();
        Money transferAmount = Money.of(new BigDecimal("200000"), "VND");

        // Step 1: Init Transfer
        Transaction initTx = walletService.initTransfer(requestId, senderWallet.getId(), receiverWallet.getId(), "SENHONG", transferAmount, null);
        
        assertNotNull(initTx);
        assertEquals(TransactionStatus.PENDING_CONFIRMATION, initTx.getStatus());

        // Step 2: Confirm Transfer with wrong PIN
        assertThrows(InvalidPinException.class, () -> {
            if (!userService.verifyPin(sender.getId(), "999999")) {
                throw new InvalidPinException("Invalid PIN");
            }
            walletService.confirmTransfer(initTx.getId());
        });

        // Verify Balances remain unchanged
        Wallet updatedSenderWallet = walletService.getWalletById(senderWallet.getId());
        Wallet updatedReceiverWallet = walletService.getWalletById(receiverWallet.getId());

        assertEquals(new BigDecimal("51000000").stripTrailingZeros(), updatedSenderWallet.getBalance().getAmount().stripTrailingZeros());
        assertEquals(new BigDecimal("50000000").stripTrailingZeros(), updatedReceiverWallet.getBalance().getAmount().stripTrailingZeros());
    }

    @Test
    public void testCompleteTransferFlow_Failed_InsufficientBalance() {
        // Withdraw the 50M signup bonus so the balance is small enough to not hit limit
        walletService.withdraw(UUID.randomUUID().toString(), sender.getId(), senderWallet.getId(), "dummy-bank", Money.of(new BigDecimal("50000000"), "VND"));
        
        Wallet updatedSenderWalletBefore = walletService.getWalletById(senderWallet.getId());
        BigDecimal currentBalance = updatedSenderWalletBefore.getBalance().getAmount();

        String requestId = UUID.randomUUID().toString();
        Money excessiveAmount = Money.of(currentBalance.add(new BigDecimal("100000")), "VND"); // Slightly more than balance
        // Step 1: Init Transfer
        Transaction initTx = walletService.initTransfer(requestId, senderWallet.getId(), receiverWallet.getId(), "SENHONG", excessiveAmount, null);
        assertNotNull(initTx);

        // Step 2: Confirm Transfer fails due to insufficient balance
        assertThrows(com.fintech.wallet.domain.exception.InsufficientBalanceException.class, () -> {
            if (!userService.verifyPin(sender.getId(), "123456")) {
                throw new InvalidPinException("Invalid PIN");
            }
            walletService.confirmTransfer(initTx.getId());
        });

        // Verify Balances remain unchanged
        Wallet updatedSenderWallet = walletService.getWalletById(senderWallet.getId());
        Wallet updatedReceiverWallet = walletService.getWalletById(receiverWallet.getId());

        assertEquals(currentBalance.stripTrailingZeros(), updatedSenderWallet.getBalance().getAmount().stripTrailingZeros());
        assertEquals(new BigDecimal("50000000").stripTrailingZeros(), updatedReceiverWallet.getBalance().getAmount().stripTrailingZeros());
    }

    @Test
    public void testCompleteTransferFlow_Failed_ExceedDailyLimit() {
        String requestId = UUID.randomUUID().toString();
        Money overLimitAmount = Money.of(new BigDecimal("150000000"), "VND");

        // Step 1: Init Transfer fails immediately due to exceeding limit
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            walletService.initTransfer(requestId, senderWallet.getId(), receiverWallet.getId(), "SENHONG", overLimitAmount, null);
        });
        assertTrue(ex.getMessage().toLowerCase().contains("limit") || ex.getMessage().toLowerCase().contains("hạn mức"));

        // Verify Balances remain unchanged
        Wallet updatedSenderWallet = walletService.getWalletById(senderWallet.getId());
        Wallet updatedReceiverWallet = walletService.getWalletById(receiverWallet.getId());

        assertEquals(new BigDecimal("51000000").stripTrailingZeros(), updatedSenderWallet.getBalance().getAmount().stripTrailingZeros());
        assertEquals(new BigDecimal("50000000").stripTrailingZeros(), updatedReceiverWallet.getBalance().getAmount().stripTrailingZeros());
    }

    @Test
    public void testTransfer_FractionalAmounts_ShouldMaintainBalanceIntegrity() {
        String requestId = UUID.randomUUID().toString();
        Money fractionalAmount = Money.of(new BigDecimal("1000.55"), "VND");

        Transaction tx = walletService.transfer(requestId, senderWallet.getId(), receiverWallet.getId(), "SENHONG", fractionalAmount, null);

        assertEquals(TransactionStatus.SUCCESS, tx.getStatus());

        Wallet updatedSenderWallet = walletService.getWalletById(senderWallet.getId());
        Wallet updatedReceiverWallet = walletService.getWalletById(receiverWallet.getId());

        assertEquals(new BigDecimal("50998999.45").stripTrailingZeros(), updatedSenderWallet.getBalance().getAmount().stripTrailingZeros());
        assertEquals(new BigDecimal("50001000.55").stripTrailingZeros(), updatedReceiverWallet.getBalance().getAmount().stripTrailingZeros());
        
        // System Total Balance
        BigDecimal totalBefore = new BigDecimal("101000000"); // sender: 51M, receiver: 50M
        BigDecimal totalAfter = updatedSenderWallet.getBalance().getAmount().add(updatedReceiverWallet.getBalance().getAmount());
        assertEquals(totalBefore.stripTrailingZeros(), totalAfter.stripTrailingZeros());
    }

    @Test
    public void testPrintJsonForFrontend() throws Exception {
        String requestId = UUID.randomUUID().toString();
        Money transferAmount = Money.of(new BigDecimal("200000"), "VND");

        // Init Transfer
        Transaction initTx = walletService.initTransfer(requestId, senderWallet.getId(), receiverWallet.getId(), "SENHONG", transferAmount, null);
        
        // Confirm Transfer
        if (!userService.verifyPin(sender.getId(), "123456")) {
            throw new InvalidPinException("Invalid PIN");
        }
        Transaction confirmedTx = walletService.confirmTransfer(initTx.getId());

        // Map to Response
        TransferResponse response = TransferResponse.fromDomain(confirmedTx);
        
        // Manually set fields that controller usually sets
        com.fintech.wallet.domain.model.User sourceUser = userService.getUserById(sender.getId());
        response.setSenderName(sourceUser.getPhoneNumber()); // Assuming no KYC for this test
        response.setSenderAccount(sourceUser.getPhoneNumber());
        
        response.setIsInternal(true);
        com.fintech.wallet.domain.model.Wallet targetWallet = walletService.getWalletById(confirmedTx.getTargetWalletId());
        com.fintech.wallet.domain.model.User targetUser = userService.getUserById(targetWallet.getOwnerId());
        response.setRecipientName(targetUser.getPhoneNumber());
        response.setRecipientAccount(targetUser.getPhoneNumber());
        response.setCounterpartyName(targetUser.getPhoneNumber());
        response.setCounterpartyAccount(targetUser.getPhoneNumber());
        response.setCounterpartyBankName("SenHong");

        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        System.out.println("====== JSON RESPONSE FOR FRONTEND ======");
        System.out.println(mapper.writerWithDefaultPrettyPrinter().writeValueAsString(response));
        System.out.println("========================================");
    }
}

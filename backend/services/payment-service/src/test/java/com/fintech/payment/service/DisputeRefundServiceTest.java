package com.fintech.payment.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fintech.payment.audit.AuditEventPublisher;
import com.fintech.payment.domain.entity.DisputeCase;
import com.fintech.payment.domain.entity.OutboxEvent;
import com.fintech.payment.domain.entity.Transaction;
import com.fintech.payment.dto.dispute.CreateDisputeRequest;
import com.fintech.payment.dto.dispute.ResolveDisputeRequest;
import com.fintech.payment.grpc.WalletGrpcClient;
import com.fintech.payment.grpc.dto.WalletBalanceResult;
import com.fintech.payment.repository.DisputeCaseRepository;
import com.fintech.payment.repository.DisputeEventRepository;
import com.fintech.payment.repository.OutboxEventRepository;
import com.fintech.payment.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DisputeRefundServiceTest {

    @Mock
    private DisputeCaseRepository disputeCaseRepository;

    @Mock
    private DisputeEventRepository disputeEventRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private OutboxEventRepository outboxEventRepository;

    @Mock
    private WalletGrpcClient walletGrpcClient;

    @Mock
    private AuditEventPublisher auditEventPublisher;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @InjectMocks
    private DisputeRefundService service;

    private Transaction tx;

    @BeforeEach
    void setUp() {
        tx = Transaction.builder()
                .id("tx-test-01")
                .transactionCode("TXC-01")
                .sourceWalletId("wallet-source-01")
                .targetWalletId("wallet-target-02")
                .senderId("user-01")
                .receiverId("user-02")
                .amount(100_000L)
                .fee(2_000L)
                .currency("VND")
                .type("TRANSFER")
                .status("SUCCESS")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("Tạo khiếu nại tra soát thành công")
    void createDispute_success() {
        when(transactionRepository.findById("tx-test-01")).thenReturn(Optional.of(tx));
        when(disputeCaseRepository.existsByTransactionIdAndStatusNotIn(eq("tx-test-01"), any())).thenReturn(false);
        when(disputeCaseRepository.save(any(DisputeCase.class))).thenAnswer(inv -> inv.getArgument(0));

        CreateDisputeRequest request = new CreateDisputeRequest("tx-test-01", "WRONG_AMOUNT", "Chuyển nhầm số tiền", 50_000L);
        DisputeCase result = service.createDispute(request, "user-01", "user-01");

        assertNotNull(result);
        assertEquals("tx-test-01", result.getTransactionId());
        assertEquals("OPEN", result.getStatus());
        assertEquals(50_000L, result.getRefundAmount());
        assertEquals("Chuyển nhầm số tiền", result.getReason());

        verify(disputeEventRepository, times(1)).save(any());
        verify(disputeCaseRepository, times(1)).save(any());
    }

    @Test
    @DisplayName("Tạo khiếu nại báo lỗi xung đột nếu đã có phiếu tra soát chưa đóng")
    void createDispute_conflictWhenActiveDisputeExists() {
        when(transactionRepository.findById("tx-test-01")).thenReturn(Optional.of(tx));
        when(disputeCaseRepository.existsByTransactionIdAndStatusNotIn(eq("tx-test-01"), any())).thenReturn(true);

        CreateDisputeRequest request = new CreateDisputeRequest("tx-test-01", "GENERAL", "Lỗi mạng", null);
        assertThrows(ResponseStatusException.class, () -> service.createDispute(request, "user-01", "user-01"));
    }

    @Test
    @DisplayName("Duyệt hoàn tiền tra soát: gọi gRPC credit ví, đổi status tx thành REVERSED và ghi OutboxEvent")
    void resolveDispute_refund_success() {
        UUID disputeId = UUID.randomUUID();
        DisputeCase dispute = DisputeCase.builder()
                .id(disputeId)
                .transactionId("tx-test-01")
                .customerId("user-01")
                .status(DisputeCase.STATUS_OPEN)
                .refundAmount(102_000L)
                .reason("Khiếu nại không nhận được tiền")
                .createdBy("user-01")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        when(disputeCaseRepository.findById(disputeId)).thenReturn(Optional.of(dispute));
        when(transactionRepository.findById("tx-test-01")).thenReturn(Optional.of(tx));
        when(walletGrpcClient.credit(eq("wallet-source-01"), eq(102_000L), anyString(), anyString()))
                .thenReturn(WalletBalanceResult.builder().success(true).balanceAfter(500_000L).build());
        when(disputeCaseRepository.save(any(DisputeCase.class))).thenAnswer(inv -> inv.getArgument(0));

        ResolveDisputeRequest request = new ResolveDisputeRequest("REFUND", "Đồng ý hoàn tiền sau xác minh quầy");
        DisputeCase result = service.resolveDispute(disputeId, request, "manager-01");

        assertNotNull(result);
        assertEquals(DisputeCase.STATUS_REVERSED, result.getStatus());
        assertEquals("Đồng ý hoàn tiền sau xác minh quầy", result.getResolutionNote());
        assertEquals("manager-01", result.getResolvedBy());

        assertEquals("REVERSED", tx.getStatus());
        assertEquals(500_000L, tx.getSourceBalanceAfter());
        verify(transactionRepository, times(1)).save(tx);
        verify(outboxEventRepository, times(1)).save(any(OutboxEvent.class));
    }

    @Test
    @DisplayName("Từ chối khiếu nại tra soát: cập nhật REJECTED và không gọi credit ví")
    void resolveDispute_reject_success() {
        UUID disputeId = UUID.randomUUID();
        DisputeCase dispute = DisputeCase.builder()
                .id(disputeId)
                .transactionId("tx-test-01")
                .customerId("user-01")
                .status(DisputeCase.STATUS_OPEN)
                .refundAmount(102_000L)
                .reason("Khiếu nại không hợp lệ")
                .createdBy("user-01")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();

        when(disputeCaseRepository.findById(disputeId)).thenReturn(Optional.of(dispute));
        when(disputeCaseRepository.save(any(DisputeCase.class))).thenAnswer(inv -> inv.getArgument(0));

        ResolveDisputeRequest request = new ResolveDisputeRequest("REJECT", "Giao dịch đã được bên nhận rút thành công");
        DisputeCase result = service.resolveDispute(disputeId, request, "manager-01");

        assertNotNull(result);
        assertEquals(DisputeCase.STATUS_REJECTED, result.getStatus());
        assertEquals("manager-01", result.getResolvedBy());

        verify(walletGrpcClient, never()).credit(any(), any(), any(), any());
        verify(outboxEventRepository, never()).save(any());
    }

    @Test
    @DisplayName("Thực hiện đảo bút toán trực tiếp (Direct Reversal)")
    void executeDirectReversal_success() {
        when(transactionRepository.findById("tx-test-01")).thenReturn(Optional.of(tx));
        when(walletGrpcClient.credit(eq("wallet-source-01"), eq(102_000L), anyString(), anyString()))
                .thenReturn(WalletBalanceResult.builder().success(true).balanceAfter(602_000L).build());
        when(disputeCaseRepository.findFirstByTransactionIdAndStatusNotIn(eq("tx-test-01"), any()))
                .thenReturn(Optional.empty());

        Transaction reversed = service.executeDirectReversal("tx-test-01", "Giao dịch lỗi hạch toán quầy", "manager-01");

        assertNotNull(reversed);
        assertEquals("REVERSED", reversed.getStatus());
        assertEquals(602_000L, reversed.getSourceBalanceAfter());
        verify(transactionRepository, times(1)).save(reversed);
        verify(outboxEventRepository, times(1)).save(any(OutboxEvent.class));
    }
}

package com.fintech.payment.service;

import com.fintech.payment.dto.eod.PaymentEodGateResponse;
import com.fintech.payment.outbox.OutboxRelay;
import com.fintech.payment.repository.AmlCaseRepository;
import com.fintech.payment.repository.CashDepositRepository;
import com.fintech.payment.repository.CashInTransitRepository;
import com.fintech.payment.repository.DisputeCaseRepository;
import com.fintech.payment.repository.OutboxEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PaymentEodOpsServiceTest {

    @Mock
    private CashDepositRepository cashDepositRepository;

    @Mock
    private CashInTransitRepository cashInTransitRepository;

    @Mock
    private DisputeCaseRepository disputeCaseRepository;

    @Mock
    private AmlCaseRepository amlCaseRepository;

    @Mock
    private OutboxEventRepository outboxEventRepository;

    @Mock
    private OutboxRelay outboxRelay;

    private PaymentEodOpsService service;

    @BeforeEach
    void setUp() {
        service = new PaymentEodOpsService(
                cashDepositRepository,
                cashInTransitRepository,
                disputeCaseRepository,
                amlCaseRepository,
                outboxEventRepository,
                outboxRelay
        );
    }

    @Test
    void checkEodGate_whenAllCleared_shouldReturnCleared() {
        when(cashDepositRepository.countByStatus(any())).thenReturn(0L);
        when(cashInTransitRepository.countByStatusIn(any())).thenReturn(0L);
        when(disputeCaseRepository.countByStatusIn(any())).thenReturn(0L);
        when(amlCaseRepository.countByStatusIn(any())).thenReturn(0L);
        when(outboxEventRepository.countByStatus(eq("PENDING"))).thenReturn(0L);
        when(outboxEventRepository.countByStatus(eq("FAILED"))).thenReturn(0L);

        PaymentEodGateResponse response = service.checkEodGate();

        assertThat(response.isCanCloseEod()).isTrue();
        assertThat(response.getGateStatus()).isEqualTo("CLEARED");
        assertThat(response.getPendingMakerCheckerTotal()).isEqualTo(0);
        assertThat(response.getPendingOutboxCount()).isEqualTo(0);
        assertThat(response.getBlockingReasons()).isEmpty();
    }

    @Test
    void checkEodGate_whenPendingDepositsAndOutbox_shouldReturnBlocked() {
        when(cashDepositRepository.countByStatus(any())).thenReturn(2L);
        when(cashInTransitRepository.countByStatusIn(any())).thenReturn(0L);
        when(disputeCaseRepository.countByStatusIn(any())).thenReturn(1L);
        when(amlCaseRepository.countByStatusIn(any())).thenReturn(0L);
        when(outboxEventRepository.countByStatus(eq("PENDING"))).thenReturn(3L);
        when(outboxEventRepository.countByStatus(eq("FAILED"))).thenReturn(0L);

        PaymentEodGateResponse response = service.checkEodGate();

        assertThat(response.isCanCloseEod()).isFalse();
        assertThat(response.getGateStatus()).isEqualTo("BLOCKED");
        assertThat(response.getPendingCashDeposits()).isEqualTo(2);
        assertThat(response.getPendingDisputes()).isEqualTo(1);
        assertThat(response.getPendingMakerCheckerTotal()).isEqualTo(3);
        assertThat(response.getPendingOutboxCount()).isEqualTo(3);
        assertThat(response.getBlockingReasons()).hasSize(3);
    }

    @Test
    void drainOutbox_shouldTriggerRelay() {
        when(outboxEventRepository.countByStatus("PENDING")).thenReturn(0L);

        long remaining = service.drainOutbox();

        verify(outboxRelay, atLeastOnce()).relayPendingEvents();
        assertThat(remaining).isEqualTo(0L);
    }
}

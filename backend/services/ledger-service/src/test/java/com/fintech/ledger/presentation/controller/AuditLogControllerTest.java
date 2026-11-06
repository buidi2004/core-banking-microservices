package com.fintech.ledger.presentation.controller;

import com.fintech.ledger.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.fintech.ledger.infrastructure.persistence.repository.SpringAuditLogRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuditLogControllerTest {

    @Mock
    private SpringAuditLogRepository repository;

    @InjectMocks
    private AuditLogController controller;

    @Test
    void rejectsNonManagerWithoutQueryingRepository() {
        assertThrows(ResponseStatusException.class,
                () -> controller.list("ROLE_TELLER", null, null, null, null));

        verifyNoInteractions(repository);
    }

    @Test
    void managerCanQueryByCorrelationId() {
        List<AuditLogJpaEntity> expected = List.of();
        when(repository.findTop500ByCorrelationIdOrderByPerformedAtDesc("corr-1"))
                .thenReturn(expected);

        var response = controller.list("MANAGER", null, null, null, " corr-1 ");

        assertEquals(expected, response.getBody().getData());
        verify(repository).findTop500ByCorrelationIdOrderByPerformedAtDesc("corr-1");
    }

    @Test
    void managerCanQueryByActor() {
        List<AuditLogJpaEntity> expected = List.of();
        when(repository.findTop500ByPerformedByOrderByPerformedAtDesc("user-1"))
                .thenReturn(expected);

        var response = controller.list("ROLE_MANAGER", " user-1 ", null, null, null);

        assertEquals(expected, response.getBody().getData());
        verify(repository).findTop500ByPerformedByOrderByPerformedAtDesc("user-1");
    }
}

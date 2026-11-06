package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "aml_case_events")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmlCaseEvent {
    @Id
    private UUID id;
    @Column(name = "case_id", nullable = false)
    private UUID caseId;
    @Column(nullable = false)
    private String actorId;
    @Column(nullable = false)
    private String action;
    @Column(nullable = false, length = 1000)
    private String reason;
    @Column(nullable = false)
    private Instant createdAt;
}

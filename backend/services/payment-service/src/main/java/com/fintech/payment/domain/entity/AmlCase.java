package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "aml_cases")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmlCase {
    public static final String OPEN = "OPEN";
    public static final String ASSIGNED = "ASSIGNED";
    public static final String INVESTIGATING = "INVESTIGATING";
    public static final String FROZEN = "FROZEN";
    public static final String RELEASED = "RELEASED";
    public static final String CLOSED = "CLOSED";

    @Id
    private UUID id;
    @Column(name = "transaction_id", nullable = false)
    private String transactionId;
    private String customerId;
    @Column(nullable = false)
    private String status;
    @Column(nullable = false, length = 1000)
    private String reason;
    private String assignedTo;
    @Column(nullable = false)
    private String createdBy;
    @Column(nullable = false)
    private Instant slaDueAt;
    @Column(nullable = false)
    private Instant createdAt;
    @Column(nullable = false)
    private Instant updatedAt;
    private Instant closedAt;
    @Version
    private Long version;
}

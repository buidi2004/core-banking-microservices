package com.fintech.payment.domain.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "cards", indexes = {
        @Index(name = "idx_cards_user", columnList = "user_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Card {

    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", length = 36, nullable = false)
    private String userId;

    @Column(name = "card_number", length = 19, nullable = false)
    private String cardNumber;

    @Column(name = "masked_number", length = 25, nullable = false)
    private String maskedNumber;

    @Column(name = "card_holder", length = 100, nullable = false)
    private String cardHolder;

    @Column(name = "card_type", length = 20, nullable = false)
    private String cardType; // CREDIT, DEBIT, VIRTUAL

    @Column(name = "card_tier", length = 50, nullable = false)
    private String cardTier;

    @Column(name = "scheme", length = 20, nullable = false)
    private String scheme; // VISA, NAPAS, MASTERCARD

    @Column(name = "expiry_date", length = 10, nullable = false)
    private String expiryDate;

    @Column(name = "cvv", length = 4, nullable = false)
    private String cvv;

    @Column(name = "credit_limit", precision = 19, scale = 4, nullable = false)
    private BigDecimal creditLimit;

    @Column(name = "available_limit", precision = 19, scale = 4, nullable = false)
    private BigDecimal availableLimit;

    @Column(name = "status", length = 20, nullable = false)
    private String status; // ACTIVE, LOCKED, BLOCKED

    @Column(name = "color_scheme", length = 30, nullable = false)
    private String colorScheme;

    @Column(name = "is_physical", nullable = false)
    private Boolean physical;

    @Column(name = "delivery_address", length = 255)
    private String deliveryAddress;

    @Column(name = "online_payment", nullable = false)
    private Boolean onlinePayment;

    @Column(name = "intl_payment", nullable = false)
    private Boolean intlPayment;

    @Column(name = "contactless", nullable = false)
    private Boolean contactless;

    @Column(name = "atm_withdraw", nullable = false)
    private Boolean atmWithdraw;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;

    @PrePersist
    public void prePersist() {
        if (id == null) id = UUID.randomUUID().toString();
        if (createdAt == null) createdAt = Instant.now();
        if (updatedAt == null) updatedAt = Instant.now();
        if (status == null) status = "ACTIVE";
        if (colorScheme == null) colorScheme = "platinum";
        if (physical == null) physical = false;
        if (onlinePayment == null) onlinePayment = true;
        if (intlPayment == null) intlPayment = true;
        if (contactless == null) contactless = true;
        if (atmWithdraw == null) atmWithdraw = true;
        if (creditLimit == null) creditLimit = BigDecimal.ZERO;
        if (availableLimit == null) availableLimit = BigDecimal.ZERO;
    }
}


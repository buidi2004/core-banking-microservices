package com.fintech.wallet.domain.model;

/**
 * Status of a P2P money request.
 */
public enum MoneyRequestStatus {
    PENDING,    // Request created, waiting for payer to accept or reject
    ACCEPTED,   // Payer accepted and payment was successful
    REJECTED,   // Payer explicitly rejected the request
    CANCELLED,  // Requester cancelled before payer responded
    EXPIRED     // Request expired (e.g., after 7 days)
}

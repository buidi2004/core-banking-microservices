package com.fintech.ledger.domain.model;

public enum JournalEntryStatus {
    /** Chứng từ gốc */
    POSTED,
    /** Chứng từ bù hoàn lại chứng từ gốc (append-only: không UPDATE chứng từ gốc) */
    REVERSAL
}

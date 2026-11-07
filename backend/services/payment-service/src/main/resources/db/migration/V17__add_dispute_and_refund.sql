CREATE TABLE dispute_cases (
    id UUID PRIMARY KEY,
    transaction_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100),
    dispute_type VARCHAR(50) NOT NULL,
    reason VARCHAR(1000) NOT NULL,
    status VARCHAR(32) NOT NULL,
    refund_amount BIGINT NOT NULL,
    resolution_note VARCHAR(1000),
    created_by VARCHAR(100) NOT NULL,
    assigned_to VARCHAR(100),
    resolved_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    version BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_dispute_cases_status_created ON dispute_cases(status, created_at DESC);
CREATE INDEX idx_dispute_cases_transaction ON dispute_cases(transaction_id);
CREATE INDEX idx_dispute_cases_customer ON dispute_cases(customer_id);

CREATE TABLE dispute_events (
    id UUID PRIMARY KEY,
    dispute_id UUID NOT NULL REFERENCES dispute_cases(id) ON DELETE CASCADE,
    actor_id VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    note VARCHAR(1000),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_dispute_events_dispute_created ON dispute_events(dispute_id, created_at ASC);


CREATE TABLE aml_cases (
    id UUID PRIMARY KEY,
    transaction_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100),
    status VARCHAR(32) NOT NULL,
    reason VARCHAR(1000) NOT NULL,
    assigned_to VARCHAR(100),
    created_by VARCHAR(100) NOT NULL,
    sla_due_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE,
    version BIGINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_aml_cases_status_sla ON aml_cases(status, sla_due_at);
CREATE INDEX idx_aml_cases_transaction ON aml_cases(transaction_id);

CREATE TABLE aml_case_events (
    id UUID PRIMARY KEY,
    case_id UUID NOT NULL REFERENCES aml_cases(id),
    actor_id VARCHAR(100) NOT NULL,
    action VARCHAR(32) NOT NULL,
    reason VARCHAR(1000) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_aml_case_events_case_created ON aml_case_events(case_id, created_at);


CREATE TABLE IF NOT EXISTS audit.pipeline_runs (
    run_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    source_rows BIGINT,
    loaded_rows BIGINT,
    status VARCHAR(20) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    duration_seconds NUMERIC(12, 3),
    error_message TEXT,
    CONSTRAINT chk_pipeline_status
        CHECK (status IN ('SUCCESS', 'FAILED'))
);
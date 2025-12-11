-- ====================================================================
-- Quarantine Schema:  Rejected Records with Validation Failures
-- ====================================================================

CREATE SCHEMA IF NOT EXISTS quarantine;

-- ====================================================================
-- Main Quarantine Table
-- ====================================================================

CREATE TABLE IF NOT EXISTS quarantine.customer_profile_rejected (
    -- ================================================================
    -- QUARANTINE METADATA (Primary)
    -- ================================================================
    rejection_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rejection_reason TEXT NOT NULL,
    rejection_code VARCHAR(100) NOT NULL,
    rejection_severity VARCHAR(20) DEFAULT 'ERROR',  -- ERROR, WARNING, CRITICAL
    
    -- ================================================================
    -- SOURCE TRACKING
    -- ================================================================
    source_system VARCHAR(100) DEFAULT 'MSSQL_CORE',
    bronze_batch_id BIGINT,
    bronze_load_ts TIMESTAMP,
    silver_load_attempt_ts TIMESTAMP,
    
    -- ================================================================
    -- RESOLUTION TRACKING
    -- ================================================================
    resolution_status VARCHAR(50) DEFAULT 'PENDING',  -- PENDING, FIXED, REPROCESSED, IGNORED
    resolved_timestamp TIMESTAMP,
    resolved_by VARCHAR(100),
    resolution_notes TEXT,
    retry_count INT DEFAULT 0,
    
    -- ================================================================
    -- ALL ORIGINAL COLUMNS (Bronze structure)
    -- ================================================================
    customer_id VARCHAR(50),
    evidence_unique_key VARCHAR(100),
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local VARCHAR(200),
    lastname_local VARCHAR(200),
    person_title VARCHAR(50),
    person_title_other VARCHAR(200),
    marital_status VARCHAR(50),
    nationality VARCHAR(2),
    nationality_other VARCHAR(200),
    occupation VARCHAR(100),
    occupation_other VARCHAR(200),
    education_level VARCHAR(100),
    education_level_other VARCHAR(200),
    business_type VARCHAR(100),
    business_type_other VARCHAR(200),
    birthdate DATE,
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(2),
    income_country_other VARCHAR(200),
    source_of_income_list TEXT,
    purpose_of_investment_list TEXT,
    last_modified_ts TIMESTAMP,
    
    -- ================================================================
    -- DATA QUALITY SCORES (from Silver attempt)
    -- ================================================================
    dq_score NUMERIC(5,2),
    dq_status VARCHAR(20),
    failed_validations JSONB,  -- Details of which validations failed
    
    -- ================================================================
    -- INDEXES
    -- ================================================================
    CONSTRAINT chk_rejection_severity CHECK (rejection_severity IN ('WARNING', 'ERROR', 'CRITICAL')),
    CONSTRAINT chk_resolution_status CHECK (resolution_status IN ('PENDING', 'FIXED', 'REPROCESSED', 'IGNORED', 'DUPLICATE'))
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

CREATE INDEX idx_quarantine_customer_id 
    ON quarantine.customer_profile_rejected(customer_id);

CREATE INDEX idx_quarantine_rejection_ts 
    ON quarantine.customer_profile_rejected(rejection_timestamp);

CREATE INDEX idx_quarantine_rejection_code 
    ON quarantine.customer_profile_rejected(rejection_code);

CREATE INDEX idx_quarantine_resolution_status 
    ON quarantine.customer_profile_rejected(resolution_status) 
    WHERE resolution_status = 'PENDING';

CREATE INDEX idx_quarantine_bronze_batch 
    ON quarantine.customer_profile_rejected(bronze_batch_id);

CREATE INDEX idx_quarantine_severity 
    ON quarantine.customer_profile_rejected(rejection_severity);

-- ================================================================
-- COMMENTS
-- ================================================================

COMMENT ON TABLE quarantine.customer_profile_rejected IS 
    'Quarantine table for customer profile records that failed validation. 
     Records are moved here from Bronze when they cannot be processed into Silver.
     Track rejection reasons, allow manual review, and support reprocessing after fixes.';

COMMENT ON COLUMN quarantine.customer_profile_rejected.rejection_code IS 
    'Short code for rejection reason (e.g., MISSING_CUSTOMER_ID, INVALID_ENUM, DQ_THRESHOLD_FAILED)';

COMMENT ON COLUMN quarantine.customer_profile_rejected.rejection_reason IS 
    'Detailed explanation of why record was rejected, including failed validations';

COMMENT ON COLUMN quarantine.customer_profile_rejected.failed_validations IS 
    'JSONB structure containing details of each failed validation check';

COMMENT ON COLUMN quarantine.customer_profile_rejected.resolution_status IS 
    'PENDING = awaiting review, FIXED = corrected in source, REPROCESSED = successfully reloaded, IGNORED = accepted as-is';
	
	
	
-- ====================================================================
-- Quarantine Summary View (for monitoring dashboards)
-- ====================================================================

CREATE OR REPLACE VIEW quarantine.vw_quarantine_summary AS
SELECT 
    rejection_code,
    rejection_severity,
    resolution_status,
    COUNT(*) AS record_count,
    MIN(rejection_timestamp) AS first_occurrence,
    MAX(rejection_timestamp) AS last_occurrence,
    COUNT(DISTINCT customer_id) AS unique_customers,
    AVG(retry_count) AS avg_retry_count
FROM quarantine.customer_profile_rejected
GROUP BY rejection_code, rejection_severity, resolution_status
ORDER BY record_count DESC;

COMMENT ON VIEW quarantine.vw_quarantine_summary IS 
    'Summary of quarantined records by rejection code and status - use for monitoring';

-- ====================================================================
-- Recent Rejections View (for operational monitoring)
-- ====================================================================

CREATE OR REPLACE VIEW quarantine.vw_recent_rejections AS
SELECT 
    quarantine_id,
    customer_id,
    rejection_timestamp,
    rejection_code,
    rejection_reason,
    rejection_severity,
    resolution_status,
    bronze_batch_id
FROM quarantine.customer_profile_rejected
WHERE rejection_timestamp > CURRENT_TIMESTAMP - INTERVAL '7 days'
  AND resolution_status = 'PENDING'
ORDER BY rejection_timestamp DESC;

COMMENT ON VIEW quarantine.vw_recent_rejections IS 
    'Recent unresolved quarantine records from last 7 days - use for alerting';
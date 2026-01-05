-- =====================================================================
-- Quarantine Layer:  Customer Profile Rejected Records
-- =====================================================================
-- Source Contract: contracts/quarantine/customer_profile_rejected. yaml
-- Database: PostgreSQL
-- Layer:  Quarantine
-- Created: 2026-01-05
-- =====================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS quarantine;

-- Drop table if exists (for development only - comment out in production)
-- DROP TABLE IF EXISTS quarantine.customer_profile_rejected CASCADE;

-- =====================================================================
-- CREATE TABLE
-- =====================================================================
CREATE TABLE quarantine.customer_profile_rejected (
    -- ================================================================
    -- SURROGATE KEY
    -- ================================================================
    rejection_id BIGSERIAL PRIMARY KEY,
    
    -- ================================================================
    -- ORIGINAL DATA (from Silver)
    -- ================================================================
    customer_id VARCHAR(50) NOT NULL,
    evidence_unique_key VARCHAR(100),
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local VARCHAR(200),
    lastname_local VARCHAR(200),
    person_title VARCHAR(50),
    person_title_other VARCHAR(500),
    marital_status VARCHAR(50),
    nationality VARCHAR(50),
    nationality_other VARCHAR(500),
    occupation VARCHAR(100),
    occupation_other VARCHAR(500),
    education_level VARCHAR(100),
    education_level_other VARCHAR(500),
    business_type VARCHAR(100),
    business_type_other VARCHAR(500),
    birthdate DATE,
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(50),
    income_country_other VARCHAR(500),
    source_of_income_list TEXT,
    purpose_of_investment_list TEXT,
    last_modified_ts TIMESTAMP NOT NULL,
    
    -- ================================================================
    -- DATA QUALITY FLAGS (from Silver)
    -- ================================================================
    is_valid_person_title BOOLEAN,
    is_valid_marital_status BOOLEAN,
    is_valid_nationality BOOLEAN,
    is_valid_occupation BOOLEAN,
    is_valid_education_level BOOLEAN,
    is_valid_business_type BOOLEAN,
    is_valid_total_asset BOOLEAN,
    is_valid_monthly_income BOOLEAN,
    is_valid_income_country BOOLEAN,
    is_valid_birthdate BOOLEAN,
    is_valid_source_of_income_list BOOLEAN,
    is_valid_purpose_of_investment_list BOOLEAN,
    
    -- ================================================================
    -- REJECTION METADATA
    -- ================================================================
    rejection_code VARCHAR(100) NOT NULL,
    rejection_reason TEXT NOT NULL,
    rejection_severity VARCHAR(20) NOT NULL,
    data_quality_score NUMERIC(5,2),
    data_quality_status VARCHAR(50),
    
    -- ================================================================
    -- LINEAGE & AUDIT
    -- ================================================================
    silver_load_attempt_ts TIMESTAMP NOT NULL,
    rejection_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _bronze_batch_id BIGINT,
    
    -- ================================================================
    -- CONSTRAINTS
    -- ================================================================
    
    -- Rejection severity validation
    CONSTRAINT chk_rejection_severity
        CHECK (rejection_severity IN ('CRITICAL', 'ERROR', 'WARNING')),
    
    -- Rejection code validation (matches rejection_rules. yml)
    CONSTRAINT chk_rejection_code
        CHECK (rejection_code IN (
            -- Critical errors
            'MISSING_CUSTOMER_ID',
            'MISSING_EVIDENCE_KEY',
            'DUPLICATE_PRIMARY_KEY',
            -- Validation errors
            'DQ_THRESHOLD_FAILED',
            'INVALID_PERSON_TITLE',
            'PERSON_TITLE_OTHER_INCOMPLETE',
            'INVALID_MARITAL_STATUS',
            'INVALID_BIRTHDATE',
            'INVALID_NATIONALITY',
            'INVALID_OCCUPATION',
            'INVALID_EDUCATION_LEVEL',
            'INVALID_BUSINESS_TYPE',
            'INVALID_INCOME_COUNTRY',
            'MULTIPLE_VALIDATION_FAILURES',
            -- Warnings
            'LOW_DQ_SCORE',
            'MISSING_OPTIONAL_FIELD'
        )),
    
    -- Data quality score range
    CONSTRAINT chk_quarantine_dq_score
        CHECK (data_quality_score IS NULL OR data_quality_score BETWEEN 0.00 AND 100.00)
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- Lookup by customer
CREATE INDEX idx_quarantine_customer_id 
    ON quarantine.customer_profile_rejected(customer_id);

-- Lookup by rejection code
CREATE INDEX idx_quarantine_rejection_code 
    ON quarantine.customer_profile_rejected(rejection_code);

-- Lookup by rejection severity
CREATE INDEX idx_quarantine_rejection_severity 
    ON quarantine.customer_profile_rejected(rejection_severity);

-- Time-based queries
CREATE INDEX idx_quarantine_rejection_ts 
    ON quarantine.customer_profile_rejected(rejection_ts);

-- Silver load attempt tracking
CREATE INDEX idx_quarantine_silver_attempt_ts 
    ON quarantine.customer_profile_rejected(silver_load_attempt_ts);

-- Data quality filtering
CREATE INDEX idx_quarantine_dq_score
    ON quarantine.customer_profile_rejected(data_quality_score);

-- ================================================================
-- COMMENTS (Documentation)
-- ================================================================

COMMENT ON TABLE quarantine.customer_profile_rejected IS 
    'Quarantine table for rejected customer profile records. 
     Source:  silver. customer_profile_standardized (failed validations)
     Grain: One row per rejection event
     Pattern: Append-only audit trail
     
     Usage: 
     - Track data quality issues over time
     - Analyze rejection patterns
     - Reprocess after fixes
     - Alert on critical errors
     
     Rejection Rules:  See dbt/models/silver/rejection_rules.yml';

COMMENT ON COLUMN quarantine.customer_profile_rejected.rejection_id IS 
    'Surrogate key - auto-incrementing primary key for rejection event. ';

COMMENT ON COLUMN quarantine.customer_profile_rejected.rejection_code IS 
    'Categorized rejection reason code from rejection_rules.yml';

COMMENT ON COLUMN quarantine.customer_profile_rejected.rejection_reason IS 
    'Human-readable explanation of why record was rejected';

COMMENT ON COLUMN quarantine.customer_profile_rejected.rejection_severity IS 
    'CRITICAL = cannot process, ERROR = should quarantine, WARNING = can process but flagged';

COMMENT ON COLUMN quarantine.customer_profile_rejected.silver_load_attempt_ts IS 
    'Timestamp when Silver tried to process this record';

COMMENT ON COLUMN quarantine.customer_profile_rejected.rejection_ts IS 
    'Timestamp when record was moved to quarantine';

-- ================================================================
-- NOTES
-- ================================================================
-- 1. Append-only table - records are never deleted (only archived)
-- 2. Same record can appear multiple times (one per rejection event)
-- 3. Use for monitoring, alerting, and data quality improvement
-- 4. Records can be reprocessed after source data is fixed
-- 5. Retention:  Keep for 1 year then archive to cold storage
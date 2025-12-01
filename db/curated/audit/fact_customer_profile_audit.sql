-- =====================================================================
-- Curated Layer: fact_customer_profile_audit
-- Audit fact tracking all profile change events (SCD2 versions)
-- =====================================================================
-- Source Contract: contracts/customer/fact_customer_profile_audit.yaml
-- Database: PostgreSQL
-- Layer: Curated (Gold)
-- Created: 2025-12-01
-- =====================================================================

-- Drop table if exists (for development only)
-- DROP TABLE IF EXISTS curated.fact_customer_profile_audit CASCADE;

-- Create schema if not exists (already created in dimension script)
-- CREATE SCHEMA IF NOT EXISTS curated;

-- Create sequence for surrogate key
CREATE SEQUENCE IF NOT EXISTS curated.seq_customer_profile_audit_event_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Create table
CREATE TABLE curated.fact_customer_profile_audit (
    -- Surrogate Key
    audit_event_id BIGINT NOT NULL DEFAULT nextval('curated.seq_customer_profile_audit_event_id'),
    
    -- Natural Keys
    customer_id BIGINT NOT NULL,
    customer_profile_version_sk_new BIGINT NOT NULL,
    customer_profile_version_sk_old BIGINT,
    
    -- Version Tracking
    version_num_new INT NOT NULL,
    version_num_old INT,
    
    -- Change Classification
    change_reason VARCHAR(50) NOT NULL,
    
    -- Change Details (JSON)
    changed_scalar_attributes TEXT NOT NULL,
    changed_set_names TEXT NOT NULL,
    scalar_attribute_old_values TEXT,
    scalar_attribute_new_values TEXT NOT NULL,
    set_membership_diff_summary TEXT,
    
    -- Hashes
    old_profile_hash VARCHAR(64),
    new_profile_hash VARCHAR(64) NOT NULL,
    
    -- Timestamps
    event_source_ts TIMESTAMP NOT NULL,
    event_detected_ts TIMESTAMP NOT NULL,
    effective_start_ts_new TIMESTAMP NOT NULL,
    processing_latency_seconds INT,
    
    -- Audit Trail
    initiated_by_system VARCHAR(100),
    initiated_by_user_id VARCHAR(100),
    
    -- ETL Metadata
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Primary Key
    CONSTRAINT pk_customer_profile_audit PRIMARY KEY (audit_event_id),
    
    -- Unique Constraint
    CONSTRAINT uk_audit_customer_version_new UNIQUE (customer_id, customer_profile_version_sk_new),
    
    -- Foreign Keys
    CONSTRAINT fk_audit_profile_version_new FOREIGN KEY (customer_profile_version_sk_new)
        REFERENCES curated.dim_customer_profile (customer_profile_version_sk)
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_audit_profile_version_old FOREIGN KEY (customer_profile_version_sk_old)
        REFERENCES curated.dim_customer_profile (customer_profile_version_sk)
        ON DELETE RESTRICT,
    
    -- Check Constraints
    CONSTRAINT chk_audit_change_reason CHECK (
        change_reason IN (
            'INITIAL_LOAD', 'SOURCE_UPDATE', 'CORRECTION', 
            'DATA_QUALITY_FIX', 'BACKDATED_CORRECTION', 'RECOMPUTE_HASH'
        )
    ),
    CONSTRAINT chk_audit_initial_load_null_old CHECK (
        (change_reason = 'INITIAL_LOAD' AND customer_profile_version_sk_old IS NULL) OR
        (change_reason != 'INITIAL_LOAD' AND customer_profile_version_sk_old IS NOT NULL)
    ),
    CONSTRAINT chk_audit_hash_length_new CHECK (LENGTH(new_profile_hash) = 64),
    CONSTRAINT chk_audit_hash_length_old CHECK (
        old_profile_hash IS NULL OR LENGTH(old_profile_hash) = 64
    ),
    CONSTRAINT chk_audit_version_sequence CHECK (
        (version_num_old IS NULL AND version_num_new = 1) OR
        (version_num_old IS NOT NULL AND version_num_new = version_num_old + 1)
    ),
    CONSTRAINT chk_audit_change_not_empty CHECK (
        changed_scalar_attributes != '[]' OR changed_set_names != '[]'
    )
);

-- Indexes
CREATE INDEX idx_audit_customer_id 
    ON curated.fact_customer_profile_audit (customer_id);

CREATE INDEX idx_audit_event_source_ts 
    ON curated. fact_customer_profile_audit (event_source_ts);

CREATE INDEX idx_audit_change_reason 
    ON curated.fact_customer_profile_audit (change_reason);

CREATE INDEX idx_audit_version_new 
    ON curated.fact_customer_profile_audit (customer_profile_version_sk_new);

CREATE INDEX idx_audit_version_old 
    ON curated.fact_customer_profile_audit (customer_profile_version_sk_old);

CREATE INDEX idx_audit_load_ts 
    ON curated.fact_customer_profile_audit (load_ts);

-- Comments on table
COMMENT ON TABLE curated. fact_customer_profile_audit IS 
'Audit fact table tracking all profile change events that created new SCD2 versions.   One row per version creation event with JSON change details.';

-- Comments on columns
COMMENT ON COLUMN curated.fact_customer_profile_audit.audit_event_id IS 
'Surrogate identifier for the audit event (auto-increment)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.customer_id IS 
'Customer identifier affected by this change';

COMMENT ON COLUMN curated.fact_customer_profile_audit.customer_profile_version_sk_new IS 
'Surrogate key of newly created profile version';

COMMENT ON COLUMN curated.fact_customer_profile_audit.customer_profile_version_sk_old IS 
'Surrogate key of previous profile version (NULL for INITIAL_LOAD)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.version_num_new IS 
'Version number of new profile version';

COMMENT ON COLUMN curated.fact_customer_profile_audit.version_num_old IS 
'Version number of old profile version (NULL for initial)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.change_reason IS 
'Categorized reason for profile version creation: INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, DATA_QUALITY_FIX, BACKDATED_CORRECTION, RECOMPUTE_HASH.   See enumerations/customer_profile_audit_change_reason.yaml';

COMMENT ON COLUMN curated. fact_customer_profile_audit. changed_scalar_attributes IS 
'JSON array of scalar attribute names that changed (e.g., ["firstname","occupation","birthdate"]).  Valid values defined in enumerations/customer_profile_attribute_names.yaml';

COMMENT ON COLUMN curated.fact_customer_profile_audit.changed_set_names IS 
'JSON array of multi-valued set names that changed (e.g., ["source_of_income","purpose_of_investment"])';

COMMENT ON COLUMN curated.fact_customer_profile_audit.scalar_attribute_old_values IS 
'JSON object with old values of changed scalar attributes only (e.g., {"occupation":"EMPLOYEE","birthdate":"1985-03-10"})';

COMMENT ON COLUMN curated.fact_customer_profile_audit.scalar_attribute_new_values IS 
'JSON object with new values of changed scalar attributes only';

COMMENT ON COLUMN curated.fact_customer_profile_audit.set_membership_diff_summary IS 
'JSON object with counts of added/removed members per set (e.g., {"source_of_income":{"added":1,"removed":0}})';

COMMENT ON COLUMN curated.fact_customer_profile_audit.old_profile_hash IS 
'Profile hash of previous version (NULL for initial load)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.new_profile_hash IS 
'Profile hash of new version (must match dim_customer_profile)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.event_source_ts IS 
'Business timestamp when source system recorded the change';

COMMENT ON COLUMN curated.fact_customer_profile_audit.event_detected_ts IS 
'Timestamp when ETL process detected the change';

COMMENT ON COLUMN curated.fact_customer_profile_audit.effective_start_ts_new IS 
'Effective start timestamp of new version (copied from dimension for convenience)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.processing_latency_seconds IS 
'Seconds between event_source_ts and event_detected_ts (may be negative for backdated corrections)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.initiated_by_system IS 
'Source system code that initiated change (e.g., CRM, KYC_PORTAL, SURVEY_APP, ETL_CORRECTION)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.initiated_by_user_id IS 
'User identifier if manual correction/update (NULL for automated processes)';

COMMENT ON COLUMN curated.fact_customer_profile_audit.load_ts IS 
'ETL ingestion timestamp for this audit event';

-- Grant permissions
GRANT SELECT ON curated.fact_customer_profile_audit TO dw_etl_service;
GRANT INSERT ON curated.fact_customer_profile_audit TO dw_etl_service;
GRANT SELECT ON curated.fact_customer_profile_audit TO dw_privileged;
GRANT SELECT ON curated.fact_customer_profile_audit TO dw_analyst;

GRANT USAGE, SELECT ON SEQUENCE curated.seq_customer_profile_audit_event_id TO dw_etl_service;

-- =====================================================================
-- Example Queries
-- =====================================================================

-- Query 1: Get all changes for a customer
/*
SELECT 
    audit_event_id,
    version_num_new,
    change_reason,
    changed_scalar_attributes,
    changed_set_names,
    event_source_ts,
    initiated_by_system
FROM curated.fact_customer_profile_audit
WHERE customer_id = 12345
ORDER BY event_source_ts;
*/

-- Query 2: Get change details for specific version
/*
SELECT 
    a.*,
    p_new.firstname AS new_firstname,
    p_new.occupation AS new_occupation,
    p_old.firstname AS old_firstname,
    p_old.occupation AS old_occupation
FROM curated.fact_customer_profile_audit a
JOIN curated.dim_customer_profile p_new 
    ON a.customer_profile_version_sk_new = p_new.customer_profile_version_sk
LEFT JOIN curated.dim_customer_profile p_old 
    ON a.customer_profile_version_sk_old = p_old. customer_profile_version_sk
WHERE a.customer_id = 12345
    AND a.version_num_new = 3;
*/

-- Query 3: Summary of changes by reason
/*
SELECT 
    change_reason,
    COUNT(*) AS event_count,
    AVG(processing_latency_seconds) AS avg_latency_seconds,
    COUNT(DISTINCT customer_id) AS affected_customers
FROM curated.fact_customer_profile_audit
WHERE event_source_ts >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY change_reason
ORDER BY event_count DESC;
*/

-- Query 4: Recent changes with high latency
/*
SELECT 
    customer_id,
    version_num_new,
    change_reason,
    processing_latency_seconds,
    event_source_ts,
    event_detected_ts
FROM curated.fact_customer_profile_audit
WHERE processing_latency_seconds > 3600  -- More than 1 hour
    AND event_source_ts >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY processing_latency_seconds DESC;
*/

-- Query 5: Attribute change frequency analysis
/*
SELECT 
    jsonb_array_elements_text(changed_scalar_attributes::jsonb) AS attribute_name,
    COUNT(*) AS change_count
FROM curated.fact_customer_profile_audit
WHERE change_reason = 'SOURCE_UPDATE'
    AND event_source_ts >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY attribute_name
ORDER BY change_count DESC;
*/
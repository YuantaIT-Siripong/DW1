-- =====================================================================
-- Gold Layer:   Fact Customer Profile Audit
-- =====================================================================
-- Source Contract: contracts/gold/fact_customer_profile_audit.yaml
-- Database: PostgreSQL
-- Layer: Gold
-- Created: 2026-01-05
-- =====================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS gold;

-- Drop table if exists (for development only - comment out in production)
-- DROP TABLE IF EXISTS gold.fact_customer_profile_audit CASCADE;

-- =====================================================================
-- CREATE TABLE
-- =====================================================================
CREATE TABLE gold.fact_customer_profile_audit (
    -- ================================================================
    -- SURROGATE KEY
    -- ================================================================
    audit_event_id BIGSERIAL PRIMARY KEY,
    
    -- ================================================================
    -- FOREIGN KEYS
    -- ================================================================
    customer_id VARCHAR(50) NOT NULL,
    customer_profile_version_sk_new BIGINT NOT NULL,
    customer_profile_version_sk_old BIGINT,
    
    -- ================================================================
    -- VERSION TRACKING
    -- ================================================================
    version_num_new INT NOT NULL,
    version_num_old INT,
    
    -- ================================================================
    -- CHANGE METADATA
    -- ================================================================
    change_reason VARCHAR(50) NOT NULL,
    changed_scalar_attributes TEXT NOT NULL,
    changed_set_names TEXT NOT NULL,
    scalar_attribute_old_values TEXT,
    scalar_attribute_new_values TEXT NOT NULL,
    set_membership_diff_summary TEXT,
    
    -- ================================================================
    -- HASH TRACKING
    -- ================================================================
    old_profile_hash VARCHAR(64),
    new_profile_hash VARCHAR(64) NOT NULL,
    old_source_of_income_set_hash VARCHAR(64),
    new_source_of_income_set_hash VARCHAR(64),
    old_purpose_of_investment_set_hash VARCHAR(64),
    new_purpose_of_investment_set_hash VARCHAR(64),
    
    -- ================================================================
    -- DATA QUALITY TRACKING
    -- ================================================================
    old_data_quality_score NUMERIC(5,2),
    new_data_quality_score NUMERIC(5,2),
    old_data_quality_status VARCHAR(50),
    new_data_quality_status VARCHAR(50),
    
    -- ================================================================
    -- TEMPORAL TRACKING
    -- ================================================================
    event_ts TIMESTAMP NOT NULL,
    effective_start_ts_new TIMESTAMP NOT NULL,
    effective_end_ts_old TIMESTAMP,
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- ================================================================
    -- LINEAGE
    -- ================================================================
    source_system VARCHAR(100) DEFAULT 'MSSQL_CORE',
    etl_batch_id BIGINT,
    
    -- ================================================================
    -- CONSTRAINTS
    -- ================================================================
    
    -- Foreign keys
    CONSTRAINT fk_audit_version_new
        FOREIGN KEY (customer_profile_version_sk_new)
        REFERENCES gold.dim_customer_profile(customer_profile_version_sk),
    
    CONSTRAINT fk_audit_version_old
        FOREIGN KEY (customer_profile_version_sk_old)
        REFERENCES gold.dim_customer_profile(customer_profile_version_sk),
    
    -- Change reason validation
    CONSTRAINT chk_change_reason_values
        CHECK (change_reason IN (
            'INITIAL_LOAD',
            'SOURCE_UPDATE',
            'CORRECTION',
            'DATA_QUALITY_FIX',
            'BACKDATED_CORRECTION',
            'RECOMPUTE_HASH'
        )),
    
    -- Version number validation
    CONSTRAINT chk_version_num_positive
        CHECK (version_num_new > 0 AND (version_num_old IS NULL OR version_num_old > 0)),
    
    -- Version sequence validation (except INITIAL_LOAD)
    CONSTRAINT chk_version_sequence
        CHECK (
            (change_reason = 'INITIAL_LOAD' AND version_num_old IS NULL AND version_num_new = 1)
            OR (change_reason != 'INITIAL_LOAD' AND version_num_new = version_num_old + 1)
        ),
    
    -- Hash format validation
    CONSTRAINT chk_hash_format
        CHECK (
            (old_profile_hash IS NULL OR old_profile_hash ~ '^[a-f0-9]{64}$')
            AND
            (new_profile_hash ~ '^[a-f0-9]{64}$')
        ),
    
    -- Data quality score range
    CONSTRAINT chk_dq_score_range
        CHECK (
            (old_data_quality_score IS NULL OR old_data_quality_score BETWEEN 0.00 AND 100.00)
            AND (new_data_quality_score IS NULL OR new_data_quality_score BETWEEN 0.00 AND 100.00)
        ),
    
    -- Data quality status values
    CONSTRAINT chk_dq_status_values
        CHECK (
            (old_data_quality_status IS NULL OR old_data_quality_status IN (
                'VALID', 'VALID_WITH_OTHER', 'INVALID_ENUMERATION', 'INVALID_BIRTHDATE', 'MULTIPLE_ISSUES'
            ))
            AND (new_data_quality_status IS NULL OR new_data_quality_status IN (
                'VALID', 'VALID_WITH_OTHER', 'INVALID_ENUMERATION', 'INVALID_BIRTHDATE', 'MULTIPLE_ISSUES'
            ))
        )
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- Lookup all changes for a customer
CREATE INDEX idx_audit_customer_id 
    ON gold.fact_customer_profile_audit(customer_id);

-- Time-based queries
CREATE INDEX idx_audit_event_ts 
    ON gold. fact_customer_profile_audit(event_ts);

-- Lookup audit for specific version
CREATE INDEX idx_audit_version_new 
    ON gold.fact_customer_profile_audit(customer_profile_version_sk_new);

-- Filter by change reason
CREATE INDEX idx_audit_change_reason 
    ON gold.fact_customer_profile_audit(change_reason);

-- Data quality tracking
CREATE INDEX idx_audit_dq_status_new
    ON gold.fact_customer_profile_audit(new_data_quality_status);

-- Load timestamp for incremental processing
CREATE INDEX idx_audit_load_ts 
    ON gold.fact_customer_profile_audit(load_ts);

-- ================================================================
-- COMMENTS (Documentation)
-- ================================================================

COMMENT ON TABLE gold.fact_customer_profile_audit IS 
    'Audit fact table tracking all profile change events that created new SCD2 versions. 
     Source: Generated during SCD2 merge process in dim_customer_profile
     Grain: One row per profile change event
     Pattern: Append-only audit trail
     
     Usage: 
     - Track what changed:   changed_scalar_attributes, changed_set_names
     - Track old vs new values:  scalar_attribute_old_values, scalar_attribute_new_values
     - Track data quality trends: old/new_data_quality_score, old/new_data_quality_status
     - Track set changes: set_membership_diff_summary
     - Join to dim_customer_profile via customer_profile_version_sk_new/old
     
     Change Reasons:
     - INITIAL_LOAD: First version for customer
     - SOURCE_UPDATE: Normal update from source system
     - CORRECTION: Manual data correction
     - DATA_QUALITY_FIX: Fix for data quality issue
     - BACKDATED_CORRECTION: Historical correction
     - RECOMPUTE_HASH: Hash algorithm change';

COMMENT ON COLUMN gold. fact_customer_profile_audit. audit_event_id IS 
    'Surrogate key - auto-incrementing primary key for audit event. ';

COMMENT ON COLUMN gold.fact_customer_profile_audit.customer_id IS 
    'Customer identifier affected by this change.';

COMMENT ON COLUMN gold.fact_customer_profile_audit.customer_profile_version_sk_new IS 
    'Foreign key to newly created profile version in dim_customer_profile.';

COMMENT ON COLUMN gold.fact_customer_profile_audit.customer_profile_version_sk_old IS 
    'Foreign key to previous profile version (NULL for INITIAL_LOAD).';

COMMENT ON COLUMN gold.fact_customer_profile_audit.changed_scalar_attributes IS 
    'JSON array of scalar attribute names that changed.  
     Example: ["firstname","occupation","birthdate"]
     Empty array [] if only set membership changed.';

COMMENT ON COLUMN gold.fact_customer_profile_audit.changed_set_names IS 
    'JSON array of multi-valued set names that changed.
     Example: ["source_of_income","purpose_of_investment"]
     Empty array [] if only scalar attributes changed.';

COMMENT ON COLUMN gold.fact_customer_profile_audit.scalar_attribute_old_values IS 
    'JSON object with old values of changed scalar attributes only.
     Example: {"occupation":"EMPLOYEE","birthdate":"1985-03-10"}
     NULL for INITIAL_LOAD.';

COMMENT ON COLUMN gold.fact_customer_profile_audit.scalar_attribute_new_values IS 
    'JSON object with new values of changed scalar attributes only.
     Example: {"occupation":"SELF_EMPLOYED","birthdate":"1985-03-15"}';

COMMENT ON COLUMN gold.fact_customer_profile_audit.set_membership_diff_summary IS 
    'JSON object with counts of added/removed members per set.
     Example: {"source_of_income": {"added":1,"removed":0},"purpose_of_investment": {"added":0,"removed":1}}
     NULL if no set changes.';

COMMENT ON COLUMN gold.fact_customer_profile_audit.event_ts IS 
    'UTC timestamp when the change event occurred (from source last_modified_ts).';

COMMENT ON COLUMN gold.fact_customer_profile_audit.load_ts IS 
    'UTC timestamp when audit record was created in Gold layer.';

-- ================================================================
-- NOTES
-- ================================================================
-- 1. Append-only audit trail - no updates or deletes
-- 2. Generated during SCD2 merge in dim_customer_profile dbt model
-- 3. JSON columns allow flexible change tracking without schema changes
-- 4. Hash tracking enables validation of change detection logic
-- 5. DQ tracking enables monitoring of data quality trends over time
-- 6. For initial load: version_num_new = 1, version_num_old = NULL
-- 7. For subsequent versions: version_num_new = version_num_old + 1
-- 8. Use for impact analysis, audit reporting, and debugging SCD2 logic
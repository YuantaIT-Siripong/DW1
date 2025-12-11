-- ====================================================================
-- Gold Layer:  SCD Type 2 Customer Profile Dimension
-- ====================================================================

CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE IF NOT EXISTS gold.dim_customer_profile (
    -- ================================================================
    -- SURROGATE KEY (Primary Key for Dimension)
    -- ================================================================
    customer_profile_sk BIGSERIAL PRIMARY KEY,
    
    -- ================================================================
    -- NATURAL KEY (Business Key)
    -- ================================================================
    customer_id VARCHAR(50) NOT NULL,
    
    -- ================================================================
    -- SCD TYPE 2 TEMPORAL COLUMNS
    -- ================================================================
    effective_start_date TIMESTAMP NOT NULL,
    effective_end_date TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59',
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- ================================================================
    -- PROFILE ATTRIBUTES (from Silver)
    -- ================================================================
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
    
    -- ================================================================
    -- DATA QUALITY METRICS (from Silver)
    -- ================================================================
    dq_score NUMERIC(5,2),
    dq_status VARCHAR(20),
    
    -- ================================================================
    -- HASHES (from Silver - for debugging)
    -- ================================================================
    profile_hash VARCHAR(64) NOT NULL,
    source_of_income_set_hash VARCHAR(64),
    purpose_of_investment_set_hash VARCHAR(64),
    
    -- ================================================================
    -- AUDIT COLUMNS
    -- ================================================================
    source_system VARCHAR(100) DEFAULT 'MSSQL_CORE',
    source_last_modified_ts TIMESTAMP,
    record_created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_updated_ts TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'dbt_etl',
    updated_by VARCHAR(100),
    
    -- ================================================================
    -- LINEAGE TRACKING
    -- ================================================================
    silver_load_ts TIMESTAMP,
    bronze_batch_id BIGINT,
    
    -- ================================================================
    -- SOFT DELETE (Optional)
    -- ================================================================
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_ts TIMESTAMP,
    deleted_reason TEXT,
    
    -- ================================================================
    -- CONSTRAINTS
    -- ================================================================
    CONSTRAINT chk_effective_dates 
        CHECK (effective_start_date <= effective_end_date),
    CONSTRAINT uq_one_current_per_customer 
        UNIQUE (customer_id, is_current) 
        DEFERRABLE INITIALLY DEFERRED
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- Natural key lookup
CREATE INDEX idx_dim_customer_natural_key 
    ON gold.dim_customer_profile(customer_id);

-- Temporal queries
CREATE INDEX idx_dim_customer_effective_dates 
    ON gold.dim_customer_profile(effective_start_date, effective_end_date);

-- Current record lookup (most common query)
CREATE INDEX idx_dim_customer_current 
    ON gold.dim_customer_profile(customer_id, is_current) 
    WHERE is_current = TRUE;

-- Change detection
CREATE INDEX idx_dim_customer_profile_hash 
    ON gold.dim_customer_profile(profile_hash);

-- Data quality filtering
CREATE INDEX idx_dim_customer_dq_status 
    ON gold.dim_customer_profile(dq_status);

-- Source tracking
CREATE INDEX idx_dim_customer_source_ts 
    ON gold.dim_customer_profile(source_last_modified_ts);

-- ================================================================
-- COMMENTS (Documentation)
-- ================================================================
COMMENT ON TABLE gold.dim_customer_profile IS 
    'SCD Type 2 customer profile dimension with full history tracking.  
     Each customer can have multiple rows representing different time periods.
     Use is_current=TRUE for latest version or filter by effective dates for point-in-time queries.';

COMMENT ON COLUMN gold. dim_customer_profile.customer_profile_sk IS 
    'Surrogate key - auto-incrementing primary key for dimension.  Use this in fact table foreign keys.';

COMMENT ON COLUMN gold.dim_customer_profile. customer_id IS 
    'Natural business key from source system. Multiple rows can have same customer_id (history).';

COMMENT ON COLUMN gold.dim_customer_profile. effective_start_date IS 
    'Start timestamp when this version became active (inclusive). Based on source last_modified_ts.';

COMMENT ON COLUMN gold.dim_customer_profile.effective_end_date IS 
    'End timestamp when this version was superseded (inclusive). 9999-12-31 = current/active version.';

COMMENT ON COLUMN gold.dim_customer_profile. is_current IS 
    'TRUE = latest/active version. FALSE = historical.  Only one TRUE per customer_id.';

COMMENT ON COLUMN gold.dim_customer_profile.profile_hash IS 
    'SHA256 hash of all profile attributes - used for change detection in SCD Type 2 logic.';

COMMENT ON COLUMN gold.dim_customer_profile. dq_score IS 
    'Data quality score (0-100) from Silver layer validation.';

COMMENT ON COLUMN gold.dim_customer_profile. record_created_ts IS 
    'Timestamp when this dimension row was first created in Gold layer.';

COMMENT ON COLUMN gold.dim_customer_profile.record_updated_ts IS 
    'Timestamp when this dimension row was last updated (e.g., effective_end_date changed).';
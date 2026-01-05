-- =====================================================================
-- Gold Layer:   SCD Type 2 Customer Profile Dimension
-- =====================================================================
-- Source Contract: contracts/gold/dim_customer_profile.yaml
-- Database: PostgreSQL
-- Layer: Gold
-- Created: 2025-12-01
-- Updated: 2026-01-05 (Added DQ fields, aligned with contract)
-- =====================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS gold;

-- Drop table if exists (for development only - comment out in production)
-- DROP TABLE IF EXISTS gold.dim_customer_profile CASCADE;

-- =====================================================================
-- CREATE TABLE
-- =====================================================================
CREATE TABLE gold.dim_customer_profile (
    -- ================================================================
    -- SURROGATE KEY (Primary Key for Dimension)
    -- ================================================================
    customer_profile_version_sk BIGSERIAL PRIMARY KEY,
    
    -- ================================================================
    -- NATURAL KEY (Business Key)
    -- ================================================================
    customer_id VARCHAR(50) NOT NULL,
    
    -- ================================================================
    -- PROFILE ATTRIBUTES (Type 2 - Versioned)
    -- ================================================================
    
    -- Identity Evidence (PII)
    evidence_unique_key VARCHAR(100),
    
    -- Names (PII)
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local VARCHAR(200),
    lastname_local VARCHAR(200),
    
    -- Enumeration Fields (Type 2)
    person_title VARCHAR(50),
    marital_status VARCHAR(50),
    nationality VARCHAR(50),
    occupation VARCHAR(100),
    education_level VARCHAR(100),
    business_type VARCHAR(100),
    birthdate DATE,
    
    -- Economic Bands (Type 2)
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(50),
    
    -- ================================================================
    -- FREETEXT FIELDS (Type 1 - NOT Versioned)
    -- ================================================================
    person_title_other VARCHAR(500),
    nationality_other VARCHAR(500),
    occupation_other VARCHAR(500),
    education_level_other VARCHAR(500),
    business_type_other VARCHAR(500),
    income_country_other VARCHAR(500),
    
    -- ================================================================
    -- HASHES (for change detection and validation)
    -- ================================================================
    profile_hash VARCHAR(64) NOT NULL,
    source_of_income_set_hash VARCHAR(64),
    purpose_of_investment_set_hash VARCHAR(64),
    
    -- ================================================================
    -- DATA QUALITY METRICS (Type 1 - from Silver)
    -- ================================================================
    data_quality_score NUMERIC(5,2),
    data_quality_status VARCHAR(50),
    
    -- ================================================================
    -- VERSION MANAGEMENT
    -- ================================================================
    version_num INT NOT NULL,
    
    -- ================================================================
    -- SCD TYPE 2 TEMPORAL COLUMNS
    -- ================================================================
    effective_start_ts TIMESTAMP NOT NULL,
    effective_end_ts TIMESTAMP NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- ================================================================
    -- ETL METADATA
    -- ================================================================
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- ================================================================
    -- CONSTRAINTS
    -- ================================================================
    
    -- Profile hash format validation
    CONSTRAINT chk_profile_hash_format 
        CHECK (profile_hash ~ '^[a-f0-9]{64}$'),
    
    -- Set hash format validation
    CONSTRAINT chk_source_of_income_set_hash_format
        CHECK (source_of_income_set_hash IS NULL OR source_of_income_set_hash ~ '^[a-f0-9]{64}$'),
    
    CONSTRAINT chk_purpose_of_investment_set_hash_format
        CHECK (purpose_of_investment_set_hash IS NULL OR purpose_of_investment_set_hash ~ '^[a-f0-9]{64}$'),
    
    -- Effective dates validation
    CONSTRAINT chk_effective_dates 
        CHECK (effective_end_ts IS NULL OR effective_end_ts > effective_start_ts),
    
    -- Version number validation
    CONSTRAINT chk_version_num_positive
        CHECK (version_num > 0),
    
    -- Data quality score range
    CONSTRAINT chk_data_quality_score_range
        CHECK (data_quality_score IS NULL OR data_quality_score BETWEEN 0.00 AND 100.00),
    
    -- Data quality status values
    CONSTRAINT chk_data_quality_status_values
        CHECK (data_quality_status IS NULL OR data_quality_status IN (
            'VALID',
            'VALID_WITH_OTHER',
            'INVALID_ENUMERATION',
            'INVALID_BIRTHDATE',
            'MULTIPLE_ISSUES'
        )),
    
    -- Birthdate validation
    CONSTRAINT chk_birthdate_valid
        CHECK (birthdate IS NULL OR birthdate <= CURRENT_DATE)
);

-- ================================================================
-- UNIQUE CONSTRAINTS
-- ================================================================

-- Business key uniqueness:  customer_id + version_num
CREATE UNIQUE INDEX uq_customer_version_num 
    ON gold.dim_customer_profile(customer_id, version_num);

-- Only one current version per customer
-- Note: PostgreSQL doesn't support filtered unique constraints with WHERE clause in standard syntax
-- Using partial unique index instead
CREATE UNIQUE INDEX uq_one_current_per_customer 
    ON gold. dim_customer_profile(customer_id) 
    WHERE is_current = TRUE;

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- Natural key lookup (all versions)
CREATE INDEX idx_dim_customer_natural_key 
    ON gold. dim_customer_profile(customer_id);

-- Current record lookup (most common query)
CREATE INDEX idx_dim_customer_current 
    ON gold.dim_customer_profile(customer_id, is_current) 
    WHERE is_current = TRUE;

-- Temporal queries (point-in-time)
CREATE INDEX idx_dim_customer_effective_dates 
    ON gold.dim_customer_profile(effective_start_ts, effective_end_ts);

-- Change detection
CREATE INDEX idx_dim_customer_profile_hash 
    ON gold.dim_customer_profile(profile_hash);

-- Data quality filtering
CREATE INDEX idx_dim_customer_dq_status 
    ON gold.dim_customer_profile(data_quality_status);

-- Data quality score range queries
CREATE INDEX idx_dim_customer_dq_score
    ON gold.dim_customer_profile(data_quality_score);

-- Load timestamp for incremental processing
CREATE INDEX idx_dim_customer_load_ts 
    ON gold.dim_customer_profile(load_ts);

-- ================================================================
-- COMMENTS (Documentation)
-- ================================================================

COMMENT ON TABLE gold.dim_customer_profile IS 
    'SCD Type 2 customer profile dimension with full history tracking. 
     Source:  silver.customer_profile_standardized
     Grain: One row per customer profile version
     SCD Pattern: Type 2 for profile attributes, Type 1 for *_other fields and data_quality_*
     
     Usage: 
     - Current version: WHERE is_current = TRUE
     - Point-in-time:  WHERE effective_start_ts <= : date AND (effective_end_ts IS NULL OR effective_end_ts > :date)
     - All history: No filter
     
     Change Detection:  profile_hash comparison drives version creation
     Multi-valued sets: See bridge_customer_source_of_income and bridge_customer_purpose_of_investment';

-- Key columns
COMMENT ON COLUMN gold.dim_customer_profile.customer_profile_version_sk IS 
    'Surrogate key - auto-incrementing primary key for dimension.  Use this in fact table foreign keys.';

COMMENT ON COLUMN gold.dim_customer_profile.customer_id IS 
    'Natural business key from source system.  Multiple rows can have same customer_id (history).';

COMMENT ON COLUMN gold.dim_customer_profile.version_num IS
    'Sequential version number per customer (1, 2, 3, .. .). Combined with customer_id forms business key.';

-- Temporal columns
COMMENT ON COLUMN gold.dim_customer_profile.effective_start_ts IS 
    'UTC timestamp when this version became active (inclusive). Derived from source last_modified_ts.';

COMMENT ON COLUMN gold.dim_customer_profile.effective_end_ts IS 
    'UTC timestamp when this version was superseded (exclusive). NULL = current/active version.';

COMMENT ON COLUMN gold.dim_customer_profile.is_current IS 
    'TRUE = latest/active version.  FALSE = historical.  Only one TRUE per customer_id. ';

-- Hash columns
COMMENT ON COLUMN gold.dim_customer_profile.profile_hash IS 
    'SHA256 hash (64 hex chars) of all Type 2 attributes for change detection. 
     Includes:  evidence_unique_key, firstname, lastname, firstname_local, lastname_local,
     person_title, marital_status, nationality, occupation, education_level, business_type,
     birthdate, total_asset, monthly_income, income_country,
     source_of_income_set_hash, purpose_of_investment_set_hash. 
     Excludes: Type 1 fields (*_other), DQ metrics, metadata.';

COMMENT ON COLUMN gold.dim_customer_profile. source_of_income_set_hash IS 
    'SHA256 hash of sorted, pipe-delimited source_of_income codes from bridge table.
     Empty set = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

COMMENT ON COLUMN gold. dim_customer_profile.purpose_of_investment_set_hash IS 
    'SHA256 hash of sorted, pipe-delimited purpose_of_investment codes from bridge table.
     Empty set = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

-- Data quality columns
COMMENT ON COLUMN gold. dim_customer_profile.data_quality_score IS 
    'Data quality score (0.00-100.00) from Silver layer validation.
     Type 1 attribute - updates do not create new version.
     Based on 12 validation flags from Silver layer.';

COMMENT ON COLUMN gold.dim_customer_profile.data_quality_status IS 
    'Data quality status classification from Silver layer: 
       - VALID: All validations pass
       - VALID_WITH_OTHER: High score with OTHER enumeration usage
       - INVALID_ENUMERATION:  Enumeration validation failures
       - INVALID_BIRTHDATE: Birthdate validation failure
       - MULTIPLE_ISSUES:  Multiple validation failures
     Type 1 attribute - updates do not create new version.';

-- Type 1 fields
COMMENT ON COLUMN gold.dim_customer_profile. person_title_other IS 
    'Freetext when person_title = OTHER. Type 1 - updates in place without versioning.';

COMMENT ON COLUMN gold.dim_customer_profile.nationality_other IS 
    'Freetext when nationality = OTHER. Type 1 - updates in place without versioning.';

COMMENT ON COLUMN gold.dim_customer_profile.occupation_other IS 
    'Freetext when occupation = OTHER. Type 1 - updates in place without versioning.';

COMMENT ON COLUMN gold.dim_customer_profile.education_level_other IS 
    'Freetext when education_level = OTHER. Type 1 - updates in place without versioning.';

COMMENT ON COLUMN gold.dim_customer_profile.business_type_other IS 
    'Freetext when business_type = OTHER. Type 1 - updates in place without versioning.';

COMMENT ON COLUMN gold.dim_customer_profile.income_country_other IS 
    'Freetext when income_country = OTHER. Type 1 - updates in place without versioning. ';

-- ETL metadata
COMMENT ON COLUMN gold.dim_customer_profile. load_ts IS 
    'UTC timestamp when this dimension row was loaded into Gold layer.';

-- ================================================================
-- NOTES
-- ================================================================
-- 1. SCD Type 2 pattern: New version created when profile_hash changes
-- 2. Type 1 pattern: *_other fields and data_quality_* fields update in-place
-- 3. Multi-valued attributes stored in bridge tables (not in dimension)
-- 4. Profile hash computed in Silver, compared in Gold for change detection
-- 5. For dbt SCD2 merge: 
--    - Match on:  customer_id
--    - Compare: profile_hash
--    - On hash change: Close current version, insert new version
--    - On Type 1 change: Update current version
-- 6. Exactly one row per customer has is_current = TRUE
-- 7. Closed versions have effective_end_ts = next version's effective_start_ts - 1 microsecond
-- 8. PII columns:  evidence_unique_key, firstname, lastname, firstname_local, lastname_local, birthdate
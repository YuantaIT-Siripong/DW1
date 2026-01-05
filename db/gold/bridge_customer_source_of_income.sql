-- =====================================================================
-- Gold Layer:   Bridge Customer Source of Income
-- =====================================================================
-- Source Contract: contracts/gold/bridge_customer_source_of_income.yaml
-- Database: PostgreSQL
-- Layer: Gold
-- Created: 2026-01-05
-- =====================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS gold;

-- Drop table if exists (for development only - comment out in production)
-- DROP TABLE IF EXISTS gold.bridge_customer_source_of_income CASCADE;

-- =====================================================================
-- CREATE TABLE
-- =====================================================================
CREATE TABLE gold. bridge_customer_source_of_income (
    -- ================================================================
    -- PRIMARY KEY (Composite)
    -- ================================================================
    customer_profile_version_sk BIGINT NOT NULL,
    source_of_income_code VARCHAR(100) NOT NULL,
    
    -- ================================================================
    -- DENORMALIZED CUSTOMER ID (for query convenience)
    -- ================================================================
    customer_id VARCHAR(50) NOT NULL,
    
    -- ================================================================
    -- ETL METADATA
    -- ================================================================
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- ================================================================
    -- CONSTRAINTS
    -- ================================================================
    
    -- Primary key
    CONSTRAINT pk_bridge_income_source 
        PRIMARY KEY (customer_profile_version_sk, source_of_income_code),
    
    -- Foreign key to dimension
    CONSTRAINT fk_bridge_income_to_dim
        FOREIGN KEY (customer_profile_version_sk)
        REFERENCES gold.dim_customer_profile(customer_profile_version_sk)
        ON DELETE CASCADE,
    
    -- Valid enumeration values
    CONSTRAINT chk_source_of_income_valid_values
        CHECK (source_of_income_code IN (
            'SALARY',
            'DIVIDEND',
            'RENTAL',
            'BUSINESS',
            'PENSION',
            'INVESTMENT',
            'INHERITANCE',
            'GIFT',
            'OTHER',
            'UNKNOWN'
        ))
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- Lookup by customer (all versions)
CREATE INDEX idx_bridge_income_customer_id 
    ON gold.bridge_customer_source_of_income(customer_id);

-- Lookup by income source type
CREATE INDEX idx_bridge_income_source_code 
    ON gold.bridge_customer_source_of_income(source_of_income_code);

-- Load timestamp for incremental processing
CREATE INDEX idx_bridge_income_load_ts 
    ON gold.bridge_customer_source_of_income(load_ts);

-- ================================================================
-- COMMENTS (Documentation)
-- ================================================================

COMMENT ON TABLE gold.bridge_customer_source_of_income IS 
    'Bridge table for multi-valued source of income relationship. 
     Source:  silver.customer_profile_standardized. source_of_income_list (parsed)
     Grain: One row per (customer_profile_version_sk, source_of_income_code) combination
     Pattern:  Immutable rows - re-materialized only when set membership changes
     
     Usage: 
     - Join to dim_customer_profile on customer_profile_version_sk
     - Rows created only when new dimension version has different source_of_income_set_hash
     - Set hash validation:  Recompute from bridge rows and compare to dim. source_of_income_set_hash
     
     ETL Process:
     1. Parse source_of_income_list from Silver (pipe-delimited)
     2. Split by "|" delimiter
     3. Normalize each code:  UPPER(TRIM)
     4. Create one bridge row per code
     5. Compute hash for validation';

COMMENT ON COLUMN gold. bridge_customer_source_of_income.customer_profile_version_sk IS 
    'Foreign key to dim_customer_profile.  Links to specific profile version.';

COMMENT ON COLUMN gold.bridge_customer_source_of_income.source_of_income_code IS 
    'Income source enumeration code.  Must be valid value from enumeration.';

COMMENT ON COLUMN gold.bridge_customer_source_of_income.customer_id IS 
    'Denormalized customer identifier for query convenience.  Allows filtering without joining to dimension.';

COMMENT ON COLUMN gold.bridge_customer_source_of_income.load_ts IS 
    'UTC timestamp when bridge row was created.';

-- ================================================================
-- NOTES
-- ================================================================
-- 1. Bridge rows are immutable - tied to specific profile version
-- 2. Full set re-materialized only when membership changes (set hash differs)
-- 3. To validate:  Recompute hash from bridge and compare to dim.source_of_income_set_hash
-- 4. Hash computation:  LOWER(ENCODE(SHA256(STRING_AGG(code, '|' ORDER BY code)::bytea), 'hex'))
-- 5. Empty set represented by no bridge rows (hash = empty set constant)
-- 6. For dbt:  Insert rows only when new dim version created with changed set hash
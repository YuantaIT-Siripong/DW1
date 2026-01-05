-- =====================================================================
-- Gold Layer:   Bridge Customer Purpose of Investment
-- =====================================================================
-- Source Contract: contracts/gold/bridge_customer_purpose_of_investment.yaml
-- Database: PostgreSQL
-- Layer: Gold
-- Created: 2026-01-05
-- =====================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS gold;

-- Drop table if exists (for development only - comment out in production)
-- DROP TABLE IF EXISTS gold.bridge_customer_purpose_of_investment CASCADE;

-- =====================================================================
-- CREATE TABLE
-- =====================================================================
CREATE TABLE gold.bridge_customer_purpose_of_investment (
    -- ================================================================
    -- PRIMARY KEY (Composite)
    -- ================================================================
    customer_profile_version_sk BIGINT NOT NULL,
    purpose_of_investment_code VARCHAR(100) NOT NULL,
    
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
    CONSTRAINT pk_bridge_investment_purpose 
        PRIMARY KEY (customer_profile_version_sk, purpose_of_investment_code),
    
    -- Foreign key to dimension
    CONSTRAINT fk_bridge_investment_to_dim
        FOREIGN KEY (customer_profile_version_sk)
        REFERENCES gold.dim_customer_profile(customer_profile_version_sk)
        ON DELETE CASCADE,
    
    -- Valid enumeration values
    CONSTRAINT chk_purpose_of_investment_valid_values
        CHECK (purpose_of_investment_code IN (
            'RETIREMENT',
            'EDUCATION',
            'SPECULATION',
            'INCOME',
            'WEALTH_PRESERVATION',
            'GROWTH',
            'TAX_PLANNING',
            'ESTATE_PLANNING',
            'OTHER',
            'UNKNOWN'
        ))
);

-- ================================================================
-- INDEXES FOR PERFORMANCE
-- ================================================================

-- Lookup by customer (all versions)
CREATE INDEX idx_bridge_investment_customer_id 
    ON gold.bridge_customer_purpose_of_investment(customer_id);

-- Lookup by investment purpose type
CREATE INDEX idx_bridge_investment_purpose_code 
    ON gold.bridge_customer_purpose_of_investment(purpose_of_investment_code);

-- Load timestamp for incremental processing
CREATE INDEX idx_bridge_investment_load_ts 
    ON gold.bridge_customer_purpose_of_investment(load_ts);

-- ================================================================
-- COMMENTS (Documentation)
-- ================================================================

COMMENT ON TABLE gold.bridge_customer_purpose_of_investment IS 
    'Bridge table for multi-valued purpose of investment relationship. 
     Source:  silver.customer_profile_standardized.purpose_of_investment_list (parsed)
     Grain: One row per (customer_profile_version_sk, purpose_of_investment_code) combination
     Pattern: Immutable rows - re-materialized only when set membership changes
     
     Usage:
     - Join to dim_customer_profile on customer_profile_version_sk
     - Rows created only when new dimension version has different purpose_of_investment_set_hash
     - Set hash validation: Recompute from bridge rows and compare to dim.purpose_of_investment_set_hash
     
     ETL Process:
     1. Parse purpose_of_investment_list from Silver (pipe-delimited)
     2. Split by "|" delimiter
     3. Normalize each code: UPPER(TRIM)
     4. Create one bridge row per code
     5. Compute hash for validation';

COMMENT ON COLUMN gold.bridge_customer_purpose_of_investment.customer_profile_version_sk IS 
    'Foreign key to dim_customer_profile.  Links to specific profile version.';

COMMENT ON COLUMN gold.bridge_customer_purpose_of_investment.purpose_of_investment_code IS 
    'Investment purpose enumeration code. Must be valid value from enumeration.';

COMMENT ON COLUMN gold.bridge_customer_purpose_of_investment. customer_id IS 
    'Denormalized customer identifier for query convenience. Allows filtering without joining to dimension.';

COMMENT ON COLUMN gold.bridge_customer_purpose_of_investment.load_ts IS 
    'UTC timestamp when bridge row was created.';

-- ================================================================
-- NOTES
-- ================================================================
-- 1. Bridge rows are immutable - tied to specific profile version
-- 2. Full set re-materialized only when membership changes (set hash differs)
-- 3. To validate: Recompute hash from bridge and compare to dim.purpose_of_investment_set_hash
-- 4. Hash computation: LOWER(ENCODE(SHA256(STRING_AGG(code, '|' ORDER BY code)::bytea), 'hex'))
-- 5. Empty set represented by no bridge rows (hash = empty set constant)
-- 6. For dbt: Insert rows only when new dim version created with changed set hash
-- =====================================================================
-- Curated Layer: bridge_customer_source_of_income
-- Multi-valued relationship between profile versions and income sources
-- =====================================================================
-- Source Contract: contracts/gold/bridge_customer_income_source_version.yaml
-- Database: PostgreSQL
-- Layer: Curated (Gold)
-- Created: 2025-12-01
-- =====================================================================

-- Drop table if exists (for development only)
-- DROP TABLE IF EXISTS curated.bridge_customer_source_of_income CASCADE;

-- Create table
CREATE TABLE curated.bridge_customer_source_of_income (
    -- Foreign Keys
    customer_profile_version_sk BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    
    -- Enumeration Code
    source_of_income_code VARCHAR(100) NOT NULL,
    
    -- ETL Metadata
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Primary Key (composite)
    CONSTRAINT pk_bridge_source_of_income PRIMARY KEY (customer_profile_version_sk, source_of_income_code),
    
    -- Foreign Key to dimension
    CONSTRAINT fk_bridge_income_profile FOREIGN KEY (customer_profile_version_sk)
        REFERENCES curated.dim_customer_profile (customer_profile_version_sk)
        ON DELETE CASCADE,
    
    -- Check Constraint (valid enumeration values)
    CONSTRAINT chk_source_of_income_code CHECK (
        source_of_income_code IN (
            'SALARY', 'DIVIDEND', 'RENTAL', 'BUSINESS', 
            'PENSION', 'INVESTMENT', 'INHERITANCE', 'GIFT', 
            'OTHER', 'UNKNOWN'
        )
    )
);

-- Indexes
CREATE INDEX idx_bridge_income_customer_id 
    ON curated.bridge_customer_source_of_income (customer_id);

CREATE INDEX idx_bridge_income_code 
    ON curated.bridge_customer_source_of_income (source_of_income_code);

-- Comments
COMMENT ON TABLE curated.bridge_customer_source_of_income IS 
'Bridge table for multi-valued source of income.   One row per income source per profile version.  Immutable once created.';

COMMENT ON COLUMN curated.bridge_customer_source_of_income.customer_profile_version_sk IS 
'Surrogate key of the profile version this income source belongs to';

COMMENT ON COLUMN curated.bridge_customer_source_of_income. customer_id IS 
'Denormalized stable customer identifier (for convenience queries)';

COMMENT ON COLUMN curated.bridge_customer_source_of_income.source_of_income_code IS 
'Income source enumeration code (direct code, not FK to lookup dimension)';

-- Grant permissions
GRANT SELECT ON curated.bridge_customer_source_of_income TO dw_etl_service;
GRANT INSERT ON curated.bridge_customer_source_of_income TO dw_etl_service;
GRANT DELETE ON curated.bridge_customer_source_of_income TO dw_etl_service;
GRANT SELECT ON curated.bridge_customer_source_of_income TO dw_privileged;
GRANT SELECT ON curated.bridge_customer_source_of_income TO dw_analyst;
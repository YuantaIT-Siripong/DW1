-- =====================================================================
-- Gold Layer: bridge_customer_purpose_of_investment
-- Multi-valued relationship between profile versions and investment purposes
-- =====================================================================
-- Source Contract: contracts/gold/bridge_customer_investment_purpose_version.yaml
-- Database: PostgreSQL
-- Layer: Gold (Gold)
-- Created: 2025-12-01
-- =====================================================================

-- Drop table if exists (for development only)
-- DROP TABLE IF EXISTS gold.bridge_customer_purpose_of_investment CASCADE;

-- Create table
CREATE TABLE gold.bridge_customer_purpose_of_investment (
    -- Foreign Keys
    customer_profile_version_sk BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    
    -- Enumeration Code
    purpose_of_investment_code VARCHAR(100) NOT NULL,
    
    -- ETL Metadata
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Primary Key (composite)
    CONSTRAINT pk_bridge_purpose_of_investment PRIMARY KEY (customer_profile_version_sk, purpose_of_investment_code),
    
    -- Foreign Key to dimension
    CONSTRAINT fk_bridge_purpose_profile FOREIGN KEY (customer_profile_version_sk)
        REFERENCES gold.dim_customer_profile (customer_profile_version_sk)
        ON DELETE CASCADE,
    
    -- Check Constraint (valid enumeration values)
    CONSTRAINT chk_purpose_of_investment_code CHECK (
        purpose_of_investment_code IN (
            'RETIREMENT', 'EDUCATION', 'SPECULATION', 'INCOME',
            'WEALTH_PRESERVATION', 'GROWTH', 'TAX_PLANNING', 
            'ESTATE_PLANNING', 'OTHER', 'UNKNOWN'
        )
    )
);

-- Indexes
CREATE INDEX idx_bridge_purpose_customer_id 
    ON gold.bridge_customer_purpose_of_investment (customer_id);

CREATE INDEX idx_bridge_purpose_code 
    ON gold. bridge_customer_purpose_of_investment (purpose_of_investment_code);

-- Comments
COMMENT ON TABLE gold.bridge_customer_purpose_of_investment IS 
'Bridge table for multi-valued investment purposes.  One row per purpose per profile version. Immutable once created. ';

COMMENT ON COLUMN gold.bridge_customer_purpose_of_investment.customer_profile_version_sk IS 
'Surrogate key of the profile version this investment purpose belongs to';

COMMENT ON COLUMN gold.bridge_customer_purpose_of_investment. customer_id IS 
'Denormalized stable customer identifier (for convenience queries)';

COMMENT ON COLUMN gold.bridge_customer_purpose_of_investment.purpose_of_investment_code IS 
'Investment purpose enumeration code (direct code, not FK to lookup dimension)';

-- Grant permissions
GRANT SELECT ON gold.bridge_customer_purpose_of_investment TO dw_etl_service;
GRANT INSERT ON gold.bridge_customer_purpose_of_investment TO dw_etl_service;
GRANT DELETE ON gold.bridge_customer_purpose_of_investment TO dw_etl_service;
GRANT SELECT ON gold.bridge_customer_purpose_of_investment TO dw_privileged;
GRANT SELECT ON gold.bridge_customer_purpose_of_investment TO dw_analyst;
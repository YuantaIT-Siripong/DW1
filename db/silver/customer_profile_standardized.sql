-- ====================================================================
-- Silver Layer: customer_profile_standardized
-- Cleaned, validated, with hashes and data quality flags
-- ====================================================================

CREATE SCHEMA IF NOT EXISTS silver;

CREATE TABLE IF NOT EXISTS silver.customer_profile_standardized (
    -- ================================================================
    -- NATURAL KEY (from Bronze)
    -- ================================================================
    customer_id VARCHAR(50) NOT NULL,
    
    -- ================================================================
    -- PROFILE ATTRIBUTES (from Bronze)
    -- ================================================================
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
    
    -- ================================================================
    -- SOURCE METADATA (from Bronze)
    -- ================================================================
    last_modified_ts TIMESTAMP,
    
    -- ================================================================
    -- COMPUTED HASHES (Silver adds these)
    -- ================================================================
    profile_hash VARCHAR(64) NOT NULL,
    source_of_income_set_hash VARCHAR(64),
    purpose_of_investment_set_hash VARCHAR(64),
    
    -- ================================================================
    -- DATA QUALITY FLAGS (Silver adds these)
    -- ================================================================
    dq_person_title_valid BOOLEAN,
    dq_person_title_other_complete BOOLEAN,
    dq_marital_status_valid BOOLEAN,
    dq_nationality_valid BOOLEAN,
    dq_nationality_other_complete BOOLEAN,
    dq_occupation_valid BOOLEAN,
    dq_occupation_other_complete BOOLEAN,
    dq_education_level_valid BOOLEAN,
    dq_business_type_valid BOOLEAN,
    dq_total_asset_valid BOOLEAN,
    dq_monthly_income_valid BOOLEAN,
    dq_income_country_valid BOOLEAN,
    
    -- ================================================================
    -- DATA QUALITY METRICS (Silver adds these)
    -- ================================================================
    dq_score NUMERIC(5,2),
    dq_status VARCHAR(20),
    
    -- ================================================================
    -- ETL METADATA
    -- ================================================================
    _bronze_load_ts TIMESTAMP,
    _bronze_source_file VARCHAR(500),
    _bronze_batch_id BIGINT,
    _silver_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- ================================================================
    -- CONSTRAINTS
    -- ================================================================
    CONSTRAINT pk_silver_customer_profile 
        PRIMARY KEY (customer_id, last_modified_ts),
    
    CONSTRAINT chk_profile_hash_format 
        CHECK (profile_hash ~ '^[a-f0-9]{64}$'),
    
    CONSTRAINT chk_dq_score_range 
        CHECK (dq_score BETWEEN 0 AND 100),
    
    CONSTRAINT chk_dq_status_values 
        CHECK (dq_status IN ('VALID', 'WARNING', 'INVALID'))
);

-- ================================================================
-- INDEXES
-- ================================================================
CREATE INDEX idx_silver_customer_profile_hash 
    ON silver.customer_profile_standardized(profile_hash);

CREATE INDEX idx_silver_customer_dq_status 
    ON silver.customer_profile_standardized(dq_status);

CREATE INDEX idx_silver_customer_silver_load_ts 
    ON silver.customer_profile_standardized(_silver_load_ts);

CREATE INDEX idx_silver_customer_bronze_batch 
    ON silver.customer_profile_standardized(_bronze_batch_id);

-- ================================================================
-- COMMENTS
-- ================================================================
COMMENT ON TABLE silver.customer_profile_standardized IS 
    'Silver layer:  Cleaned and validated customer profile with hashes and data quality flags. 
     Source: bronze.customer_profile_standardized
     Transformations: Hash computation, enumeration validation, data quality scoring';

COMMENT ON COLUMN silver. customer_profile_standardized.profile_hash IS 
    'SHA256 hash of all Type 2 attributes for SCD2 change detection.  Excludes Type 1 fields (*_other).';

COMMENT ON COLUMN silver. customer_profile_standardized. dq_score IS 
    'Data quality score (0-100) based on 12 validation rules. ';

COMMENT ON COLUMN silver.customer_profile_standardized. dq_status IS 
    'Data quality status: VALID (12/12), WARNING (10-11/12), INVALID (<10/12)';
-- =====================================================================
-- Silver Layer:  customer_profile_standardized
-- Cleaned, validated, with hashes and data quality flags
-- =====================================================================
-- Source Contract: contracts/silver/customer_profile_standardized. yaml
-- Database: PostgreSQL
-- Layer: Silver
-- Created: 2025-12-01
-- Updated: 2026-01-05 (Changed to append-only pattern with composite PK)
-- =====================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS silver;

-- Drop table if exists (for development only - comment out in production)
-- DROP TABLE IF EXISTS silver.customer_profile_standardized CASCADE;

-- =====================================================================
-- CREATE TABLE
-- =====================================================================
CREATE TABLE silver.customer_profile_standardized (
    -- ================================================================
    -- NATURAL KEY (from Bronze)
    -- ================================================================
    customer_id VARCHAR(50) NOT NULL,
    
    -- ================================================================
    -- PROFILE ATTRIBUTES (from Bronze - passthrough with normalization)
    -- ================================================================
    
    -- Identity Evidence (PII)
    evidence_unique_key VARCHAR(100),
    
    -- Names (PII)
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local VARCHAR(200),
    lastname_local VARCHAR(200),
    
    -- Enumeration Fields
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
    
    -- Demographics
    birthdate DATE,
    
    -- Economic Bands
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(50),
    income_country_other VARCHAR(500),
    
    -- Multi-Valued Sets (Pipe-Delimited)
    source_of_income_list TEXT,
    purpose_of_investment_list TEXT,
    
    -- ================================================================
    -- SOURCE METADATA (from Bronze - passthrough)
    -- ================================================================
    last_modified_ts TIMESTAMP NOT NULL,
    
    -- ================================================================
    -- COMPUTED HASHES (Silver adds these)
    -- ================================================================
    profile_hash VARCHAR(64) NOT NULL,
    source_of_income_set_hash VARCHAR(64),
    purpose_of_investment_set_hash VARCHAR(64),
    
    -- ================================================================
    -- DATA QUALITY FLAGS (Silver adds these - 12 total)
    -- Pattern: is_valid_* for consistency with naming conventions
    -- Includes OTHER validation where applicable
    -- ================================================================
    is_valid_person_title BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_marital_status BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_nationality BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_occupation BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_education_level BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_business_type BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_total_asset BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_monthly_income BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_income_country BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_birthdate BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_source_of_income_list BOOLEAN NOT NULL DEFAULT FALSE,
    is_valid_purpose_of_investment_list BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- ================================================================
    -- DATA QUALITY METRICS (Silver adds these)
    -- ================================================================
    data_quality_score NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    _silver_dq_status VARCHAR(50),
    
    -- ================================================================
    -- ETL METADATA
    -- ================================================================
    _bronze_load_ts TIMESTAMP NOT NULL,
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
    
    CONSTRAINT chk_data_quality_score_range 
        CHECK (data_quality_score BETWEEN 0.00 AND 100.00),
    
    CONSTRAINT chk_silver_dq_status_values 
        CHECK (_silver_dq_status IN (
            'VALID', 
            'VALID_WITH_OTHER', 
            'INVALID_ENUMERATION', 
            'INVALID_BIRTHDATE', 
            'MULTIPLE_ISSUES'
        ))
);

-- ================================================================
-- INDEXES
-- ================================================================

-- Customer lookup (all versions for one customer)
CREATE INDEX idx_silver_customer_lookup 
    ON silver.customer_profile_standardized(customer_id);

-- Profile hash lookup (for change detection)
CREATE INDEX idx_silver_customer_profile_hash 
    ON silver.customer_profile_standardized(profile_hash);

-- Data quality status filtering
CREATE INDEX idx_silver_customer_dq_status 
    ON silver.customer_profile_standardized(_silver_dq_status);

-- Silver load timestamp (for incremental processing)
CREATE INDEX idx_silver_customer_silver_load_ts 
    ON silver.customer_profile_standardized(_silver_load_ts);

-- Bronze batch tracking
CREATE INDEX idx_silver_customer_bronze_batch 
    ON silver.customer_profile_standardized(_bronze_batch_id);

-- ================================================================
-- COMMENTS (Documentation)
-- ================================================================
COMMENT ON TABLE silver.customer_profile_standardized IS 
    'Silver layer:   Cleaned and validated customer profile with hashes and data quality flags.  
     Source:   bronze. customer_profile_standardized
     Transformations:  
       - Normalization (TRIM, UPPER on enumerations)
       - SHA256 hash computation (profile_hash, set hashes)
       - Data quality validation (12 flags with OTHER validation)
       - Quality scoring (0-100 scale based on 12 validation flags)
     Grain: One record per customer per last_modified_ts (append-only)
     SCD Pattern: Append-only (preserves cleaned history for Gold layer rebuild)
     Notes:
       - Use MAX(last_modified_ts) GROUP BY customer_id to get latest version
       - Enables Gold SCD2 rebuild without recomputing hashes from Bronze
       - Composite PK (customer_id, last_modified_ts) same as Bronze';

-- Key columns
COMMENT ON COLUMN silver.customer_profile_standardized.customer_id IS 
    'Unique business key from operational system (part of composite PK)';

COMMENT ON COLUMN silver.customer_profile_standardized.last_modified_ts IS 
    'Last modified timestamp from operational system (part of composite PK for temporal tracking)';

COMMENT ON COLUMN silver.customer_profile_standardized.profile_hash IS 
    'SHA256 hash (64 hex chars) of all Type 2 attributes for SCD2 change detection in Gold layer.  
     Includes:   evidence_unique_key, firstname, lastname, firstname_local, lastname_local, 
     person_title, marital_status, nationality, occupation, education_level, business_type, 
     birthdate, total_asset, monthly_income, income_country, 
     source_of_income_set_hash, purpose_of_investment_set_hash.  
     Excludes: surrogate keys, timestamps, version management, Type 1 fields (*_other), 
     derived scores (data_quality_score), metadata fields. ';

COMMENT ON COLUMN silver.customer_profile_standardized. source_of_income_set_hash IS 
    'SHA256 hash of sorted, pipe-delimited source_of_income codes.   
     Empty set = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

COMMENT ON COLUMN silver.customer_profile_standardized.purpose_of_investment_set_hash IS 
    'SHA256 hash of sorted, pipe-delimited purpose_of_investment codes.  
     Empty set = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

-- Data Quality Flags
COMMENT ON COLUMN silver.customer_profile_standardized.is_valid_person_title IS 
    'TRUE if person_title is in enumeration AND if OTHER, person_title_other is populated';

COMMENT ON COLUMN silver. customer_profile_standardized.is_valid_marital_status IS 
    'TRUE if marital_status is in enumeration valid_values (no OTHER option)';

COMMENT ON COLUMN silver.customer_profile_standardized.is_valid_nationality IS 
    'TRUE if nationality is in enumeration AND if OTHER, nationality_other is populated';

COMMENT ON COLUMN silver.customer_profile_standardized. is_valid_occupation IS 
    'TRUE if occupation is in enumeration AND if OTHER, occupation_other is populated';

COMMENT ON COLUMN silver.customer_profile_standardized. is_valid_education_level IS 
    'TRUE if education_level is in enumeration AND if OTHER, education_level_other is populated';

COMMENT ON COLUMN silver.customer_profile_standardized. is_valid_business_type IS 
    'TRUE if business_type is in enumeration AND if OTHER, business_type_other is populated';

COMMENT ON COLUMN silver.customer_profile_standardized. is_valid_total_asset IS 
    'TRUE if total_asset is in enumeration valid_values (no OTHER option - must select from bands)';

COMMENT ON COLUMN silver.customer_profile_standardized.is_valid_monthly_income IS 
    'TRUE if monthly_income is in enumeration valid_values (no OTHER option - must select from bands)';

COMMENT ON COLUMN silver.customer_profile_standardized.is_valid_income_country IS 
    'TRUE if income_country is in enumeration AND if OTHER, income_country_other is populated';

COMMENT ON COLUMN silver.customer_profile_standardized.is_valid_birthdate IS 
    'TRUE if birthdate <= CURRENT_DATE and age between 18-120 years';

COMMENT ON COLUMN silver.customer_profile_standardized. is_valid_source_of_income_list IS 
    'TRUE if all codes in pipe-delimited list are valid enumeration values';

COMMENT ON COLUMN silver.customer_profile_standardized.is_valid_purpose_of_investment_list IS 
    'TRUE if all codes in pipe-delimited list are valid enumeration values';

-- Data Quality Metrics
COMMENT ON COLUMN silver.customer_profile_standardized.data_quality_score IS 
    'Data quality score (0.00-100.00) based on 12 validation flags. 
     Formula: (count of TRUE flags / 12) * 100
     Examples:  
       - 12/12 = 100.00 (perfect)
       - 11/12 = 91.67 (one validation failure)
       - 10/12 = 83.33 (two validation failures)
     Used for filtering and quality monitoring.';

COMMENT ON COLUMN silver.customer_profile_standardized._silver_dq_status IS 
    'Data quality status classification:
       - VALID: All 12 validations pass (100.00)
       - VALID_WITH_OTHER: 11-12 validations pass AND uses OTHER option
       - INVALID_BIRTHDATE:   Birthdate validation fails
       - INVALID_ENUMERATION: 8-10 validations pass
       - MULTIPLE_ISSUES:   < 8 validations pass (<70.00 score)';

-- Metadata
COMMENT ON COLUMN silver.customer_profile_standardized._bronze_load_ts IS 
    'UTC timestamp when record was landed into Bronze layer';

COMMENT ON COLUMN silver.customer_profile_standardized._bronze_source_file IS 
    'Source view name or file identifier from Bronze ETL';

COMMENT ON COLUMN silver. customer_profile_standardized._bronze_batch_id IS 
    'ETL batch identifier for lineage tracking from Bronze layer';

COMMENT ON COLUMN silver.customer_profile_standardized._silver_load_ts IS 
    'UTC timestamp when record was processed into Silver layer';

-- ================================================================
-- NOTES
-- ================================================================
-- 1. Silver layer is append-only (same pattern as Bronze)
-- 2. Composite PK (customer_id, last_modified_ts) preserves temporal history
-- 3. Profile hash computation is expensive - storing history in Silver avoids recomputation
-- 4. Gold layer can rebuild SCD2 versions from Silver without accessing Bronze
-- 5. To get latest version: SELECT * FROM silver.customer_profile_standardized 
--    WHERE (customer_id, last_modified_ts) IN 
--      (SELECT customer_id, MAX(last_modified_ts) FROM silver.customer_profile_standardized GROUP BY customer_id)
-- 6. Data quality flags include OTHER validation:  
--    - When enum='OTHER', validates that corresponding *_other field is populated
-- 7. Profile hash EXCLUDES:  
--    - Type 1 fields (*_other freetext)
--    - Derived scores (data_quality_score)
--    - Metadata fields (_silver_load_ts, etc.)
-- 8. For dbt incremental processing: 
--    - Use unique_key=['customer_id', 'last_modified_ts']
--    - Use _bronze_load_ts as watermark
--    - Materialize as table (hashes are expensive to compute)
-- =====================================================================
-- Bronze Layer: customer_profile_standardized
-- Raw landing zone - exact mirror of IT operational view
-- =====================================================================
-- Source Contract: contracts/bronze/customer_profile_standardized. yaml
-- Database: PostgreSQL
-- Layer: Bronze
-- Created: 2025-12-01
-- =====================================================================

-- Drop table if exists (for development only)
-- DROP TABLE IF EXISTS bronze.customer_profile_standardized CASCADE;

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS bronze;

-- Create table
CREATE TABLE bronze.customer_profile_standardized (
    -- Natural Key
    customer_id VARCHAR(50) NOT NULL,
    
    -- Identity Evidence (PII)
    evidence_unique_key VARCHAR(100),
    
    -- Names (PII)
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local VARCHAR(200),
    lastname_local VARCHAR(200),
    
    -- Enumeration Fields
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
    
    -- Demographics
    birthdate DATE,
    
    -- Economic Bands
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(2),
    income_country_other VARCHAR(200),
    
    -- Multi-Valued Sets (Pipe-Delimited)
    source_of_income_list TEXT,
    purpose_of_investment_list TEXT,
    
    -- IT Source Metadata
    last_modified_ts TIMESTAMP,
    
    -- Bronze ETL Metadata
    _bronze_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _bronze_source_file VARCHAR(500) DEFAULT 'opdb. vw_customer_profile_standardized',
    _bronze_batch_id BIGINT,
    
    -- Primary Key
    CONSTRAINT pk_bronze_customer_profile PRIMARY KEY (customer_id)
);

-- Indexes
CREATE INDEX idx_bronze_customer_load_ts 
    ON bronze.customer_profile_standardized (_bronze_load_ts);

CREATE INDEX idx_bronze_customer_batch_id 
    ON bronze. customer_profile_standardized (_bronze_batch_id);

-- Comments on table
COMMENT ON TABLE bronze. customer_profile_standardized IS 
'Raw landing zone for customer profile data from IT operational view.  Immutable append-only pattern. No transformations applied.';

-- Comments on columns
COMMENT ON COLUMN bronze. customer_profile_standardized.customer_id IS 
'Unique business key from operational system';

COMMENT ON COLUMN bronze.customer_profile_standardized. evidence_unique_key IS 
'National ID/Passport (PII - trimmed, uppercase from IT)';

COMMENT ON COLUMN bronze.customer_profile_standardized. firstname IS 
'Given name (PII - trimmed, preserve case from IT)';

COMMENT ON COLUMN bronze.customer_profile_standardized.lastname IS 
'Family name (PII - trimmed, preserve case from IT)';

COMMENT ON COLUMN bronze. customer_profile_standardized.firstname_local IS 
'Local script given name (PII - trimmed, preserve case from IT)';

COMMENT ON COLUMN bronze.customer_profile_standardized.lastname_local IS 
'Local script family name (PII - trimmed, preserve case from IT)';

COMMENT ON COLUMN bronze.customer_profile_standardized.person_title IS 
'Honorific title enumeration code (MR, MRS, MS, MISS, DR, PROF, REV, OTHER)';

COMMENT ON COLUMN bronze.customer_profile_standardized.person_title_other IS 
'Freetext title when person_title=OTHER';

COMMENT ON COLUMN bronze.customer_profile_standardized.marital_status IS 
'Marital status enumeration code (SINGLE, MARRIED, DIVORCED, WIDOWED, SEPARATED, UNKNOWN)';

COMMENT ON COLUMN bronze.customer_profile_standardized.nationality IS 
'Nationality enumeration code - ISO 3166-1 alpha-2';

COMMENT ON COLUMN bronze. customer_profile_standardized.nationality_other IS 
'Freetext nationality when nationality=OTHER';

COMMENT ON COLUMN bronze. customer_profile_standardized.occupation IS 
'Occupational classification enumeration code';

COMMENT ON COLUMN bronze. customer_profile_standardized.occupation_other IS 
'Freetext occupation when occupation=OTHER';

COMMENT ON COLUMN bronze. customer_profile_standardized.education_level IS 
'Education attainment enumeration code';

COMMENT ON COLUMN bronze.customer_profile_standardized.education_level_other IS 
'Freetext education when education_level=OTHER';

COMMENT ON COLUMN bronze.customer_profile_standardized.business_type IS 
'Business/industry sector enumeration code';

COMMENT ON COLUMN bronze.customer_profile_standardized.business_type_other IS 
'Freetext business type when business_type=OTHER';

COMMENT ON COLUMN bronze.customer_profile_standardized.birthdate IS 
'Date of birth in YYYY-MM-DD format (PII)';

COMMENT ON COLUMN bronze.customer_profile_standardized. total_asset IS 
'Total asset value band enumeration code (no OTHER option)';

COMMENT ON COLUMN bronze.customer_profile_standardized.monthly_income IS 
'Monthly income band enumeration code (no OTHER option)';

COMMENT ON COLUMN bronze.customer_profile_standardized.income_country IS 
'Country of income origin - ISO 3166-1 alpha-2';

COMMENT ON COLUMN bronze.customer_profile_standardized.income_country_other IS 
'Freetext income country when income_country=OTHER';

COMMENT ON COLUMN bronze. customer_profile_standardized.source_of_income_list IS 
'Pipe-delimited list of income source codes (sorted alphabetically by IT) e.g., "DIVIDEND|RENTAL|SALARY"';

COMMENT ON COLUMN bronze.customer_profile_standardized. purpose_of_investment_list IS 
'Pipe-delimited list of investment purpose codes (sorted alphabetically by IT) e.g., "EDUCATION|RETIREMENT"';

COMMENT ON COLUMN bronze.customer_profile_standardized. last_modified_ts IS 
'Last modified timestamp from operational system (for change tracking)';

COMMENT ON COLUMN bronze.customer_profile_standardized._bronze_load_ts IS 
'UTC timestamp when record was landed into Bronze';

COMMENT ON COLUMN bronze. customer_profile_standardized._bronze_source_file IS 
'Source view name or file identifier';

COMMENT ON COLUMN bronze.customer_profile_standardized._bronze_batch_id IS 
'ETL batch identifier for lineage tracking';

-- Row-level security (optional - enable if needed)
-- ALTER TABLE bronze.customer_profile_standardized ENABLE ROW LEVEL SECURITY;

-- Grant permissions (adjust roles as needed)
GRANT SELECT ON bronze.customer_profile_standardized TO dw_etl_service;
GRANT INSERT ON bronze.customer_profile_standardized TO dw_etl_service;
GRANT SELECT ON bronze.customer_profile_standardized TO dw_privileged;

-- Immutability policy note
-- Bronze records are append-only.  Never UPDATE or DELETE.
-- Use _bronze_batch_id for batch tracking and reprocessing.
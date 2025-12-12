-- =====================================================================
-- Curated Layer: dim_customer_profile
-- SCD Type 2 Dimension with version management
-- =====================================================================
-- Source Contract: contracts/gold/dim_customer_profile.yaml
-- Database: PostgreSQL
-- Layer: Curated (Gold)
-- Created: 2025-12-01
-- =====================================================================

-- Drop table if exists (for development only)
-- DROP TABLE IF EXISTS curated.dim_customer_profile CASCADE;

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS curated;

-- Create sequence for surrogate key
CREATE SEQUENCE IF NOT EXISTS curated.seq_customer_profile_version_sk
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Create table
CREATE TABLE curated.dim_customer_profile (
    -- Surrogate & Natural Keys
    customer_profile_version_sk BIGINT NOT NULL DEFAULT nextval('curated.seq_customer_profile_version_sk'),
    customer_id BIGINT NOT NULL,
    
    -- Identity Evidence (PII)
    evidence_unique_key VARCHAR(100),
    
    -- Names (PII - preserve case in storage)
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local VARCHAR(200),
    lastname_local VARCHAR(200),
    
    -- Enumeration Fields (Type 2 - versioned)
    person_title VARCHAR(50),
    marital_status VARCHAR(50),
    nationality VARCHAR(2),
    occupation VARCHAR(100),
    education_level VARCHAR(100),
    business_type VARCHAR(100),
    birthdate DATE,
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(2),
    
    -- Freetext Fields (Type 1 - NOT versioned, NOT in hash)
    person_title_other VARCHAR(200),
    nationality_other VARCHAR(200),
    occupation_other VARCHAR(200),
    education_level_other VARCHAR(200),
    business_type_other VARCHAR(200),
    income_country_other VARCHAR(200),
    
    -- Set Hashes (computed from bridge tables)
    source_of_income_set_hash VARCHAR(64),
    purpose_of_investment_set_hash VARCHAR(64),
    
    -- Profile Hash (change detection)
    profile_hash VARCHAR(64) NOT NULL,
    
    -- Version Management
    version_num INT NOT NULL,
    
    -- SCD2 Temporal Columns
    effective_start_ts TIMESTAMP NOT NULL,
    effective_end_ts TIMESTAMP,
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- ETL Metadata
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Primary Key
    CONSTRAINT pk_customer_profile_version PRIMARY KEY (customer_profile_version_sk),
    
    -- Check Constraints
    CONSTRAINT chk_profile_hash_length CHECK (LENGTH(profile_hash) = 64),
    CONSTRAINT chk_set_hash_length_income CHECK (
        source_of_income_set_hash IS NULL OR 
        LENGTH(source_of_income_set_hash) = 64
    ),
    CONSTRAINT chk_set_hash_length_purpose CHECK (
        purpose_of_investment_set_hash IS NULL OR 
        LENGTH(purpose_of_investment_set_hash) = 64
    ),
    CONSTRAINT chk_version_num_positive CHECK (version_num > 0),
    CONSTRAINT chk_effective_dates CHECK (
        effective_end_ts IS NULL OR effective_end_ts > effective_start_ts
    ),
    CONSTRAINT chk_birthdate_valid CHECK (
        birthdate IS NULL OR birthdate <= CURRENT_DATE
    )
);

-- Indexes
CREATE UNIQUE INDEX idx_customer_profile_natural_current 
    ON curated.dim_customer_profile (customer_id, is_current)
    WHERE is_current = TRUE;

CREATE INDEX idx_customer_profile_customer_id 
    ON curated.dim_customer_profile (customer_id);

CREATE INDEX idx_customer_profile_hash 
    ON curated.dim_customer_profile (profile_hash);

CREATE INDEX idx_customer_profile_effective_dates 
    ON curated.dim_customer_profile (effective_start_ts, effective_end_ts);

CREATE INDEX idx_customer_profile_version_num 
    ON curated.dim_customer_profile (customer_id, version_num);

-- Comments on table
COMMENT ON TABLE curated.dim_customer_profile IS 
'SCD Type 2 dimension for customer profile with version management.   One record per historical profile version.  Enumeration pattern with _other freetext fields (Type 1).  ';

-- Comments on key columns
COMMENT ON COLUMN curated.dim_customer_profile. customer_profile_version_sk IS 
'Surrogate key for profile version (unique across all versions)';

COMMENT ON COLUMN curated.dim_customer_profile. customer_id IS 
'Stable internal customer identifier (Type 1 anchor)';

COMMENT ON COLUMN curated.dim_customer_profile.evidence_unique_key IS 
'Raw identity evidence (national ID or passport number) - PII';

COMMENT ON COLUMN curated.dim_customer_profile.profile_hash IS 
'SHA256 hash of all version-driving attributes (17 fields) for change detection';

COMMENT ON COLUMN curated.dim_customer_profile.source_of_income_set_hash IS 
'SHA256 hash of sorted, normalized source_of_income codes from bridge table';

COMMENT ON COLUMN curated.dim_customer_profile. purpose_of_investment_set_hash IS 
'SHA256 hash of sorted, normalized purpose_of_investment codes from bridge table';

COMMENT ON COLUMN curated. dim_customer_profile.version_num IS 
'Sequential version number per customer_id (1, 2, 3, ...)';

COMMENT ON COLUMN curated.dim_customer_profile.effective_start_ts IS 
'UTC timestamp when this version became effective';

COMMENT ON COLUMN curated.dim_customer_profile. effective_end_ts IS 
'UTC timestamp when this version ended (NULL = current version)';

COMMENT ON COLUMN curated.dim_customer_profile.is_current IS 
'Flag indicating current/active version (TRUE for latest, FALSE for historical)';

COMMENT ON COLUMN curated.dim_customer_profile.person_title_other IS 
'Freetext title when person_title=OTHER (Type 1 - NOT versioned, NOT in hash)';

COMMENT ON COLUMN curated.dim_customer_profile.nationality_other IS 
'Freetext nationality when nationality=OTHER (Type 1 - NOT versioned, NOT in hash)';

COMMENT ON COLUMN curated.dim_customer_profile.occupation_other IS 
'Freetext occupation when occupation=OTHER (Type 1 - NOT versioned, NOT in hash)';

COMMENT ON COLUMN curated.dim_customer_profile. education_level_other IS 
'Freetext education level when education_level=OTHER (Type 1 - NOT versioned, NOT in hash)';

COMMENT ON COLUMN curated.dim_customer_profile.business_type_other IS 
'Freetext business type when business_type=OTHER (Type 1 - NOT versioned, NOT in hash)';

COMMENT ON COLUMN curated. dim_customer_profile.income_country_other IS 
'Freetext income country when income_country=OTHER (Type 1 - NOT versioned, NOT in hash)';

-- Grant permissions
GRANT SELECT ON curated.dim_customer_profile TO dw_etl_service;
GRANT INSERT ON curated.dim_customer_profile TO dw_etl_service;
GRANT UPDATE ON curated.dim_customer_profile TO dw_etl_service;
GRANT SELECT ON curated.dim_customer_profile TO dw_privileged;
GRANT SELECT ON curated.dim_customer_profile TO dw_analyst;

GRANT USAGE, SELECT ON SEQUENCE curated.seq_customer_profile_version_sk TO dw_etl_service;
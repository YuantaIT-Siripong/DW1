-- =====================================================================
-- Silver Layer: customer_profile_standardized
-- Cleaned, validated, and enriched data with computed hashes
-- =====================================================================
-- Source Contract: contracts/silver/customer_profile_standardized. yaml
-- Database: PostgreSQL
-- Layer: Silver
-- Created: 2025-12-01
-- =====================================================================

-- Drop table if exists (for development only)
-- DROP TABLE IF EXISTS silver.customer_profile_standardized CASCADE;

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS silver;

-- Create table
CREATE TABLE silver.customer_profile_standardized (
    -- Natural Key (TYPE CONVERTED)
    customer_id BIGINT NOT NULL,
    
    -- Identity Evidence (PII - normalized)
    evidence_unique_key VARCHAR(100),
    
    -- Names (PII - case preserved, trimmed)
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local VARCHAR(200),
    lastname_local VARCHAR(200),
    
    -- Enumeration Fields (normalized)
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
    
    -- Multi-Valued Sets (normalized, still pipe-delimited)
    source_of_income_list TEXT,
    purpose_of_investment_list TEXT,
    
    -- IT Source Metadata (passthrough)
    last_modified_ts TIMESTAMP,
    
    -- Bronze Metadata (passthrough)
    _bronze_load_ts TIMESTAMP NOT NULL,
    _bronze_source_file VARCHAR(500),
    _bronze_batch_id BIGINT,
    
    -- ===== COMPUTED COLUMNS (NEW IN SILVER) =====
    
    -- Set Hashes
    source_of_income_set_hash VARCHAR(64),
    purpose_of_investment_set_hash VARCHAR(64),
    
    -- Profile Hash (for SCD2 change detection)
    profile_hash VARCHAR(64) NOT NULL,
    
    -- Data Quality Flags
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
    
    -- Overall Data Quality Score
    data_quality_score DECIMAL(5,4) NOT NULL DEFAULT 0.0000,
    
    -- Silver Metadata
    _silver_processed_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _silver_dq_status VARCHAR(50),
    
    -- Primary Key
    CONSTRAINT pk_silver_customer_profile PRIMARY KEY (customer_id),
    
    -- Check Constraints
    CONSTRAINT chk_silver_profile_hash_length CHECK (LENGTH(profile_hash) = 64),
    CONSTRAINT chk_silver_dq_score_range CHECK (data_quality_score BETWEEN 0.0000 AND 1.0000),
    CONSTRAINT chk_silver_dq_status CHECK (_silver_dq_status IN ('VALID', 'VALID_WITH_OTHER', 'INVALID_ENUMERATION', 'INVALID_BIRTHDATE', 'MULTIPLE_ISSUES'))
);

-- Indexes
CREATE INDEX idx_silver_customer_profile_hash 
    ON silver.customer_profile_standardized (profile_hash);

CREATE INDEX idx_silver_customer_dq_status 
    ON silver.customer_profile_standardized (_silver_dq_status);

CREATE INDEX idx_silver_customer_processed_ts 
    ON silver. customer_profile_standardized (_silver_processed_ts);

CREATE INDEX idx_silver_customer_bronze_batch 
    ON silver.customer_profile_standardized (_bronze_batch_id);

-- Comments on table
COMMENT ON TABLE silver.customer_profile_standardized IS 
'Cleaned and enriched customer profile data with computed hashes for change detection and data quality flags.  Still flat table (not dimensional model yet). ';

-- Comments on key columns
COMMENT ON COLUMN silver.customer_profile_standardized. customer_id IS 
'Unique business key (converted from VARCHAR to BIGINT)';

COMMENT ON COLUMN silver.customer_profile_standardized.profile_hash IS 
'SHA256 hash of all 17 version-driving attributes for SCD2 change detection (lowercase hex, 64 chars)';

COMMENT ON COLUMN silver.customer_profile_standardized.source_of_income_set_hash IS 
'SHA256 hash of normalized, sorted source_of_income codes.  Empty set = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

COMMENT ON COLUMN silver.customer_profile_standardized.purpose_of_investment_set_hash IS 
'SHA256 hash of normalized, sorted purpose_of_investment codes. Empty set = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

COMMENT ON COLUMN silver.customer_profile_standardized.data_quality_score IS 
'Overall data quality score (0.0000 to 1.0000) = count of TRUE validation flags / 12';

COMMENT ON COLUMN silver.customer_profile_standardized._silver_dq_status IS 
'Data quality status classification: VALID, VALID_WITH_OTHER, INVALID_ENUMERATION, INVALID_BIRTHDATE, MULTIPLE_ISSUES';

-- Grant permissions (adjust roles as needed)
GRANT SELECT ON silver.customer_profile_standardized TO dw_etl_service;
GRANT INSERT ON silver.customer_profile_standardized TO dw_etl_service;
GRANT UPDATE ON silver.customer_profile_standardized TO dw_etl_service;
GRANT SELECT ON silver.customer_profile_standardized TO dw_privileged;
GRANT SELECT ON silver.customer_profile_standardized TO dw_analyst;

-- =====================================================================
-- Helper Functions for Hash Computation
-- =====================================================================

-- Function: Compute set hash from pipe-delimited list
CREATE OR REPLACE FUNCTION silver.compute_set_hash(
    p_pipe_delimited_list TEXT
) RETURNS VARCHAR(64) AS $$
DECLARE
    v_codes TEXT[];
    v_normalized_codes TEXT[];
    v_code TEXT;
    v_joined_string TEXT;
BEGIN
    -- Handle NULL or empty input
    IF p_pipe_delimited_list IS NULL OR TRIM(p_pipe_delimited_list) = '' THEN
        RETURN encode(digest('', 'sha256'), 'hex');  -- Empty set hash
    END IF;
    
    -- Split by pipe delimiter
    v_codes := string_to_array(p_pipe_delimited_list, '|');
    
    -- Normalize each code: UPPER(TRIM)
    FOREACH v_code IN ARRAY v_codes
    LOOP
        IF TRIM(v_code) != '' THEN
            v_normalized_codes := array_append(v_normalized_codes, UPPER(TRIM(v_code)));
        END IF;
    END LOOP;
    
    -- Remove duplicates and sort
    SELECT ARRAY_AGG(DISTINCT code ORDER BY code)
    INTO v_normalized_codes
    FROM unnest(v_normalized_codes) AS code;
    
    -- Join with pipe delimiter
    v_joined_string := array_to_string(v_normalized_codes, '|');
    
    -- Return SHA256 hash (lowercase hex)
    RETURN encode(digest(v_joined_string, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION silver.compute_set_hash IS 
'Compute SHA256 hash of normalized, sorted pipe-delimited codes.  Returns lowercase hex (64 chars). ';

-- Function: Compute profile hash (17 fields)
CREATE OR REPLACE FUNCTION silver.compute_profile_hash(
    p_evidence_unique_key VARCHAR,
    p_firstname VARCHAR,
    p_lastname VARCHAR,
    p_firstname_local VARCHAR,
    p_lastname_local VARCHAR,
    p_person_title VARCHAR,
    p_marital_status VARCHAR,
    p_nationality VARCHAR,
    p_occupation VARCHAR,
    p_education_level VARCHAR,
    p_business_type VARCHAR,
    p_birthdate DATE,
    p_total_asset VARCHAR,
    p_monthly_income VARCHAR,
    p_income_country VARCHAR,
    p_source_of_income_set_hash VARCHAR,
    p_purpose_of_investment_set_hash VARCHAR
) RETURNS VARCHAR(64) AS $$
DECLARE
    v_canonical_string TEXT;
BEGIN
    -- Build canonical string (17 fields, | delimiter, __NULL__ for NULLs)
    v_canonical_string := 
        COALESCE(UPPER(TRIM(p_evidence_unique_key)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_firstname)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_lastname)), '__NULL__') || '|' ||
        COALESCE(TRIM(p_firstname_local), '__NULL__') || '|' ||
        COALESCE(TRIM(p_lastname_local), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_person_title)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_marital_status)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_nationality)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_occupation)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_education_level)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_business_type)), '__NULL__') || '|' ||
        COALESCE(p_birthdate::TEXT, '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_total_asset)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_monthly_income)), '__NULL__') || '|' ||
        COALESCE(UPPER(TRIM(p_income_country)), '__NULL__') || '|' ||
        COALESCE(p_source_of_income_set_hash, '__NULL__') || '|' ||
        COALESCE(p_purpose_of_investment_set_hash, '__NULL__');
    
    -- Return SHA256 hash (lowercase hex)
    RETURN encode(digest(v_canonical_string, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION silver.compute_profile_hash IS 
'Compute SHA256 hash of 17 version-driving attributes per AI_CONTEXT. md specification. Returns lowercase hex (64 chars).';

-- =====================================================================
-- ETL Insert/Update Example (Template)
-- =====================================================================

/*
-- Example ETL to populate Silver from Bronze:

INSERT INTO silver.customer_profile_standardized (
    customer_id,
    evidence_unique_key,
    firstname,
    lastname,
    firstname_local,
    lastname_local,
    person_title,
    person_title_other,
    marital_status,
    nationality,
    nationality_other,
    occupation,
    occupation_other,
    education_level,
    education_level_other,
    business_type,
    business_type_other,
    birthdate,
    total_asset,
    monthly_income,
    income_country,
    income_country_other,
    source_of_income_list,
    purpose_of_investment_list,
    last_modified_ts,
    _bronze_load_ts,
    _bronze_source_file,
    _bronze_batch_id,
    source_of_income_set_hash,
    purpose_of_investment_set_hash,
    profile_hash,
    is_valid_person_title,
    is_valid_marital_status,
    is_valid_nationality,
    is_valid_occupation,
    is_valid_education_level,
    is_valid_business_type,
    is_valid_total_asset,
    is_valid_monthly_income,
    is_valid_income_country,
    is_valid_birthdate,
    is_valid_source_of_income_list,
    is_valid_purpose_of_investment_list,
    data_quality_score,
    _silver_processed_ts,
    _silver_dq_status
)
SELECT 
    -- Type conversion
    customer_id::BIGINT,
    
    -- Normalized fields
    UPPER(TRIM(evidence_unique_key)),
    TRIM(firstname),
    TRIM(lastname),
    TRIM(firstname_local),
    TRIM(lastname_local),
    UPPER(TRIM(person_title)),
    TRIM(person_title_other),
    UPPER(TRIM(marital_status)),
    UPPER(TRIM(nationality)),
    TRIM(nationality_other),
    UPPER(TRIM(occupation)),
    TRIM(occupation_other),
    UPPER(TRIM(education_level)),
    TRIM(education_level_other),
    UPPER(TRIM(business_type)),
    TRIM(business_type_other),
    birthdate,
    UPPER(TRIM(total_asset)),
    UPPER(TRIM(monthly_income)),
    UPPER(TRIM(income_country)),
    TRIM(income_country_other),
    
    -- Normalized multi-valued lists (would need parsing/rejoining function)
    source_of_income_list,
    purpose_of_investment_list,
    
    -- Passthrough metadata
    last_modified_ts,
    _bronze_load_ts,
    _bronze_source_file,
    _bronze_batch_id,
    
    -- Computed set hashes
    silver.compute_set_hash(source_of_income_list),
    silver.compute_set_hash(purpose_of_investment_list),
    
    -- Computed profile hash (using helper function)
    silver.compute_profile_hash(
        evidence_unique_key,
        firstname,
        lastname,
        firstname_local,
        lastname_local,
        person_title,
        marital_status,
        nationality,
        occupation,
        education_level,
        business_type,
        birthdate,
        total_asset,
        monthly_income,
        income_country,
        silver.compute_set_hash(source_of_income_list),
        silver.compute_set_hash(purpose_of_investment_list)
    ),
    
    -- Data quality flags (simplified - would need enumeration validation)
    UPPER(TRIM(person_title)) IN ('MR', 'MRS', 'MS', 'MISS', 'DR', 'PROF', 'REV', 'OTHER'),
    UPPER(TRIM(marital_status)) IN ('SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED', 'SEPARATED', 'UNKNOWN'),
    LENGTH(UPPER(TRIM(nationality))) = 2,  -- Simplified - should validate against enum
    UPPER(TRIM(occupation)) IN ('EMPLOYEE', 'SELF_EMPLOYED', 'BUSINESS_OWNER', 'GOVERNMENT_OFFICER', 'PROFESSIONAL', 'RETIRED', 'STUDENT', 'HOMEMAKER', 'UNEMPLOYED', 'OTHER', 'UNKNOWN'),
    UPPER(TRIM(education_level)) IN ('PRIMARY', 'SECONDARY', 'VOCATIONAL', 'DIPLOMA', 'BACHELOR', 'MASTER', 'DOCTORATE', 'OTHER', 'UNKNOWN'),
    UPPER(TRIM(business_type)) IN ('FINANCE', 'MANUFACTURING', 'RETAIL', 'SERVICES', 'AGRICULTURE', 'TECHNOLOGY', 'HEALTHCARE', 'EDUCATION', 'CONSTRUCTION', 'HOSPITALITY', 'TRANSPORTATION', 'ENERGY', 'MEDIA', 'GOVERNMENT', 'OTHER', 'UNKNOWN'),
    UPPER(TRIM(total_asset)) IN ('ASSET_BAND_1', 'ASSET_BAND_2', 'ASSET_BAND_3', 'ASSET_BAND_4', 'ASSET_BAND_5', 'UNKNOWN'),
    UPPER(TRIM(monthly_income)) IN ('INCOME_BAND_1', 'INCOME_BAND_2', 'INCOME_BAND_3', 'INCOME_BAND_4', 'INCOME_BAND_5', 'UNKNOWN'),
    LENGTH(UPPER(TRIM(income_country))) = 2,  -- Simplified
    birthdate IS NOT NULL AND birthdate <= CURRENT_DATE AND EXTRACT(YEAR FROM AGE(birthdate)) BETWEEN 18 AND 120,
    TRUE,  -- is_valid_source_of_income_list (simplified)
    TRUE,  -- is_valid_purpose_of_investment_list (simplified)
    
    -- Data quality score (count TRUE flags / 12)
    (
        (CASE WHEN UPPER(TRIM(person_title)) IN ('MR', 'MRS', 'MS', 'MISS', 'DR', 'PROF', 'REV', 'OTHER') THEN 1 ELSE 0 END) +
        (CASE WHEN UPPER(TRIM(marital_status)) IN ('SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED', 'SEPARATED', 'UNKNOWN') THEN 1 ELSE 0 END) +
        (CASE WHEN LENGTH(UPPER(TRIM(nationality))) = 2 THEN 1 ELSE 0 END) +
        (CASE WHEN UPPER(TRIM(occupation)) IN ('EMPLOYEE', 'SELF_EMPLOYED', 'BUSINESS_OWNER', 'GOVERNMENT_OFFICER', 'PROFESSIONAL', 'RETIRED', 'STUDENT', 'HOMEMAKER', 'UNEMPLOYED', 'OTHER', 'UNKNOWN') THEN 1 ELSE 0 END) +
        (CASE WHEN UPPER(TRIM(education_level)) IN ('PRIMARY', 'SECONDARY', 'VOCATIONAL', 'DIPLOMA', 'BACHELOR', 'MASTER', 'DOCTORATE', 'OTHER', 'UNKNOWN') THEN 1 ELSE 0 END) +
        (CASE WHEN UPPER(TRIM(business_type)) IN ('FINANCE', 'MANUFACTURING', 'RETAIL', 'SERVICES', 'AGRICULTURE', 'TECHNOLOGY', 'HEALTHCARE', 'EDUCATION', 'CONSTRUCTION', 'HOSPITALITY', 'TRANSPORTATION', 'ENERGY', 'MEDIA', 'GOVERNMENT', 'OTHER', 'UNKNOWN') THEN 1 ELSE 0 END) +
        (CASE WHEN UPPER(TRIM(total_asset)) IN ('ASSET_BAND_1', 'ASSET_BAND_2', 'ASSET_BAND_3', 'ASSET_BAND_4', 'ASSET_BAND_5', 'UNKNOWN') THEN 1 ELSE 0 END) +
        (CASE WHEN UPPER(TRIM(monthly_income)) IN ('INCOME_BAND_1', 'INCOME_BAND_2', 'INCOME_BAND_3', 'INCOME_BAND_4', 'INCOME_BAND_5', 'UNKNOWN') THEN 1 ELSE 0 END) +
        (CASE WHEN LENGTH(UPPER(TRIM(income_country))) = 2 THEN 1 ELSE 0 END) +
        (CASE WHEN birthdate IS NOT NULL AND birthdate <= CURRENT_DATE AND EXTRACT(YEAR FROM AGE(birthdate)) BETWEEN 18 AND 120 THEN 1 ELSE 0 END) +
        1 + 1  -- Simplified for source/purpose lists
    )::DECIMAL / 12. 0,
    
    -- Silver metadata
    CURRENT_TIMESTAMP,
    
    -- DQ status (simplified logic)
    CASE 
        WHEN (12 = 12) THEN 'VALID'
        ELSE 'VALID_WITH_OTHER'
    END
    
FROM bronze.customer_profile_standardized
WHERE _bronze_batch_id = :batch_id;  -- Incremental processing

*/
{{
    config(
        materialized='incremental',
        unique_key=['customer_id', 'last_modified_ts', 'rejection_code'],
        on_schema_change='fail',
        schema='quarantine',
        tags=['quarantine', 'data_quality']
    )
}}

-- ====================================================================
-- Quarantine Model: Extract records that failed Silver validation
-- ====================================================================
-- Strategy: Process AFTER Silver, extract records with critical DQ issues
-- Source: silver.customer_profile_standardized (all records including bad)
-- Rejection Rules: dbt/models/silver/rejection_rules.yml
-- ====================================================================

WITH silver_all_records AS (
    SELECT 
        *,
        _silver_load_ts AS silver_load_attempt_ts
    FROM {{ ref('customer_profile_standardized') }}
    
    {% if is_incremental() %}
    -- Only check new Silver records
    WHERE _silver_load_ts > (
        SELECT COALESCE(MAX(silver_load_attempt_ts), '1900-01-01':: TIMESTAMP)
        FROM {{ this }}
    )
    {% endif %}
),

-- ====================================================================
-- QUARANTINE RULES:  Define what should be quarantined
-- ====================================================================

critical_errors AS (
    -- Rule 1: Missing customer_id (should never happen, but defensive)
    SELECT 
        *,
        'MISSING_CUSTOMER_ID' AS rejection_code,
        'Customer ID is NULL - cannot process' AS rejection_reason,
        'CRITICAL' AS rejection_severity
    FROM silver_all_records
    WHERE customer_id IS NULL
    
    UNION ALL
    
    -- Rule 2: DQ Score below critical threshold
    SELECT 
        *,
        'DQ_THRESHOLD_FAILED' AS rejection_code,
        'Data quality score (' || data_quality_score:: TEXT || '%) is below critical threshold (50%)' AS rejection_reason,
        'CRITICAL' AS rejection_severity
    FROM silver_all_records
    WHERE data_quality_score < 50
    
    UNION ALL
    
    -- Rule 3: Multiple validation failures
    SELECT 
        *,
        'MULTIPLE_VALIDATION_FAILURES' AS rejection_code,
        'Multiple critical validations failed (' || 
            (12 - (
                CASE WHEN is_valid_person_title THEN 1 ELSE 0 END +
                CASE WHEN is_valid_marital_status THEN 1 ELSE 0 END +
                CASE WHEN is_valid_nationality THEN 1 ELSE 0 END +
                CASE WHEN is_valid_occupation THEN 1 ELSE 0 END +
                CASE WHEN is_valid_education_level THEN 1 ELSE 0 END +
                CASE WHEN is_valid_business_type THEN 1 ELSE 0 END +
                CASE WHEN is_valid_total_asset THEN 1 ELSE 0 END +
                CASE WHEN is_valid_monthly_income THEN 1 ELSE 0 END +
                CASE WHEN is_valid_income_country THEN 1 ELSE 0 END +
                CASE WHEN is_valid_birthdate THEN 1 ELSE 0 END +
                CASE WHEN is_valid_source_of_income_list THEN 1 ELSE 0 END +
                CASE WHEN is_valid_purpose_of_investment_list THEN 1 ELSE 0 END
            ))::TEXT || ' of 12 validations failed)' AS rejection_reason,
        'ERROR' AS rejection_severity
    FROM silver_all_records
    WHERE (
        CASE WHEN is_valid_person_title THEN 1 ELSE 0 END +
        CASE WHEN is_valid_marital_status THEN 1 ELSE 0 END +
        CASE WHEN is_valid_nationality THEN 1 ELSE 0 END +
        CASE WHEN is_valid_occupation THEN 1 ELSE 0 END +
        CASE WHEN is_valid_education_level THEN 1 ELSE 0 END +
        CASE WHEN is_valid_business_type THEN 1 ELSE 0 END +
        CASE WHEN is_valid_total_asset THEN 1 ELSE 0 END +
        CASE WHEN is_valid_monthly_income THEN 1 ELSE 0 END +
        CASE WHEN is_valid_income_country THEN 1 ELSE 0 END +
        CASE WHEN is_valid_birthdate THEN 1 ELSE 0 END +
        CASE WHEN is_valid_source_of_income_list THEN 1 ELSE 0 END +
        CASE WHEN is_valid_purpose_of_investment_list THEN 1 ELSE 0 END
    ) < 9
    
    UNION ALL
    
    -- Rule 4: Invalid birthdate
    SELECT 
        *,
        'INVALID_BIRTHDATE' AS rejection_code,
        'Birthdate is invalid:  ' || 
            CASE 
                WHEN birthdate IS NULL THEN 'NULL'
                WHEN birthdate > CURRENT_DATE THEN 'future date (' || birthdate::TEXT || ')'
                WHEN DATE_PART('year', AGE(birthdate)) < 18 THEN 'age < 18'
                WHEN DATE_PART('year', AGE(birthdate)) > 120 THEN 'age > 120'
                ELSE 'unknown'
            END AS rejection_reason,
        'ERROR' AS rejection_severity
    FROM silver_all_records
    WHERE NOT is_valid_birthdate
    
    UNION ALL
    
    -- Rule 5: Person title validation failed
    SELECT 
        *,
        'INVALID_PERSON_TITLE' AS rejection_code,
        'Person title validation failed: ' ||
            CASE 
                WHEN person_title = 'OTHER' AND (person_title_other IS NULL OR TRIM(person_title_other) = '')
                    THEN 'OTHER selected but person_title_other is empty'
                ELSE 'Invalid person_title value:  ' || COALESCE(person_title, 'NULL')
            END AS rejection_reason,
        'ERROR' AS rejection_severity
    FROM silver_all_records
    WHERE NOT is_valid_person_title
),

warnings AS (
    -- Rule:  Low DQ score (but above threshold)
    SELECT 
        *,
        'LOW_DQ_SCORE' AS rejection_code,
        'Data quality score is low (' || data_quality_score:: TEXT || '%) but acceptable' AS rejection_reason,
        'WARNING' AS rejection_severity
    FROM silver_all_records
    WHERE data_quality_score BETWEEN 50 AND 75
),

all_rejections AS (
    SELECT * FROM critical_errors
    UNION ALL
    SELECT * FROM warnings
),

final AS (
    SELECT 
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
        
        -- Data Quality flags
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
        
        -- Rejection metadata
        rejection_code,
        rejection_reason,
        rejection_severity,
        data_quality_score,
        _silver_dq_status AS data_quality_status,
        
        -- Lineage  
        silver_load_attempt_ts,
        CURRENT_TIMESTAMP AS rejection_ts,
        _bronze_batch_id
        
    FROM all_rejections
)

SELECT * FROM final
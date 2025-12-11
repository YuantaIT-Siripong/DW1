{{
    config(
        materialized='incremental',
		incremental_strategy='append',
        unique_key=['customer_id', 'last_modified_ts', 'rejection_code'],
        schema='quarantine',
        tags=['quarantine', 'data_quality']
    )
}}

-- ====================================================================
-- Quarantine Model: Extract records that failed Silver validation
-- ====================================================================
-- Strategy: Process AFTER Silver, extract records with critical DQ issues
-- This is a post-processing audit trail, not a filter
-- ====================================================================

WITH silver_all_records AS (
    SELECT 
        *,
        _silver_load_ts AS silver_load_ts,
        _bronze_batch_id AS bronze_batch_id
    FROM {{ ref('customer_profile_standardized') }}
    
    {% if is_incremental() %}
    -- Only check new Silver records
    WHERE _silver_load_ts > (
        SELECT COALESCE(MAX(silver_load_attempt_ts), '1900-01-01'::timestamp)
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
        'DQ_CRITICAL_THRESHOLD' AS rejection_code,
        'Data quality score (' || dq_score:: text || '%) is below critical threshold (50%)' AS rejection_reason,
        'CRITICAL' AS rejection_severity
    FROM silver_all_records
    WHERE dq_score < 50
    
    UNION ALL
    
    -- Rule 3: Invalid DQ status
    SELECT 
        *,
        'DQ_STATUS_INVALID' AS rejection_code,
        'Data quality status is INVALID - multiple validation failures' AS rejection_reason,
        'ERROR' AS rejection_severity
    FROM silver_all_records
    WHERE dq_status = 'INVALID'
    
    UNION ALL
    
    -- Rule 4: Missing required fields
    SELECT 
        *,
        'MISSING_REQUIRED_FIELDS' AS rejection_code,
        'Required fields are missing: ' || 
            CASE WHEN firstname IS NULL THEN 'firstname ' ELSE '' END ||
            CASE WHEN lastname IS NULL THEN 'lastname ' ELSE '' END ||
            CASE WHEN birthdate IS NULL THEN 'birthdate ' ELSE '' END AS rejection_reason,
        'ERROR' AS rejection_severity
    FROM silver_all_records
    WHERE firstname IS NULL 
       OR lastname IS NULL 
       OR birthdate IS NULL
    
    UNION ALL
    
    -- Rule 5: Person title validation failed
    SELECT 
        *,
        'PERSON_TITLE_VALIDATION_FAILED' AS rejection_code,
        'Person title validation failed (dq_person_title_valid = FALSE or dq_person_title_other_complete = FALSE)' AS rejection_reason,
        'ERROR' AS rejection_severity
    FROM silver_all_records
    WHERE NOT dq_person_title_valid 
       OR NOT dq_person_title_other_complete
    
    UNION ALL
    
    -- Rule 6: Multiple critical validations failed
    SELECT 
        *,
        'MULTIPLE_VALIDATIONS_FAILED' AS rejection_code,
        'Multiple critical validations failed (3 or more)' AS rejection_reason,
        'ERROR' AS rejection_severity
    FROM silver_all_records
    WHERE (
        CASE WHEN NOT dq_person_title_valid THEN 1 ELSE 0 END +
        CASE WHEN NOT dq_marital_status_valid THEN 1 ELSE 0 END +
        CASE WHEN NOT dq_nationality_valid THEN 1 ELSE 0 END +
        CASE WHEN NOT dq_occupation_valid THEN 1 ELSE 0 END +
        CASE WHEN NOT dq_total_asset_valid THEN 1 ELSE 0 END +
        CASE WHEN NOT dq_monthly_income_valid THEN 1 ELSE 0 END
    ) >= 3
),

-- Build failed validations JSON
with_failed_validations AS (
    SELECT 
        *,
        jsonb_build_object(
            'dq_person_title_valid', dq_person_title_valid,
            'dq_person_title_other_complete', dq_person_title_other_complete,
            'dq_marital_status_valid', dq_marital_status_valid,
            'dq_nationality_valid', dq_nationality_valid,
            'dq_occupation_valid', dq_occupation_valid,
            'dq_education_level_valid', dq_education_level_valid,
            'dq_business_type_valid', dq_business_type_valid,
            'dq_total_asset_valid', dq_total_asset_valid,
            'dq_monthly_income_valid', dq_monthly_income_valid,
            'dq_income_country_valid', dq_income_country_valid,
            'dq_score', dq_score,
            'dq_status', dq_status
        ) AS failed_validations_json
    FROM critical_errors
),

-- Format for quarantine table
final AS (
    SELECT 
        CURRENT_TIMESTAMP AS rejection_timestamp,
        rejection_reason,
        rejection_code,
        rejection_severity,
        
        -- Source tracking
        'MSSQL_CORE' AS source_system,
        bronze_batch_id,
        _bronze_load_ts AS bronze_load_ts,
        silver_load_ts AS silver_load_attempt_ts,
        
        -- Resolution tracking
        'PENDING' AS resolution_status,
        NULL:: timestamp AS resolved_timestamp,
        NULL AS resolved_by,
        NULL AS resolution_notes,
        0 AS retry_count,
        
        -- All original columns
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
        
        -- DQ scores
        dq_score,
        dq_status,
        failed_validations_json AS failed_validations
        
    FROM with_failed_validations
)

SELECT * FROM final
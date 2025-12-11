{{
    config(
        materialized='table',
        schema='gold',
        tags=['gold', 'dimension', 'scd2']
    )
}}

-- ====================================================================
-- Gold Layer: SCD Type 2 Customer Profile Dimension (Full Rebuild)
-- ====================================================================
-- Strategy: Full rebuild on each run (simple and correct)
-- For large datasets, switch to incremental with merge logic
-- ====================================================================

WITH silver_all_versions AS (
    -- Get all versions from Silver (historical + new)
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
        dq_score,
        dq_status,
        profile_hash,
        source_of_income_set_hash,
        purpose_of_investment_set_hash,
        last_modified_ts AS source_last_modified_ts,
        _silver_load_ts AS silver_load_ts,
        _bronze_batch_id AS bronze_batch_id,
        
        -- Rank versions per customer (1 = latest)
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY last_modified_ts DESC
        ) AS version_rank
        
    FROM {{ ref('customer_profile_standardized') }}
),

with_effective_dates AS (
    SELECT 
        *,
        
        -- effective_start_date = this version's timestamp
        source_last_modified_ts AS effective_start_date,
        
        -- effective_end_date = next version's timestamp - 1 second (or 9999-12-31 if current)
        COALESCE(
            LEAD(source_last_modified_ts) OVER (
                PARTITION BY customer_id 
                ORDER BY source_last_modified_ts
            ) - INTERVAL '1 second',
            '9999-12-31 23:59:59'::timestamp
        ) AS effective_end_date,
        
        -- is_current = TRUE if this is the latest version
        CASE WHEN version_rank = 1 THEN TRUE ELSE FALSE END AS is_current
        
    FROM silver_all_versions
),

final AS (
    SELECT 
        -- Surrogate key (use ROW_NUMBER as temp key, will be replaced by SERIAL on insert)
        ROW_NUMBER() OVER (ORDER BY customer_id, effective_start_date) AS customer_profile_sk,
        
        -- Natural key
        customer_id,
        
        -- SCD Type 2 columns
        effective_start_date,
        effective_end_date,
        is_current,
        
        -- Profile attributes
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
        
        -- Data quality
        dq_score,
        dq_status,
        
        -- Hashes
        profile_hash,
        source_of_income_set_hash,
        purpose_of_investment_set_hash,
        
        -- Audit columns
        'MSSQL_CORE' AS source_system,
        source_last_modified_ts,
        CURRENT_TIMESTAMP AS record_created_ts,
        NULL:: timestamp AS record_updated_ts,
        'dbt_etl' AS created_by,
        NULL AS updated_by,
        
        -- Lineage
        silver_load_ts,
        bronze_batch_id,
        
        -- Soft delete
        FALSE AS is_deleted,
        NULL::timestamp AS deleted_ts,
        NULL AS deleted_reason
        
    FROM with_effective_dates
)

SELECT * FROM final
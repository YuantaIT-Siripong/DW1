{{
    config(
        materialized='incremental',
        unique_key=['customer_id', 'last_modified_ts'],
        on_schema_change='fail',
        schema='silver'
    )
}}

WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'customer_profile_standardized') }}
    {% if is_incremental() %}
    WHERE _bronze_load_ts > (SELECT MAX(_bronze_load_ts) FROM {{ this }})
    {% endif %}
),

validated AS (
    SELECT 
        -- Natural Key
        customer_id,
        
        -- Identity Evidence
        evidence_unique_key,
        
        -- Names
        firstname,
        lastname,
        firstname_local,
        lastname_local,
        
        -- Enumeration Fields
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
        
        -- Demographics
        birthdate,
        
        -- Economic Bands
        total_asset,
        monthly_income,
        income_country,
        income_country_other,
        
        -- Multi-Valued Sets
        source_of_income_list,
        purpose_of_investment_list,
        
        -- Source Metadata
        last_modified_ts,
        
        -- Bronze Metadata
        _bronze_load_ts,
        _bronze_source_file,
        _bronze_batch_id,
        
        -- ====================================================================
        -- DATA QUALITY FLAGS (12 flags)
        -- ====================================================================
        
        -- Flag 1: person_title validation
        CASE 
            WHEN person_title IS NULL THEN TRUE
            WHEN person_title IN (SELECT code FROM {{ ref('_customer_person_title') }}) THEN TRUE
            ELSE FALSE
        END AS dq_person_title_valid,
        
        -- Flag 2: person_title_other required when person_title = 'OTHER'
        CASE 
            WHEN person_title = 'OTHER' AND person_title_other IS NOT NULL THEN TRUE
            WHEN person_title != 'OTHER' OR person_title IS NULL THEN TRUE
            ELSE FALSE
        END AS dq_person_title_other_complete,
        
        -- Flag 3: marital_status validation
        CASE 
            WHEN marital_status IS NULL THEN TRUE
            WHEN marital_status IN (SELECT code FROM {{ ref('_customer_marital_status') }}) THEN TRUE
            ELSE FALSE
        END AS dq_marital_status_valid,
        
        -- Flag 4: nationality validation
        CASE 
            WHEN nationality IS NULL THEN TRUE
            WHEN nationality IN (SELECT code FROM {{ ref('_customer_nationality') }}) THEN TRUE
            ELSE FALSE
        END AS dq_nationality_valid,
        
        -- Flag 5: nationality_other required when nationality = 'OTHER'
        CASE 
            WHEN nationality = 'OTHER' AND nationality_other IS NOT NULL THEN TRUE
            WHEN nationality != 'OTHER' OR nationality IS NULL THEN TRUE
            ELSE FALSE
        END AS dq_nationality_other_complete,
        
        -- Flag 6: occupation validation
        CASE 
            WHEN occupation IS NULL THEN TRUE
            WHEN occupation IN (SELECT code FROM {{ ref('_customer_occupation') }}) THEN TRUE
            ELSE FALSE
        END AS dq_occupation_valid,
        
        -- Flag 7: occupation_other required when occupation = 'OTHER'
        CASE 
            WHEN occupation = 'OTHER' AND occupation_other IS NOT NULL THEN TRUE
            WHEN occupation != 'OTHER' OR occupation IS NULL THEN TRUE
            ELSE FALSE
        END AS dq_occupation_other_complete,
        
        -- Flag 8: education_level validation
        CASE 
            WHEN education_level IS NULL THEN TRUE
            WHEN education_level IN (SELECT code FROM {{ ref('_customer_education_level') }}) THEN TRUE
            ELSE FALSE
        END AS dq_education_level_valid,
        
        -- Flag 9: business_type validation
        CASE 
            WHEN business_type IS NULL THEN TRUE
            WHEN business_type IN (SELECT code FROM {{ ref('_customer_business_type') }}) THEN TRUE
            ELSE FALSE
        END AS dq_business_type_valid,
        
        -- Flag 10: total_asset validation
        CASE 
            WHEN total_asset IS NULL THEN TRUE
            WHEN total_asset IN (SELECT code FROM {{ ref('_customer_total_asset_bands') }}) THEN TRUE
            ELSE FALSE
        END AS dq_total_asset_valid,
        
        -- Flag 11: monthly_income validation
        CASE 
            WHEN monthly_income IS NULL THEN TRUE
            WHEN monthly_income IN (SELECT code FROM {{ ref('_customer_monthly_income_bands') }}) THEN TRUE
            ELSE FALSE
        END AS dq_monthly_income_valid,
        
        -- Flag 12: income_country validation
        CASE 
            WHEN income_country IS NULL THEN TRUE
            WHEN income_country IN (SELECT code FROM {{ ref('_customer_income_country') }}) THEN TRUE
            ELSE FALSE
        END AS dq_income_country_valid
        
    FROM source
),

with_hashes AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- SET HASHES (Normalized for change detection)
        -- ====================================================================
        
        -- source_of_income_set_hash: Hash of sorted pipe-delimited set
        {{ compute_set_hash('source_of_income_list') }} AS source_of_income_set_hash,
        
        -- purpose_of_investment_set_hash: Hash of sorted pipe-delimited set
        {{ compute_set_hash('purpose_of_investment_list') }} AS purpose_of_investment_set_hash
        
    FROM validated
),

with_profile_hash AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- PROFILE HASH (For SCD2 change detection)
        -- ====================================================================
        
        {{ compute_profile_hash(
            'evidence_unique_key',
            'firstname',
            'lastname',
            'firstname_local',
            'lastname_local',
            'person_title',
            'marital_status',
            'nationality',
            'occupation',
            'education_level',
            'business_type',
            'birthdate',
            'total_asset',
            'monthly_income',
            'income_country',
            'source_of_income_set_hash',
            'purpose_of_investment_set_hash'
        ) }} AS profile_hash
        
    FROM with_hashes
),

final AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- DATA QUALITY SCORE & STATUS
        -- ====================================================================
        
        -- DQ Score: Percentage of passed validations (0-100)
        ROUND(
            (
                CASE WHEN dq_person_title_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_person_title_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_marital_status_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_nationality_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_nationality_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_occupation_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_occupation_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_education_level_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_business_type_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_total_asset_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_monthly_income_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_income_country_valid THEN 1 ELSE 0 END
            ):: NUMERIC / 12 * 100,
            2
        ) AS dq_score,
        
        -- DQ Status: Categorical quality classification
        CASE 
            WHEN (
                CASE WHEN dq_person_title_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_person_title_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_marital_status_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_nationality_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_nationality_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_occupation_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_occupation_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_education_level_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_business_type_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_total_asset_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_monthly_income_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_income_country_valid THEN 1 ELSE 0 END
            ) = 12 THEN 'VALID'
            WHEN (
                CASE WHEN dq_person_title_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_person_title_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_marital_status_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_nationality_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_nationality_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_occupation_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_occupation_other_complete THEN 1 ELSE 0 END +
                CASE WHEN dq_education_level_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_business_type_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_total_asset_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_monthly_income_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_income_country_valid THEN 1 ELSE 0 END
            ) >= 10 THEN 'WARNING'
            ELSE 'INVALID'
        END AS dq_status,
        
        -- Silver Metadata
        CURRENT_TIMESTAMP AS _silver_load_ts
        
    FROM with_profile_hash
)

SELECT * FROM final
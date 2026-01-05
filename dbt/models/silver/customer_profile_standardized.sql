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
        -- DATA QUALITY FLAGS (12 flags with OTHER validation)
        -- ====================================================================
        
        -- Flag 1: person_title validation (includes OTHER check)
        CASE 
            WHEN person_title IS NULL THEN TRUE
            WHEN person_title = 'OTHER' AND (person_title_other IS NULL OR TRIM(person_title_other) = '') 
                THEN FALSE
            WHEN person_title IN ('MR', 'MRS', 'MS', 'MISS', 'DR', 'PROF', 'REV', 'OTHER')
                THEN TRUE
            ELSE FALSE
        END AS is_valid_person_title,
        
        -- Flag 2: marital_status validation (no OTHER option)
        CASE 
            WHEN marital_status IS NULL THEN TRUE
            WHEN marital_status IN ('SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED', 'SEPARATED', 'UNKNOWN')
                THEN TRUE
            ELSE FALSE
        END AS is_valid_marital_status,
        
        -- Flag 3: nationality validation (includes OTHER check)
        CASE 
            WHEN nationality IS NULL THEN TRUE
            WHEN nationality = 'OTHER' AND (nationality_other IS NULL OR TRIM(nationality_other) = '') 
                THEN FALSE
            WHEN LENGTH(nationality) = 2 OR nationality = 'OTHER'
                THEN TRUE
            ELSE FALSE
        END AS is_valid_nationality,
        
        -- Flag 4: occupation validation (includes OTHER check)
        CASE 
            WHEN occupation IS NULL THEN TRUE
            WHEN occupation = 'OTHER' AND (occupation_other IS NULL OR TRIM(occupation_other) = '') 
                THEN FALSE
            WHEN occupation IN ('EMPLOYEE', 'SELF_EMPLOYED', 'BUSINESS_OWNER', 'GOVERNMENT_OFFICER', 
                               'PROFESSIONAL', 'RETIRED', 'STUDENT', 'HOMEMAKER', 'UNEMPLOYED', 'OTHER', 'UNKNOWN')
                THEN TRUE
            ELSE FALSE
        END AS is_valid_occupation,
        
        -- Flag 5: education_level validation (includes OTHER check)
        CASE 
            WHEN education_level IS NULL THEN TRUE
            WHEN education_level = 'OTHER' AND (education_level_other IS NULL OR TRIM(education_level_other) = '') 
                THEN FALSE
            WHEN education_level IN ('PRIMARY', 'SECONDARY', 'VOCATIONAL', 'DIPLOMA', 'BACHELOR', 
                                    'MASTER', 'DOCTORATE', 'OTHER', 'UNKNOWN')
                THEN TRUE
            ELSE FALSE
        END AS is_valid_education_level,
        
        -- Flag 6: business_type validation (includes OTHER check)
        CASE 
            WHEN business_type IS NULL THEN TRUE
            WHEN business_type = 'OTHER' AND (business_type_other IS NULL OR TRIM(business_type_other) = '') 
                THEN FALSE
            WHEN business_type IN ('FINANCE', 'MANUFACTURING', 'RETAIL', 'SERVICES', 'AGRICULTURE', 
                                  'TECHNOLOGY', 'HEALTHCARE', 'EDUCATION', 'CONSTRUCTION', 'HOSPITALITY', 
                                  'TRANSPORTATION', 'ENERGY', 'MEDIA', 'GOVERNMENT', 'OTHER', 'UNKNOWN')
                THEN TRUE
            ELSE FALSE
        END AS is_valid_business_type,
        
        -- Flag 7: total_asset validation (NO OTHER option)
        CASE 
            WHEN total_asset IS NULL THEN TRUE
            WHEN total_asset IN ('ASSET_BAND_1', 'ASSET_BAND_2', 'ASSET_BAND_3', 'ASSET_BAND_4', 'ASSET_BAND_5', 'UNKNOWN')
                THEN TRUE
            ELSE FALSE
        END AS is_valid_total_asset,
        
        -- Flag 8: monthly_income validation (NO OTHER option)
        CASE 
            WHEN monthly_income IS NULL THEN TRUE
            WHEN monthly_income IN ('INCOME_BAND_1', 'INCOME_BAND_2', 'INCOME_BAND_3', 'INCOME_BAND_4', 'INCOME_BAND_5', 'UNKNOWN')
                THEN TRUE
            ELSE FALSE
        END AS is_valid_monthly_income,
        
        -- Flag 9: income_country validation (includes OTHER check)
        CASE 
            WHEN income_country IS NULL THEN TRUE
            WHEN income_country = 'OTHER' AND (income_country_other IS NULL OR TRIM(income_country_other) = '') 
                THEN FALSE
            WHEN LENGTH(income_country) = 2 OR income_country = 'OTHER'
                THEN TRUE
            ELSE FALSE
        END AS is_valid_income_country,
        
        -- Flag 10: birthdate validation
        CASE 
            WHEN birthdate IS NULL THEN FALSE
            WHEN birthdate > CURRENT_DATE THEN FALSE
            WHEN DATE_PART('year', AGE(birthdate)) < 18 THEN FALSE
            WHEN DATE_PART('year', AGE(birthdate)) > 120 THEN FALSE
            ELSE TRUE
        END AS is_valid_birthdate,
        
        -- Flag 11: source_of_income_list validation (simplified - check not empty)
        CASE 
            WHEN source_of_income_list IS NULL OR TRIM(source_of_income_list) = '' THEN TRUE
            WHEN source_of_income_list ~ '^[A-Z_|]+$' THEN TRUE
            ELSE FALSE
        END AS is_valid_source_of_income_list,
        
        -- Flag 12: purpose_of_investment_list validation (simplified - check not empty)
        CASE 
            WHEN purpose_of_investment_list IS NULL OR TRIM(purpose_of_investment_list) = '' THEN TRUE
            WHEN purpose_of_investment_list ~ '^[A-Z_|]+$' THEN TRUE
            ELSE FALSE
        END AS is_valid_purpose_of_investment_list
        
    FROM source
),

with_hashes AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- SET HASHES (Normalized for change detection)
        -- ====================================================================
        
        -- source_of_income_set_hash:  Hash of sorted pipe-delimited set
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
            ):: NUMERIC / 12 * 100,
            2
        ) AS data_quality_score,
        
        -- DQ Status:  Categorical quality classification
        CASE 
            -- Perfect score
            WHEN (
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
            ) = 12 THEN 'VALID'
            
            -- Good score with OTHER usage
            WHEN (
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
            ) >= 11
            AND (person_title = 'OTHER' OR nationality = 'OTHER' OR occupation = 'OTHER' 
                 OR education_level = 'OTHER' OR business_type = 'OTHER' OR income_country = 'OTHER')
            THEN 'VALID_WITH_OTHER'
            
            -- Birthdate specific failure
            WHEN NOT is_valid_birthdate THEN 'INVALID_BIRTHDATE'
            
            -- Multiple issues
            WHEN (
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
            ) < 9 THEN 'MULTIPLE_ISSUES'
            
            -- Default:  enumeration issues
            ELSE 'INVALID_ENUMERATION'
        END AS _silver_dq_status,
        
        -- Silver Metadata
        CURRENT_TIMESTAMP AS _silver_load_ts
        
    FROM with_profile_hash
)

SELECT * FROM final
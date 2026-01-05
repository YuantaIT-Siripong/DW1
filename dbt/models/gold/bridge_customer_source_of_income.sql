{{
    config(
        materialized='table',
        schema='gold',
        tags=['gold', 'bridge']
    )
}}

-- ====================================================================
-- Gold Layer: Bridge Customer Source of Income
-- ====================================================================
-- Parses pipe-delimited source_of_income_list into individual rows
-- Links to dim_customer_profile via customer_profile_version_sk
-- ====================================================================

WITH dim_profile AS (
    SELECT 
        customer_profile_version_sk,
        customer_id,
        source_of_income_set_hash
    FROM {{ ref('dim_customer_profile') }}
),

silver_source AS (
    SELECT 
        customer_id,
        source_of_income_list,
        source_of_income_set_hash,
        last_modified_ts
    FROM {{ ref('customer_profile_standardized') }}
    WHERE source_of_income_list IS NOT NULL 
      AND TRIM(source_of_income_list) != ''
),

-- Split pipe-delimited list into rows
parsed_codes AS (
    SELECT 
        customer_id,
        TRIM(UNNEST(STRING_TO_ARRAY(source_of_income_list, '|'))) AS source_of_income_code,
        source_of_income_set_hash,
        last_modified_ts
    FROM silver_source
),

-- Join to dimension to get surrogate key
final AS (
    SELECT 
        dim. customer_profile_version_sk,
        dim.customer_id,
        parsed.source_of_income_code,
        CURRENT_TIMESTAMP AS load_ts
        
    FROM parsed_codes parsed
    INNER JOIN dim_profile dim
        ON parsed.customer_id = dim.customer_id
        AND parsed.source_of_income_set_hash = dim.source_of_income_set_hash
    
    WHERE parsed.source_of_income_code IS NOT NULL
      AND TRIM(parsed.source_of_income_code) != ''
)

SELECT * FROM final
{{
    config(
        materialized='table',
        schema='gold',
        tags=['gold', 'bridge']
    )
}}

-- ====================================================================
-- Gold Layer: Bridge Customer Purpose of Investment
-- ====================================================================
-- Parses pipe-delimited purpose_of_investment_list into individual rows
-- Links to dim_customer_profile via customer_profile_version_sk
-- ====================================================================

WITH dim_profile AS (
    SELECT 
        customer_profile_version_sk,
        customer_id,
        purpose_of_investment_set_hash
    FROM {{ ref('dim_customer_profile') }}
),

silver_source AS (
    SELECT 
        customer_id,
        purpose_of_investment_list,
        purpose_of_investment_set_hash,
        last_modified_ts
    FROM {{ ref('customer_profile_standardized') }}
    WHERE purpose_of_investment_list IS NOT NULL 
      AND TRIM(purpose_of_investment_list) != ''
),

-- Split pipe-delimited list into rows
parsed_codes AS (
    SELECT 
        customer_id,
        TRIM(UNNEST(STRING_TO_ARRAY(purpose_of_investment_list, '|'))) AS purpose_of_investment_code,
        purpose_of_investment_set_hash,
        last_modified_ts
    FROM silver_source
),

-- Join to dimension to get surrogate key
final AS (
    SELECT 
        dim.customer_profile_version_sk,
        dim.customer_id,
        parsed.purpose_of_investment_code,
        CURRENT_TIMESTAMP AS load_ts
        
    FROM parsed_codes parsed
    INNER JOIN dim_profile dim
        ON parsed.customer_id = dim.customer_id
        AND parsed.purpose_of_investment_set_hash = dim.purpose_of_investment_set_hash
    
    WHERE parsed.purpose_of_investment_code IS NOT NULL
      AND TRIM(parsed.purpose_of_investment_code) != ''
)

SELECT * FROM final
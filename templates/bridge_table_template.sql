-- =====================================================================
-- TEMPLATE: Bridge Table for Multi-Valued Sets
-- =====================================================================
-- PURPOSE: Handle many-to-many relationships between versioned dimensions
--          and multi-valued attributes (e.g., investment objectives,
--          income sources, contact channels)
-- =====================================================================
-- WHEN TO USE:
--   - An entity can have MULTIPLE values for an attribute
--   - Values can change over time (hence the version reference)
--   - You need to query individual set members efficiently
--   - Set membership changes should trigger new dimension versions
-- =====================================================================
-- PATTERN: Medallion Architecture
--   Bronze:  Pipe-delimited list (e.g., "GROWTH|INCOME|PRESERVATION")
--   Silver:  Pipe-delimited list + set_hash (SHA256 for change detection)
--   Gold:    Bridge table (one row per version-code pair)
-- =====================================================================

-- =====================================================================
-- STEP 1: CONFIGURE PLACEHOLDERS
-- =====================================================================
-- Replace these throughout the template:
--   <DOMAIN>        : customer, investment, company, service
--   <ENTITY>        : profile, account, subscription, service
--   <SET_NAME>      : source_of_income, investment_objective, contact_channel
--   <VERSION_SK>    : {entity}_version_sk (e.g., customer_profile_version_sk)
--   <DIMENSION_TABLE>: Fully qualified dimension table name
-- =====================================================================

-- =====================================================================
-- SCHEMA & TABLE CREATION
-- =====================================================================

-- Create schema (if not exists)
CREATE SCHEMA IF NOT EXISTS gold;

-- Drop table (for development - remove in production)
-- DROP TABLE IF EXISTS gold.bridge_<DOMAIN>_<SET_NAME> CASCADE;

-- Create bridge table
CREATE TABLE gold.bridge_<DOMAIN>_<SET_NAME> (
    -- ================================================================
    -- COMPOSITE PRIMARY KEY
    -- ================================================================
    -- Foreign key to the versioned dimension
    <VERSION_SK> BIGINT NOT NULL,
    
    -- Enumeration code for this set member
    <SET_NAME>_code VARCHAR(50) NOT NULL,
    
    -- ================================================================
    -- RELATIONSHIP ATTRIBUTES (Optional)
    -- ================================================================
    -- Add only if the relationship itself has attributes
    -- Examples:
    --   - effective_date: When this member was added to the set
    --   - weight: Importance/priority of this member
    --   - rank: Ordering within the set
    --   - is_primary: Flag for primary selection
    
    -- effective_date DATE,
    -- weight NUMERIC(5,2),
    -- rank INT,
    -- is_primary BOOLEAN DEFAULT FALSE,
    
    -- ================================================================
    -- AUDIT COLUMNS (Standard for all tables)
    -- ================================================================
    created_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'dbt_etl',
    
    -- ================================================================
    -- CONSTRAINTS
    -- ================================================================
    -- Primary Key: Composite of version and code
    CONSTRAINT pk_bridge_<DOMAIN>_<SET_NAME> 
        PRIMARY KEY (<VERSION_SK>, <SET_NAME>_code),
    
    -- Foreign Key: Link to versioned dimension
    CONSTRAINT fk_bridge_<DOMAIN>_<SET_NAME>_version
        FOREIGN KEY (<VERSION_SK>)
        REFERENCES <DIMENSION_TABLE>(<VERSION_SK>)
        ON DELETE CASCADE  -- Optional: cascade deletes
);

-- ================================================================
-- INDEXES FOR QUERY PERFORMANCE
-- ================================================================

-- Index 1: Lookup by version (MOST COMMON QUERY)
-- Use: Get all set members for a specific dimension version
CREATE INDEX idx_bridge_<DOMAIN>_<SET_NAME>_version
    ON gold.bridge_<DOMAIN>_<SET_NAME>(<VERSION_SK>);

-- Index 2: Reverse lookup by code (LESS COMMON)
-- Use: Find all versions that include a specific set member
CREATE INDEX idx_bridge_<DOMAIN>_<SET_NAME>_code
    ON gold.bridge_<DOMAIN>_<SET_NAME>(<SET_NAME>_code);

-- Index 3: Composite index for analytical queries (OPTIONAL)
-- Use: Join dimension + bridge + filter by code
-- CREATE INDEX idx_bridge_<DOMAIN>_<SET_NAME>_composite
--     ON gold.bridge_<DOMAIN>_<SET_NAME>(<VERSION_SK>, <SET_NAME>_code, created_ts);

-- ================================================================
-- TABLE COMMENTS (Documentation)
-- ================================================================

COMMENT ON TABLE gold.bridge_<DOMAIN>_<SET_NAME> IS
'Bridge table for multi-valued <SET_NAME> attribute of <ENTITY>.
Each row represents ONE value in the set for a SPECIFIC version.
Use this pattern when an entity can have MULTIPLE values for an attribute.

Example: A customer can have multiple income sources (SALARY, DIVIDEND, RENTAL).
When the set changes (add/remove member), a new dimension version is created.

Query Pattern:
  SELECT d.*, array_agg(b.<SET_NAME>_code ORDER BY b.<SET_NAME>_code) as <SET_NAME>_array
  FROM <DIMENSION_TABLE> d
  LEFT JOIN gold.bridge_<DOMAIN>_<SET_NAME> b ON d.<VERSION_SK> = b.<VERSION_SK>
  WHERE d.is_current = TRUE
  GROUP BY d.<VERSION_SK>;
';

COMMENT ON COLUMN gold.bridge_<DOMAIN>_<SET_NAME>.<VERSION_SK> IS
'Foreign key to versioned dimension (surrogate key).
Links this set member to a specific version of the dimension.
When dimension creates a new version, bridge records are recreated for that version.';

COMMENT ON COLUMN gold.bridge_<DOMAIN>_<SET_NAME>.<SET_NAME>_code IS
'Enumeration code for this set member.
Must be a valid value from the enumeration YAML definition file located at:
  enumerations/<DOMAIN>_<SET_NAME>.yaml
These are physical YAML files in the repository, not database tables.
Examples: SALARY, DIVIDEND, RENTAL (for source_of_income)';

COMMENT ON COLUMN gold.bridge_<DOMAIN>_<SET_NAME>.created_ts IS
'UTC timestamp when this bridge record was created.
Typically matches the dimension version effective_start_ts.';

-- ================================================================
-- GRANT PERMISSIONS
-- ================================================================
GRANT SELECT ON gold.bridge_<DOMAIN>_<SET_NAME> TO dw_analyst;
GRANT SELECT, INSERT, UPDATE, DELETE ON gold.bridge_<DOMAIN>_<SET_NAME> TO dw_etl_service;
GRANT SELECT ON gold.bridge_<DOMAIN>_<SET_NAME> TO dw_privileged;

-- ================================================================
-- SET HASH COMPUTATION (For Change Detection)
-- ================================================================
/*
To detect changes in the set membership, compute a set_hash in the Silver layer:

ALGORITHM:
1. Parse pipe-delimited list from Bronze/Silver
2. Split by '|' delimiter
3. Normalize each code: UPPER(TRIM(code))
4. Remove empty strings
5. Deduplicate (DISTINCT)
6. Sort ascending
7. Re-join with '|' delimiter
8. Compute SHA256 hash -> lowercase hex (64 characters)

EMPTY SET HANDLING:
- Empty list or NULL -> SHA256('') 
- Constant: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'

STORAGE:
- Store set_hash in the dimension table (for change detection)
- Store original pipe-delimited list in dimension (for reference)
- Store individual members in bridge table (for querying)

EXAMPLE (PostgreSQL):
SELECT 
    <VERSION_SK>,
    <SET_NAME>_list,  -- Original: "SALARY|DIVIDEND|RENTAL"
    encode(
        sha256(
            string_agg(code, '|' ORDER BY code)::bytea
        ),
        'hex'
    ) as <SET_NAME>_set_hash
FROM (
    SELECT DISTINCT
        <VERSION_SK>,
        UPPER(TRIM(code)) as code
    FROM gold.bridge_<DOMAIN>_<SET_NAME>
) t
GROUP BY <VERSION_SK>, <SET_NAME>_list;
*/

-- ================================================================
-- EXAMPLE QUERIES
-- ================================================================
/*
-- QUERY 1: Get all set members for a specific version
SELECT <SET_NAME>_code
FROM gold.bridge_<DOMAIN>_<SET_NAME>
WHERE <VERSION_SK> = 12345
ORDER BY <SET_NAME>_code;

-- QUERY 2: Get current set members for an entity
SELECT b.<SET_NAME>_code
FROM <DIMENSION_TABLE> d
JOIN gold.bridge_<DOMAIN>_<SET_NAME> b 
    ON d.<VERSION_SK> = b.<VERSION_SK>
WHERE d.{entity}_id = 556677
  AND d.is_current = TRUE
ORDER BY b.<SET_NAME>_code;

-- QUERY 3: Get set as array (PostgreSQL)
SELECT 
    d.{entity}_id,
    d.version_num,
    array_agg(b.<SET_NAME>_code ORDER BY b.<SET_NAME>_code) as <SET_NAME>_array
FROM <DIMENSION_TABLE> d
JOIN gold.bridge_<DOMAIN>_<SET_NAME> b 
    ON d.<VERSION_SK> = b.<VERSION_SK>
WHERE d.is_current = TRUE
GROUP BY d.{entity}_id, d.version_num;

-- QUERY 4: Get set as pipe-delimited string
SELECT 
    d.{entity}_id,
    string_agg(b.<SET_NAME>_code, '|' ORDER BY b.<SET_NAME>_code) as <SET_NAME>_list
FROM <DIMENSION_TABLE> d
JOIN gold.bridge_<DOMAIN>_<SET_NAME> b 
    ON d.<VERSION_SK> = b.<VERSION_SK>
WHERE d.{entity}_id = 556677
  AND d.is_current = TRUE
GROUP BY d.{entity}_id;

-- QUERY 5: Find entities with a specific set member
SELECT DISTINCT d.{entity}_id
FROM <DIMENSION_TABLE> d
JOIN gold.bridge_<DOMAIN>_<SET_NAME> b 
    ON d.<VERSION_SK> = b.<VERSION_SK>
WHERE b.<SET_NAME>_code = 'SALARY'
  AND d.is_current = TRUE;

-- QUERY 6: Count set members per entity
SELECT 
    d.{entity}_id,
    COUNT(b.<SET_NAME>_code) as member_count
FROM <DIMENSION_TABLE> d
LEFT JOIN gold.bridge_<DOMAIN>_<SET_NAME> b 
    ON d.<VERSION_SK> = b.<VERSION_SK>
WHERE d.is_current = TRUE
GROUP BY d.{entity}_id
ORDER BY member_count DESC;

-- QUERY 7: Historical view - show set changes over time
SELECT 
    d.{entity}_id,
    d.version_num,
    d.effective_start_ts,
    d.effective_end_ts,
    string_agg(b.<SET_NAME>_code, '|' ORDER BY b.<SET_NAME>_code) as <SET_NAME>_list
FROM <DIMENSION_TABLE> d
LEFT JOIN gold.bridge_<DOMAIN>_<SET_NAME> b 
    ON d.<VERSION_SK> = b.<VERSION_SK>
WHERE d.{entity}_id = 556677
GROUP BY d.{entity}_id, d.version_num, d.effective_start_ts, d.effective_end_ts
ORDER BY d.version_num;

-- QUERY 8: Validate referential integrity
-- Check for orphaned bridge records (version_sk not in dimension)
SELECT DISTINCT b.<VERSION_SK>
FROM gold.bridge_<DOMAIN>_<SET_NAME> b
LEFT JOIN <DIMENSION_TABLE> d ON b.<VERSION_SK> = d.<VERSION_SK>
WHERE d.<VERSION_SK> IS NULL;
-- Expected: No results (all bridge records should have matching dimension version)

-- QUERY 9: Validate enumeration values
-- Check for invalid codes (not in enumeration)
SELECT DISTINCT b.<SET_NAME>_code
FROM gold.bridge_<DOMAIN>_<SET_NAME> b
WHERE b.<SET_NAME>_code NOT IN (
    SELECT code FROM silver._<DOMAIN>_<SET_NAME>  -- enumeration reference table
);
-- Expected: No results (all codes should be valid)
*/

-- ================================================================
-- dbt MODEL IMPLEMENTATION
-- ================================================================
/*
-- File: dbt/models/gold/bridge_<DOMAIN>_<SET_NAME>.sql

{{
    config(
        materialized='table',  -- Full refresh each time
        schema='gold'
    )
}}

-- Description:
-- Bridge table for <SET_NAME> multi-valued set.
-- Parses pipe-delimited list from Silver/dimension and creates one row per member.

WITH source_versions AS (
    -- Get all dimension versions with non-null set list
    SELECT 
        <VERSION_SK>,
        {entity}_id,
        <SET_NAME>_list,
        effective_start_ts
    FROM {{ ref('dim_<ENTITY>') }}
    WHERE <SET_NAME>_list IS NOT NULL
      AND TRIM(<SET_NAME>_list) != ''
),

unnested AS (
    -- Parse pipe-delimited list and normalize each code
    SELECT 
        <VERSION_SK>,
        {entity}_id,
        UPPER(TRIM(code)) AS <SET_NAME>_code,
        effective_start_ts
    FROM source_versions,
    LATERAL unnest(string_to_array(<SET_NAME>_list, '|')) AS code
    WHERE TRIM(code) != ''  -- Filter out empty strings
),

distinct_pairs AS (
    -- Deduplicate (in case source has duplicates)
    SELECT DISTINCT
        <VERSION_SK>,
        <SET_NAME>_code
    FROM unnested
),

validated AS (
    -- Optional: Validate against enumeration table
    SELECT 
        dp.*,
        CASE 
            WHEN e.code IS NOT NULL THEN TRUE 
            ELSE FALSE 
        END AS is_valid_code
    FROM distinct_pairs dp
    LEFT JOIN {{ ref('_<DOMAIN>_<SET_NAME>') }} e
        ON dp.<SET_NAME>_code = e.code
)

-- Final output
SELECT 
    <VERSION_SK>,
    <SET_NAME>_code,
    CURRENT_TIMESTAMP AS created_ts,
    'dbt_etl' AS created_by
FROM validated
WHERE is_valid_code = TRUE  -- Only include valid enumeration codes
ORDER BY <VERSION_SK>, <SET_NAME>_code;

-- Add tests in schema.yml:
-- tests:
--   - unique:
--       column_name: "concat(<VERSION_SK>, '|', <SET_NAME>_code)"
--   - relationships:
--       to: ref('dim_<ENTITY>')
--       field: <VERSION_SK>
--   - accepted_values:
--       column_name: <SET_NAME>_code
--       values: [list from enumeration]
*/

-- ================================================================
-- ALTERNATIVE: INCREMENTAL MATERIALIZATION
-- ================================================================
/*
If your bridge table is very large and full refresh is expensive,
use incremental materialization:

{{
    config(
        materialized='incremental',
        unique_key=['<VERSION_SK>', '<SET_NAME>_code'],
        on_schema_change='fail',
        schema='gold'
    )
}}

WITH new_versions AS (
    SELECT <VERSION_SK>, <SET_NAME>_list, effective_start_ts
    FROM {{ ref('dim_<ENTITY>') }}
    {% if is_incremental() %}
    WHERE effective_start_ts > (SELECT MAX(created_ts) FROM {{ this }})
    {% endif %}
),

-- ... rest of logic same as above ...

NOTES:
- Incremental is more complex because you need to handle:
  1. New versions (new <VERSION_SK>)
  2. Changed sets (same <VERSION_SK>, different members - shouldn't happen if designed correctly)
  3. Deletions (version closed/deleted)
- Usually table materialization is preferred for bridge tables (simpler, safer)
*/

-- ================================================================
-- DATA QUALITY CHECKS
-- ================================================================
/*
Add these as dbt tests or SQL validation queries:

1. NO ORPHANED RECORDS
   Every bridge record must have a matching dimension version:
   SELECT COUNT(*) FROM gold.bridge_<DOMAIN>_<SET_NAME> b
   LEFT JOIN <DIMENSION_TABLE> d ON b.<VERSION_SK> = d.<VERSION_SK>
   WHERE d.<VERSION_SK> IS NULL;
   -- Must be 0

2. NO INVALID CODES
   Every code must be in the enumeration:
   SELECT COUNT(*) FROM gold.bridge_<DOMAIN>_<SET_NAME> b
   WHERE NOT EXISTS (
       SELECT 1 FROM silver._<DOMAIN>_<SET_NAME> e 
       WHERE e.code = b.<SET_NAME>_code
   );
   -- Must be 0

3. NO DUPLICATE PAIRS
   (Handled by PK constraint, but good to verify in tests)
   SELECT <VERSION_SK>, <SET_NAME>_code, COUNT(*)
   FROM gold.bridge_<DOMAIN>_<SET_NAME>
   GROUP BY <VERSION_SK>, <SET_NAME>_code
   HAVING COUNT(*) > 1;
   -- Must be 0 rows

4. CONSISTENT WITH DIMENSION
   Verify set_hash in dimension matches recomputed hash from bridge:
   SELECT 
       d.<VERSION_SK>,
       d.<SET_NAME>_set_hash as dimension_hash,
       encode(sha256(string_agg(b.<SET_NAME>_code, '|' ORDER BY b.<SET_NAME>_code)::bytea), 'hex') as bridge_hash
   FROM <DIMENSION_TABLE> d
   JOIN gold.bridge_<DOMAIN>_<SET_NAME> b ON d.<VERSION_SK> = b.<VERSION_SK>
   GROUP BY d.<VERSION_SK>, d.<SET_NAME>_set_hash
   HAVING d.<SET_NAME>_set_hash != encode(sha256(string_agg(b.<SET_NAME>_code, '|' ORDER BY b.<SET_NAME>_code)::bytea), 'hex');
   -- Must be 0 rows (hashes should match)
*/

-- ================================================================
-- MAINTENANCE & OPERATIONS
-- ================================================================
/*
REBUILD BRIDGE TABLE:
If data gets corrupted or you change logic, rebuild from dimension:

TRUNCATE gold.bridge_<DOMAIN>_<SET_NAME>;
-- Then run dbt model: dbt run --models bridge_<DOMAIN>_<SET_NAME>

PERFORMANCE TUNING:
- If queries are slow, analyze query patterns
- Add composite indexes if needed
- Consider partitioning by <VERSION_SK> for very large tables

MONITORING:
- Track row counts over time
- Monitor for orphaned records
- Alert on invalid enumeration codes
- Check referential integrity weekly
*/

-- =====================================================================
-- END OF TEMPLATE
-- =====================================================================

-- USAGE SUMMARY:
-- 1. Replace all <PLACEHOLDERS> with your specific values
-- 2. Uncomment optional relationship attributes if needed
-- 3. Create enumeration table/file for valid codes
-- 4. Run DDL to create bridge table
-- 5. Create dbt model using template above
-- 6. Add tests in schema.yml
-- 7. Test with sample data
-- 8. Deploy to production
-- =====================================================================

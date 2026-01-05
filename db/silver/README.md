# Silver Layer DDL

**Purpose**: Cleaned & validated data with computed hash columns  
**Layer**: Silver (Cleaned)  
**Schema**: `silver`  
**Last Updated**: 2026-01-05

---

## Overview

The Silver layer contains **cleaned, validated, and enriched** data from Bronze. This layer adds computed columns (hashes, quality flags) while maintaining a flat table structure.

---

## Silver Layer Principles

### 1. Cleaned Data
- ✅ Type conversions applied
- ✅ Text normalization (TRIM, UPPER for codes)
- ✅ NULL standardization

### 2. Computed Columns
- ✅ **profile_hash**: SHA256 of version-driving attributes
- ✅ **<set>_set_hash**: SHA256 of multi-valued sets
- ✅ **dq_* flags**: Data quality validation results
- ✅ **dq_score**: Overall quality score (0-100)
- ✅ **dq_status**: Quality status (PASS/WARN/FAIL)

### 3. Still Flat Structure
- ✅ One row per entity version (like Bronze)
- ✅ NOT dimensional (no star schema yet)
- ✅ Preserves all Bronze columns

---

## DDL Files in This Directory

**Note**: Silver DDL files may be minimal or absent because dbt handles materialization.

If DDL exists:
- **Purpose**: Document expected structure
- **Usage**: Reference for dbt model development
- **Maintenance**: Update when dbt model structure changes

---

## Silver Table Structure

### Required Columns (All Silver Tables)

```sql
CREATE TABLE silver.<entity>_standardized (
    -- All Bronze columns (inherited)
    <entity>_id BIGINT NOT NULL,
    last_modified_ts TIMESTAMP NOT NULL,
    -- ... all business attributes ...
    
    -- Computed hash columns
    profile_hash VARCHAR(64) NOT NULL,
    <set1>_set_hash VARCHAR(64),  -- if multi-valued sets exist
    <set2>_set_hash VARCHAR(64),
    
    -- Data quality flags
    dq_<enum1>_valid BOOLEAN,
    dq_<enum2>_valid BOOLEAN,
    -- ... one flag per enumeration validation ...
    
    -- Data quality metrics
    dq_score NUMERIC(5,2),
    dq_status VARCHAR(20),
    
    -- ETL metadata
    _bronze_load_ts TIMESTAMP NOT NULL,
    _bronze_source_file VARCHAR(255),
    _bronze_batch_id VARCHAR(100),
    _silver_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Primary key
    PRIMARY KEY (<entity>_id, last_modified_ts)
);
```

---

## Hash Computation

### profile_hash

**Purpose**: Detect changes in version-driving attributes

**Algorithm**: SHA256

**Includes**:
- ✅ All Type 2 attributes (version-driving)
- ✅ Multi-valued set hashes

**Excludes**:
- ❌ Surrogate keys (_version_sk)
- ❌ Temporal columns (effective_*, is_current, version_num)
- ❌ Type 1 attributes (*_other fields)
- ❌ ETL metadata (_bronze_*, _silver_*, load_ts)
- ❌ profile_hash itself
- ❌ Data quality columns (dq_*)

**Implementation**: Use dbt macro `{{ compute_profile_hash() }}`

### <set>_set_hash

**Purpose**: Detect changes in multi-valued sets (e.g., income sources)

**Algorithm**: SHA256 of pipe-delimited sorted values

**Example**:
```
income_source_set_hash = SHA256('BUSINESS|SALARY|INVESTMENT')
```

**Implementation**: Use dbt macro `{{ compute_set_hash() }}`

---

## Data Quality Columns

### Validation Flags (dq_*)

One boolean flag per enumeration validation:

```sql
dq_marital_status_valid BOOLEAN  -- Is marital_status in enum?
dq_nationality_valid BOOLEAN      -- Is nationality in enum?
dq_occupation_valid BOOLEAN       -- Is occupation in enum?
```

**Implementation**: Use dbt macro `{{ validate_enumeration() }}`

### Quality Score

```sql
dq_score NUMERIC(5,2)  -- 0.00 to 100.00
```

**Calculation**:
```
dq_score = (count of TRUE flags / count of all flags) * 100
```

### Quality Status

```sql
dq_status VARCHAR(20)  -- 'PASS', 'WARN', 'FAIL'
```

**Logic**:
- `PASS`: dq_score >= 95
- `WARN`: dq_score >= 70 and < 95
- `FAIL`: dq_score < 70

---

## Indexes

**Mandatory indexes**:

1. **Primary Key** (automatic)
2. **profile_hash**: For change detection
3. **Natural Key**: For lookups

```sql
CREATE INDEX idx_silver_<entity>_hash 
    ON silver.<entity>_standardized(profile_hash);

CREATE INDEX idx_silver_<entity>_nk 
    ON silver.<entity>_standardized(<entity>_id);
```

---

## Materialization Strategy

**dbt Materialization**: `incremental`

**Incremental Logic**:
```sql
{% if is_incremental() %}
    WHERE _bronze_load_ts > (SELECT MAX(_bronze_load_ts) FROM {{ this }})
{% endif %}
```

**Why incremental?**:
- Performance: Process only new/changed records
- Efficiency: Avoid full table scans
- Scalability: Handles large datasets

---

## dbt Model Structure

```sql
-- Config
{{ config(
    materialized='incremental',
    unique_key=['<entity>_id', 'last_modified_ts'],
    schema='silver'
) }}

-- CTEs
WITH source AS (
    SELECT * FROM {{ ref('bronze_<entity>_standardized') }}
    {% if is_incremental() %}
        WHERE _bronze_load_ts > (SELECT MAX(_bronze_load_ts) FROM {{ this }})
    {% endif %}
),

validated AS (
    SELECT 
        *,
        -- Validation flags using macro
        {{ validate_enumeration('marital_status', 'customer_marital_status') }} AS dq_marital_status_valid,
        {{ validate_enumeration('nationality', 'customer_nationality') }} AS dq_nationality_valid
    FROM source
),

with_set_hashes AS (
    SELECT 
        *,
        -- Compute set hashes
        {{ compute_set_hash(['income_source_1', 'income_source_2', 'income_source_3']) }} AS income_source_set_hash
    FROM validated
),

with_profile_hash AS (
    SELECT 
        *,
        -- Compute profile hash
        {{ compute_profile_hash([
            'first_name', 'last_name', 'marital_status',
            'income_source_set_hash'
        ]) }} AS profile_hash
    FROM with_set_hashes
),

final AS (
    SELECT 
        *,
        -- Compute quality metrics
        ((dq_marital_status_valid::INT + dq_nationality_valid::INT) * 100.0 / 2) AS dq_score,
        CASE 
            WHEN ((dq_marital_status_valid::INT + dq_nationality_valid::INT) * 100.0 / 2) >= 95 THEN 'PASS'
            WHEN ((dq_marital_status_valid::INT + dq_nationality_valid::INT) * 100.0 / 2) >= 70 THEN 'WARN'
            ELSE 'FAIL'
        END AS dq_status,
        CURRENT_TIMESTAMP AS _silver_load_ts
    FROM with_profile_hash
)

SELECT * FROM final
```

---

## Data Flow

```
Bronze Layer (bronze.<entity>_standardized)
    ↓ (dbt incremental)
dbt CTE: source (with incremental filter)
    ↓
dbt CTE: validated (enumeration validation)
    ↓
dbt CTE: with_set_hashes (compute set hashes)
    ↓
dbt CTE: with_profile_hash (compute profile hash)
    ↓
dbt CTE: final (compute quality metrics)
    ↓
Silver Layer (silver.<entity>_standardized)
    ↓ (dbt)
Gold Layer (gold.dim_<entity>)
```

---

## Relationship to Contracts

**Contract Location**: `contracts/silver/<entity>_standardized.yaml`

**Contract MUST define**:
- All Bronze columns
- All computed columns (hashes, dq_*)
- Data types
- Validation rules

---

## Common Mistakes to Avoid

### ❌ Missing Hash Columns
```sql
-- WRONG: Missing profile_hash
SELECT * FROM bronze_table  -- No hash computation
```

### ❌ Wrong Hash Inclusion
```sql
-- WRONG: Including Type 1 attributes in hash
{{ compute_profile_hash([
    'first_name',
    'customer_occupation_other'  -- Type 1, should exclude
]) }}
```

### ❌ Not Using Macros
```sql
-- WRONG: Manual hash computation instead of macro
SHA256(CONCAT(first_name, last_name))  -- Use macro instead
```

### ❌ Missing Incremental Filter
```sql
-- WRONG: Full table scan every run
WITH source AS (
    SELECT * FROM {{ ref('bronze_table') }}
    -- Missing incremental filter
)
```

---

## Testing

Before committing:
1. ✅ Verify hash columns computed correctly
2. ✅ Check all enumerations validated
3. ✅ Confirm incremental logic works
4. ✅ Test quality score calculation
5. ✅ Validate contract alignment

---

## Related Documentation

- **Parent**: `/db/README.md`
- **Contracts**: `/contracts/silver/README.md`
- **Previous Layer**: `/db/bronze/README.md`
- **Next Layer**: `/db/gold/README.md`
- **Hashing Standards**: `docs/data-modeling/hashing_standards.md`
- **dbt Macros**: `dbt/macros/README.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Engineering Team

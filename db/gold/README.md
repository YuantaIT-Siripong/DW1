# Gold Layer DDL

**Purpose**: Dimensional model (star schema) for analytics - SCD Type 2 dimensions, bridge tables, fact tables  
**Layer**: Gold (Dimensional)  
**Schema**: `gold`  
**Last Updated**: 2026-01-05

---

## Overview

The Gold layer contains the **dimensional model** - a star schema optimized for analytics with SCD Type 2 slowly changing dimensions, bridge tables for multi-valued attributes, and fact tables for events/transactions.

---

## Gold Layer Principles

### 1. Dimensional Model (Star Schema)
- ✅ **Dimensions**: Master data with SCD Type 2 versioning
- ✅ **Bridge Tables**: Multi-valued attributes
- ✅ **Fact Tables**: Events, transactions, audit trails

### 2. Analytics-Optimized
- ✅ Surrogate keys for joins
- ✅ Denormalized for query performance
- ✅ Complete historical tracking
- ✅ Point-in-time reconstruction

### 3. SCD Type 2 Versioning
- ✅ Multiple versions per entity
- ✅ Temporal validity tracking
- ✅ Current record flagging
- ✅ Hash-based change detection

---

## DDL Files in This Directory

### Dimensions (SCD Type 2)

#### dim_customer_profile.sql
- **Entity**: Customer Profile
- **Type**: SCD Type 2 Dimension
- **Natural Key**: `customer_id`
- **Surrogate Key**: `customer_version_sk`
- **Attributes**: 31 versioned attributes
- **Contract**: `contracts/gold/dim_customer_profile.yaml`

### Bridge Tables

#### bridge_customer_income_source_version.sql
- **Purpose**: Customer income sources (multi-valued)
- **Links**: `customer_version_sk` → income sources
- **Contract**: `contracts/gold/bridge_customer_income_source_version.yaml`

#### bridge_customer_investment_purpose_version.sql
- **Purpose**: Customer investment purposes (multi-valued)
- **Links**: `customer_version_sk` → investment purposes
- **Contract**: `contracts/gold/bridge_customer_investment_purpose_version.yaml`

### Fact Tables

#### fact_customer_profile_audit.sql
- **Purpose**: Customer profile change audit trail
- **Grain**: One row per attribute change
- **Contract**: `contracts/gold/fact_customer_profile_audit.yaml`

---

## SCD Type 2 Dimension Template

```sql
-- Create schema
CREATE SCHEMA IF NOT EXISTS gold;

-- Drop table (development only)
DROP TABLE IF EXISTS gold.dim_<entity> CASCADE;

-- Create table
CREATE TABLE gold.dim_<entity> (
    -- Surrogate key (primary key)
    <entity>_version_sk BIGSERIAL PRIMARY KEY,
    
    -- Natural key
    <entity>_id BIGINT NOT NULL,
    
    -- SCD Type 2 temporal columns
    effective_start_ts TIMESTAMP NOT NULL,
    effective_end_ts TIMESTAMP NULL,  -- No DEFAULT
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    version_num INT NOT NULL,
    
    -- Business attributes (Type 2 - versioned)
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    marital_status VARCHAR(20),
    -- ... all Type 2 attributes ...
    
    -- Change detection
    profile_hash VARCHAR(64) NOT NULL,
    
    -- Audit metadata
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (effective_end_ts IS NULL OR effective_end_ts > effective_start_ts),
    CHECK (version_num > 0),
    CHECK (profile_hash ~ '^[a-f0-9]{64}$')
);

-- Mandatory indexes (6 required by SCD2 policy)
-- 1. Primary key (automatic)

-- 2. Unique on natural key + version
CREATE UNIQUE INDEX idx_gold_<entity>_nk_version 
    ON gold.dim_<entity>(<entity>_id, version_num);

-- 3. Unique on natural key where current
CREATE UNIQUE INDEX idx_gold_<entity>_nk_current 
    ON gold.dim_<entity>(<entity>_id) 
    WHERE is_current = TRUE;

-- 4. Non-unique on natural key + current flag
CREATE INDEX idx_gold_<entity>_nk_current_flag 
    ON gold.dim_<entity>(<entity>_id, is_current) 
    WHERE is_current = TRUE;

-- 5. Non-unique on natural key + temporal range
CREATE INDEX idx_gold_<entity>_nk_temporal 
    ON gold.dim_<entity>(<entity>_id, effective_start_ts, effective_end_ts);

-- 6. Non-unique on profile hash
CREATE INDEX idx_gold_<entity>_hash 
    ON gold.dim_<entity>(profile_hash);

-- Comments
COMMENT ON TABLE gold.dim_<entity> IS 
    'SCD Type 2 dimension for <entity>. Tracks full history with microsecond precision.';

COMMENT ON COLUMN gold.dim_<entity>.<entity>_version_sk IS 
    'Surrogate key. Unique identifier for each version of the entity.';

COMMENT ON COLUMN gold.dim_<entity>.effective_start_ts IS 
    'Start of validity period for this version. Inclusive.';

COMMENT ON COLUMN gold.dim_<entity>.effective_end_ts IS 
    'End of validity period for this version. Exclusive. NULL for current version.';

COMMENT ON COLUMN gold.dim_<entity>.is_current IS 
    'TRUE if this is the current (latest) version. Only one version can be current per entity.';

COMMENT ON COLUMN gold.dim_<entity>.version_num IS 
    'Sequential version number starting from 1 for each entity.';

COMMENT ON COLUMN gold.dim_<entity>.profile_hash IS 
    'SHA256 hash of all Type 2 attributes for change detection.';
```

---

## SCD Type 2 Requirements

### Mandatory Columns

**MUST have ALL of these**:

1. **Surrogate Key**: `<entity>_version_sk BIGSERIAL PRIMARY KEY`
2. **Natural Key**: `<entity>_id BIGINT NOT NULL`
3. **Temporal Columns**:
   - `effective_start_ts TIMESTAMP NOT NULL`
   - `effective_end_ts TIMESTAMP NULL` (NO DEFAULT)
   - `is_current BOOLEAN NOT NULL DEFAULT FALSE`
   - `version_num INT NOT NULL`
4. **Change Detection**: `profile_hash VARCHAR(64) NOT NULL`
5. **Audit**: `load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`

### Mandatory Indexes (6 Required)

Per `contracts/scd2/STANDARD_SCD2_POLICY.md`:

1. ✅ PRIMARY KEY on `<entity>_version_sk`
2. ✅ UNIQUE INDEX on `(<natural_key>, version_num)`
3. ✅ UNIQUE INDEX on `(<natural_key>) WHERE is_current = TRUE`
4. ✅ INDEX on `(<natural_key>, is_current) WHERE is_current = TRUE`
5. ✅ INDEX on `(<natural_key>, effective_start_ts, effective_end_ts)`
6. ✅ INDEX on `(profile_hash)`

### Mandatory Constraints

```sql
CHECK (effective_end_ts IS NULL OR effective_end_ts > effective_start_ts)
CHECK (version_num > 0)
CHECK (profile_hash ~ '^[a-f0-9]{64}$')
```

---

## Bridge Table Template

```sql
CREATE TABLE gold.bridge_<entity>_<attribute>_version (
    -- Foreign key to dimension
    <entity>_version_sk BIGINT NOT NULL,
    
    -- Multi-valued attribute
    <attribute> VARCHAR(50) NOT NULL,
    
    -- Optional: Sequence if order matters
    <attribute>_seq INT,
    
    -- Primary key
    PRIMARY KEY (<entity>_version_sk, <attribute>),
    
    -- Foreign key constraint (optional)
    FOREIGN KEY (<entity>_version_sk) 
        REFERENCES gold.dim_<entity>(<entity>_version_sk)
);

-- Index on FK
CREATE INDEX idx_bridge_<entity>_<attribute>_fk 
    ON gold.bridge_<entity>_<attribute>_version(<entity>_version_sk);

-- Comments
COMMENT ON TABLE gold.bridge_<entity>_<attribute>_version IS 
    'Bridge table linking <entity> versions to their <attribute> values.';
```

---

## Fact Table Template

```sql
CREATE TABLE gold.fact_<entity>_<event> (
    -- Fact primary key
    <event>_sk BIGSERIAL PRIMARY KEY,
    
    -- Foreign keys to dimensions
    <entity>_version_sk BIGINT NOT NULL,
    
    -- Degenerate dimensions (if any)
    <event>_id VARCHAR(100),
    
    -- Measures
    <measure1> NUMERIC(18,2),
    <measure2> INT,
    
    -- Event timestamp
    <event>_ts TIMESTAMP NOT NULL,
    
    -- Audit
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    FOREIGN KEY (<entity>_version_sk) 
        REFERENCES gold.dim_<entity>(<entity>_version_sk)
);

-- Indexes
CREATE INDEX idx_fact_<entity>_<event>_dim_fk 
    ON gold.fact_<entity>_<event>(<entity>_version_sk);

CREATE INDEX idx_fact_<entity>_<event>_ts 
    ON gold.fact_<entity>_<event>(<event>_ts);
```

---

## dbt Model Generation

### Dimension (SCD Type 2)

```sql
{{ config(
    materialized='table',
    schema='gold'
) }}

WITH silver_all_versions AS (
    SELECT * FROM {{ ref('silver_<entity>_standardized') }}
),

with_effective_dates AS (
    SELECT 
        *,
        -- Effective start = source timestamp
        last_modified_ts AS effective_start_ts,
        
        -- Effective end = next version's start - 1 microsecond
        LEAD(last_modified_ts) OVER (
            PARTITION BY <entity>_id 
            ORDER BY last_modified_ts
        ) - INTERVAL '1 microsecond' AS effective_end_ts,
        
        -- Is current = latest version
        CASE 
            WHEN ROW_NUMBER() OVER (
                PARTITION BY <entity>_id 
                ORDER BY last_modified_ts DESC
            ) = 1 THEN TRUE 
            ELSE FALSE 
        END AS is_current,
        
        -- Version number
        ROW_NUMBER() OVER (
            PARTITION BY <entity>_id 
            ORDER BY last_modified_ts
        ) AS version_num
    FROM silver_all_versions
),

final AS (
    SELECT 
        -- Surrogate key will be generated by BIGSERIAL
        <entity>_id,
        effective_start_ts,
        effective_end_ts,
        is_current,
        version_num,
        
        -- Business attributes
        first_name,
        last_name,
        marital_status,
        
        -- Change detection
        profile_hash,
        
        -- Audit
        CURRENT_TIMESTAMP AS load_ts
    FROM with_effective_dates
)

SELECT * FROM final
```

---

## Closure Rule

**CRITICAL**: Use microsecond precision for closure

**Correct**:
```sql
LEAD(effective_start_ts) OVER (...) - INTERVAL '1 microsecond'
```

**Current Version**: `effective_end_ts = NULL` (NOT '9999-12-31')

---

## Data Flow

```
Silver Layer (silver.<entity>_standardized)
    ↓ (dbt)
dbt CTE: silver_all_versions (source)
    ↓
dbt CTE: with_effective_dates (calculate SCD2 columns)
    ↓
dbt CTE: final (select columns)
    ↓
Gold Dimension (gold.dim_<entity>)
```

---

## Relationship to Contracts

**Contract Location**: `contracts/gold/dim_<entity>.yaml`

**Contract MUST include**:
- All SCD2 columns
- All business attributes (Type 2 only, no *_other)
- All 6 required indexes
- ADR reference to `contracts/scd2/STANDARD_SCD2_POLICY.md`

---

## Common Mistakes to Avoid

### ❌ Wrong Schema Name
```sql
CREATE TABLE curated.dim_customer_profile (...);  -- WRONG
```
✅ **Correct**: `gold.dim_customer_profile`

### ❌ Wrong Temporal Column Default
```sql
effective_end_ts TIMESTAMP DEFAULT '9999-12-31'  -- WRONG
```
✅ **Correct**: `effective_end_ts TIMESTAMP NULL`

### ❌ Wrong Surrogate Key Suffix
```sql
customer_sk BIGSERIAL PRIMARY KEY  -- WRONG
```
✅ **Correct**: `customer_version_sk BIGSERIAL PRIMARY KEY`

### ❌ Missing Indexes
```sql
-- Creating only primary key, missing other 5 required indexes
```

### ❌ Including Type 1 Attributes in Dimensions
```sql
-- WRONG: *_other fields should not be in dimensional table
customer_occupation_other VARCHAR(200)  -- Type 1, exclude
```

---

## Testing DDL

Before committing:
1. ✅ Verify all 6 indexes created
2. ✅ Check temporal columns (no DEFAULT on effective_end_ts)
3. ✅ Validate surrogate key suffix (_version_sk)
4. ✅ Confirm schema is 'gold' not 'curated'
5. ✅ Test SCD2 logic with sample data
6. ✅ Validate contract alignment

---

## Related Documentation

- **Parent**: `/db/README.md`
- **Contracts**: `/contracts/gold/README.md`
- **Previous Layer**: `/db/silver/README.md`
- **SCD2 Policy**: `contracts/scd2/STANDARD_SCD2_POLICY.md`
- **Architectural Constraints**: `docs/architecture/ARCHITECTURAL_CONSTRAINTS.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team

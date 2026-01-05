# Bronze Layer DDL

**Purpose**: Raw landing zone DDL - Exact source mirror with ETL metadata  
**Layer**: Bronze (Raw)  
**Schema**: `bronze`  
**Last Updated**: 2026-01-05

---

## Overview

The Bronze layer is the **raw landing zone** for data from source systems. Tables in this layer are **immutable** and **append-only**, serving as a historical archive of all source data.

---

## Bronze Layer Principles

### 1. Exact Source Mirror
- ✅ ALL source columns included (no column drops)
- ✅ NO transformations (preserve raw values)
- ✅ NO cleansing (even invalid data lands here)
- ✅ Data types match source system

### 2. Immutable Append-Only
- ✅ Records NEVER updated or deleted
- ✅ Historical versions preserved
- ✅ Source system changes tracked via temporal column

### 3. ETL Metadata Required
ALL Bronze tables MUST include:
```sql
_bronze_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
_bronze_source_file VARCHAR(255)
_bronze_batch_id VARCHAR(100)
```

---

## DDL Files in This Directory

### customer_profile_standardized.sql
- **Entity**: Customer Profile
- **Source**: MSSQL IT view `vw_customer_profile_standardized`
- **Natural Key**: `customer_id`
- **Temporal Key**: `last_modified_ts`
- **Attributes**: 31 customer attributes + ETL metadata
- **Contract**: `contracts/bronze/customer_profile_standardized.yaml`

---

## Bronze DDL Template

```sql
-- Create schema
CREATE SCHEMA IF NOT EXISTS bronze;

-- Drop table (development only)
DROP TABLE IF EXISTS bronze.<entity>_standardized CASCADE;

-- Create table
CREATE TABLE bronze.<entity>_standardized (
    -- Natural key
    <entity>_id BIGINT NOT NULL,
    
    -- Temporal key (from source)
    last_modified_ts TIMESTAMP NOT NULL,
    
    -- Business attributes (from source)
    attribute1 VARCHAR(100),
    attribute2 BIGINT,
    
    -- ETL metadata (REQUIRED)
    _bronze_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _bronze_source_file VARCHAR(255),
    _bronze_batch_id VARCHAR(100),
    
    -- Primary key
    PRIMARY KEY (<entity>_id, last_modified_ts)
);

-- Indexes (REQUIRED)
CREATE INDEX idx_bronze_<entity>_load_ts 
    ON bronze.<entity>_standardized(_bronze_load_ts);

CREATE INDEX idx_bronze_<entity>_batch_id 
    ON bronze.<entity>_standardized(_bronze_batch_id);

-- Comments
COMMENT ON TABLE bronze.<entity>_standardized IS 
    'Raw <entity> data from IT operational database. Immutable append-only landing zone.';
```

---

## Required Indexes

**Mandatory indexes for ALL Bronze tables**:

1. **Primary Key** (automatic)
2. **Load Timestamp**: `_bronze_load_ts` (for incremental processing)
3. **Batch ID**: `_bronze_batch_id` (for batch tracking)

---

## Naming Convention

**Table Name Pattern**: `<domain>_<entity>_standardized`

Examples:
- ✅ `customer_profile_standardized`
- ✅ `investment_profile_standardized`
- ✅ `company_profile_standardized`

**Why "standardized"?**: Indicates IT has standardized/cleaned the source view before we extract it.

---

## Primary Key Pattern

**Pattern**: Composite key of natural key + temporal column

```sql
PRIMARY KEY (customer_id, last_modified_ts)
```

**Why composite?**: Allows multiple versions of same entity in Bronze for full historical tracking.

---

## Data Flow

```
Source System (MSSQL)
    ↓
IT Standardized View (vw_<entity>_standardized)
    ↓
Python ETL Script (etl/bronze_extract_*.py)
    ↓
Bronze Layer (bronze.<entity>_standardized)
    ↓ (dbt incremental)
Silver Layer (silver.<entity>_standardized)
```

---

## ETL Process

### Ingestion Method
- **Tool**: Python ETL scripts (`/etl/bronze_extract_*.py`)
- **Strategy**: Incremental (watermark-based on `last_modified_ts`)
- **Batch Size**: 1000 rows per batch
- **Frequency**: Scheduled (e.g., daily, hourly)

### Incremental Logic
```sql
-- Python ETL selects records where:
last_modified_ts > (SELECT MAX(last_modified_ts) FROM bronze.<entity>_standardized)
```

---

## Relationship to Contracts

**Contract Location**: `contracts/bronze/<entity>_standardized.yaml`

**DDL MUST match contract**:
- Column names (exact match)
- Data types (exact match)
- Nullability (exact match)
- Primary key (exact match)
- Indexes (exact match)

---

## Common Mistakes to Avoid

### ❌ Transforming Data
```sql
-- WRONG: Don't transform in Bronze
UPPER(TRIM(first_name)) AS first_name
```
✅ **Correct**: Preserve raw value, transform in Silver

### ❌ Missing ETL Metadata
```sql
-- WRONG: Missing _bronze_* columns
CREATE TABLE bronze.customer_profile_standardized (
    customer_id BIGINT
);
```

### ❌ Updating Records
```sql
-- WRONG: Bronze is append-only
UPDATE bronze.customer_profile_standardized SET ...;
```

### ❌ Wrong Schema
```sql
-- WRONG: Schema must be 'bronze'
CREATE TABLE raw.customer_profile_standardized (...);
```

---

## Testing DDL

Before committing:
1. ✅ Verify contract alignment
2. ✅ Check ETL metadata columns present
3. ✅ Confirm all required indexes
4. ✅ Validate immutable pattern (no UPDATE/DELETE triggers)
5. ✅ Test incremental load

---

## Related Documentation

- **Parent**: `/db/README.md`
- **Contracts**: `/contracts/bronze/README.md`
- **ETL Scripts**: `/etl/README.md`
- **Next Layer**: `/db/silver/README.md`
- **Standards**: `docs/architecture/ARCHITECTURAL_CONSTRAINTS.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Engineering Team

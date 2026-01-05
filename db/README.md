# Database DDL Directory

**Purpose**: PostgreSQL Data Definition Language (DDL) scripts for all layers  
**Owner**: Data Architecture Team  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains all DDL (Data Definition Language) scripts that define the physical database structure for the DW1 data warehouse. These scripts create schemas, tables, indexes, constraints, and comments.

---

## Directory Structure

```
db/
├── bronze/          # Raw landing zone DDL
├── silver/          # Cleaned & validated layer DDL
├── gold/            # Dimensional model DDL (star schema)
├── quarantine/      # Data quality quarantine DDL
├── source_system/   # Source system view samples/DDL
└── deprecated/      # Legacy DDL (pre-medallion architecture)
```

---

## DDL Execution Order

**IMPORTANT**: DDL scripts must be executed in this order:

1. **Schemas First** (if separate schema creation files exist)
2. **Bronze Layer** - Raw landing tables
3. **Silver Layer** - Cleaned data tables
4. **Gold Layer** - Dimensional model
5. **Quarantine Layer** - Rejection tables

Within each layer:
1. Dimensions before fact tables
2. Parent tables before child tables (if FKs exist)
3. Bridge tables after dimensions

---

## Relationship to Contracts

**Critical Rule**: Every DDL file MUST have a corresponding contract file.

| DDL Location | Contract Location | Purpose |
|--------------|-------------------|---------|
| `db/bronze/*.sql` | `contracts/bronze/*.yaml` | Bronze layer tables |
| `db/silver/*.sql` | `contracts/silver/*.yaml` | Silver layer tables |
| `db/gold/*.sql` | `contracts/gold/*.yaml` | Gold layer dimensions/facts |
| `db/quarantine/*.sql` | `contracts/quarantine/*.yaml` | Quarantine tables |

**Validation**: Use contract as source of truth. DDL must match:
- Column names (exact match)
- Data types (exact match)
- Nullability (exact match)
- Comments (should align)

---

## DDL Standards

### File Naming Convention

**Pattern**: `<entity>_<layer_qualifier>.sql`

**Examples**:
- ✅ `customer_profile_standardized.sql` (Bronze/Silver)
- ✅ `dim_customer_profile.sql` (Gold dimension)
- ✅ `bridge_customer_income_source_version.sql` (Gold bridge)
- ✅ `fact_customer_profile_audit.sql` (Gold fact)
- ❌ `customerProfile.sql` (wrong case)
- ❌ `customer.sql` (not descriptive)

### Schema Creation Pattern

All DDL files MUST include schema creation:

```sql
-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS bronze;

-- Set search path
SET search_path TO bronze;
```

### Table Creation Pattern

```sql
-- Drop table if exists (development only - remove for production)
DROP TABLE IF EXISTS bronze.customer_profile_standardized CASCADE;

-- Create table
CREATE TABLE bronze.customer_profile_standardized (
    -- Natural key
    customer_id BIGINT NOT NULL,
    
    -- Business attributes
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    
    -- ETL metadata (Bronze layer)
    _bronze_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _bronze_source_file VARCHAR(255),
    _bronze_batch_id VARCHAR(100),
    
    -- Primary key
    PRIMARY KEY (customer_id, last_modified_ts)
);
```

### Index Creation Pattern

**MUST create indexes immediately after table**:

```sql
-- Indexes
CREATE INDEX idx_bronze_customer_load_ts 
    ON bronze.customer_profile_standardized(_bronze_load_ts);

CREATE INDEX idx_bronze_customer_batch_id 
    ON bronze.customer_profile_standardized(_bronze_batch_id);
```

### Comment Pattern

**MUST add comments for all tables and columns**:

```sql
-- Table comment
COMMENT ON TABLE bronze.customer_profile_standardized IS 
    'Raw customer profile data from IT operational database. Immutable append-only landing zone.';

-- Column comments
COMMENT ON COLUMN bronze.customer_profile_standardized.customer_id IS 
    'Unique customer identifier from source system';

COMMENT ON COLUMN bronze.customer_profile_standardized._bronze_load_ts IS 
    'Timestamp when record was loaded into Bronze layer';
```

---

## Layer-Specific Rules

### Bronze Layer (`/db/bronze/`)

**Purpose**: Raw landing zone (exact source mirror + metadata)

**Requirements**:
- ✅ Immutable (append-only)
- ✅ Include ALL source columns
- ✅ Include ETL metadata: `_bronze_load_ts`, `_bronze_source_file`, `_bronze_batch_id`
- ✅ Primary key = natural key + temporal column
- ✅ No transformations (raw data)

**Prohibited**:
- ❌ Computed columns
- ❌ Foreign keys
- ❌ Business logic
- ❌ Data cleansing

### Silver Layer (`/db/silver/`)

**Purpose**: Cleaned & validated data with computed columns

**Requirements**:
- ✅ All Bronze columns
- ✅ Computed hash columns: `profile_hash`, `<set>_set_hash`
- ✅ Data quality flags: `dq_*` columns
- ✅ Data quality score: `dq_score`, `dq_status`
- ✅ Include `_silver_load_ts` metadata

**Note**: Silver DDL files may be minimal or absent if dbt handles materialization.

### Gold Layer (`/db/gold/`)

**Purpose**: Dimensional model (star schema) for analytics

**Requirements**:
- ✅ SCD Type 2 dimensions with:
  - `<entity>_version_sk BIGSERIAL PRIMARY KEY`
  - `effective_start_ts TIMESTAMP NOT NULL`
  - `effective_end_ts TIMESTAMP NULL` (no DEFAULT)
  - `is_current BOOLEAN NOT NULL DEFAULT FALSE`
  - `version_num INT NOT NULL`
  - `profile_hash VARCHAR(64) NOT NULL`
- ✅ Bridge tables for multi-valued sets
- ✅ Fact tables for events/transactions
- ✅ ALL 6 required indexes (see SCD2 policy)

**Prohibited**:
- ❌ Schema name 'curated' (use 'gold')
- ❌ effective_end_ts DEFAULT '9999-12-31' (use NULL)
- ❌ Column suffix '_sk' instead of '_version_sk' for SCD2

### Quarantine Layer (`/db/quarantine/`)

**Purpose**: Data quality failures and rejected records

**Requirements**:
- ✅ All original columns
- ✅ Rejection metadata: `rejection_reason`, `rejected_at`, `rejected_by_rule`
- ✅ Original source reference

---

## Index Requirements by Layer

### Bronze Layer Indexes

**Mandatory**:
1. Primary key (automatic)
2. `_bronze_load_ts` (for incremental processing)
3. `_bronze_batch_id` (for batch tracking)

### Silver Layer Indexes

**Mandatory**:
1. Primary key (automatic)
2. `profile_hash` (for change detection)
3. Natural key (for lookups)

### Gold Layer Indexes (SCD2 Dimensions)

**Mandatory** (6 indexes per STANDARD_SCD2_POLICY.md):
1. `PRIMARY KEY` on `<entity>_version_sk`
2. `UNIQUE INDEX` on `(<natural_key>, version_num)`
3. `UNIQUE INDEX` on `(<natural_key>) WHERE is_current = TRUE`
4. `INDEX` on `(<natural_key>, is_current) WHERE is_current = TRUE`
5. `INDEX` on `(<natural_key>, effective_start_ts, effective_end_ts)`
6. `INDEX` on `(profile_hash)`

---

## Maintenance

### When to Update DDL

Update DDL when:
- ✅ Adding new columns (update contract first)
- ✅ Changing data types (update contract first)
- ✅ Adding/removing indexes
- ✅ Modifying constraints

**Process**:
1. Update contract YAML file
2. Update DDL file
3. Validate contract-DDL alignment
4. Test in development
5. Document change in ADR (if architectural)
6. Update REPOSITORY_FILE_INDEX.md

### Version Control

**IMPORTANT**: DDL files are version-controlled but database changes require migration scripts.

For schema changes:
1. Create migration script: `migrations/YYYYMMDD_description.sql`
2. Document breaking changes
3. Plan downtime if required
4. Test rollback procedure

---

## Testing DDL

Before committing DDL:

1. **Syntax Check**: Run `psql --dry-run` or equivalent
2. **Contract Validation**: Compare against YAML contract
3. **Index Coverage**: Verify all required indexes exist
4. **Comment Coverage**: Ensure all tables/columns commented
5. **Naming Convention**: Validate snake_case, correct suffixes
6. **Idempotency**: Script should be runnable multiple times

---

## Common Mistakes to Avoid

### ❌ Wrong Schema Name
```sql
CREATE TABLE curated.dim_customer_profile (...);  -- WRONG
```
✅ **Correct**:
```sql
CREATE TABLE gold.dim_customer_profile (...);  -- CORRECT
```

### ❌ Missing ETL Metadata
```sql
CREATE TABLE bronze.customer_profile_standardized (
    customer_id BIGINT
    -- Missing _bronze_load_ts, _bronze_source_file, _bronze_batch_id
);
```

### ❌ Wrong Temporal Column Default
```sql
effective_end_ts TIMESTAMP DEFAULT '9999-12-31'  -- WRONG
```
✅ **Correct**:
```sql
effective_end_ts TIMESTAMP NULL  -- CORRECT (no DEFAULT)
```

### ❌ Missing Indexes
```sql
-- Only creating primary key, forgetting other 5 mandatory indexes
```

### ❌ DDL Doesn't Match Contract
```sql
-- Contract says: first_name VARCHAR(100)
-- DDL says: first_name VARCHAR(50)  -- MISMATCH
```

---

## Related Documentation

- **Contracts**: `/contracts/README.md`
- **SCD2 Policy**: `contracts/scd2/STANDARD_SCD2_POLICY.md`
- **Naming Conventions**: `docs/data-modeling/naming_conventions.md`
- **File Index**: `REPOSITORY_FILE_INDEX.md`
- **Architectural Constraints**: `docs/architecture/ARCHITECTURAL_CONSTRAINTS.md`

---

## Subdirectories

- [Bronze Layer DDL](bronze/README.md) - Raw landing zone
- [Silver Layer DDL](silver/README.md) - Cleaned & validated
- [Gold Layer DDL](gold/README.md) - Dimensional model
- [Quarantine Layer DDL](quarantine/README.md) - Data quality failures
- [Source System Samples](source_system/README.md) - IT view examples

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team  
**Contact**: Data Architecture Team for DDL changes or questions

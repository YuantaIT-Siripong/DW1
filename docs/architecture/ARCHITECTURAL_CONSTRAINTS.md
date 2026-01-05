# Architectural Constraints and Rules

**Purpose**: Explicit documentation of all architectural rules, constraints, and "must not" boundaries  
**Audience**: AI agents, architects, developers  
**Status**: Authoritative - All implementations MUST comply  
**Last Updated**: 2026-01-05

---

## Table of Contents

1. [System Boundaries](#system-boundaries)
2. [Module Definition and Boundaries](#module-definition-and-boundaries)
3. [Domain Ownership Rules](#domain-ownership-rules)
4. [Schema Naming Rules](#schema-naming-rules)
5. [Data Type Standards](#data-type-standards)
6. [Layer Architecture Constraints](#layer-architecture-constraints)
7. [SCD Type Selection Rules](#scd-type-selection-rules)
8. [Enumeration Management Rules](#enumeration-management-rules)
9. [Naming Convention Enforcement](#naming-convention-enforcement)
10. [Hash Computation Rules](#hash-computation-rules)
11. [Temporal Field Standards](#temporal-field-standards)
12. [Key Management Rules](#key-management-rules)
13. [dbt Materialization Patterns](#dbt-materialization-patterns)
14. [ETL Metadata Requirements](#etl-metadata-requirements)
15. [Inter-Module Dependency Rules](#inter-module-dependency-rules)
16. [File Creation Order](#file-creation-order)
17. [Prohibited Patterns](#prohibited-patterns)
18. [Validation Requirements](#validation-requirements)

---

## System Boundaries

### What This System IS

This is a **Data Warehouse (DW)** for:
- Historical data storage with full temporal tracking
- Analytical queries and reporting
- Regulatory compliance and audit trails
- Point-in-time historical reconstructions

### What This System IS NOT

This is **NOT**:
- ❌ An operational transaction system (OLTP)
- ❌ A real-time streaming platform
- ❌ A master data management (MDM) system
- ❌ A data lake for unstructured data
- ❌ A machine learning feature store

### Technology Scope

**Approved Technologies**:
- ✅ PostgreSQL (database)
- ✅ Python (Bronze ETL)
- ✅ dbt (Silver/Gold transformations)
- ✅ YAML (contracts and enumerations)
- ✅ Markdown (documentation)

**Prohibited Technologies** (without ADR):
- ❌ NoSQL databases
- ❌ Alternative transformation tools (Spark, Airflow DAGs for transformation)
- ❌ Different database platforms (MySQL, Oracle, etc.)
- ❌ JSON for contracts (use YAML)

---

## Module Definition and Boundaries

### What Constitutes a "Module"

A **module** is a cohesive set of artifacts representing a **business domain entity** with:
1. One primary dimension table (SCD0, SCD1, or SCD2)
2. Zero or more bridge tables (for multi-valued sets)
3. Zero or more fact tables (for events/transactions)
4. Complete documentation in `/docs/business/modules/`

### Module Granularity Rules

**✅ CORRECT Module Granularity**:
- Customer Profile (person demographics + economic attributes)
- Investment Profile (suitability, risk, KYC)
- Company Profile (organization demographics)
- Account (financial account)
- Transaction (financial transaction)

**❌ INCORRECT Module Granularity** (too fine-grained):
- Customer Name (part of Customer Profile)
- Customer Address (part of Customer Profile)
- Investment Risk Level (part of Investment Profile)

**❌ INCORRECT Module Granularity** (too coarse-grained):
- "All Customer Data" (mixing profile, accounts, transactions)
- "Complete Financial Picture" (mixing multiple domains)

### Module Independence Rule

**RULE**: Modules MUST be independently deployable and versioned.

**Implications**:
- Each module has its own set of contracts
- Each module has its own set of enumerations (domain-prefixed)
- Module versioning is independent (Customer v2 can coexist with Investment v1)

### Module Naming Convention

**Pattern**: `{domain}_module`

**Examples**:
- ✅ customer_module.md
- ✅ investment_profile_module.md
- ✅ company_module.md
- ❌ customers.md (missing _module suffix)
- ❌ customerProfile_module.md (wrong case)

---

## Domain Ownership Rules

### Domain Definitions

**Domains** are logical groupings of related modules.

**Current Domains**:
1. **customer** - Individual person data (profiles, demographics)
2. **investment** - Investment-related data (profiles, transactions, holdings)
3. **company** - Organization data (profiles, relationships)
4. **account** - Financial account data
5. **product** - Product and service definitions
6. **transaction** - Financial transaction events

### Domain Assignment Rules

**RULE 1**: Every module MUST belong to exactly one domain.

**RULE 2**: Domain is determined by **primary entity ownership**.

**Examples**:
- Customer Profile → `customer` domain (owns person identity)
- Investment Profile → `investment` domain (owns suitability assessment)
- Company Profile → `company` domain (owns organization identity)
- Customer-Investment Bridge → `investment` domain (investment owns the relationship)

**RULE 3**: Domain prefix MUST appear in all related artifacts:

```
customer domain:
  - enumerations/customer_*.yaml
  - contracts/bronze/customer_*.yaml
  - db/bronze/customer_*.sql
  - dbt/models/silver/customer_*.sql
  - docs/business/modules/customer_module.md
```

### Cross-Domain References

**RULE**: Modules MAY reference other domains via foreign keys but MUST NOT duplicate owned data.

**✅ CORRECT**:
```sql
-- Investment Profile references Customer Profile
CREATE TABLE gold.dim_investment_profile (
    investment_profile_sk BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,  -- FK to customer domain
    ...
);
```

**❌ INCORRECT**:
```sql
-- Investment Profile duplicating customer name (owned by customer domain)
CREATE TABLE gold.dim_investment_profile (
    investment_profile_sk BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    customer_firstname VARCHAR(200),  -- ❌ Duplicate! Owned by customer domain
    ...
);
```

---

## Schema Naming Rules

### Schema Name Standards

**RULE**: Schema names MUST use Medallion Architecture naming:

| Layer | Schema Name | Description |
|-------|-------------|-------------|
| Bronze | `bronze` | Raw landing zone |
| Silver | `silver` | Cleaned and validated |
| Gold | `gold` | Dimensional model |
| Quarantine | `quarantine` | Rejected records |

### CRITICAL: Schema Naming Enforcement

**✅ CORRECT**:
```sql
CREATE TABLE gold.dim_customer_profile (...);
CREATE TABLE gold.fact_customer_profile_audit (...);
```

**❌ PROHIBITED**:
```sql
CREATE TABLE curated.dim_customer_profile (...);  -- ❌ 'curated' is DEPRECATED
CREATE TABLE dim.dim_customer_profile (...);      -- ❌ 'dim' is INCORRECT
CREATE TABLE dw.dim_customer_profile (...);       -- ❌ 'dw' is NOT standard
CREATE TABLE public.dim_customer_profile (...);   -- ❌ 'public' is INCORRECT
```

### Schema Name Change History

**Historical Context**: Early versions used `curated` schema. This was migrated to `gold` in 2025-12 to align with industry-standard Medallion Architecture.

**Migration Reference**: `docs/migrations/CURATED_TO_GOLD_MIGRATION.md`

**RULE**: All new development MUST use `gold` schema. No exceptions.

---

## Data Type Standards

### Natural Key Type Rules

**RULE**: All entity natural keys (IDs) MUST be `BIGINT`, NOT `STRING/VARCHAR`.

**Rationale**: 
- Performance (integer joins faster than string joins)
- Storage efficiency
- Index efficiency
- Consistency across modules

**✅ CORRECT**:
```sql
customer_id BIGINT NOT NULL
investment_profile_id BIGINT NOT NULL
company_id BIGINT NOT NULL
```

**❌ PROHIBITED**:
```sql
customer_id VARCHAR(50) NOT NULL     -- ❌ Wrong type
customer_id STRING NOT NULL          -- ❌ Wrong type
customer_id INTEGER NOT NULL         -- ❌ Too small (use BIGINT)
```

### Surrogate Key Type Rules

**RULE**: All surrogate keys MUST be `BIGINT` with suffix `_sk` or `_version_sk`.

**✅ CORRECT**:
```sql
customer_profile_version_sk BIGINT PRIMARY KEY  -- SCD2 dimension
product_sk BIGINT PRIMARY KEY                   -- Non-versioned dimension
audit_event_id BIGINT PRIMARY KEY               -- Fact table
```

**❌ PROHIBITED**:
```sql
customer_profile_id BIGINT PRIMARY KEY          -- ❌ Missing _sk suffix
customer_profile_key BIGINT PRIMARY KEY         -- ❌ Use _sk not _key
```

### Timestamp Type Rules

**RULE**: All temporal columns MUST use `TIMESTAMP` (UTC, microsecond precision), NOT `DATE` or `DATETIME`.

**Exceptions**: Birthdates and other calendar dates MAY use `DATE` type.

**✅ CORRECT**:
```sql
effective_start_ts TIMESTAMP NOT NULL
effective_end_ts TIMESTAMP NULL
load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
birthdate DATE NOT NULL
```

**❌ PROHIBITED**:
```sql
effective_start_date DATE NOT NULL              -- ❌ Use TIMESTAMP
effective_start DATETIME NOT NULL               -- ❌ Use TIMESTAMP
load_datetime DATETIME NOT NULL                 -- ❌ Use TIMESTAMP with _ts suffix
```

### Boolean Type Rules

**RULE**: All boolean flags MUST use `BOOLEAN` type with prefix `is_` or `has_`.

**✅ CORRECT**:
```sql
is_current BOOLEAN NOT NULL DEFAULT FALSE
has_pii BOOLEAN NOT NULL DEFAULT FALSE
```

**❌ PROHIBITED**:
```sql
current_flag CHAR(1) NOT NULL                   -- ❌ Use BOOLEAN not CHAR
is_current VARCHAR(10) NOT NULL                 -- ❌ Use BOOLEAN not VARCHAR
active BOOLEAN NOT NULL                         -- ❌ Missing is_ prefix
```

### Enumeration Type Rules

**RULE**: Enumeration fields MUST use `VARCHAR(length)` storing direct codes, NOT integer FKs.

**Rationale**: Eliminates need for lookup dimension joins, improves query simplicity.

**✅ CORRECT**:
```sql
marital_status VARCHAR(50) NOT NULL             -- Direct code: "MARRIED"
person_title VARCHAR(50) NULL                   -- Direct code: "MR"
```

**❌ PROHIBITED**:
```sql
marital_status_id INT NOT NULL                  -- ❌ No FK integers
marital_status ENUM('SINGLE', 'MARRIED') NOT NULL  -- ❌ No database ENUMs
```

### Hash Type Rules

**RULE**: All hash columns MUST be `VARCHAR(64)` for SHA256 lowercase hex.

**✅ CORRECT**:
```sql
profile_hash VARCHAR(64) NOT NULL
source_of_income_set_hash VARCHAR(64) NOT NULL
```

**❌ PROHIBITED**:
```sql
profile_hash CHAR(64) NOT NULL                  -- ❌ Use VARCHAR not CHAR
profile_hash VARCHAR(32) NOT NULL               -- ❌ Wrong length (MD5, not SHA256)
profile_hash BYTEA NOT NULL                     -- ❌ Use hex string, not binary
```

---

## Layer Architecture Constraints

### Bronze Layer Rules

**PURPOSE**: Raw landing zone - exact mirror of source + ETL metadata.

**CONSTRAINTS**:
1. ✅ MUST mirror source structure exactly (no transformations)
2. ✅ MUST be append-only (immutable)
3. ✅ MUST include ETL metadata columns
4. ✅ MUST use `bronze` schema
5. ❌ MUST NOT apply business logic
6. ❌ MUST NOT compute derived columns
7. ❌ MUST NOT implement star schema

**Required ETL Metadata Columns**:
```sql
_bronze_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
_bronze_source_file VARCHAR(500) NULL
_bronze_batch_id BIGINT NULL
```

### Silver Layer Rules

**PURPOSE**: Cleaned, validated, with computed columns. Still flat tables (not dimensional).

**CONSTRAINTS**:
1. ✅ MUST apply data quality validation
2. ✅ MUST compute profile_hash and set_hash columns
3. ✅ MUST add data quality flag columns (dq_*)
4. ✅ MUST use `silver` schema
5. ✅ MAY apply type conversions and normalization
6. ❌ MUST NOT implement SCD2 versioning (that's Gold)
7. ❌ MUST NOT create dimension/fact structure (that's Gold)
8. ❌ MUST NOT create bridge tables (that's Gold)

**Required Computed Columns** (if SCD2 in Gold):
```sql
profile_hash VARCHAR(64) NOT NULL
<set>_set_hash VARCHAR(64) NULL  -- For each multi-valued set
dq_* BOOLEAN NULL                -- Validation flags
dq_score NUMERIC(5,2) NULL
dq_status VARCHAR(20) NULL
_silver_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

### Gold Layer Rules

**PURPOSE**: Dimensional model (star schema) with SCD versioning.

**CONSTRAINTS**:
1. ✅ MUST implement star schema (dimensions, facts, bridges)
2. ✅ MUST implement SCD Type 2 versioning where specified
3. ✅ MUST use `gold` schema
4. ✅ MUST include surrogate keys
5. ✅ MUST follow SCD2 policy for temporal columns
6. ❌ MUST NOT include ETL metadata from Bronze/Silver
7. ❌ MUST NOT include data quality flags (from Silver)

**Required SCD2 Columns**:
```sql
<entity>_version_sk BIGINT PRIMARY KEY
effective_start_ts TIMESTAMP NOT NULL
effective_end_ts TIMESTAMP NULL
is_current BOOLEAN NOT NULL DEFAULT FALSE
version_num INT NOT NULL
profile_hash VARCHAR(64) NOT NULL
load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

---

## SCD Type Selection Rules

### SCD Type Decision Matrix

| Criteria | Type 0 | Type 1 | Type 2 | Type 3 |
|----------|--------|--------|--------|--------|
| **History needed?** | No | No | Yes | Partial |
| **Point-in-time queries?** | No | No | Yes | No |
| **Regulatory audit?** | No | Maybe | Yes | No |
| **Performance priority?** | High | High | Medium | Medium |
| **Storage concern?** | Yes | Yes | No | No |

### When to Use Each Type

**SCD Type 0 (Static)**:
- ✅ Reference data that never changes
- ✅ Lookup tables (e.g., country codes, static categories)
- ✅ Example: dim_country, dim_currency

**SCD Type 1 (Overwrite)**:
- ✅ Attributes where only current value matters
- ✅ Non-regulated attributes
- ✅ Freetext fields (e.g., `*_other` fields)
- ✅ Example: Customer email (if not audited), customer phone

**SCD Type 2 (Versioning)**:
- ✅ Attributes requiring full history
- ✅ Regulatory compliance requirements
- ✅ Point-in-time reconstruction needed
- ✅ Example: Customer profile demographics, Investment profile suitability

**SCD Type 3 (Previous Value)**:
- ⚠️ Rarely used in this warehouse
- ✅ Only when need "current + previous" (not full history)
- ✅ Example: Customer segment (current_segment, previous_segment)

### Customer Profile SCD Type Example

**Type 2 Attributes** (versioned):
- evidence_unique_key, firstname, lastname, person_title, marital_status, nationality, occupation, education_level, birthdate, etc.

**Type 1 Attributes** (not versioned):
- person_title_other, nationality_other, occupation_other, education_level_other

**Rationale**: Type 1 freetext fields prevent spurious versioning from typo corrections.

---

## Enumeration Management Rules

### Enumeration Definition Rules

**RULE 1**: Every enumeration field MUST have a corresponding YAML file in `/enumerations/`.

**RULE 2**: No inline enumeration definitions in SQL or contracts.

**RULE 3**: Enumeration YAML MUST follow this structure:
```yaml
enumeration_name: <name>
domain: <domain>
description: <description>
version: <version>
values:
  - code: <CODE>
    description: <description>
    sort_order: <integer>
    deprecated: false  # Optional
```

### Enumeration + Freetext Pattern

**RULE**: For enumerations with "OTHER" option, MUST provide corresponding `*_other` freetext field.

**Pattern**:
```sql
-- Enumeration field (Type 2, versioned)
person_title VARCHAR(50) NULL

-- Freetext field (Type 1, NOT versioned)
person_title_other VARCHAR(200) NULL
```

**Business Logic**:
- If person_title = "OTHER", then person_title_other MUST be populated
- If person_title ≠ "OTHER", then person_title_other SHOULD be NULL

**Hash Computation**:
- person_title → INCLUDED in profile_hash
- person_title_other → EXCLUDED from profile_hash

### Enumeration Naming Rules

**RULE**: Enumeration files MUST follow pattern: `{domain}_{attribute}.yaml`

**✅ CORRECT**:
```
enumerations/customer_marital_status.yaml
enumerations/customer_occupation.yaml
enumerations/investment_risk_level.yaml
```

**❌ PROHIBITED**:
```
enumerations/maritalStatus.yaml          -- ❌ Wrong case, missing domain
enumerations/customer-marital-status.yaml -- ❌ Use underscore not hyphen
enumerations/marital_status.yaml         -- ❌ Missing domain prefix
```

### Lookup Dimension Prohibition

**RULE**: Do NOT create separate lookup dimensions for enumerations.

**❌ PROHIBITED Pattern** (old approach):
```sql
-- DO NOT DO THIS
CREATE TABLE gold.dim_marital_status (
    marital_status_sk INT PRIMARY KEY,
    marital_status_code VARCHAR(50),
    marital_status_name VARCHAR(200)
);

CREATE TABLE gold.dim_customer_profile (
    customer_profile_version_sk BIGINT PRIMARY KEY,
    marital_status_sk INT REFERENCES gold.dim_marital_status  -- ❌ NO
);
```

**✅ CORRECT Pattern** (current approach):
```sql
-- Store codes directly
CREATE TABLE gold.dim_customer_profile (
    customer_profile_version_sk BIGINT PRIMARY KEY,
    marital_status VARCHAR(50) NOT NULL  -- ✅ Direct code: "MARRIED"
);
```

**Rationale**: 
- Eliminates unnecessary joins
- Simplifies queries
- Enumeration definitions in YAML are sufficient for documentation and validation

---

## Naming Convention Enforcement

### File and Folder Naming

**RULE**: All files and folders MUST use `snake_case`.

**✅ CORRECT**:
```
customer_profile_standardized.sql
dim_customer_profile.yaml
bridge_customer_source_of_income.sql
```

**❌ PROHIBITED**:
```
CustomerProfile.sql              -- ❌ PascalCase
customer-profile.sql             -- ❌ kebab-case
customerProfile.sql              -- ❌ camelCase
```

### Table Naming

**RULE**: Table names MUST use `snake_case` with type prefix:

| Table Type | Prefix | Example |
|------------|--------|---------|
| Dimension | `dim_` | `dim_customer_profile` |
| Fact | `fact_` | `fact_customer_profile_audit` |
| Bridge | `bridge_` | `bridge_customer_source_of_income` |
| Landing (Bronze) | none | `customer_profile_standardized` |

### Column Naming

**RULE**: Column names MUST use `snake_case`.

**Temporal Columns**:
- effective_start_ts, effective_end_ts (NOT effective_start_date)
- load_ts (NOT load_datetime)

**Boolean Columns**:
- is_current (NOT current_flag)
- has_pii (NOT pii_flag)

**Key Columns**:
- {entity}_version_sk (for SCD2 surrogate key)
- {entity}_sk (for non-versioned surrogate key)
- {entity}_id (for natural key)

### dbt Model Naming

**RULE**: dbt model files MUST match table names exactly.

**✅ CORRECT**:
```
dbt/models/gold/dim_customer_profile.sql  → gold.dim_customer_profile
dbt/models/silver/customer_profile_standardized.sql  → silver.customer_profile_standardized
```

---

## Hash Computation Rules

### Profile Hash Rules

**RULE 1**: profile_hash MUST be SHA256 of canonically ordered attributes.

**RULE 2**: Canonical order MUST be documented in module specification.

**RULE 3**: Hash normalization MUST follow these rules:
- English text: UPPER(TRIM())
- Local text: TRIM() only (preserve case)
- Enumerations: UPPER(TRIM())
- Dates: YYYY-MM-DD format
- NULLs: "__NULL__" token
- Delimiter: "|"

### What to INCLUDE in Hash

**✅ INCLUDE**:
- All Type 2 (versioned) attributes
- Multi-valued set hashes (e.g., source_of_income_set_hash)
- Natural keys (e.g., evidence_unique_key)

### What to EXCLUDE from Hash

**❌ EXCLUDE**:
- Surrogate keys (*_sk, *_version_sk)
- Temporal columns (effective_start_ts, effective_end_ts, is_current, version_num)
- Type 1 attributes (e.g., *_other freetext fields)
- ETL metadata (_bronze_*, _silver_*, load_ts)
- Data quality flags (dq_*)
- The profile_hash itself

### Set Hash Rules

**RULE**: Multi-valued sets MUST be hashed as sorted, pipe-delimited strings.

**Algorithm**:
1. Normalize each member: UPPER(TRIM())
2. Deduplicate
3. Sort ascending alphabetically
4. Join with "|" delimiter (empty set → "")
5. SHA256(joined_string) → set_hash

**Empty Set Hash**:
```
SHA256("") = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
```

---

## Temporal Field Standards

### SCD2 Temporal Columns

**Required Columns** for ALL SCD2 dimensions:

```sql
effective_start_ts TIMESTAMP NOT NULL
effective_end_ts TIMESTAMP NULL        -- NULL for current version
is_current BOOLEAN NOT NULL DEFAULT FALSE
version_num INT NOT NULL
```

### Temporal Column Rules

**RULE 1**: effective_start_ts MUST be NOT NULL.

**RULE 2**: effective_end_ts MUST be NULL for current version (is_current = TRUE).

**RULE 3**: effective_end_ts MUST NOT have DEFAULT value.

**RULE 4**: Exactly ONE row with is_current = TRUE per natural key.

**RULE 5**: Version closure MUST follow: `effective_end_ts = LEAD(effective_start_ts) - INTERVAL '1 microsecond'`

### Prohibited Patterns

**❌ DO NOT USE**:
```sql
effective_end_ts TIMESTAMP NOT NULL DEFAULT '9999-12-31'  -- ❌ Use NULL for current
effective_start_date DATE NOT NULL                        -- ❌ Use TIMESTAMP not DATE
current_flag CHAR(1) NOT NULL                             -- ❌ Use is_current BOOLEAN
```

---

## Key Management Rules

### Surrogate Key Generation

**RULE**: Surrogate keys MUST be auto-generated sequences (BIGSERIAL or IDENTITY).

**✅ CORRECT**:
```sql
customer_profile_version_sk BIGSERIAL PRIMARY KEY
-- Or: customer_profile_version_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

**❌ PROHIBITED**:
```sql
customer_profile_version_sk BIGINT PRIMARY KEY  -- ❌ Missing auto-generation
```

### Primary Key Constraints

**RULE**: Every table MUST have a PRIMARY KEY constraint.

**Examples**:
```sql
-- Dimension
PRIMARY KEY (customer_profile_version_sk)

-- Bridge
PRIMARY KEY (customer_profile_version_sk, source_of_income_code)

-- Fact
PRIMARY KEY (audit_event_id)
```

### Required Indexes for SCD2

**RULE**: ALL SCD2 dimensions MUST have these 6 indexes:

```sql
-- 1. Primary key (auto-created)
PRIMARY KEY (customer_profile_version_sk)

-- 2. Unique business key with version
CREATE UNIQUE INDEX idx_customer_profile_nk_version 
    ON gold.dim_customer_profile(customer_id, version_num);

-- 3. Unique current version
CREATE UNIQUE INDEX idx_customer_profile_current 
    ON gold.dim_customer_profile(customer_id) 
    WHERE is_current = TRUE;

-- 4. Current version query optimization
CREATE INDEX idx_customer_profile_nk_current 
    ON gold.dim_customer_profile(customer_id, is_current) 
    WHERE is_current = TRUE;

-- 5. Point-in-time query optimization
CREATE INDEX idx_customer_profile_temporal 
    ON gold.dim_customer_profile(customer_id, effective_start_ts, effective_end_ts);

-- 6. Change detection
CREATE INDEX idx_customer_profile_hash 
    ON gold.dim_customer_profile(profile_hash);
```

**Rationale**: These indexes support all common query patterns:
- Current version retrieval
- Historical point-in-time queries
- Change detection
- Version traversal

---

## dbt Materialization Patterns

### Layer-Specific Materialization

| Layer | Default Materialization | Rationale |
|-------|------------------------|-----------|
| Silver | `incremental` | Large data volume, efficient updates |
| Gold Dimensions | `table` | Full rebuild for SCD2 logic |
| Gold Facts | `incremental` | Append-only, large volume |
| Gold Bridges | `table` | Derived from dimensions, full rebuild |
| Quarantine | `incremental` | Append-only rejected records |

### Silver Incremental Pattern

**RULE**: Silver models MUST use incremental materialization with watermark:

```sql
{{ config(
    materialized='incremental',
    unique_key='<natural_key>',
    schema='silver'
) }}

SELECT ...
FROM {{ source('bronze', 'customer_profile_standardized') }}
{% if is_incremental() %}
WHERE _bronze_load_ts > (SELECT MAX(_silver_load_ts) FROM {{ this }})
{% endif %}
```

### Gold Dimension Pattern

**RULE**: SCD2 dimensions MUST use table materialization (full rebuild):

```sql
{{ config(
    materialized='table',
    schema='gold'
) }}

WITH silver_all_versions AS (...),
with_effective_dates AS (
    SELECT 
        *,
        source_last_modified_ts AS effective_start_ts,
        LEAD(source_last_modified_ts) OVER (PARTITION BY customer_id ORDER BY source_last_modified_ts) 
            - INTERVAL '1 microsecond' AS effective_end_ts,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY source_last_modified_ts DESC) = 1 AS is_current,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY source_last_modified_ts) AS version_num
    FROM silver_all_versions
)
SELECT * FROM with_effective_dates;
```

---

## ETL Metadata Requirements

### Bronze Layer ETL Metadata

**RULE**: ALL Bronze tables MUST include these 3 columns:

```sql
_bronze_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
_bronze_source_file VARCHAR(500) NULL
_bronze_batch_id BIGINT NULL
```

**Purpose**:
- _bronze_load_ts: When record was loaded into warehouse
- _bronze_source_file: Source file name (if file-based extraction)
- _bronze_batch_id: Batch identifier for grouping related records

### Silver Layer ETL Metadata

**RULE**: ALL Silver tables MUST include:

```sql
_silver_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

### Gold Layer Audit Metadata

**RULE**: ALL Gold tables MUST include:

```sql
load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

**Note**: Gold tables do NOT include _bronze_* or _silver_* metadata.

---

## Inter-Module Dependency Rules

### Dependency Direction

**RULE**: Modules MAY only reference modules they depend on, not the reverse.

**✅ ALLOWED**:
```
Investment Profile → Customer Profile  (investment depends on customer)
Account → Customer Profile             (account depends on customer)
Transaction → Account                  (transaction depends on account)
```

**❌ PROHIBITED**:
```
Customer Profile → Investment Profile  (circular dependency)
Customer Profile → Account             (backward dependency)
```

### Foreign Key Rules

**RULE 1**: Foreign keys SHOULD reference natural keys, not surrogate keys.

**✅ PREFERRED**:
```sql
CREATE TABLE gold.dim_investment_profile (
    investment_profile_sk BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL  -- FK to dim_customer_profile(customer_id)
);
```

**⚠️ AVOID** (unless versioned FK needed):
```sql
CREATE TABLE gold.dim_investment_profile (
    investment_profile_sk BIGINT PRIMARY KEY,
    customer_profile_version_sk BIGINT NOT NULL  -- FK to specific version
);
```

**Rationale**: Referencing natural key allows JOIN to any version; referencing version_sk locks to specific version.

### Circular Dependency Prohibition

**RULE**: Circular dependencies between modules are STRICTLY PROHIBITED.

If circular relationship exists in business domain, break cycle by:
1. Creating association/link table
2. Choosing primary ownership direction
3. Documenting decision in ADR

---

## File Creation Order

### Correct Order for Module Creation

**RULE**: Files MUST be created in this order to maintain referential integrity:

1. **Documentation** (`docs/business/modules/{module}_module.md`)
2. **Enumerations** (`enumerations/{domain}_*.yaml`)
3. **Contracts** in order:
   - Bronze contract
   - Silver contract
   - Gold contracts (dimension, then bridges, then facts)
4. **DDL** in order:
   - Bronze DDL
   - Silver DDL
   - Gold DDL (dimension, then bridges, then facts)
5. **dbt Models** in order:
   - Bronze sources
   - Silver models
   - Gold models (dimension, then bridges, then facts)

**Rationale**: Each layer depends on previous layer being defined.

### Parallel Creation Exception

**EXCEPTION**: Within same layer, files MAY be created in parallel (e.g., multiple enumerations).

---

## Prohibited Patterns

### Absolutely Prohibited

The following patterns are STRICTLY PROHIBITED without ADR approval:

1. ❌ **Using 'curated' schema** (use 'gold' schema)
2. ❌ **Creating lookup dimensions for enumerations** (use direct codes)
3. ❌ **Using STRING/VARCHAR for entity IDs** (use BIGINT)
4. ❌ **Using DEFAULT '9999-12-31' for effective_end_ts** (use NULL)
5. ❌ **Including *_other fields in hash** (Type 1 fields excluded)
6. ❌ **Creating new versions for *_other field changes** (Type 1 = no versioning)
7. ❌ **Storing case-normalized names in dimension** (preserve original case)
8. ❌ **Using different temporal column names** (must be effective_start_ts, effective_end_ts)
9. ❌ **Using CHAR for booleans** (use BOOLEAN type)
10. ❌ **Putting star schema in Silver layer** (star schema only in Gold)
11. ❌ **Hardcoding enumeration values in SQL** (use YAML files)
12. ❌ **Creating tables without PRIMARY KEY** (all tables need PK)
13. ❌ **SCD2 dimension without 6 required indexes** (see Key Management Rules)
14. ❌ **Circular module dependencies** (see Inter-Module Dependency Rules)

---

## Validation Requirements

### Pre-Commit Validation

**RULE**: Before committing, MUST validate:

1. ✅ File naming follows conventions
2. ✅ DDL matches contract exactly
3. ✅ dbt model outputs match contract
4. ✅ All enumerations have YAML files
5. ✅ SCD2 dimensions have all 6 indexes
6. ✅ All tables have PRIMARY KEY
7. ✅ No prohibited patterns present

### Validation Checklist

Use these checklists:
- `docs/MODULE_DEVELOPMENT_CHECKLIST.md` - Module development
- `docs/POLICY_ALIGNMENT_CHECKLIST.md` - Policy compliance
- `docs/_ai-first-employee-boarding-guide/040_ai_validates_against_standards.md` - Standards validation

---

## Enforcement

### How Constraints are Enforced

1. **Documentation** - This file is authoritative
2. **Code Review** - Manual review checks compliance
3. **Validation Scripts** - Automated checks (future)
4. **ADR Process** - Changes require ADR

### Requesting Exceptions

If you believe a constraint should be violated:

1. **DO NOT proceed** without approval
2. Create ADR documenting:
   - Why constraint needs to be violated
   - Alternative approaches considered
   - Risk analysis
   - Migration plan if constraint later reinstated
3. Get architectural approval
4. Update this document if exception becomes new standard

---

## Summary of Critical "Must Not" Rules

**Schema Naming**:
- ❌ MUST NOT use 'curated', 'dim', or 'dw' schemas

**Data Types**:
- ❌ MUST NOT use STRING/VARCHAR for entity IDs
- ❌ MUST NOT use DATE for temporal columns (except birthdates)
- ❌ MUST NOT use CHAR for booleans

**Enumerations**:
- ❌ MUST NOT create lookup dimensions
- ❌ MUST NOT hardcode enumeration values in SQL

**SCD2**:
- ❌ MUST NOT use '9999-12-31' for effective_end_ts
- ❌ MUST NOT omit any of the 6 required indexes

**Hash**:
- ❌ MUST NOT include *_other fields in hash
- ❌ MUST NOT include ETL metadata in hash
- ❌ MUST NOT include profile_hash itself in hash

**Layer Separation**:
- ❌ MUST NOT put star schema in Silver
- ❌ MUST NOT put business logic in Bronze

**Module Boundaries**:
- ❌ MUST NOT create circular dependencies
- ❌ MUST NOT duplicate data owned by another domain

---

**Document End**

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team  
**Status**: AUTHORITATIVE - Compliance Mandatory

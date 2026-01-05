# Module Replication Validation Guide

**Purpose**: Validation checklist to ensure new modules align with Customer Profile pattern  
**Audience**: AI agents, developers, architects  
**Reference Module**: Customer Profile  
**Last Updated**: 2026-01-05

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-Validation Checklist](#pre-validation-checklist)
3. [Architectural Alignment Validation](#architectural-alignment-validation)
4. [Naming Convention Alignment](#naming-convention-alignment)
5. [Data Type Alignment](#data-type-alignment)
6. [SCD2 Pattern Alignment](#scd2-pattern-alignment)
7. [Hash Computation Alignment](#hash-computation-alignment)
8. [Enumeration Pattern Alignment](#enumeration-pattern-alignment)
9. [Bridge Table Alignment](#bridge-table-alignment)
10. [dbt Model Alignment](#dbt-model-alignment)
11. [Documentation Alignment](#documentation-alignment)
12. [Final Go/No-Go Checklist](#final-gono-go-checklist)

---

## Overview

### Purpose of This Guide

This guide ensures that any new module created follows the **exact same patterns** as the Customer Profile module, maintaining consistency and architectural integrity across the repository.

### When to Use This Guide

Use this checklist:
- ✅ After generating all files for a new module
- ✅ Before committing files to repository
- ✅ During code review
- ✅ When uncertain if module aligns with standards

### Validation Approach

**Method**: Compare new module artifacts against Customer Profile reference artifacts point-by-point.

**Outcome**: Either:
- ✅ **GO** - Module fully aligns, safe to commit
- ❌ **NO-GO** - Module has misalignments, must fix before committing

---

## Pre-Validation Checklist

Before starting detailed validation, verify these prerequisites:

- [ ] Module specification document exists (`docs/business/modules/{module}_module.md`)
- [ ] All enumeration YAML files created (`enumerations/{domain}_*.yaml`)
- [ ] All contracts created (Bronze, Silver, Gold)
- [ ] All DDL created (Bronze, Silver, Gold)
- [ ] All dbt models created (Silver, Gold)
- [ ] Module Development Checklist completed (`docs/MODULE_DEVELOPMENT_CHECKLIST.md`)

**If any prerequisite is missing → STOP → Complete prerequisites first**

---

## Architectural Alignment Validation

### Layer Architecture

Compare your module's layer structure with Customer Profile:

| Aspect | Customer Profile Pattern | Your Module | ✅/❌ |
|--------|-------------------------|-------------|-------|
| **Bronze Layer** | Raw landing, exact source mirror | | |
| **Bronze Schema** | `bronze` | | |
| **Bronze Table Name** | `customer_profile_standardized` | | |
| **Bronze has ETL metadata** | Yes (_bronze_load_ts, _bronze_source_file, _bronze_batch_id) | | |
| **Silver Layer** | Cleaned + validated + hashes | | |
| **Silver Schema** | `silver` | | |
| **Silver Table Name** | `customer_profile_standardized` | | |
| **Silver has quality flags** | Yes (dq_* columns) | | |
| **Gold Layer** | Dimensional model with SCD2 | | |
| **Gold Schema** | `gold` (NOT curated) | | |
| **Gold Dimension Name** | `dim_customer_profile` | | |
| **Gold has bridge tables** | Yes (for multi-valued sets) | | |
| **Gold has audit fact** | Yes (fact_customer_profile_audit) | | |

### ❌ Common Misalignments to Check

- [ ] Using 'curated' schema instead of 'gold' → Fix: Use 'gold'
- [ ] Putting star schema in Silver → Fix: Star schema only in Gold
- [ ] Missing ETL metadata in Bronze → Fix: Add _bronze_* columns
- [ ] Missing quality flags in Silver → Fix: Add dq_* columns

---

## Naming Convention Alignment

### File Naming Alignment

| File Type | Customer Profile Pattern | Your Module | ✅/❌ |
|-----------|-------------------------|-------------|-------|
| **Module Spec** | `customer_module.md` | | |
| **Enumeration** | `customer_{attribute}.yaml` | | |
| **Bronze Contract** | `customer_profile_standardized.yaml` | | |
| **Silver Contract** | `customer_profile_standardized.yaml` | | |
| **Gold Dimension Contract** | `dim_customer_profile.yaml` | | |
| **Gold Bridge Contract** | `bridge_customer_{set}.yaml` | | |
| **Gold Fact Contract** | `fact_customer_profile_audit.yaml` | | |
| **Bronze DDL** | `customer_profile_standardized.sql` | | |
| **Gold Dimension DDL** | `dim_customer_profile.sql` | | |
| **Gold Bridge DDL** | `bridge_customer_{set}.sql` | | |
| **Silver dbt Model** | `customer_profile_standardized.sql` | | |
| **Gold Dimension dbt Model** | `dim_customer_profile.sql` | | |

**✅ Pattern**: All files use `snake_case`, domain prefix, consistent naming

### ❌ Common Misalignments to Check

- [ ] Using camelCase or PascalCase → Fix: Convert to snake_case
- [ ] Missing domain prefix → Fix: Add domain prefix
- [ ] Inconsistent naming across layers → Fix: Standardize base name

### Table and Column Naming Alignment

| Naming Rule | Customer Profile Example | Your Module | ✅/❌ |
|-------------|-------------------------|-------------|-------|
| **Dimension Prefix** | `dim_customer_profile` | | |
| **Fact Prefix** | `fact_customer_profile_audit` | | |
| **Bridge Prefix** | `bridge_customer_source_of_income` | | |
| **Surrogate Key Suffix** | `customer_profile_version_sk` | | |
| **Natural Key Name** | `customer_id` | | |
| **Temporal Column Names** | `effective_start_ts`, `effective_end_ts` | | |
| **Boolean Column Prefix** | `is_current` | | |
| **Version Column Name** | `version_num` | | |
| **Hash Column Name** | `profile_hash` | | |
| **Set Hash Column Name** | `source_of_income_set_hash` | | |

### ❌ Common Misalignments to Check

- [ ] Using `_id` suffix for surrogate key → Fix: Use `_version_sk` or `_sk`
- [ ] Using `_date` suffix for timestamps → Fix: Use `_ts`
- [ ] Using `current_flag` instead of `is_current` → Fix: Use `is_current`
- [ ] Using `_key` suffix → Fix: Use `_sk`

---

## Data Type Alignment

### Core Data Type Alignment

| Data Type Rule | Customer Profile Example | Your Module | ✅/❌ |
|----------------|-------------------------|-------------|-------|
| **Natural Key Type** | `customer_id BIGINT` | | |
| **Surrogate Key Type** | `customer_profile_version_sk BIGINT` | | |
| **Timestamp Type** | `effective_start_ts TIMESTAMP` | | |
| **Boolean Type** | `is_current BOOLEAN` | | |
| **Enumeration Type** | `marital_status VARCHAR(50)` | | |
| **Hash Type** | `profile_hash VARCHAR(64)` | | |
| **Text Type** | `firstname VARCHAR(200)` | | |
| **Freetext Other Type** | `person_title_other VARCHAR(200)` | | |

### ❌ Common Misalignments to Check

- [ ] Using STRING or VARCHAR for natural key → Fix: Use BIGINT
- [ ] Using INTEGER instead of BIGINT → Fix: Use BIGINT
- [ ] Using DATE for temporal columns → Fix: Use TIMESTAMP
- [ ] Using CHAR for boolean → Fix: Use BOOLEAN
- [ ] Using INT for enumeration FK → Fix: Use VARCHAR with direct codes
- [ ] Using CHAR(64) for hash → Fix: Use VARCHAR(64)

---

## SCD2 Pattern Alignment

### Required SCD2 Columns

Compare column structure:

| SCD2 Column | Customer Profile Definition | Your Module Definition | ✅/❌ |
|-------------|----------------------------|------------------------|-------|
| **Surrogate Key** | `customer_profile_version_sk BIGSERIAL PRIMARY KEY` | | |
| **Natural Key** | `customer_id BIGINT NOT NULL` | | |
| **Effective Start** | `effective_start_ts TIMESTAMP NOT NULL` | | |
| **Effective End** | `effective_end_ts TIMESTAMP NULL` | | |
| **Current Flag** | `is_current BOOLEAN NOT NULL DEFAULT FALSE` | | |
| **Version Number** | `version_num INT NOT NULL` | | |
| **Profile Hash** | `profile_hash VARCHAR(64) NOT NULL` | | |
| **Load Timestamp** | `load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP` | | |

### ❌ Common Misalignments to Check

- [ ] effective_end_ts has DEFAULT value → Fix: Remove DEFAULT, allow NULL
- [ ] Using '9999-12-31' pattern → Fix: Use NULL for current version
- [ ] Missing is_current column → Fix: Add is_current
- [ ] Missing version_num column → Fix: Add version_num
- [ ] Missing profile_hash column → Fix: Add profile_hash

### SCD2 Constraints Alignment

| Constraint Type | Customer Profile Example | Your Module | ✅/❌ |
|----------------|-------------------------|-------------|-------|
| **Primary Key** | `PRIMARY KEY (customer_profile_version_sk)` | | |
| **Check: End > Start** | `CHECK (effective_end_ts IS NULL OR effective_end_ts > effective_start_ts)` | | |
| **Check: Version > 0** | `CHECK (version_num > 0)` | | |
| **Check: Hash Format** | `CHECK (profile_hash ~ '^[a-f0-9]{64}$')` | | |

### Required SCD2 Indexes

Verify ALL 6 indexes exist:

| Index Purpose | Customer Profile Index | Your Module Index | ✅/❌ |
|---------------|----------------------|-------------------|-------|
| **1. Primary Key** | Auto-created on customer_profile_version_sk | | |
| **2. Business Key + Version** | `UNIQUE INDEX idx_customer_profile_nk_version ON (customer_id, version_num)` | | |
| **3. Current Version Unique** | `UNIQUE INDEX idx_customer_profile_current ON (customer_id) WHERE is_current = TRUE` | | |
| **4. Current Version Query** | `INDEX idx_customer_profile_nk_current ON (customer_id, is_current) WHERE is_current = TRUE` | | |
| **5. Point-in-Time Query** | `INDEX idx_customer_profile_temporal ON (customer_id, effective_start_ts, effective_end_ts)` | | |
| **6. Change Detection** | `INDEX idx_customer_profile_hash ON (profile_hash)` | | |

**CRITICAL**: All 6 indexes are REQUIRED. Missing any index = NO-GO.

### ❌ Common Misalignments to Check

- [ ] Missing any of the 6 required indexes → Fix: Add missing indexes
- [ ] Index names don't follow pattern → Fix: Rename to match pattern
- [ ] WHERE clause missing on current version indexes → Fix: Add WHERE is_current = TRUE

---

## Hash Computation Alignment

### Profile Hash Inclusion Rules

Compare what's included in profile_hash:

| Attribute Category | Customer Profile | Your Module | ✅/❌ |
|--------------------|------------------|-------------|-------|
| **Natural Key** | ✅ evidence_unique_key | | |
| **Names** | ✅ firstname, lastname, firstname_local, lastname_local | | |
| **Enumeration Fields** | ✅ person_title, marital_status, nationality, etc. | | |
| **Date Fields** | ✅ birthdate | | |
| **Band Fields** | ✅ total_asset, monthly_income | | |
| **Set Hashes** | ✅ source_of_income_set_hash, purpose_of_investment_set_hash | | |
| **Freetext _other** | ❌ person_title_other, nationality_other, etc. (EXCLUDED) | | |
| **Surrogate Keys** | ❌ customer_profile_version_sk (EXCLUDED) | | |
| **Temporal Columns** | ❌ effective_start_ts, effective_end_ts, is_current, version_num (EXCLUDED) | | |
| **ETL Metadata** | ❌ _bronze_*, _silver_*, load_ts (EXCLUDED) | | |
| **Quality Flags** | ❌ dq_* (EXCLUDED) | | |
| **Profile Hash Itself** | ❌ profile_hash (EXCLUDED) | | |

### ❌ Common Misalignments to Check

- [ ] Including *_other fields in hash → Fix: Exclude them
- [ ] Including ETL metadata in hash → Fix: Exclude them
- [ ] Including temporal columns in hash → Fix: Exclude them
- [ ] Including surrogate key in hash → Fix: Exclude it
- [ ] Not including all Type 2 attributes → Fix: Include all Type 2 attributes

### Hash Normalization Rules

| Normalization Rule | Customer Profile Pattern | Your Module | ✅/❌ |
|-------------------|-------------------------|-------------|-------|
| **English Text** | UPPER(TRIM()) | | |
| **Local Text** | TRIM() only (preserve case) | | |
| **Enumerations** | UPPER(TRIM()) | | |
| **Dates** | YYYY-MM-DD format | | |
| **NULLs** | "__NULL__" token | | |
| **Delimiter** | "|" (pipe) | | |
| **Algorithm** | SHA256 → lowercase hex | | |
| **Output Length** | 64 characters | | |

### Set Hash Rules

If your module has multi-valued sets:

| Set Hash Rule | Customer Profile Pattern | Your Module | ✅/❌ |
|---------------|-------------------------|-------------|-------|
| **Member Normalization** | UPPER(TRIM()) each member | | |
| **Deduplication** | Yes | | |
| **Sorting** | Ascending alphabetical | | |
| **Delimiter** | "|" (pipe) | | |
| **Empty Set** | "" (empty string) → SHA256 = "e3b0c4..." | | |
| **Algorithm** | SHA256 → lowercase hex | | |
| **Output Length** | 64 characters | | |

---

## Enumeration Pattern Alignment

### Enumeration YAML Structure

For each enumeration field, verify YAML file exists and matches pattern:

| YAML Element | Customer Profile Example | Your Module | ✅/❌ |
|--------------|-------------------------|-------------|-------|
| **File Location** | `enumerations/customer_marital_status.yaml` | | |
| **File Naming** | `{domain}_{attribute}.yaml` | | |
| **enumeration_name** | `customer_marital_status` | | |
| **domain** | `customer` | | |
| **description** | Clear description | | |
| **version** | Version number | | |
| **values.code** | UPPERCASE code (e.g., "MARRIED") | | |
| **values.description** | Human-readable description | | |
| **values.sort_order** | Integer sort order | | |

### Enumeration + Freetext Pattern

If enumeration has "OTHER" option, verify freetext field exists:

| Enumeration Field | Freetext Field | Customer Profile Example | Your Module | ✅/❌ |
|-------------------|---------------|-------------------------|-------------|-------|
| `person_title` | `person_title_other` | ✅ Yes | | |
| `nationality` | `nationality_other` | ✅ Yes | | |
| `occupation` | `occupation_other` | ✅ Yes | | |

**Rules**:
- Freetext field MUST be Type 1 (not versioned)
- Freetext field MUST be excluded from profile_hash
- Freetext field SHOULD be NULL when enumeration ≠ "OTHER"

### ❌ Common Misalignments to Check

- [ ] Enumeration has "OTHER" but no *_other field → Fix: Add freetext field
- [ ] Freetext field is Type 2 (versioned) → Fix: Make it Type 1
- [ ] Freetext field included in hash → Fix: Exclude from hash
- [ ] Enumeration codes not UPPERCASE → Fix: Convert to UPPERCASE
- [ ] Missing enumeration YAML file → Fix: Create YAML file

### No Lookup Dimension Check

**CRITICAL CHECK**: Verify NO separate lookup dimensions created:

| Anti-Pattern | Customer Profile | Your Module | ✅/❌ |
|--------------|------------------|-------------|-------|
| **dim_marital_status** | ❌ Does NOT exist | | |
| **dim_nationality** | ❌ Does NOT exist | | |
| **dim_occupation** | ❌ Does NOT exist | | |
| **Enumeration FK in dimension** | ❌ NO (uses direct codes) | | |

**If any lookup dimensions exist → NO-GO → Remove them**

---

## Bridge Table Alignment

If your module has multi-valued sets, validate bridge tables:

### Bridge Table Structure

| Aspect | Customer Profile Pattern | Your Module | ✅/❌ |
|--------|-------------------------|-------------|-------|
| **Table Name Pattern** | `bridge_customer_source_of_income` | | |
| **Schema** | `gold` | | |
| **Primary Key** | `(customer_profile_version_sk, source_of_income_code)` | | |
| **FK to Dimension** | `customer_profile_version_sk BIGINT NOT NULL` | | |
| **Natural Key (denormalized)** | `customer_id BIGINT NOT NULL` | | |
| **Code Column Type** | `source_of_income_code VARCHAR(100) NOT NULL` | | |
| **Load Timestamp** | `load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP` | | |

### Bridge Table Constraints

| Constraint | Customer Profile Example | Your Module | ✅/❌ |
|------------|-------------------------|-------------|-------|
| **Primary Key** | `PRIMARY KEY (customer_profile_version_sk, source_of_income_code)` | | |
| **FK to Dimension** | `FOREIGN KEY (customer_profile_version_sk) REFERENCES dim_customer_profile` | | |
| **Check: Code Not Empty** | `CHECK (LENGTH(TRIM(source_of_income_code)) > 0)` | | |

### Bridge Table dbt Model

| dbt Aspect | Customer Profile Pattern | Your Module | ✅/❌ |
|------------|-------------------------|-------------|-------|
| **Materialization** | `materialized='table'` | | |
| **Schema** | `schema='gold'` | | |
| **Explodes Set** | Uses UNNEST or similar to explode pipe-delimited string | | |
| **Source** | Gold dimension (not Silver) | | |

### ❌ Common Misalignments to Check

- [ ] Bridge sources from Silver instead of Gold → Fix: Source from Gold dimension
- [ ] Bridge uses FK integer instead of direct code → Fix: Use VARCHAR code
- [ ] Missing denormalized natural key → Fix: Add natural key column
- [ ] Composite PK not (version_sk, code) → Fix: Correct PK columns

---

## dbt Model Alignment

### Silver dbt Model Structure

| Element | Customer Profile Pattern | Your Module | ✅/❌ |
|---------|-------------------------|-------------|-------|
| **File Name** | `customer_profile_standardized.sql` | | |
| **Config: Materialized** | `materialized='incremental'` | | |
| **Config: Unique Key** | Natural key | | |
| **Config: Schema** | `schema='silver'` | | |
| **CTE 1: source** | Selects from Bronze with incremental filter | | |
| **CTE 2: validated** | Uses {{ validate_enumeration() }} macro | | |
| **CTE 3: with_hashes** | Uses {{ compute_set_hash() }} macro | | |
| **CTE 4: with_profile_hash** | Uses {{ compute_profile_hash() }} macro | | |
| **CTE 5: final** | Computes dq_score, dq_status, adds _silver_load_ts | | |
| **Incremental Filter** | `WHERE _bronze_load_ts > (SELECT MAX(_silver_load_ts) FROM {{ this }})` | | |

### Gold Dimension dbt Model Structure

| Element | Customer Profile Pattern | Your Module | ✅/❌ |
|---------|-------------------------|-------------|-------|
| **File Name** | `dim_customer_profile.sql` | | |
| **Config: Materialized** | `materialized='table'` | | |
| **Config: Schema** | `schema='gold'` | | |
| **CTE 1: silver_all_versions** | Selects from Silver | | |
| **CTE 2: with_effective_dates** | Uses LEAD() for effective_end_ts | | |
| **effective_end_ts Calculation** | `LEAD(effective_start_ts) - INTERVAL '1 microsecond'` | | |
| **is_current Calculation** | `ROW_NUMBER() = 1` over partition by natural key | | |
| **version_num Calculation** | `ROW_NUMBER()` over partition by natural key | | |
| **CTE 3: final** | Selects all columns, adds load_ts | | |

### ❌ Common Misalignments to Check

- [ ] Silver uses table materialization → Fix: Use incremental
- [ ] Gold dimension uses incremental → Fix: Use table
- [ ] Missing dbt macro calls → Fix: Add macro calls
- [ ] Wrong macro parameters → Fix: Correct parameters
- [ ] Not using LEAD() for effective_end_ts → Fix: Use LEAD() pattern
- [ ] Wrong interval (not microsecond) → Fix: Use '1 microsecond'

---

## Documentation Alignment

### Module Specification Document

Verify module spec follows Customer Profile structure:

| Section | Customer Profile | Your Module | ✅/❌ |
|---------|------------------|-------------|-------|
| **1. Module Overview** | ✅ Present | | |
| **2. Business Goals / KPIs** | ✅ Present | | |
| **3. Core Use Cases** | ✅ Present | | |
| **4. Entity Inventory** | ✅ Present | | |
| **5. Attribute Inventory** | ✅ Present (31 attributes) | | |
| **6. Semantic & Regulatory Notes** | ✅ Present | | |
| **8. Hashing Standard** | ✅ Present (canonical order) | | |
| **18. IT View Specification** | ✅ Present (Bronze source) | | |

### Contract Documentation

Verify contracts have complete documentation:

| Contract Element | Customer Profile | Your Module | ✅/❌ |
|------------------|------------------|-------------|-------|
| **entity_name** | ✅ Present | | |
| **domain** | ✅ Present | | |
| **table_type** | ✅ Present | | |
| **layer** | ✅ Present | | |
| **grain_description** | ✅ Present | | |
| **primary_keys** | ✅ Present | | |
| **natural_keys** | ✅ Present | | |
| **attributes** | ✅ Complete with business_definition | | |
| **indexes** | ✅ Present | | |
| **sample_rows** | ✅ Present | | |

### DDL Documentation

Verify DDL has COMMENT statements:

| DDL Comments | Customer Profile | Your Module | ✅/❌ |
|--------------|------------------|-------------|-------|
| **Table COMMENT** | ✅ Present | | |
| **Column COMMENT (all columns)** | ✅ Present | | |
| **Index COMMENT** | ✅ Present | | |

---

## Final Go/No-Go Checklist

### Critical Validation Points

**These MUST ALL be ✅ for GO decision**:

#### Architecture
- [ ] Uses correct schema names (bronze, silver, gold - NOT curated)
- [ ] Star schema only in Gold layer
- [ ] Bronze has ETL metadata (_bronze_*)
- [ ] Silver has quality flags (dq_*)

#### Naming
- [ ] All files use snake_case
- [ ] Dimension table has dim_ prefix
- [ ] Surrogate key has _version_sk or _sk suffix
- [ ] Temporal columns named effective_start_ts, effective_end_ts
- [ ] Boolean columns named is_*

#### Data Types
- [ ] Natural keys are BIGINT (not STRING)
- [ ] Timestamps are TIMESTAMP (not DATE)
- [ ] Booleans are BOOLEAN (not CHAR)
- [ ] Enumerations are VARCHAR codes (not INT FK)
- [ ] Hashes are VARCHAR(64)

#### SCD2 (if applicable)
- [ ] All 6 required indexes present
- [ ] effective_end_ts is NULL for current (not '9999-12-31')
- [ ] Uses LEAD() for effective_end_ts calculation
- [ ] Uses ROW_NUMBER() for version_num
- [ ] has is_current column
- [ ] has profile_hash column

#### Hash Computation
- [ ] Includes all Type 2 attributes
- [ ] Excludes *_other fields
- [ ] Excludes ETL metadata
- [ ] Excludes temporal columns
- [ ] Excludes surrogate keys
- [ ] Uses SHA256
- [ ] Output is 64 character lowercase hex

#### Enumerations
- [ ] All enumerations have YAML files
- [ ] YAML files follow naming convention
- [ ] Enumerations with "OTHER" have *_other freetext field
- [ ] Freetext fields are Type 1 (not versioned)
- [ ] Freetext fields excluded from hash
- [ ] NO lookup dimensions created

#### Bridge Tables (if applicable)
- [ ] Uses direct codes (not FK integers)
- [ ] Composite PK: (version_sk, code)
- [ ] Denormalizes natural key
- [ ] Sources from Gold dimension (not Silver)

#### dbt Models
- [ ] Silver uses incremental materialization
- [ ] Gold dimensions use table materialization
- [ ] Uses correct dbt macros
- [ ] Incremental filter uses watermark

#### Documentation
- [ ] Module specification complete
- [ ] Contracts complete
- [ ] DDL has COMMENT statements
- [ ] README files updated

---

## Go/No-Go Decision

### ✅ GO - Ready to Commit

**Criteria**: ALL 47 critical validation points are ✅

**Actions**:
1. Commit files to repository
2. Create pull request
3. Request code review
4. Update CONTEXT_MANIFEST.yaml
5. Update REPOSITORY_FILE_INDEX.md

### ❌ NO-GO - Must Fix Issues

**Criteria**: ANY critical validation point is ❌

**Actions**:
1. Document all ❌ issues
2. Fix issues
3. Re-run this validation
4. Repeat until all ✅

**DO NOT commit until all critical points are ✅**

---

## Alignment Score

Calculate alignment percentage:

**Formula**: (Number of ✅) / (Total checkpoints) × 100%

**Interpretation**:
- **100%**: Perfect alignment - GO
- **95-99%**: Excellent alignment - Review minor issues, likely GO
- **90-94%**: Good alignment - Review all issues, conditional GO
- **80-89%**: Moderate alignment - Fix major issues, NO-GO until fixed
- **< 80%**: Poor alignment - Major rework needed, NO-GO

---

## Customer Profile Reference Files

When validating, compare against these reference files:

### Documentation
- `docs/business/modules/customer_module.md` - Module specification
- `AI_CONTEXT.md` - Quick reference patterns
- `contracts/scd2/STANDARD_SCD2_POLICY.md` - SCD2 rules

### Enumerations
- `enumerations/customer_marital_status.yaml` - Example enumeration
- `enumerations/customer_source_of_income.yaml` - Example multi-valued set enumeration

### Contracts
- `contracts/bronze/customer_profile_standardized.yaml` - Bronze contract
- `contracts/silver/customer_profile_standardized.yaml` - Silver contract
- `contracts/gold/dim_customer_profile.yaml` - Gold dimension contract
- `contracts/gold/bridge_customer_income_source_version.yaml` - Bridge contract
- `contracts/gold/fact_customer_profile_audit.yaml` - Audit fact contract

### DDL
- `db/bronze/customer_profile_standardized.sql` - Bronze DDL
- `db/gold/dim_customer_profile.sql` - Gold dimension DDL (with 6 indexes!)
- `db/gold/bridge_customer_source_of_income.sql` - Bridge DDL

### dbt Models
- `dbt/models/silver/customer_profile_standardized.sql` - Silver transformation
- `dbt/models/gold/dim_customer_profile.sql` - Gold dimension transformation
- `dbt/models/gold/bridge_customer_source_of_income.sql` - Bridge transformation

---

## Summary

### Key Alignment Principles

1. **Consistency over Creativity**: Follow Customer Profile pattern exactly
2. **Validate Early, Validate Often**: Check alignment before committing
3. **When in Doubt, Ask**: Better to ask than to diverge from pattern
4. **Zero Tolerance for Prohibited Patterns**: See ARCHITECTURAL_CONSTRAINTS.md

### Success Metrics

✅ **Successful Module Replication** means:
- Passes this validation 100%
- Follows all architectural constraints
- Aligns with Customer Profile in structure, naming, types, and patterns
- Can be understood and maintained by any team member familiar with Customer Profile

---

**Document End**

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team  
**Status**: Authoritative Validation Standard

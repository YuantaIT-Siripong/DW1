# Contracts Directory

**Purpose**: YAML-based data contracts defining structure, rules, and metadata for all tables  
**Owner**: Data Architecture Team  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains **data contracts** - authoritative YAML specifications that define the structure, validation rules, and metadata for every table in the data warehouse. Contracts serve as the **single source of truth** for data definitions.

---

## Directory Structure

```
contracts/
├── bronze/          # Raw landing zone contracts
├── silver/          # Cleaned & validated layer contracts
├── gold/            # Dimensional model contracts (dimensions, bridges, facts)
├── quarantine/      # Data quality rejection contracts
├── scd2/            # SCD Type 2 policy and standards
└── deprecate/       # Legacy contracts (pre-medallion architecture)
```

---

## What is a Data Contract?

A **data contract** is a YAML file that defines:

1. **Structure**: Column names, data types, nullability
2. **Metadata**: Entity name, domain, layer, grain
3. **Business Rules**: Validation rules, constraints
4. **Relationships**: Upstream sources, downstream consumers
5. **Documentation**: Business definitions, examples

### Why Contracts?

**Benefits**:
- ✅ Single source of truth (DDL derives from contracts)
- ✅ Machine-readable (can auto-generate code)
- ✅ Version-controlled (track changes over time)
- ✅ Self-documenting (business + technical definitions)
- ✅ Validation-ready (define quality rules)

**Principle**: **Contract First, Code Second**
1. Define contract YAML
2. Generate/validate DDL
3. Generate/validate dbt models
4. Generate/validate documentation

---

## Contract Structure

### Standard Contract Template

```yaml
# Entity metadata
entity_name: "customer_profile_standardized"
domain: "customer"
table_type: "landing"  # landing | cleaned | dimension_scd2 | bridge | fact
layer: "bronze"  # bronze | silver | gold

# Description
description: "Customer profile demographics and economic attributes from IT operational database"
business_definition: "Represents a customer's profile information at a point in time..."

# Grain
grain_description: "One row per customer per source system modification"
grain_level: "customer_version"

# Source/Target
upstream_source:
  type: "IT_view"
  location: "MSSQL.operational_db.vw_customer_profile_standardized"
downstream_consumers:
  - "silver.customer_profile_standardized"
  - "Analytics dashboards"

# Keys
primary_keys:
  - "customer_id"
  - "last_modified_ts"
natural_keys:
  - "customer_id"

# Attributes
attributes:
  - name: "customer_id"
    data_type: "BIGINT"
    nullable: false
    business_definition: "Unique customer identifier from source system"
    example: "1234567890"
    
  - name: "first_name"
    data_type: "VARCHAR(100)"
    nullable: true
    business_definition: "Customer's legal first name"
    example: "John"
    validation_rules:
      - "length <= 100"
      - "no special characters except hyphen and apostrophe"

# Indexes
indexes:
  - name: "idx_bronze_customer_load_ts"
    columns: ["_bronze_load_ts"]
    unique: false
    
# Sample data
sample_rows:
  - customer_id: 1234567890
    first_name: "John"
    last_name: "Smith"

# References
adr_refs:
  - "docs/adr/ADR-001-scd2-customer-profile.md"
related_contracts:
  - "contracts/gold/dim_customer_profile.yaml"
```

---

## Contract Types by Layer

### Bronze Layer Contracts (`/contracts/bronze/`)

**Purpose**: Define raw landing zone tables

**Required Sections**:
- ✅ `entity_name`, `domain`, `table_type: landing`, `layer: bronze`
- ✅ `upstream_source` (IT view specification)
- ✅ `primary_keys` (natural key + temporal)
- ✅ ALL source system attributes
- ✅ ETL metadata attributes: `_bronze_load_ts`, `_bronze_source_file`, `_bronze_batch_id`

**Example**: `contracts/bronze/customer_profile_standardized.yaml`

### Silver Layer Contracts (`/contracts/silver/`)

**Purpose**: Define cleaned & validated tables

**Required Sections**:
- ✅ All Bronze attributes
- ✅ Computed columns:
  - `profile_hash VARCHAR(64)`
  - `<set>_set_hash VARCHAR(64)` (for multi-valued sets)
- ✅ Data quality columns:
  - `dq_*` flags (e.g., `dq_marital_status_valid BOOLEAN`)
  - `dq_score NUMERIC(5,2)`
  - `dq_status VARCHAR(20)`
- ✅ `_silver_load_ts` metadata

**Example**: `contracts/silver/customer_profile_standardized.yaml`

### Gold Layer Contracts (`/contracts/gold/`)

**Purpose**: Define dimensional model (star schema)

#### Dimension Contracts (SCD Type 2)

**Required Sections**:
- ✅ `table_type: dimension_scd2`, `layer: gold`
- ✅ Surrogate key: `<entity>_version_sk BIGSERIAL`
- ✅ SCD2 columns:
  - `effective_start_ts TIMESTAMP NOT NULL`
  - `effective_end_ts TIMESTAMP NULL`
  - `is_current BOOLEAN NOT NULL`
  - `version_num INT NOT NULL`
- ✅ `profile_hash VARCHAR(64) NOT NULL`
- ✅ All Type 2 attributes (no `_other` fields)
- ✅ `load_ts TIMESTAMP NOT NULL`
- ✅ ALL 6 required indexes (per SCD2 policy)
- ✅ `adr_refs` (must reference STANDARD_SCD2_POLICY.md)

**Example**: `contracts/gold/dim_customer_profile.yaml`

#### Bridge Table Contracts

**Required Sections**:
- ✅ `table_type: bridge`, `layer: gold`
- ✅ Foreign key to dimension: `<entity>_version_sk BIGINT NOT NULL`
- ✅ Multi-valued attribute column(s)
- ✅ Sequence/order column (if order matters)

**Example**: `contracts/gold/bridge_customer_income_source_version.yaml`

#### Fact Table Contracts

**Required Sections**:
- ✅ `table_type: fact`, `layer: gold`
- ✅ Fact primary key (surrogate or composite)
- ✅ Foreign keys to dimensions
- ✅ Measures (numeric facts)
- ✅ Degenerate dimensions (if any)

**Example**: `contracts/gold/fact_customer_profile_audit.yaml`

### Quarantine Contracts (`/contracts/quarantine/`)

**Purpose**: Define data quality rejection tables

**Required Sections**:
- ✅ All original source columns
- ✅ Rejection metadata:
  - `rejection_reason TEXT`
  - `rejected_at TIMESTAMP`
  - `rejected_by_rule VARCHAR(100)`
- ✅ Original source reference

**Example**: `contracts/quarantine/customer_profile_rejected.yaml`

---

## Naming Conventions

### Contract File Names

**Pattern**: `<entity>_<layer_qualifier>.yaml`

**Examples**:
- ✅ `customer_profile_standardized.yaml` (Bronze/Silver)
- ✅ `dim_customer_profile.yaml` (Gold dimension)
- ✅ `bridge_customer_income_source_version.yaml` (Gold bridge)
- ✅ `fact_customer_profile_audit.yaml` (Gold fact)
- ❌ `customerProfile.yaml` (wrong case)
- ❌ `customer.yaml` (not descriptive)

### Entity Name Convention

**Bronze/Silver**: `<domain>_<entity>_standardized`
- Example: `customer_profile_standardized`

**Gold Dimension**: `dim_<domain>_<entity>`
- Example: `dim_customer_profile`

**Gold Bridge**: `bridge_<entity>_<attribute>_version`
- Example: `bridge_customer_income_source_version`

**Gold Fact**: `fact_<entity>_<event>`
- Example: `fact_customer_profile_audit`

---

## Contract-to-DDL Relationship

**CRITICAL RULE**: DDL MUST match contract exactly.

| Contract Attribute | DDL Equivalent | Must Match |
|-------------------|----------------|------------|
| `name` | Column name | ✅ Exact |
| `data_type` | Column type | ✅ Exact |
| `nullable` | NULL/NOT NULL | ✅ Exact |
| `primary_keys` | PRIMARY KEY | ✅ Exact |
| `indexes` | CREATE INDEX | ✅ Exact |
| `business_definition` | COMMENT | ⚠️ Should align |

### Validation Process

1. **Define Contract**: Create/update YAML file
2. **Generate DDL**: Manually write or auto-generate from contract
3. **Validate**: Compare DDL to contract
   - Column count matches
   - Column names match (case-sensitive)
   - Data types match
   - Nullability matches
   - Primary keys match
   - Indexes match
4. **Test**: Execute DDL in development
5. **Commit**: Contract + DDL together

---

## Contract Maintenance

### When to Update Contracts

Update contracts when:
- ✅ Adding new attributes
- ✅ Changing data types
- ✅ Modifying validation rules
- ✅ Adding indexes
- ✅ Updating business definitions
- ✅ Deprecating attributes

### Update Process

1. **Update Contract YAML**
2. **Update Related DDL** (`/db/` directory)
3. **Update dbt Models** (if applicable)
4. **Update Documentation** (if structural change)
5. **Version Control**: Commit contract + DDL together
6. **Migration**: Create migration script if needed

### Version Control

**Contract versioning** (optional field):
```yaml
version: "2.0"
last_modified: "2026-01-05"
change_log:
  - version: "2.0"
    date: "2026-01-05"
    changes: "Added customer_segment attribute"
  - version: "1.0"
    date: "2025-11-20"
    changes: "Initial version"
```

---

## Contract Validation Rules

### Required Sections (All Contracts)

- ✅ `entity_name`
- ✅ `domain`
- ✅ `table_type`
- ✅ `layer`
- ✅ `description`
- ✅ `grain_description`
- ✅ `primary_keys`
- ✅ `attributes` (at least one)

### Layer-Specific Requirements

**Bronze**:
- ✅ `upstream_source` defined
- ✅ ETL metadata attributes present

**Silver**:
- ✅ `profile_hash` attribute
- ✅ `dq_*` attributes

**Gold (SCD2)**:
- ✅ `<entity>_version_sk` surrogate key
- ✅ SCD2 temporal columns
- ✅ `adr_refs` includes STANDARD_SCD2_POLICY.md
- ✅ 6 required indexes defined

---

## SCD2 Contracts (`/contracts/scd2/`)

### STANDARD_SCD2_POLICY.md

**Type**: Policy Document (Markdown)  
**Purpose**: Authoritative specification for all SCD Type 2 implementations

**Defines**:
- Temporal column naming (`effective_start_ts`, `effective_end_ts`)
- Closure rule (NULL for current, `LEAD() - INTERVAL '1 microsecond'`)
- Surrogate key pattern (`<entity>_version_sk`)
- Index requirements (6 mandatory indexes)
- Version numbering (`version_num`)
- Current record flag (`is_current`)

**Usage**: ALL SCD2 contracts MUST reference this policy in `adr_refs`.

### Module-Specific SCD2 Column Contracts

**Examples**:
- `dim_customer_profile_columns.yaml` - Customer Profile SCD2 columns
- `dim_investment_profile_version_columns.yaml` - Investment Profile SCD2 columns

**Purpose**: Define which attributes are Type 2 (versioned) vs Type 1 (overwrite)

---

## Special Contracts

### INDEX.yaml

**Purpose**: Index of all contracts in a directory

**Location**: `contracts/deprecate/INDEX.yaml`

**Contents**:
```yaml
deprecated_contracts:
  - file: "customer/customer_profile.yaml"
    deprecated_date: "2025-12-01"
    reason: "Replaced by medallion architecture"
    replacement: "contracts/bronze/customer_profile_standardized.yaml"
```

---

## Common Mistakes to Avoid

### ❌ Contract-DDL Mismatch
```yaml
# Contract says:
- name: "first_name"
  data_type: "VARCHAR(100)"

# DDL says:
first_name VARCHAR(50)  -- WRONG: Doesn't match contract
```

### ❌ Missing ETL Metadata
```yaml
# Bronze contract missing:
- name: "_bronze_load_ts"
- name: "_bronze_source_file"
- name: "_bronze_batch_id"
```

### ❌ Wrong Table Type
```yaml
table_type: "dimension"  # WRONG: Should be "dimension_scd2"
```

### ❌ Missing ADR Reference (SCD2)
```yaml
# Gold SCD2 dimension contract missing:
adr_refs:
  - "contracts/scd2/STANDARD_SCD2_POLICY.md"  # REQUIRED
```

### ❌ Type 1 Attributes in SCD2 Hash
```yaml
# Contract includes customer_occupation_other in profile_hash
# WRONG: *_other fields are Type 1, must be excluded
```

---

## Related Documentation

- **DDL Scripts**: `/db/README.md`
- **SCD2 Policy**: `contracts/scd2/STANDARD_SCD2_POLICY.md`
- **Naming Conventions**: `docs/data-modeling/naming_conventions.md`
- **Hashing Standards**: `docs/data-modeling/hashing_standards.md`
- **File Index**: `REPOSITORY_FILE_INDEX.md`
- **Architectural Constraints**: `docs/architecture/ARCHITECTURAL_CONSTRAINTS.md`

---

## Subdirectories

- [Bronze Contracts](bronze/README.md) - Raw landing zone
- [Silver Contracts](silver/README.md) - Cleaned & validated
- [Gold Contracts](gold/README.md) - Dimensional model
- [Quarantine Contracts](quarantine/README.md) - Data quality failures
- [SCD2 Standards](scd2/README.md) - SCD Type 2 policy and patterns

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team  
**Contact**: Data Architecture Team for contract questions or changes

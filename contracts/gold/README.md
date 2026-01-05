# Gold Layer Contracts

**Purpose**: Data contracts for dimensional model (dimensions, bridges, facts)  
**Layer**: Gold (Dimensional)  
**Last Updated**: 2026-01-05

---

## Overview

Gold contracts define the dimensional model - SCD Type 2 dimensions, bridge tables for multi-valued attributes, and fact tables for events. This is the analytics-ready layer.

---

## Contract Files in This Directory

### Dimensions

#### dim_customer_profile.yaml
- **Type**: SCD Type 2 Dimension
- **Natural Key**: `customer_id`
- **Surrogate Key**: `customer_version_sk`
- **Attributes**: 31 versioned business attributes
- **DDL**: `db/gold/dim_customer_profile.sql`
- **dbt Model**: `dbt/models/gold/dim_customer_profile.sql`

### Bridge Tables

#### bridge_customer_income_source_version.yaml
- **Type**: Bridge Table
- **Links**: `customer_version_sk` to income sources
- **DDL**: `db/gold/bridge_customer_income_source_version.sql`

#### bridge_customer_investment_purpose_version.yaml
- **Type**: Bridge Table
- **Links**: `customer_version_sk` to investment purposes
- **DDL**: `db/gold/bridge_customer_investment_purpose_version.sql`

### Fact Tables

#### fact_customer_profile_audit.yaml
- **Type**: Fact Table (Audit)
- **Grain**: One row per attribute change
- **DDL**: `db/gold/fact_customer_profile_audit.sql`

---

## SCD Type 2 Dimension Contract Requirements

### Required Sections

```yaml
entity_name: "dim_<domain>_<entity>"
domain: "<domain>"
table_type: "dimension_scd2"
layer: "gold"
description: "SCD Type 2 dimension for <entity>"
grain_description: "One row per version of <entity>"

upstream_source:
  type: "dbt_model"
  location: "gold.dim_<entity>"

primary_keys:
  - "<entity>_version_sk"

natural_keys:
  - "<entity>_id"

attributes:
  # Surrogate key (REQUIRED)
  - name: "<entity>_version_sk"
    data_type: "BIGSERIAL"
    nullable: false
    business_definition: "Surrogate key for each version"
  
  # Natural key (REQUIRED)
  - name: "<entity>_id"
    data_type: "BIGINT"
    nullable: false
  
  # SCD2 temporal columns (ALL REQUIRED)
  - name: "effective_start_ts"
    data_type: "TIMESTAMP"
    nullable: false
    business_definition: "Start of validity period (inclusive)"
    
  - name: "effective_end_ts"
    data_type: "TIMESTAMP"
    nullable: true
    business_definition: "End of validity period (exclusive). NULL for current version"
    
  - name: "is_current"
    data_type: "BOOLEAN"
    nullable: false
    business_definition: "TRUE if current version"
    
  - name: "version_num"
    data_type: "INT"
    nullable: false
    business_definition: "Sequential version number starting from 1"
  
  # Business attributes (Type 2 only - no _other fields)
  - name: "first_name"
    data_type: "VARCHAR(100)"
    nullable: true
  
  # Change detection (REQUIRED)
  - name: "profile_hash"
    data_type: "VARCHAR(64)"
    nullable: false
    business_definition: "SHA256 hash for change detection"
  
  # Audit (REQUIRED)
  - name: "load_ts"
    data_type: "TIMESTAMP"
    nullable: false

indexes:
  # 1. Primary key (automatic)
  
  # 2. Unique on natural key + version
  - name: "idx_gold_<entity>_nk_version"
    columns: ["<entity>_id", "version_num"]
    unique: true
  
  # 3. Unique on natural key where current
  - name: "idx_gold_<entity>_nk_current"
    columns: ["<entity>_id"]
    unique: true
    where_clause: "is_current = TRUE"
  
  # 4. Non-unique on natural key + current flag
  - name: "idx_gold_<entity>_nk_current_flag"
    columns: ["<entity>_id", "is_current"]
    unique: false
    where_clause: "is_current = TRUE"
  
  # 5. Non-unique on natural key + temporal range
  - name: "idx_gold_<entity>_nk_temporal"
    columns: ["<entity>_id", "effective_start_ts", "effective_end_ts"]
    unique: false
  
  # 6. Non-unique on profile hash
  - name: "idx_gold_<entity>_hash"
    columns: ["profile_hash"]
    unique: false

adr_refs:
  - "contracts/scd2/STANDARD_SCD2_POLICY.md"  # REQUIRED
```

---

## Bridge Table Contract Requirements

```yaml
entity_name: "bridge_<entity>_<attribute>_version"
domain: "<domain>"
table_type: "bridge"
layer: "gold"

attributes:
  # Foreign key to dimension (REQUIRED)
  - name: "<entity>_version_sk"
    data_type: "BIGINT"
    nullable: false
    business_definition: "Foreign key to dim_<entity>"
  
  # Multi-valued attribute (REQUIRED)
  - name: "<attribute>"
    data_type: "VARCHAR(50)"
    nullable: false
  
  # Optional: Sequence if order matters
  - name: "<attribute>_seq"
    data_type: "INT"
    nullable: true

primary_keys:
  - "<entity>_version_sk"
  - "<attribute>"
```

---

## Fact Table Contract Requirements

```yaml
entity_name: "fact_<entity>_<event>"
domain: "<domain>"
table_type: "fact"
layer: "gold"
grain_description: "One row per <event> occurrence"

attributes:
  # Fact primary key
  - name: "<event>_sk"
    data_type: "BIGSERIAL"
    nullable: false
  
  # Foreign keys to dimensions
  - name: "<entity>_version_sk"
    data_type: "BIGINT"
    nullable: false
  
  # Degenerate dimensions (if any)
  - name: "<event>_id"
    data_type: "VARCHAR(100)"
    nullable: true
  
  # Measures
  - name: "<measure1>"
    data_type: "NUMERIC(18,2)"
    nullable: true
  
  # Event timestamp
  - name: "<event>_ts"
    data_type: "TIMESTAMP"
    nullable: false
  
  # Audit
  - name: "load_ts"
    data_type: "TIMESTAMP"
    nullable: false
```

---

## Key Principles

### 1. SCD Type 2 Dimensions
- MUST include all 6 required indexes
- MUST reference STANDARD_SCD2_POLICY.md
- NO Type 1 attributes (*_other fields)
- Surrogate key suffix: `_version_sk`

### 2. Bridge Tables
- Link dimension versions to multi-valued attributes
- Composite primary key: (dimension_fk, attribute)
- Optional sequence for ordered attributes

### 3. Fact Tables
- Grain clearly defined
- Foreign keys to dimension versions
- Measures clearly identified
- Event timestamp required

---

## Common Mistakes to Avoid

### ❌ Wrong Table Type
```yaml
table_type: "dimension"  # WRONG
```
✅ **Correct**: `table_type: "dimension_scd2"`

### ❌ Missing ADR Reference
```yaml
# SCD2 dimension contract missing:
adr_refs:
  - "contracts/scd2/STANDARD_SCD2_POLICY.md"
```

### ❌ Missing Indexes
```yaml
# Missing indexes 2-6 (only primary key defined)
```

### ❌ Wrong Surrogate Key Suffix
```yaml
- name: "customer_sk"  # WRONG
```
✅ **Correct**: `customer_version_sk`

### ❌ Including Type 1 Attributes
```yaml
# WRONG: *_other fields should not be in Gold dimension
- name: "customer_occupation_other"
```

---

## Related Documentation

- **Parent**: `/contracts/README.md`
- **Previous Layer**: `/contracts/silver/README.md`
- **SCD2 Policy**: `/contracts/scd2/README.md`
- **DDL**: `/db/gold/README.md`
- **dbt Models**: `dbt/models/gold/`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team

# Bronze Layer Contracts

**Purpose**: Data contracts for raw landing zone tables  
**Layer**: Bronze (Raw)  
**Last Updated**: 2026-01-05

---

## Overview

Bronze contracts define the structure and metadata for raw landing zone tables that mirror source system data with minimal transformation.

---

## Contract Files in This Directory

### customer_profile_standardized.yaml
- **Entity**: Customer Profile
- **Source**: IT view `vw_customer_profile_standardized`
- **Natural Key**: `customer_id`
- **Attributes**: 31 business attributes + ETL metadata
- **DDL**: `db/bronze/customer_profile_standardized.sql`

---

## Bronze Contract Requirements

### Required Sections

```yaml
entity_name: "<domain>_<entity>_standardized"
domain: "<domain>"
table_type: "landing"
layer: "bronze"
description: "Raw <entity> data from IT operational database"
grain_description: "One row per <entity> per source system modification"

upstream_source:
  type: "IT_view"
  location: "MSSQL.operational_db.vw_<entity>_standardized"

primary_keys:
  - "<entity>_id"
  - "last_modified_ts"

natural_keys:
  - "<entity>_id"

attributes:
  # All source columns
  - name: "<entity>_id"
    data_type: "BIGINT"
    nullable: false
  
  - name: "last_modified_ts"
    data_type: "TIMESTAMP"
    nullable: false
  
  # Business attributes...
  
  # ETL metadata (REQUIRED)
  - name: "_bronze_load_ts"
    data_type: "TIMESTAMP"
    nullable: false
    
  - name: "_bronze_source_file"
    data_type: "VARCHAR(255)"
    nullable: true
    
  - name: "_bronze_batch_id"
    data_type: "VARCHAR(100)"
    nullable: true

indexes:
  - name: "pk_bronze_<entity>"
    columns: ["<entity>_id", "last_modified_ts"]
    unique: true
    
  - name: "idx_bronze_<entity>_load_ts"
    columns: ["_bronze_load_ts"]
    unique: false
    
  - name: "idx_bronze_<entity>_batch_id"
    columns: ["_bronze_batch_id"]
    unique: false
```

---

## Key Principles

### 1. Exact Source Mirror
- Include ALL columns from IT view
- Match source data types
- NO computed columns
- NO transformations

### 2. Mandatory ETL Metadata
ALL Bronze contracts MUST include:
- `_bronze_load_ts` - When loaded
- `_bronze_source_file` - Source file reference
- `_bronze_batch_id` - Batch identifier

### 3. Composite Primary Key
Pattern: `(natural_key, temporal_column)`
- Enables multiple versions
- Supports full historical tracking

---

## Related Documentation

- **Parent**: `/contracts/README.md`
- **DDL**: `/db/bronze/README.md`
- **Next Layer**: `/contracts/silver/README.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team

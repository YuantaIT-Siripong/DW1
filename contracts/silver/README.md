# Silver Layer Contracts

**Purpose**: Data contracts for cleaned & validated tables with computed columns  
**Layer**: Silver (Cleaned)  
**Last Updated**: 2026-01-05

---

## Overview

Silver contracts define cleaned, validated data with computed hash columns and data quality flags. Tables maintain flat structure while adding analytical enhancements.

---

## Contract Files in This Directory

### customer_profile_standardized.yaml
- **Entity**: Customer Profile
- **Source**: Bronze layer
- **Computed Columns**: profile_hash, set_hashes, dq_* flags
- **DDL**: `db/silver/customer_profile_standardized.sql` (if exists)
- **dbt Model**: `dbt/models/silver/customer_profile_standardized.sql`

---

## Silver Contract Requirements

### Required Sections

```yaml
entity_name: "<domain>_<entity>_standardized"
domain: "<domain>"
table_type: "cleaned"
layer: "silver"
description: "Cleaned and validated <entity> data with computed hashes"

upstream_source:
  type: "dbt_model"
  location: "silver.<entity>_standardized"

# Inherit all Bronze columns plus:

attributes:
  # All Bronze columns...
  
  # Computed hash columns (REQUIRED)
  - name: "profile_hash"
    data_type: "VARCHAR(64)"
    nullable: false
    business_definition: "SHA256 hash of all version-driving attributes"
    
  - name: "<set1>_set_hash"
    data_type: "VARCHAR(64)"
    nullable: true
    business_definition: "SHA256 hash of <set1> multi-valued set"
  
  # Data quality flags (one per enumeration)
  - name: "dq_<enum1>_valid"
    data_type: "BOOLEAN"
    nullable: true
    business_definition: "TRUE if <enum1> passes enumeration validation"
  
  # Data quality metrics
  - name: "dq_score"
    data_type: "NUMERIC(5,2)"
    nullable: true
    business_definition: "Overall data quality score 0-100"
    
  - name: "dq_status"
    data_type: "VARCHAR(20)"
    nullable: true
    business_definition: "Quality status: PASS, WARN, FAIL"
  
  # Silver ETL metadata
  - name: "_silver_load_ts"
    data_type: "TIMESTAMP"
    nullable: false
```

---

## Key Principles

### 1. Inherit All Bronze Columns
- Start with all Bronze attributes
- Add computed columns
- NO column removal

### 2. Hash Computation
**profile_hash**:
- Include all Type 2 attributes
- Exclude Type 1 (_other fields)
- Exclude metadata and temporal columns
- Use SHA256 algorithm

**set_hash** (for multi-valued attributes):
- Sort values alphabetically
- Pipe-delimit: `VALUE1|VALUE2|VALUE3`
- SHA256 hash result

### 3. Data Quality Validation
**dq_* flags**:
- One flag per enumeration validation
- Boolean: TRUE (valid) / FALSE (invalid) / NULL (not applicable)

**dq_score**:
- Calculated: `(valid_count / total_count) * 100`
- Range: 0.00 to 100.00

**dq_status**:
- `PASS`: score >= 95
- `WARN`: score >= 70 and < 95
- `FAIL`: score < 70

---

## Validation Rules

Example validation rule specification:

```yaml
validation_rules:
  - attribute: "marital_status"
    rule: "enumeration"
    enumeration_file: "enumerations/customer_marital_status.yaml"
    required: false
    
  - attribute: "birth_date"
    rule: "date_range"
    min_date: "1900-01-01"
    max_date: "CURRENT_DATE - INTERVAL '18 years'"
```

---

## Related Documentation

- **Parent**: `/contracts/README.md`
- **Previous Layer**: `/contracts/bronze/README.md`
- **Next Layer**: `/contracts/gold/README.md`
- **Hashing Standards**: `docs/data-modeling/hashing_standards.md`
- **dbt Models**: `dbt/models/silver/README.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team

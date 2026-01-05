# Quarantine Contracts

**Purpose**: Data contracts for data quality rejection tables  
**Layer**: Quarantine (Quality Control)  
**Last Updated**: 2026-01-05

---

## Overview

Quarantine contracts define tables that store records failing data quality validation. These enable root cause analysis, reprocessing, and quality metrics.

---

## Contract Files in This Directory

### customer_profile_rejected.yaml
- **Entity**: Customer Profile
- **Source**: Records failing Silver validation
- **Rejection Types**: Enumeration failures, data type errors
- **DDL**: `db/quarantine/customer_profile_rejected.sql`

---

## Quarantine Contract Requirements

### Required Sections

```yaml
entity_name: "<domain>_<entity>_rejected"
domain: "<domain>"
table_type: "quarantine"
layer: "quarantine"
description: "Records from <entity> that failed data quality validation"
grain_description: "One row per rejected record"

attributes:
  # Quarantine metadata (REQUIRED)
  - name: "quarantine_id"
    data_type: "BIGSERIAL"
    nullable: false
    business_definition: "Unique identifier for quarantine record"
  
  - name: "rejected_at"
    data_type: "TIMESTAMP"
    nullable: false
    business_definition: "When record was quarantined"
  
  - name: "rejection_reason"
    data_type: "TEXT"
    nullable: false
    business_definition: "Detailed explanation of validation failure(s)"
  
  - name: "rejected_by_rule"
    data_type: "VARCHAR(100)"
    nullable: true
    business_definition: "Name of validation rule that failed"
  
  - name: "source_layer"
    data_type: "VARCHAR(20)"
    nullable: false
    business_definition: "Layer where rejection occurred (bronze/silver)"
  
  - name: "reprocessing_status"
    data_type: "VARCHAR(20)"
    nullable: false
    business_definition: "Status: PENDING, CORRECTED, IGNORED, REJECTED"
  
  - name: "reprocessed_at"
    data_type: "TIMESTAMP"
    nullable: true
    business_definition: "When record was reprocessed"
  
  # All original columns (from source)
  - name: "<entity>_id"
    data_type: "BIGINT"
    nullable: true  # May be NULL if invalid
  
  # ... all business attributes ...
  
  # Original ETL metadata
  - name: "_bronze_load_ts"
    data_type: "TIMESTAMP"
    nullable: true

indexes:
  - name: "pk_quarantine_<entity>"
    columns: ["quarantine_id"]
    unique: true
  
  - name: "idx_quarantine_<entity>_rejected_at"
    columns: ["rejected_at"]
    unique: false
  
  - name: "idx_quarantine_<entity>_nk"
    columns: ["<entity>_id"]
    unique: false
  
  - name: "idx_quarantine_<entity>_status"
    columns: ["reprocessing_status"]
    unique: false
```

---

## Key Principles

### 1. Preserve Original Data
- Include ALL original columns
- Allow NULLs (data may be invalid)
- NO transformations

### 2. Rejection Metadata
Required fields:
- `quarantine_id` - Unique identifier
- `rejected_at` - Timestamp
- `rejection_reason` - Detailed explanation
- `rejected_by_rule` - Rule name
- `source_layer` - Where rejected
- `reprocessing_status` - Workflow state

### 3. Enable Reprocessing
- Track reprocessing status
- Link to original source
- Support multiple reprocessing attempts

---

## Reprocessing Status Values

| Status | Meaning | Action |
|--------|---------|--------|
| `PENDING` | Awaiting review | Default state |
| `CORRECTED` | Fixed and reprocessed | Data corrected |
| `IGNORED` | Accepted as-is | False positive |
| `REJECTED` | Permanently rejected | Invalid data |

---

## Related Documentation

- **Parent**: `/contracts/README.md`
- **DDL**: `/db/quarantine/README.md`
- **Data Quality Framework**: `docs/data-quality/framework.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Quality Team

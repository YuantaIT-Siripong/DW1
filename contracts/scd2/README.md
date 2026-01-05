# SCD Type 2 Standards and Policy

**Purpose**: Authoritative SCD Type 2 policy and column specifications  
**Owner**: Data Architecture Team  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains the **authoritative specification** for all SCD Type 2 implementations in the repository. ALL SCD2 dimensions MUST comply with these standards.

---

## Files in This Directory

### STANDARD_SCD2_POLICY.md

**Type**: Policy Document (Authoritative)  
**Purpose**: Complete specification for SCD Type 2 pattern  
**Status**: **MANDATORY** - All implementations must comply

**Defines**:
1. **Temporal Columns**:
   - `effective_start_ts` - Start of validity (inclusive)
   - `effective_end_ts` - End of validity (exclusive, NULL for current)
   - `is_current` - Boolean flag for current version
   - `version_num` - Sequential version number

2. **Closure Rule**:
   - Formula: `LEAD(effective_start_ts) - INTERVAL '1 microsecond'`
   - Current version: `effective_end_ts = NULL` (NOT '9999-12-31')

3. **Surrogate Key Pattern**:
   - Name: `<entity>_version_sk`
   - Type: `BIGSERIAL PRIMARY KEY`

4. **Index Requirements**:
   - 6 mandatory indexes (all SCD2 dimensions)

5. **Hash-Based Change Detection**:
   - Use `profile_hash` for version detection
   - Include Type 2 attributes only

**Usage**: Reference this document in ALL SCD2 dimension contracts:
```yaml
adr_refs:
  - "contracts/scd2/STANDARD_SCD2_POLICY.md"
```

### Module-Specific Column Contracts

#### dim_customer_profile_columns.yaml
- **Purpose**: Defines which Customer Profile attributes are Type 2 (versioned)
- **Usage**: Reference for Customer Profile implementation
- **Status**: Complete

#### dim_investment_profile_version_columns.yaml
- **Purpose**: Defines which Investment Profile attributes are Type 2
- **Usage**: Reference for Investment Profile implementation
- **Status**: Complete

---

## SCD Type 2 Quick Reference

### Mandatory Columns

**ALL SCD2 dimensions MUST have**:

```sql
<entity>_version_sk BIGSERIAL PRIMARY KEY
<entity>_id BIGINT NOT NULL
effective_start_ts TIMESTAMP NOT NULL
effective_end_ts TIMESTAMP NULL  -- No DEFAULT
is_current BOOLEAN NOT NULL DEFAULT FALSE
version_num INT NOT NULL
profile_hash VARCHAR(64) NOT NULL
load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

### Mandatory Indexes (6 Required)

```sql
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
```

### Temporal Logic (dbt)

```sql
-- Effective start = source timestamp
effective_start_ts = last_modified_ts

-- Effective end = next version's start - 1 microsecond
effective_end_ts = LEAD(last_modified_ts) OVER (
    PARTITION BY <entity>_id 
    ORDER BY last_modified_ts
) - INTERVAL '1 microsecond'

-- Current version: latest record per entity
is_current = (ROW_NUMBER() OVER (
    PARTITION BY <entity>_id 
    ORDER BY last_modified_ts DESC
) = 1)

-- Version number: sequential starting from 1
version_num = ROW_NUMBER() OVER (
    PARTITION BY <entity>_id 
    ORDER BY last_modified_ts
)
```

---

## Type 2 vs Type 1 Attributes

### Type 2 (Versioned)
- **Tracked in history**: Every change creates new version
- **Examples**: 
  - Customer marital_status
  - Customer occupation code
  - Customer nationality
- **In profile_hash**: YES
- **In Gold dimension**: YES

### Type 1 (Overwrite)
- **NOT tracked in history**: Latest value only
- **Examples**:
  - `*_other` freetext fields
  - Derived metrics/scores
- **In profile_hash**: NO
- **In Gold dimension**: NO

**Rule**: Type 1 attributes should remain in Silver, not promoted to Gold dimensions.

---

## Validation Checklist

Before implementing SCD2 dimension, verify:

- [ ] All 6 mandatory columns present
- [ ] All 6 mandatory indexes created
- [ ] Surrogate key suffix is `_version_sk`
- [ ] `effective_end_ts` has NO DEFAULT (must be NULL or explicit)
- [ ] Closure formula uses `- INTERVAL '1 microsecond'`
- [ ] Current version uses `effective_end_ts = NULL` (not '9999-12-31')
- [ ] `profile_hash` includes Type 2 attributes only
- [ ] Type 1 attributes (*_other) excluded from dimension
- [ ] Contract references STANDARD_SCD2_POLICY.md in `adr_refs`
- [ ] Schema is 'gold' (not 'curated')

---

## Common SCD2 Mistakes

### ❌ Wrong Closure Formula
```sql
-- WRONG: Using '9999-12-31'
effective_end_ts = COALESCE(LEAD(...), '9999-12-31')

-- WRONG: Using day precision
effective_end_ts = LEAD(...) - INTERVAL '1 day'
```
✅ **Correct**:
```sql
effective_end_ts = LEAD(...) - INTERVAL '1 microsecond'
-- Current version: NULL
```

### ❌ Wrong Surrogate Key Suffix
```sql
customer_sk BIGSERIAL  -- WRONG
```
✅ **Correct**:
```sql
customer_version_sk BIGSERIAL  -- CORRECT
```

### ❌ Missing Indexes
```sql
-- Only creating primary key, missing indexes 2-6
```

### ❌ Including Type 1 Attributes
```sql
-- WRONG: Type 1 attributes in Gold dimension
customer_occupation_other VARCHAR(200)
```

### ❌ Missing Policy Reference
```yaml
# Contract missing adr_refs
# MUST include:
adr_refs:
  - "contracts/scd2/STANDARD_SCD2_POLICY.md"
```

---

## Evolution of SCD2 Implementation

### Version History

**v1.0** (2025-11-20):
- Initial SCD2 policy
- Customer Profile implementation

**v1.1** (2025-12-01):
- Added microsecond precision requirement
- Clarified Type 1 vs Type 2 distinction

**v2.0** (2026-01-05):
- Standardized index requirements (6 mandatory)
- Explicit prohibition of '9999-12-31' pattern
- Added Investment Profile column contract

---

## Related Documentation

- **Parent**: `/contracts/README.md`
- **Policy Details**: `STANDARD_SCD2_POLICY.md`
- **Gold Contracts**: `/contracts/gold/README.md`
- **Gold DDL**: `/db/gold/README.md`
- **Architectural Constraints**: `docs/architecture/ARCHITECTURAL_CONSTRAINTS.md`
- **ADR-001**: `docs/adr/ADR-001-scd2-customer-profile.md`

---

## Governance

### Change Process

Changes to SCD2 policy require:
1. ADR (Architectural Decision Record)
2. Impact analysis on existing dimensions
3. Migration plan if breaking change
4. Approval from Data Architecture Team

### Review Frequency

- **Policy**: Annual review (or as needed for issues)
- **Implementations**: Review during code review of new dimensions

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team  
**Contact**: Data Architecture Team for SCD2 questions or policy changes

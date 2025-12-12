# Standard SCD2 Policy

**Version**: 1.2  
**Date**: 2025-12-12  
**Status**:  Authoritative Standard  
**Applies To**: All SCD Type 2 dimensions in DW1

---

## Purpose

This document establishes the authoritative standard for implementing Slowly Changing Dimension Type 2 (SCD2) across all versioned dimensions in DW1. It ensures temporal consistency, auditability, and compliance with data governance requirements.

**Authority**: This policy supersedes all previous SCD2 documentation.  All SCD2 dimensions MUST follow these specifications.

---

## Scope

This policy applies to the following SCD2 dimension tables:
- `gold.dim_customer_profile` (customer demographics and profile attributes)
- `gold.dim_investment_profile_version` (investment suitability, risk, entitlements)
- Any future dimension requiring historical attribute tracking

---

## 1. Temporal Precision Standard

### 1.1 Data Type Requirement

**REQUIRED**: All SCD2 dimensions MUST use **TIMESTAMP(6) WITHOUT TIME ZONE** for temporal columns.

```sql
effective_start_ts TIMESTAMP(6) NOT NULL,
effective_end_ts   TIMESTAMP(6) NULL
```

**Precision**: 6 decimal places (microseconds)

**Timezone**: Store all timestamps in **UTC**.  Convert to local time at presentation layer only.

### 1.2 Column Naming Convention

**REQUIRED Names**:
- `effective_start_ts` - Start of version validity (inclusive)
- `effective_end_ts` - End of version validity (exclusive)
- `is_current` - Boolean flag for active version
- `version_num` - Sequential version number per business key

**Forbidden Names**:
- ❌ `effective_start_date`, `effective_end_date` (misleading - they're timestamps)
- ❌ `start_date`, `end_date` (insufficient precision)
- ❌ `current_flag` (use `is_current` for consistency)

### 1.3 Rationale for Microsecond Precision

**Why microseconds?**
- Supports multiple changes within the same second
- Enables precise closure formula (minus 1 microsecond)
- Prevents ambiguous overlapping intervals
- Aligns with audit event timestamps
- Future-proofs for high-frequency updates

**Example**:
```
Version 1: effective_start_ts = 2025-12-12 10:15:30. 123456
           effective_end_ts   = 2025-12-12 10:15:30.987653  (closed)

Version 2: effective_start_ts = 2025-12-12 10:15:30.987654
           effective_end_ts   = NULL (current)
```

---

## 2. Closure Rule

### 2.1 Standard Formula

**REQUIRED**: When creating a new version, close the previous version using: 

```
previous_version. effective_end_ts = new_version.effective_start_ts - INTERVAL '1 microsecond'
```

### 2.2 Implementation Example

```sql
-- TRANSACTION:  Create new version and close previous

BEGIN;

-- Step 1: Close previous version
UPDATE gold.dim_customer_profile
SET 
    effective_end_ts = TIMESTAMP '2025-12-12 14:30:00.987654' - INTERVAL '1 microsecond',
    is_current = FALSE
WHERE customer_id = '556677'
  AND is_current = TRUE;

-- Result: effective_end_ts = '2025-12-12 14:30:00.987653'

-- Step 2: Insert new version
INSERT INTO gold.dim_customer_profile (
    customer_profile_version_sk,
    customer_id,
    -- ... all attributes ...
    effective_start_ts,
    effective_end_ts,
    is_current,
    version_num,
    profile_hash,
    load_ts
) VALUES (
    nextval('seq_customer_profile_version_sk'),
    '556677',
    -- ... attribute values ...
    TIMESTAMP '2025-12-12 14:30:00.987654',  -- New start
    NULL,                                     -- Current version
    TRUE,
    2,                                        -- Incremented version
    '7b2d9e4a1c8f5b3d.. .',
    CURRENT_TIMESTAMP
);

COMMIT;
```

### 2.3 Non-Overlap Guarantee

This closure rule ensures: 
- ✅ No temporal gaps between consecutive versions
- ✅ No overlapping intervals for the same business key
- ✅ Deterministic point-in-time query results
- ✅ Audit trail integrity

**Query Pattern**:
```sql
-- Point-in-time query
WHERE effective_start_ts <= : as_of_timestamp
  AND (effective_end_ts IS NULL OR effective_end_ts > :as_of_timestamp)
```

---

## 3. NULL Pattern for Current Version

### 3.1 Standard

**REQUIRED**: Current (active) versions MUST have `effective_end_ts = NULL`.

**FORBIDDEN**: Do NOT use `9999-12-31` or similar "far future" dates.

### 3.2 Rationale

| NULL Pattern (✅ Use This) | 9999-12-31 Pattern (❌ Don't Use) |
|----------------------------|-----------------------------------|
| Clear semantic intent | Ambiguous (is it really current?) |
| Smaller index size | Wastes index space |
| Standard SQL practice | Legacy pattern |
| No magic constants | Requires documentation |
| `IS NULL` predicate | String comparison |

### 3.3 Query Examples

```sql
-- ✅ CORRECT: NULL pattern
SELECT *
FROM gold.dim_customer_profile
WHERE customer_id = '556677'
  AND effective_end_ts IS NULL;  -- Current version

-- ✅ CORRECT: Point-in-time query
SELECT *
FROM gold.dim_customer_profile
WHERE customer_id = '556677'
  AND effective_start_ts <= : as_of_ts
  AND (effective_end_ts IS NULL OR effective_end_ts > :as_of_ts);
```

### 3.4 Column Definition

```sql
effective_end_ts TIMESTAMP NULL,  -- or just TIMESTAMP (NULL is default)
```

**Do NOT add DEFAULT**: 
- ❌ Wrong: `DEFAULT NULL` (redundant)
- ❌ Wrong: `DEFAULT '9999-12-31'` (forbidden pattern)

---

## 4. Surrogate Key Standards

### 4.1 Naming Convention

**REQUIRED Pattern**:  `{entity}_version_sk` for SCD2 versioned dimensions

**Examples**:
| Table Name | Surrogate Key |
|------------|---------------|
| `gold.dim_customer_profile` | `customer_profile_version_sk` |
| `gold.dim_investment_profile_version` | `investment_profile_version_sk` |

**Forbidden Patterns**:
- ❌ `customer_profile_sk` (missing `_version`)
- ❌ `customer_sk` (not versioned)
- ❌ `dim_customer_profile_sk` (redundant `dim_` prefix)

### 4.2 Data Type

**REQUIRED**: `BIGINT` or `BIGSERIAL` (PostgreSQL auto-increment)

```sql
customer_profile_version_sk BIGSERIAL PRIMARY KEY
```

### 4.3 Generation Strategy

**Option 1: BIGSERIAL (Recommended)**
```sql
customer_profile_version_sk BIGSERIAL PRIMARY KEY
```

**Option 2: Sequence**
```sql
CREATE SEQUENCE seq_customer_profile_version_sk START WITH 100000;

customer_profile_version_sk BIGINT DEFAULT nextval('seq_customer_profile_version_sk') PRIMARY KEY
```

### 4.4 Uniqueness Requirement

**REQUIRED**:  Surrogate keys MUST be globally unique across: 
- All versions of all customers
- All time periods
- All ETL runs

**Never reuse surrogate keys**, even after deletes.

---

## 5. Version Number Management

### 5.1 version_num Column

**REQUIRED**:
```sql
version_num INT NOT NULL
```

**Purpose**:
- Human-readable version identifier
- Audit trail sequencing
- Business user understanding ("this is version 3")

### 5.2 Numbering Rules

| Rule | Example |
|------|---------|
| Start at 1 | Initial version = 1 |
| Sequential | 1, 2, 3, 4, ... (no gaps) |
| Per business key | Customer A: 1,2,3 / Customer B: 1,2,3 |
| Monotonic increasing | Never decrease |
| No reuse | Never go back to 1 after 5 |

### 5.3 Calculation

```sql
-- In dbt model
ROW_NUMBER() OVER (
    PARTITION BY customer_id 
    ORDER BY effective_start_ts
) AS version_num
```

### 5.4 Business Key Constraint

**REQUIRED**:
```sql
CREATE UNIQUE INDEX idx_dim_customer_profile_business_key
ON gold.dim_customer_profile (customer_id, version_num);
```

This ensures:  one version_num per customer_id. 

---

## 6. Change Detection Standards

### 6.1 Profile Hash

**REQUIRED Column**:
```sql
profile_hash VARCHAR(64) NOT NULL
```

**Purpose**: Deterministic SHA256 hash of all Type 2 (versioned) attributes for change detection. 

**Algorithm**: See [Hashing Standards](../../docs/data-modeling/hashing_standards.md)

### 6.2 What to Include in Hash

**✅ INCLUDE (Type 2 Attributes)**:
- All business attributes that drive versioning
- Enumeration codes (e.g., `person_title`, `occupation`, `marital_status`)
- Demographics (e.g., `firstname`, `lastname`, `birthdate`)
- Economic data (e.g., `total_asset`, `monthly_income`)
- Set hashes (e.g., `source_of_income_set_hash`)

### 6.3 What to EXCLUDE from Hash

**❌ EXCLUDE**:
- Surrogate keys (`*_version_sk`)
- Temporal columns (`effective_start_ts`, `effective_end_ts`)
- Version management (`version_num`, `is_current`)
- ETL metadata (`load_ts`, `_bronze_load_ts`, `_silver_load_ts`)
- The hash itself (`profile_hash`)
- **Type 1 attributes** (`*_other` freetext fields) ← CRITICAL
- **Derived scores** (`dq_score`, `dq_status`, `profile_reliability_score`)

### 6.4 Type 1 vs Type 2 Attributes

**Type 2 (Versioned)**:  Changes create new version
```sql
person_title VARCHAR(50)  -- Enumeration code
occupation VARCHAR(100)   -- Enumeration code
```

**Type 1 (Non-Versioned)**: Changes update in-place, do NOT create new version
```sql
person_title_other VARCHAR(200)  -- Freetext when person_title='OTHER'
occupation_other VARCHAR(200)    -- Freetext when occupation='OTHER'
```

**Example**:
```sql
-- ✅ CORRECT:  Exclude Type 1 fields from hash
{{ compute_profile_hash(
    'person_title',        -- ✅ Include enumeration
    -- 'person_title_other',  ❌ EXCLUDE freetext
    'occupation',          -- ✅ Include enumeration
    -- 'occupation_other',    ❌ EXCLUDE freetext
    'birthdate',
    'source_of_income_set_hash'
) }}
```

### 6.5 Change Detection Logic

```sql
WITH current_version AS (
    SELECT profile_hash
    FROM gold.dim_customer_profile
    WHERE customer_id = : incoming_customer_id
      AND is_current = TRUE
)
SELECT 
    CASE 
        WHEN current. profile_hash IS NULL THEN 'NEW_RECORD'
        WHEN current.profile_hash != :incoming_profile_hash THEN 'CHANGED'
        ELSE 'NO_CHANGE'
    END AS change_status
FROM current_version current;
```

**Actions**:
- `NEW_RECORD` → Insert version 1, set `is_current = TRUE`
- `CHANGED` → Close current version, insert new version (increment `version_num`)
- `NO_CHANGE` → No action (avoid duplicate versions)

---

## 7. Update Rules (Immutability)

### 7.1 Append-Only Pattern

**REQUIRED**: SCD2 dimensions are **append-only** for historical versions.

**Allowed Operations**:
- ✅ `INSERT` new versions
- ✅ `UPDATE` to close previous version (`effective_end_ts`, `is_current = FALSE`)
- ✅ `UPDATE` Type 1 attributes in existing rows (non-versioned fields)

**Forbidden Operations**:
- ❌ `UPDATE` Type 2 attribute values in existing rows
- ❌ `DELETE` rows (preserve history for audit/compliance)

### 7.2 Type 1 Attribute Updates

**Allowed**:  Update `*_other` freetext fields without creating new version

```sql
-- ✅ ALLOWED: Update Type 1 freetext field
UPDATE gold.dim_customer_profile
SET occupation_other = 'Space Engineer'  -- Changed from 'Astronaut'
WHERE customer_id = '556677'
  AND is_current = TRUE;
-- NO new version created
```

### 7.3 Version Closure Pattern

```sql
-- Standard pattern for closing previous version
UPDATE gold.dim_customer_profile
SET 
    effective_end_ts = : new_effective_start_ts - INTERVAL '1 microsecond',
    is_current = FALSE
WHERE customer_id = :customer_id
  AND is_current = TRUE;
```

---

## 8. is_current Flag Management

### 8.1 Standard

**REQUIRED**:
```sql
is_current BOOLEAN NOT NULL DEFAULT FALSE
```

**Rule**:  Exactly **ONE** row per business key must have `is_current = TRUE`.

### 8.2 Enforcement

**Use partial unique index**:
```sql
CREATE UNIQUE INDEX idx_dim_customer_profile_current_unique
ON gold.dim_customer_profile (customer_id)
WHERE is_current = TRUE;
```

This prevents accidental creation of multiple current versions.

### 8.3 Why DEFAULT FALSE? 

```sql
is_current BOOLEAN NOT NULL DEFAULT FALSE
```

**Rationale**:
- Most rows are historical (FALSE)
- Explicit `is_current = TRUE` on INSERT makes intent clear
- Prevents accidental creation of multiple current versions
- Database enforces uniqueness via partial index

### 8.4 Current Version Queries

```sql
-- ✅ Most efficient query (uses partial index)
SELECT *
FROM gold.dim_customer_profile
WHERE customer_id = '556677'
  AND is_current = TRUE;

-- ✅ Also correct (more explicit)
SELECT *
FROM gold.dim_customer_profile
WHERE customer_id = '556677'
  AND effective_end_ts IS NULL;
```

---

## 9. Index Strategy

### 9.1 Required Indexes

**MUST CREATE**: 

```sql
-- 1. Primary Key
ALTER TABLE gold.dim_customer_profile
ADD CONSTRAINT pk_dim_customer_profile 
PRIMARY KEY (customer_profile_version_sk);

-- 2. Business Key (natural key + version)
CREATE UNIQUE INDEX idx_dim_customer_profile_business_key
ON gold.dim_customer_profile (customer_id, version_num);

-- 3. Single Current Version (most important!)
CREATE UNIQUE INDEX idx_dim_customer_profile_current_unique
ON gold.dim_customer_profile (customer_id)
WHERE is_current = TRUE;

-- 4. Current Version Lookup (most common query)
CREATE INDEX idx_dim_customer_profile_current
ON gold.dim_customer_profile (customer_id, is_current)
WHERE is_current = TRUE;

-- 5. Point-in-Time Queries
CREATE INDEX idx_dim_customer_profile_temporal
ON gold.dim_customer_profile (customer_id, effective_start_ts, effective_end_ts);

-- 6. Change Detection
CREATE INDEX idx_dim_customer_profile_hash
ON gold.dim_customer_profile (profile_hash);
```

### 9.2 Index Performance Impact

| Query Pattern | Index Used | Performance |
|---------------|------------|-------------|
| Current version lookup | `idx_*_current_unique` | ⚡ Fastest |
| Point-in-time query | `idx_*_temporal` | ⚡ Fast |
| Full history | `idx_*_business_key` | ⚡ Fast |
| Hash comparison | `idx_*_hash` | ⚡ Fast |

---

## 10. Point-in-Time Query Patterns

### 10.1 Current Version

```sql
-- Get current version for a customer
SELECT *
FROM gold. dim_customer_profile
WHERE customer_id = '556677'
  AND is_current = TRUE;
```

**Performance**:  Uses `idx_dim_customer_profile_current_unique` (instant)

### 10.2 Historical Version (As-Of Date)

```sql
-- Get customer profile as of specific timestamp
SELECT *
FROM gold.dim_customer_profile
WHERE customer_id = '556677'
  AND effective_start_ts <= TIMESTAMP '2025-06-15 14:30:00'
  AND (effective_end_ts IS NULL OR effective_end_ts > TIMESTAMP '2025-06-15 14:30:00')
ORDER BY effective_start_ts DESC
LIMIT 1;
```

**Performance**: Uses `idx_dim_customer_profile_temporal`

### 10.3 Full Version History

```sql
-- Get all versions for a customer
SELECT 
    version_num,
    effective_start_ts,
    effective_end_ts,
    is_current,
    occupation,
    occupation_other
FROM gold.dim_customer_profile
WHERE customer_id = '556677'
ORDER BY version_num;
```

### 10.4 Changes Between Dates

```sql
-- Get all versions created within date range
SELECT *
FROM gold.dim_customer_profile
WHERE customer_id = '556677'
  AND effective_start_ts BETWEEN 
      TIMESTAMP '2025-01-01 00:00:00' 
      AND TIMESTAMP '2025-12-31 23:59:59'
ORDER BY effective_start_ts;
```

### 10.5 Join with Fact Table (Point-in-Time)

```sql
-- Join fact with dimension as-of transaction date
SELECT 
    f.transaction_id,
    f.transaction_date,
    f.amount,
    d.occupation,
    d.total_asset
FROM fact_transactions f
JOIN gold.dim_customer_profile d
  ON d.customer_id = f.customer_id
 AND d.effective_start_ts <= f.transaction_date
 AND (d.effective_end_ts IS NULL OR d.effective_end_ts > f.transaction_date)
WHERE f.transaction_date BETWEEN '2025-01-01' AND '2025-12-31';
```

---

## 11. Data Quality Constraints

### 11.1 Required Constraints

```sql
-- 1. Effective start always populated
ALTER TABLE gold.dim_customer_profile
ADD CONSTRAINT chk_effective_start_not_null
CHECK (effective_start_ts IS NOT NULL);

-- 2. Effective end >= effective start (when populated)
ALTER TABLE gold.dim_customer_profile
ADD CONSTRAINT chk_effective_end_after_start
CHECK (effective_end_ts IS NULL OR effective_end_ts > effective_start_ts);

-- 3. Version number positive
ALTER TABLE gold.dim_customer_profile
ADD CONSTRAINT chk_version_num_positive
CHECK (version_num > 0);

-- 4. Profile hash format (64 hex characters)
ALTER TABLE gold.dim_customer_profile
ADD CONSTRAINT chk_profile_hash_format
CHECK (profile_hash ~ '^[a-f0-9]{64}$');

-- 5. Natural key not null
ALTER TABLE gold.dim_customer_profile
ADD CONSTRAINT chk_customer_id_not_null
CHECK (customer_id IS NOT NULL);
```

### 11.2 Data Quality Validation Queries

**No overlapping intervals**:
```sql
-- Should return 0 rows
SELECT 
    a.customer_id,
    a.customer_profile_version_sk AS version_a,
    b.customer_profile_version_sk AS version_b,
    a.effective_start_ts AS a_start,
    a.effective_end_ts AS a_end,
    b.effective_start_ts AS b_start,
    b.effective_end_ts AS b_end
FROM gold.dim_customer_profile a
JOIN gold.dim_customer_profile b 
  ON a.customer_id = b.customer_id
 AND a.customer_profile_version_sk != b.customer_profile_version_sk
WHERE a.effective_start_ts < COALESCE(b.effective_end_ts, '9999-12-31':: TIMESTAMP)
  AND COALESCE(a.effective_end_ts, '9999-12-31'::TIMESTAMP) > b.effective_start_ts;
```

**Exactly one current version**:
```sql
-- Should return 0 rows (all counts = 1)
SELECT customer_id, COUNT(*) as current_count
FROM gold.dim_customer_profile
WHERE is_current = TRUE
GROUP BY customer_id
HAVING COUNT(*) != 1;
```

**Version sequence integrity**:
```sql
-- Should return 0 rows (all sequences continuous)
SELECT 
    customer_id,
    version_num,
    LEAD(version_num) OVER (PARTITION BY customer_id ORDER BY version_num) AS next_version
FROM gold.dim_customer_profile
WHERE LEAD(version_num) OVER (PARTITION BY customer_id ORDER BY version_num) != version_num + 1
  AND LEAD(version_num) OVER (PARTITION BY customer_id ORDER BY version_num) IS NOT NULL;
```

---

## 12. NULL Handling

### 12.1 Temporal Column NULLs

| Column | NULL Allowed?  | Meaning |
|--------|---------------|---------|
| `effective_start_ts` | ❌ NO (NOT NULL) | Every version has a start |
| `effective_end_ts` | ✅ YES (NULL) | NULL = current/active version |
| `is_current` | ❌ NO (NOT NULL) | Must be TRUE or FALSE |
| `version_num` | ❌ NO (NOT NULL) | Must have version number |

### 12.2 Attribute Value NULLs

**Allowed**: NULL attribute values represent "unknown" or "not applicable"

**Important**: NULLs participate in change detection
- NULL → 'VALUE' is a change (creates new version)
- 'VALUE' → NULL is a change (creates new version)
- NULL → NULL is NOT a change

**Hash Handling**: Use `'__NULL__'` token in canonical string construction (see hashing_standards.md)

---

## 13. Example Implementation

### 13.1 Table Structure

```sql
CREATE TABLE gold.dim_customer_profile (
    -- Surrogate Key
    customer_profile_version_sk BIGSERIAL PRIMARY KEY,
    
    -- Natural Key
    customer_id VARCHAR(50) NOT NULL,
    
    -- SCD2 Temporal Columns
    effective_start_ts TIMESTAMP NOT NULL,
    effective_end_ts TIMESTAMP NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    version_num INT NOT NULL,
    
    -- Type 2 Attributes (versioned - in hash)
    evidence_unique_key VARCHAR(100),
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    person_title VARCHAR(50),
    occupation VARCHAR(100),
    birthdate DATE,
    total_asset VARCHAR(50),
    -- ... more attributes ... 
    
    -- Type 1 Attributes (non-versioned - NOT in hash)
    person_title_other VARCHAR(200),
    occupation_other VARCHAR(200),
    -- ... more _other fields ...
    
    -- Hashes
    profile_hash VARCHAR(64) NOT NULL,
    source_of_income_set_hash VARCHAR(64),
    purpose_of_investment_set_hash VARCHAR(64),
    
    -- Audit
    load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_effective_dates CHECK (
        effective_end_ts IS NULL OR effective_end_ts > effective_start_ts
    ),
    CONSTRAINT chk_version_num_positive CHECK (version_num > 0),
    CONSTRAINT chk_profile_hash_format CHECK (profile_hash ~ '^[a-f0-9]{64}$')
);

-- Indexes
CREATE UNIQUE INDEX idx_dim_customer_business_key
ON gold.dim_customer_profile (customer_id, version_num);

CREATE UNIQUE INDEX idx_dim_customer_current_unique
ON gold.dim_customer_profile (customer_id)
WHERE is_current = TRUE;

CREATE INDEX idx_dim_customer_temporal
ON gold.dim_customer_profile (customer_id, effective_start_ts, effective_end_ts);

CREATE INDEX idx_dim_customer_hash
ON gold.dim_customer_profile (profile_hash);
```

### 13.2 dbt Implementation Pattern

See `dbt/models/gold/dim_customer_profile.sql` for complete working example. 

**Key CTEs**:
1. `silver_all_versions` - Source data from Silver
2. `with_effective_dates` - Calculate temporal boundaries
3. `final` - Assemble dimension with all columns

---

## 14. Applicable Tables and Contracts

| Table | Contract | Status |
|-------|----------|--------|
| `gold.dim_customer_profile` | [contracts/gold/dim_customer_profile.yaml](../gold/dim_customer_profile.yaml) | ✅ Active |
| `gold.dim_investment_profile_version` | [contracts/gold/dim_investment_profile_version.yaml](../gold/dim_investment_profile_version.yaml) | 🔄 Pending |

---

## 15. Testing Requirements

### 15.1 Unit Tests

For each SCD2 dimension, verify: 

```sql
-- Test 1: Closure rule
-- Verify:  previous. effective_end_ts = new.effective_start_ts - 1 microsecond

-- Test 2: No overlaps
-- Verify: 0 overlapping intervals per customer_id

-- Test 3: Single current
-- Verify:  Exactly 1 is_current=TRUE per customer_id

-- Test 4: Hash determinism
-- Verify: Same attributes → same profile_hash

-- Test 5: Point-in-time correctness
-- Verify: Query returns correct version for any timestamp

-- Test 6: Version sequence
-- Verify: version_num is continuous (1,2,3,4,...)

-- Test 7: Type 1 behavior
-- Verify:  Changing *_other field does NOT create new version

-- Test 8: Type 2 behavior
-- Verify: Changing enumeration field DOES create new version
```

### 15.2 Integration Tests

```sql
-- Test 1: Multi-version scenario
-- Create 3+ versions, query at different times, verify correctness

-- Test 2: Concurrent updates
-- Simulate race conditions, verify no duplicate current versions

-- Test 3: Bridge table alignment
-- Verify bridge records link to correct version_sk
```

---

## 16. Related Documents

- [Hashing Standards](../../docs/data-modeling/hashing_standards.md) - SHA256 algorithm details
- [Naming Conventions](../../docs/data-modeling/naming_conventions.md) - Column and table naming
- [Customer Module Specification](../../docs/business/modules/customer_module.md) - Business requirements
- [Gold Dimension Contract](../gold/dim_customer_profile. yaml) - Detailed attribute specs
- [AI_CONTEXT. md](../../AI_CONTEXT.md) - Quick reference for AI agents

---

## 17. Audit Event Linkage (Advanced)

### 17.1 Requirement

Each SCD2 version creation **SHOULD** have corresponding audit event in domain-specific audit fact table.

**Example**: `fact_customer_profile_audit` tracks all changes to `dim_customer_profile`

### 17.2 Audit Event Constraints

- Event timestamp aligns with `effective_start_ts`
- Event references dimension `customer_profile_version_sk`
- Event captures change reason and attribute deltas
- Immutable audit trail

See [Audit Artifacts Standard](../../docs/audit/audit_artifacts_standard.md) for details.

---

## 18. Migration from Legacy Patterns

### 18.1 From 9999-12-31 to NULL

**If currently using 9999-12-31**: 

```sql
-- One-time migration
UPDATE gold.dim_customer_profile
SET effective_end_ts = NULL
WHERE effective_end_ts = '9999-12-31 23:59:59':: TIMESTAMP;

-- Update queries from: 
WHERE effective_end_ts = '9999-12-31'
-- To:
WHERE effective_end_ts IS NULL
```

### 18.2 From Second to Microsecond Precision

**If currently using second precision**:

```sql
-- Alter column type
ALTER TABLE gold.dim_customer_profile
ALTER COLUMN effective_start_ts TYPE TIMESTAMP(6);

ALTER TABLE gold.dim_customer_profile
ALTER COLUMN effective_end_ts TYPE TIMESTAMP(6);

-- Update closure logic from:
- INTERVAL '1 second'
-- To:
- INTERVAL '1 microsecond'
```

---

## 19. Common Mistakes to Avoid

| ❌ Mistake | ✅ Correct Approach |
|-----------|-------------------|
| Including `_other` fields in hash | Exclude Type 1 attributes from hash |
| Using DEFAULT TRUE for `is_current` | Use DEFAULT FALSE |
| Using 9999-12-31 for current version | Use NULL |
| Missing `version_num` column | Always include version_num |
| `effective_end_date` naming | Use `effective_end_ts` |
| Second precision only | Use microsecond precision (6 decimals) |
| No unique index on current flag | Create partial unique index |
| UPDATE-ing Type 2 attributes | Only INSERT new versions |
| Including dq_score in dimension | Exclude derived scores |
| No closure on previous version | Always close previous before INSERT |

---

## Change Log

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-11-21 | Initial SCD2 policy | Data Architecture |
| 1.1 | 2025-11-25 | Add audit event linkage requirement | Data Architecture |
| 1.2 | 2025-12-12 | Align with implementation (NULL pattern, microsecond precision, Type 1 exclusion) | Data Architecture |

---

**Last Updated**: 2025-12-12  
**Reviewed By**: Data Architecture Team  
**Next Review**: 2026-06-12 (6 months)
# Standard SCD2 Policy

## Purpose
This document establishes the authoritative standard for implementing Slowly Changing Dimension Type 2 (SCD2) across all versioned dimensions in DW1. It ensures temporal consistency, auditability, and predictable query patterns for point-in-time reconstruction.

## Scope
This policy applies to the following SCD2 dimension tables:
- `dim.dim_customer_profile` (customer demographics and profile attributes)
- `dim.dim_investment_profile_version` (investment suitability, risk, entitlements)
- Any future dimension requiring historical attribute tracking

## Temporal Precision Rule

### Microsecond Granularity
All SCD2 effective timestamps **MUST** use **microsecond precision** to support high-frequency change scenarios and ensure unambiguous ordering.

**Data Types:**
- PostgreSQL: `TIMESTAMP(6)` or `TIMESTAMPTZ(6)`
- Other RDBMS: Equivalent microsecond-precision timestamp type

**Rationale:**
- Second-level precision is insufficient for rapid API updates or batch processing scenarios where multiple versions may be created within the same second.
- Microsecond precision provides deterministic ordering without requiring synthetic sequence numbers.

### Column Naming
- **Start timestamp**: `effective_start_ts` (inclusive)
- **End timestamp**: `effective_end_ts` (exclusive, nullable)
- **Current flag**: `is_current` or `current_flag` (boolean)

**Exception:**
- `dim_customer_profile` uses **DATE** granularity (`effective_start_date`, `effective_end_date`) as customer demographic changes are tracked daily, not intraday.

## Closure Rule

When a new version is inserted, the **previous active version** must be closed using the following rule:

```
previous_record.effective_end_ts = new_record.effective_start_ts - INTERVAL '1 microsecond'
```

**Example:**
```sql
-- Current active record
customer_profile_version_sk: 1001
effective_start_ts: 2025-01-15 10:30:45.123456
effective_end_ts: NULL
is_current: TRUE

-- New version arrives at 2025-01-20 14:22:18.987654
-- Step 1: Close previous version
UPDATE dim.dim_customer_profile
SET effective_end_ts = TIMESTAMP '2025-01-20 14:22:18.987654' - INTERVAL '1 microsecond',
    is_current = FALSE
WHERE customer_profile_version_sk = 1001;
-- Result: effective_end_ts = '2025-01-20 14:22:18.987653'

-- Step 2: Insert new version
INSERT INTO dim.dim_customer_profile (
    customer_id, 
    effective_start_ts, 
    effective_end_ts, 
    is_current, 
    ...
) VALUES (
    'C12345',
    TIMESTAMP '2025-01-20 14:22:18.987654',
    NULL,
    TRUE,
    ...
);
```

**For DATE granularity (dim_customer_profile):**
```
previous_record.effective_end_date = new_record.effective_start_date - INTERVAL '1 day'
```

### Non-Overlap Guarantee
This closure rule ensures:
- No temporal gaps between consecutive versions
- No overlapping intervals for the same business key
- Exact point-in-time query semantics: `effective_start_ts <= :as_of_ts AND (effective_end_ts IS NULL OR effective_end_ts > :as_of_ts)`

## Surrogate Key Naming Pattern

All SCD2 dimensions **MUST** use surrogate keys with the following naming convention:

### Pattern
```
<table_name_without_prefix>_version_sk
```

### Examples
| Table Name | Surrogate Key Column |
|------------|---------------------|
| `dim_customer_profile` | `customer_profile_version_sk` |
| `dim_investment_profile_version` | `investment_profile_version_sk` |
| `dim_customer_income_source_version` | `customer_income_source_version_sk` |
| `dim_customer_investment_purpose_version` | `customer_investment_purpose_version_sk` |

### Properties
- **Type**: `BIGINT` or `BIGSERIAL` (auto-incrementing)
- **Primary Key**: Yes
- **Uniqueness**: Globally unique across all versions
- **Generation**: Database sequence or application-generated (e.g., UUID converted to BIGINT)

### Version Number Column
In addition to the surrogate key, maintain a **monotonically increasing version number** per business key:

```
version_num INTEGER NOT NULL DEFAULT 1
```

**Constraint:**
```sql
UNIQUE (customer_id, version_num)
```

**Initial Version:** Always starts at `version_num = 1`.

## Change Detection Triggers

### Hash-Based Change Detection
All SCD2 dimensions **MUST** implement hash-based change detection to determine if a new version is warranted.

#### Profile Change Hash Algorithm
See [Hashing Standards](../../docs/data-modeling/hashing_standards.md) for the complete algorithm.

**Summary:**
1. Concatenate SCD2 attribute values (excluding Type 1 and derived fields) in **deterministic alphabetical order** by attribute name.
2. Apply normalization: lowercase strings, trim whitespace, represent NULL as `__NULL__`, format timestamps to ISO 8601 seconds.
3. Hash using **SHA256** (not MD5).
4. Store as `profile_change_hash` or `profile_hash` column.

#### Change Detection Logic
```sql
-- Pseudo-code for change detection
new_hash = calculate_profile_hash(incoming_record)
current_hash = SELECT profile_change_hash 
               FROM dim.dimension_table 
               WHERE business_key = :key AND is_current = TRUE

IF new_hash != current_hash THEN
    -- Trigger new version creation
    close_current_version()
    insert_new_version()
ELSE
    -- No version change; optionally update Type 1 attributes only
    update_type1_attributes()
END IF
```

### Excluded from Hash
The following fields are **NEVER** included in the profile change hash:
- Surrogate keys (`*_version_sk`)
- Effective timestamps (`effective_start_ts`, `effective_end_ts`)
- Current flag (`is_current`)
- Type 1 attributes (non-versioned fields)
- **Derived metrics and scores** (`data_quality_score`, `profile_reliability_score`)
- Audit fields (`created_ts`, `created_by`, `ingestion_batch_id`)
- The hash field itself (`profile_change_hash`)

**Rationale:** Scores and metrics are **outcomes** of the profile state, not drivers of versioning. Including them would create spurious versions when recalculations occur without business attribute changes.

## Applicable Tables and Contracts

| Table | Contract Reference | Granularity |
|-------|-------------------|-------------|
| `dim_customer_profile` | [contracts/scd2/dim_customer_profile_columns.yaml](dim_customer_profile_columns.yaml) | DATE |
| `dim_investment_profile_version` | [contracts/scd2/dim_investment_profile_version_columns.yaml](dim_investment_profile_version_columns.yaml) | TIMESTAMP(6) |
| `dim_customer_income_source_version` | [contracts/customer/dim_customer_income_source_version.yaml](../customer/dim_customer_income_source_version.yaml) | DATE (inherits from customer profile) |
| `dim_customer_investment_purpose_version` | [contracts/customer/dim_customer_investment_purpose_version.yaml](../customer/dim_customer_investment_purpose_version.yaml) | DATE (inherits from customer profile) |

## Integrity Constraints

All SCD2 tables **MUST** enforce:

1. **Uniqueness:** `(business_key, version_num)` is unique.
2. **Single Current:** Exactly one row per business key has `is_current = TRUE`.
3. **Non-Overlap:** For a given business key, no two rows have overlapping `[effective_start_ts, effective_end_ts)` intervals.
4. **Chronological Order:** `effective_end_ts > effective_start_ts` (when `effective_end_ts` is not NULL).
5. **Version Sequence:** `version_num` increases monotonically (no gaps allowed for audit purposes).

## Point-in-Time Query Pattern

### Standard Query Template
```sql
-- Retrieve active version as of a specific timestamp
SELECT *
FROM dim.<dimension_table>
WHERE <business_key> = :key_value
  AND effective_start_ts <= :as_of_timestamp
  AND (effective_end_ts IS NULL OR effective_end_ts > :as_of_timestamp)
ORDER BY effective_start_ts DESC
LIMIT 1;
```

### Example: Customer Profile
```sql
SELECT *
FROM dim.dim_customer_profile
WHERE customer_id = 'C12345'
  AND effective_start_date <= DATE '2025-06-15'
  AND (effective_end_date IS NULL OR effective_end_date > DATE '2025-06-15')
ORDER BY effective_start_date DESC
LIMIT 1;
```

### Example: Investment Profile
```sql
SELECT *
FROM dim.dim_investment_profile_version
WHERE investment_profile_id = 'IP-C12345'
  AND effective_start_ts <= TIMESTAMP '2025-06-15 14:30:00'
  AND (effective_end_ts IS NULL OR effective_end_ts > TIMESTAMP '2025-06-15 14:30:00')
ORDER BY effective_start_ts DESC
LIMIT 1;
```

## Testing and Validation

### Unit Tests
For each SCD2 dimension, implement tests verifying:
- Closure rule: Previous version's `effective_end_ts` = new version's `effective_start_ts - 1 microsecond`
- No overlapping intervals per business key
- Exactly one `is_current = TRUE` per business key
- Hash recalculation matches stored hash
- Point-in-time query returns correct version

### Integration Tests
- Multi-version scenario: Create 3+ versions for a single business key, query at different timestamps, verify correct version retrieval
- Concurrent update handling: Ensure race conditions don't violate uniqueness or overlap constraints

## Related Documents
- [Hashing Standards](../../docs/data-modeling/hashing_standards.md)
- [Naming Conventions](../../docs/data-modeling/naming_conventions.md)
- [ADR-001: SCD2 Customer Profile](../../docs/adr/ADR-001-scd2-customer-profile.md)
- [ADR-INV-001: Investment Profile](../../docs/adr/ADR-INV-001-investment-profile.md)
- [AI_CONTEXT.md](../../AI_CONTEXT.md)

## Change Log
| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-11-21 | Initial standard SCD2 policy | Data Architecture |

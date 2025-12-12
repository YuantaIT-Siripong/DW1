# Standard SCD2 Policy

**Version**: 1.2  
**Date**: 2025-12-12  
**Status**:  Authoritative Standard  
**Previous Version**: 1.1 (deprecated, moved from contracts/deprecate/)

---

## Purpose

This document establishes the authoritative standard for implementing Slowly Changing Dimension Type 2 (SCD2) across all versioned dimensions in DW1. It ensures temporal consistency, auditability, and compliance with data governance requirements.

---

## Scope

This policy applies to the following SCD2 dimension tables:
- `gold.dim_customer_profile` (customer demographics and profile attributes)
- `gold.dim_investment_profile_version` (investment suitability, risk, entitlements)
- Any future dimension requiring historical attribute tracking

---

## 1. Temporal Precision Rule

### 1.1 Microsecond Granularity

All SCD2 effective timestamps **MUST** use **microsecond precision** to support high-frequency change scenarios and ensure unambiguous ordering. 

**Data Types**:
- PostgreSQL:  `TIMESTAMP(6) WITHOUT TIME ZONE` (6 = microseconds)
- Store in UTC, convert to local time at presentation layer

**Column Naming**:
- **Start timestamp**: `effective_start_ts` (inclusive, NOT NULL)
- **End timestamp**: `effective_end_ts` (exclusive, nullable - NULL for current version)
- **Current flag**: `is_current` (BOOLEAN, NOT NULL)

**Rationale**:
- Second-level precision is insufficient for rapid API updates or batch processing scenarios where multiple versions may be created within the same second
- Microsecond precision provides deterministic ordering without requiring synthetic sequence numbers
- Supports same-day corrections and high-precision audit trails

### 1.2 No Date-Only Exceptions

**ALL dimensions use TIMESTAMP(6)** - including customer profile: 

```sql
-- ✅ CORRECT: All SCD2 dimensions
CREATE TABLE gold.dim_customer_profile (
    customer_profile_version_sk BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    effective_start_ts TIMESTAMP(6) NOT NULL,  -- TIMESTAMP, not DATE
    effective_end_ts TIMESTAMP(6) NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    version_num INT NOT NULL,
    -- ... attributes ... 
);
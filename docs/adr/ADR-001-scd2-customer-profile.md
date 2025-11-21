# ADR-001: Adopt SCD2 for Customer Profile

## Status
Accepted

## Context
Need historical reconstruction of key demographic and suitability-related sets with minimal row growth.

## Decision
Use SCD Type 2 dimension `dim_customer_profile` with effective_start_ts / effective_end_ts, version_num, and attribute/profile_hash. Multi-valued sets hashed and versioned only when set changes.

## Versioned Attributes
marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set, investment_purpose_set.

## Type 1 (Non-Versioned)
Names (TH/EN), email, phones, evidence_unique_key.

## Hash Fields
Defined in contracts/scd2/dim_customer_profile_columns.yaml + set hashes.

**Hash Algorithm**: SHA256 (see [Hashing Standards](../data-modeling/hashing_standards.md))

**Implementation Details**: See [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md) for:
- Temporal precision rules (DATE granularity for customer profile)
- Closure rule (previous_end_date = new_start_date - 1 day)
- Surrogate key pattern (customer_profile_version_sk)
- Change detection triggers (hash-based)

## Alternatives
- Daily full snapshots (discarded: duplication)
- Full Data Vault for all entities (deferred: complexity vs team size)

## Consequences
+ Accurate point-in-time queries.
+ Controlled growth.
- Requires hash diff pipeline.
- Multi-valued sets need deterministic ordering.

## Future
Investment profile dimension (implemented via ADR-INV-001).
PII masking strategy (future ADR).
Monthly snapshot (performance layer optional).

## Related Policies and Standards
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md) - Authoritative SCD2 implementation rules
- [Hashing Standards](../data-modeling/hashing_standards.md) - SHA256 profile change hash algorithm
- [Naming Conventions](../data-modeling/naming_conventions.md) - Surrogate key and attribute naming patterns
# ADR-001: Adopt SCD2 for Customer Profile

## Status
Accepted

## Context
Need historical reconstruction of key demographic and suitability-related sets with minimal row growth.

## Decision
Use SCD Type 2 dimension `dim_customer_profile` with effective_start_date / effective_end_date, version_num, and attribute_hash. Multi-valued sets hashed and versioned only when set changes.

## Versioned Attributes
marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set, investment_purpose_set.

## Type 1 (Non-Versioned)
Names (TH/EN), email, phones, evidence_unique_key.

## Hash Fields
Defined in contracts/scd2/dim_customer_profile_columns.yaml (includes list hash fields).

## Alternatives
- Daily full snapshots (discarded: duplication)
- Full Data Vault for all entities (deferred: complexity vs team size)

## Consequences
+ Accurate point-in-time queries.
+ Controlled growth.
- Requires hash diff pipeline.
- Multi-valued sets need deterministic ordering.

## Future
Investment profile dimension (new ADR).
PII masking strategy (new ADR).
Monthly snapshot (performance layer optional).

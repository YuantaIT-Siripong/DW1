# ADR-002: Multi-Valued Profile Attributes as Bridge Tables

## Status
Accepted (Phase 1)

## Context
Customer profiles contain multi-valued categorical selections (income sources, investment purposes, contact channels). These sets must be queryable point-in-time and historically auditable.

## Decision
Implement one bridge dimension per set, keyed by (profile_version_id, item_code). Rebuild the entire set only when membership changes (detected via set hash difference). Maintain deterministic ordering (ascending codes) for hash construction.

## Rationale
- Clear historical reconstruction of set membership at any effective timestamp.
- Simplifies point-in-time joins.
- Avoids complexity of diffing JSON arrays or sparse pivot columns.

## Consequences
Pros:
- Deterministic change detection.
- Straightforward analytics (COUNT distinct items per version).
Cons:
- Additional storage overhead (row per item per version).
- More ETL complexity for set re-materialization.

## Hash Construction
1. Sort item codes ascending.
2. Join with "," delimiter (comma, not pipe - see Hashing Standards).
3. Apply SHA256 → *_set_hash stored in dim_customer_profile.

**Algorithm**: SHA256 (see [Hashing Standards](../data-modeling/hashing_standards.md) for complete multi-valued set hash specification)

**Note**: Multi-valued set hashes use comma delimiter `,` whereas profile change hashes use pipe delimiter `|`. See Hashing Standards for rationale.

## Alternatives Considered
1. JSON array (harder diff, indexing challenges).
2. Delimited string single column (less normalized, parsing overhead).
3. Graph structure (overkill).

## Data Quality & Testing
- No duplicate item_code for same profile_version_id.
- All item_codes valid in lookup dimension.
- *_set_hash matches recomputation from bridge rows.

## Implementation Notes
Bridge Dimensions:
- dim_customer_income_source_version
- dim_customer_investment_purpose_version
- dim_customer_contact_channel_version

Macro: compute_set_hash(list<code>) → SHA256 hex.

## Follow-Up Actions
- Implement bridge contracts.
- Add dbt tests for duplicates & FK integrity.
- Monitoring: Avg set size distribution; version churn triggered by set changes.

## ADR References
- ADR-001-scd2-customer-profile.md (SCD2 baseline)

## Related Policies and Standards
- [Hashing Standards](../data-modeling/hashing_standards.md) - Multi-valued set hash algorithm (SHA256)
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md) - Bridge table versioning rules
- [Naming Conventions](../data-modeling/naming_conventions.md) - Bridge table and set hash naming patterns
# Naming & Data Quality Cheatsheet

**Quick Reference**: For complete standards, see:
- [Naming Conventions](naming_conventions.md)
- [Hashing Standards](hashing_standards.md)
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md)

## Column Suffixes
- *_id: Natural or foreign key reference
- *_sk: Surrogate key (dimension/fact identity)
- *_version_sk: Surrogate key for SCD2 version
- *_date: Date (no time)
- *_timestamp: DateTime
- is_*: Boolean flag

## SCD2 Effective Date Rules
- effective_start_date inclusive
- effective_end_date exclusive (row valid while end > target date or NULL)
- Only one is_current = true per customer_id.

## Hash Generation
**Algorithm**: SHA256 (not MD5 - deprecated)
Concatenate normalized SCD2 attributes with '|' delimiter; lowercase; trim spaces; represent NULL as `__NULL__`; format timestamps to ISO 8601 seconds.

**See**: [Hashing Standards](hashing_standards.md) for complete algorithm and exclusion rules.

## Multi-Valued Set Hash
**Algorithm**: SHA256
Sort IDs ascending; join with ','; apply SHA256 hash.

**See**: [Hashing Standards](hashing_standards.md) for complete algorithm.

## Data Quality Summary
- Uniqueness: (customer_id, version_num)
- Non-overlap: end date >= start date (no overlapping intervals for same customer)
- Referential integrity: All constant IDs exist in constant_list.

## Fact Grain Examples
- fact_service_request: one row per service_request_id
- fact_service_subscription_event: one row per status transition

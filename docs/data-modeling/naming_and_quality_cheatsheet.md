# Naming & Data Quality Cheatsheet

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
Concatenate normalized SCD2 attributes with '|' delimiter; lowercase; trim spaces; MD5.

## Multi-Valued Set Hash
Sort IDs ascending; join with ','; MD5 of resulting list string.

## Data Quality Summary
- Uniqueness: (customer_id, version_num)
- Non-overlap: end date >= start date (no overlapping intervals for same customer)
- Referential integrity: All constant IDs exist in constant_list.

## Fact Grain Examples
- fact_service_request: one row per service_request_id
- fact_service_subscription_event: one row per status transition

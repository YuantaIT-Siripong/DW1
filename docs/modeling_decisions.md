# Modeling Decisions (Phase 1)

## SCD2 Scope (Customer Profile)
Versioned attributes: marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set, investment_purpose_set.

Type 1 attributes (overwrite only): names (TH/EN), email, phones, evidence_unique_key.

## Multi-Valued Sets
Stored in version tables:
- dim_customer_income_source_version
- dim_customer_investment_purpose_version
Commit only when hash of sorted IDs changes.

## Service Subscription Scope
Scope dimension (dim_subscribe_scope) with codes PERSON, CUSTOMER_CODE, ACCOUNT_CODE.
Expansion view will derive entitlements across hierarchy.

## Audit
customer_profile_audit records each SCD2 change (old/new hash, timestamp, actor).

## Status Codes
Service subscription events: SUBMITTED, APPROVED, REJECTED, DEACTIVATED.

## Hash Normalization
Lowercase + trim attributes; numeric as string; date formatted YYYY-MM-DD; delimiter '|'; MD5.

## Effective Dating
Granularity: DATE. Close old version by setting effective_end_date = new_version_start - 1 day.

## Future Enhancements
- Investment profile separate SCD2 (later)
- Masked PII view
- Monthly snapshot table
- JSON payload in audit

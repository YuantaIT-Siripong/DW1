' # Modeling Decisions (Phase 1)

## Authoritative Policies
All modeling decisions in this document are governed by the following authoritative policies:
- **[Standard SCD2 Policy](../contracts/scd2/STANDARD_SCD2_POLICY.md)** - Temporal precision, closure rules, surrogate key patterns
- **[Hashing Standards](data-modeling/hashing_standards.md)** - SHA256 algorithm, profile change hash, set hash
- **[Naming Conventions](data-modeling/naming_conventions.md)** - snake_case physical, camelCase API, suffix patterns

Refer to these policies for complete implementation details and rationale.

## SCD2 Scope (Customer Profile)
Versioned attributes: marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set, investment_purpose_set.

Type 1 attributes (overwrite only): names (TH/EN), email, phones, evidence_unique_key.

## Multi-Valued Sets
Stored in bridge tables:
- dim_customer_income_source_version
- dim_customer_investment_purpose_version
- dim_customer_contact_channel_version
Re-written only when membership hash changes.

## Service Subscription Scope
dim_subscribe_scope with codes PERSON, CUSTOMER_CODE, ACCOUNT_CODE.

## Audit
fact_customer_profile_audit (future) will record each SCD2 change (old/new hash, actor).

## Status Codes
SUBMITTED, APPROVED, REJECTED, DEACTIVATED.

## Hash Normalization
**Algorithm**: SHA256 (hex) - See [Hashing Standards](data-modeling/hashing_standards.md) for complete specification.

Summary:
- Lowercase & trim string attributes
- Numeric attributes cast to string
- Date: YYYY-MM-DD
- Customer profile timestamps: date granularity
- Investment profile timestamps: ISO8601 UTC seconds
- Delimiter: "|" for profile hashes, "," for set hashes
- NULL token: "__NULL__"
- Set hashing: sort codes ascending before join
- **Exclusions**: Derived scores (data_quality_score, profile_reliability_score) excluded from profile_hash

## Effective Dating
Customer profile: DATE granularity (effective_start_date / effective_end_date).
Investment profile: TIMESTAMP(6) microsecond granularity (effective_start_ts / effective_end_ts).

See [Standard SCD2 Policy](../contracts/scd2/STANDARD_SCD2_POLICY.md) for closure rules and precision requirements.

## Investment Profile Separation
Suitability, risk, acknowledgements, vulnerability, and product entitlement modeled in dim_investment_profile (root) + dim_investment_profile_version (SCD2). Rationale captured in ADR-INV-001.

## Future Enhancements
- Investment profile audit fact
- Masked PII view
- Monthly snapshot table
- Reliability scoring ADR expansion

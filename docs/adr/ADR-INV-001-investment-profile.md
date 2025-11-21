# ADR-INV-001: Adopt Separate SCD2 Investment Profile Dimension

## Status
Accepted

## Context
The existing Customer Profile SCD2 dimension captures demographic and multi-valued preference sets. Suitability, risk tolerance, product eligibility, regulatory flags, vulnerability classification, and acknowledgements are dynamic and require independent historical tracking at both CUSTOMER and CUSTOMER_CODE scopes. Mixing these attributes with demographic profile would inflate version churn and complicate access control for sensitive suitability recalculations.

## Decision
Implement a dedicated root scope dimension (`dim_investment_profile`) with a version table (`dim_investment_profile_version`) using SCD Type 2. ScopeType supports CUSTOMER baseline and CUSTOMER_CODE overrides. Change detection is driven by a deterministic SHA256 profile_hash of ordered versioned attributes (excluding lineage fields).

## Versioned Attributes
Risk & Suitability:
- risk_level_code
- suitability_score
- ability_to_bear_loss_tier
- investment_objective_category
- investment_time_horizon
- liquidity_need_level
- investment_experience_years

Regulatory & Compliance:
- high_net_worth_status_code
- kyc_status, kyc_risk_rating, aml_risk_rating
- pep_flag, sanction_screening_status, fatca_status
- investor_category, source_of_wealth_code, tax_residency_status

Acknowledgements & Eligibility:
- derivative_risk_ack_flag
- fx_risk_ack_flag
- complex_product_ack_flag
- complex_product_allowed
- structured_note_allowed
- perpetual_bond_allowed
- ipo_participation_allowed
- tender_offer_participation_allowed
- margin_agreement_status
- leverage_tolerance
- sbl_allowed
- block_trade_allowed
- fixed_income_access_allowed
- global_trading_allowed
- derivative_trading_allowed
- advisory_discretion_flag
- esg_preference

Vulnerability & Review:
- vulnerable_investor_flag
- vulnerability_reason_code
- vulnerability_assessment_ts
- review_cycle
- next_review_due_ts
- last_risk_review_ts

Scoring:
- data_quality_score (NOTE: Excluded from profile_hash - see Hashing Standards)
- profile_reliability_score (NOTE: Excluded from profile_hash - see Hashing Standards)

**Important**: Scores are **derived metrics** and are explicitly excluded from the profile change hash to prevent spurious versioning when scoring logic is recalibrated. See [Hashing Standards](../data-modeling/hashing_standards.md) for exclusion rules.

## Non-Versioned (Type 1 / Lineage)
- created_ts
- created_by
- ingestion_batch_id
- source_extract_reference
- source_system (in root table + version for lineage)

## Alternatives Considered
1. Merge into dim_customer_profile
   - Rejected: High churn; demographic changes and risk changes unrelated.
2. Snapshot Fact (daily)
   - Rejected: Inflated storage; complex point-in-time reasoning for intraday changes.
3. Data Vault (Hubs/Links/Satellites)
   - Deferred: Added complexity not justified at current scale.

## Consequences
Pros:
- Clean separation of demographic vs suitability domains.
- Precise point-in-time trade suitability retrieval.
- Independent governance and version KPIs.
Cons:
- Additional join for combined demographic + suitability views.
- More ETL orchestration (two SCD2 streams).

## Profile Hash Specification
Ordered attribute list (see DDL comment) concatenated with '|' delimiter; UNKNOWN or NULL replaced by '__NULL__'; boolean as 'true'/'false' lowercase; timestamp values normalized to ISO8601 UTC seconds.

**Algorithm**: SHA256 (see [Hashing Standards](../data-modeling/hashing_standards.md) for complete specification)

**Exclusions**: Scores (data_quality_score, profile_reliability_score), surrogate keys, effective timestamps, Type 1 attributes, and audit fields are excluded from the hash. This prevents spurious version creation when scoring algorithms are recalibrated.

**Implementation Reference**: See [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md) for:
- Temporal precision (TIMESTAMP(6) microsecond granularity)
- Closure rule (previous_end_ts = new_start_ts - 1 microsecond)
- Surrogate key pattern (investment_profile_version_sk)
- Change detection triggers

## Overlap & Integrity Rules
- No overlapping effective intervals per investment_profile_id.
- Exactly one current_flag = true row per profile.
- If complex_product_allowed = true then complex_product_ack_flag = true.
- margin_agreement_status = 'ACTIVE' implies:
  - leverage_tolerance <> 'NONE'
  - ability_to_bear_loss_tier <> 'LOW'
  - vulnerable_investor_flag = false
- next_review_due_ts > last_risk_review_ts.
- vulnerable_investor_flag = true AND vulnerability_reason_code = 'UNKNOWN' triggers reliability penalty.

## Audit Strategy
Phase 1: Version table alone (implicit audit).
Phase 2 (future ADR): Dedicated fact_investment_profile_audit capturing old/new profile_hash + diff vectors + override reasons.

## Security & Access
- AdvisoryDiscretionFlag and vulnerability fields considered sensitive; restricted column-level access or masked views for broad consumer roles.
- Reliability & quality scores may be exposed in analytics; raw compliance flags may require restricted views.

## Data Quality Metrics (Initial)
Mandatory completion set (for data_quality_score baseline):
- risk_level_code
- suitability_score
- ability_to_bear_loss_tier
- investment_objective_category
- investor_category
- kyc_status
- acknowledgement flags required for any allowed complex/derivative products

Unknown penalty: 0.05 per missing mandatory attribute (tunable).

## Implementation Notes
- Populate root profiles first; create code-specific overrides only when questionnaire / entitlement divergences exist.
- For horizon not yet collected: keep investment_time_horizon='UNKNOWN'; do not derive authoritative value automatically.
- vulnerability_assessment_ts required when vulnerable_investor_flag = true.

## Migration / Backfill
1. Initialize dim_investment_profile rows for all active customers (CUSTOMER scope).
2. Load baseline version with earliest known suitability assessment timestamp.
3. Introduce code-specific profiles as overrides when questionnaire captured at code granularity.
4. Backfill historical versions only if reliable timestamps available; otherwise start at cutover date.

## Rollback Plan
If reliability scoring adoption delayed, keep columns data_quality_score & profile_reliability_score nullable; do not remove them to avoid later schema churn.

## Open Issues
1. Final weighting for reliability penalties.
2. Supervisory override logging (separate audit fact?).
3. Horizon collection timeline and mandatory enforcement policy.
4. ESG preference expansion (detailed categories).
5. Enumeration version synchronization process.

## Decision Metadata
- Authors: Data Architecture Team
- Date: 2025-11-19
- Related Docs: investment_profile_module.md, enumerations.md
- Supersedes: None
- Superseded By: (future) ADR-INV-002 (Audit & Override Enhancements)

## Approval
- Data Governance Lead: PENDING_NAME (2025-11-19)
- Compliance Representative: PENDING_NAME (2025-11-19)
- Engineering Lead: PENDING_NAME (2025-11-19)

## Change Log
| Version | Date | Change | Author |
|---------|------|--------|--------|
| 0.1-Accepted | 2025-11-19 | Updated status to Accepted | Data Arch |
| 0.2 | 2025-11-21 | Added references to Standard SCD2 Policy and Hashing Standards; clarified score exclusion from hash | Data Arch |

## Related Policies and Standards
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md) - Authoritative SCD2 implementation rules
- [Hashing Standards](../data-modeling/hashing_standards.md) - SHA256 profile change hash algorithm and exclusion rules
- [Naming Conventions](../data-modeling/naming_conventions.md) - Surrogate key and attribute naming patterns

End of ADR.
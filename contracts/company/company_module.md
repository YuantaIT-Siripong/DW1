# Company Module Domain Specification (Phase 1)

## 1. Overview
The Company Module manages canonical profiles of legal entities (corporate customers) separate from individual customers. It mirrors the logic of the individual customer SCD2 profile while introducing corporate-specific attributes (legal form, industry, incorporation date) and multi-valued sets (funding sources, investment objectives). An audit fact records reasons and details for profile changes.

## 2. Goals / KPIs
- Corporate profile completeness rate
- Average latency from source system change to profile version availability
- Frequency of structural changes (legal form / industry reclassification)
- Funding source churn rate
- Data quality error rate (invalid codes, overlapping intervals, missing mandatory attributes)

## 3. Entities
| Entity | Type | Description |
|--------|------|-------------|
| Company Profile | SCD2 Dimension | Versioned corporate attributes & multi-valued sets |
| Industry | Lookup | Industry classification codes (internal mapping to NAICS/NACE) |
| Legal Form | Lookup | Legal organizational form (PLC, LLC, etc.) |
| Funding Source | Lookup | Sources of corporate funding (EQUITY, DEBT, VC, INTERNAL_CASH) |
| Investment Objective | Lookup | Corporate treasury / strategic investment objectives |
| Company Funding Source Version | Bridge | Funding source membership per profile version |
| Company Investment Objective Version | Bridge | Investment objective membership per profile version |
| Company Profile Audit Event | Fact Audit | Events causing new profile versions |

## 4. Profile Attributes (Phase 1)
| Attribute | Description | Example | Versioning | Notes |
|-----------|-------------|---------|-----------|-------|
| company_id | Stable company identifier | CO123456 | No | Natural key |
| profile_version_id | Globally unique version ID | 15001 | Yes | Drives SCD2 |
| legal_name | Registered legal name | Alpha Fintech Co., Ltd. | Yes | Mandatory |
| trade_name | Operating / brand name | AlphaFin | Yes | Optional |
| tax_id | Tax identifier (VAT/TIN) | 1234567890 | No | Immutable Phase 1 |
| registration_number | Official registration number | REG-TH-998877 | No | Immutable Phase 1 |
| incorporation_date | Date of incorporation | 2012-04-15 | Yes | Must be <= current_date |
| country_of_incorporation_id | Country code (FK dim_nationality or dim_country) | 66 | Yes | Reuse nationality or add dim_country |
| legal_form_code | Legal organizational form | PLC | Yes | Mandatory |
| industry_code | Industry classification | FIN_SERV | Yes | Mandatory |
| ownership_risk_rating | Internal risk rating (1–5) | 3 | Yes | May change with compliance |
| funding_source_set | Logical set of funding sources | ["EQUITY","DEBT"] | Yes (bridge) | Rule: at least one of two sets non-empty |
| investment_objective_set | Logical set of investment objectives | ["TREASURY_MANAGEMENT"] | Yes (bridge) | Completeness rule |
| funding_source_set_hash | Hash of sorted members | sha256(...) | Yes | Derived |
| investment_objective_set_hash | Hash of sorted members | sha256(...) | Yes | Derived |
| profile_hash | Composite hash of versioning attributes & set hashes | sha256(...) | Derived | Change detection |
| effective_start_ts | Version start timestamp (UTC) | 2024-10-01T08:00:00Z | Yes | Microsecond precision |
| effective_end_ts | Version end (null=current) | null | Yes | Closure rule |
| load_ts | Ingestion timestamp | 2024-10-01T08:02:30Z | No | ETL metadata |

## 5. Versioning Rules (SCD2)
Triggers new version when any versioning scalar changes OR funding_source_set membership OR investment_objective_set membership changes.
Tax_id and registration_number immutable in Phase 1.

Closure: prior version effective_end_ts = new_effective_start_ts - microsecond.

## 6. Hash Specification
- Algorithm: SHA256
- Ordered attributes (for profile_hash input):
  legal_name | trade_name | incorporation_date | country_of_incorporation_id | legal_form_code | industry_code | ownership_risk_rating | funding_source_set_hash | investment_objective_set_hash
- Delimiter: "|"
- Null token: "__NULL__"
- Empty set hash: SHA256("") (constant e3b0c44298fc1c149afbf4c8996fb924...)

Set hashing: sort codes ascending, join with "|" (empty set → ""), then SHA256.

## 7. Completeness Rule
At least one of the two multi-valued sets (funding_source_set, investment_objective_set) must be non-empty.

## 8. Data Quality Rules
- No overlapping (effective_start_ts, effective_end_ts) intervals per company_id.
- incorporation_date <= current_date.
- legal_name NOT NULL.
- legal_form_code valid in dim_legal_form.
- industry_code valid in dim_industry.
- profile_version_id globally unique.
- At least one of funding_source_set_hash or investment_objective_set_hash indicates a non-empty set.
- profile_hash length = 64; deterministic recomputation matches stored value.
- tax_id immutable Phase 1; registration_number immutable Phase 1.
- Empty set membership hash = SHA256("").

## 9. Audit Event Reasons (change_reason)
INITIAL_LOAD
LEGAL_NAME_CHANGE
LEGAL_FORM_CHANGE
INDUSTRY_RECLASSIFICATION
FUNDING_SOURCE_UPDATE
OBJECTIVE_UPDATE
RISK_RATING_UPDATE
CORRECTION
MERGE_FLAG (future)
RECOMPUTE_HASH (technical)

## 10. Sample Change Scenario
Adding VC funding source triggers new version: change_reason=FUNDING_SOURCE_UPDATE, changed_set_names=["funding_source"].

## 11. Open Questions
- Need separate dim_country or reuse nationality?
- Expand risk rating beyond 1–5?
- Beneficial ownership linkage to individuals (Phase 2)?
- Additional sets (regulatory_licenses_set)?

## 12. Future Extensions
- fact_company_profile_audit (defined).
- Ownership structure (dim_company_owner linking to individuals).
- Compliance flags (sanctions_screened_flag).

## 13. ADR References
- ADR-010-scd2-company-profile (to create)
- ADR-002-multi-valued-sets (reuse hashing semantics)

## 14. Sample JSON
{"company_id":"CO123456","profile_version_id":15001,"legal_name":"Alpha Fintech Co., Ltd.","trade_name":"AlphaFin","tax_id":"1234567890","registration_number":"REG-TH-998877","incorporation_date":"2012-04-15","country_of_incorporation_id":66,"legal_form_code":"PLC","industry_code":"FIN_SERV","ownership_risk_rating":3,"funding_source_set":["EQUITY","DEBT"],"investment_objective_set":["TREASURY_MANAGEMENT"],"profile_hash":"2c26b46b68ffc68ff99b453c1d304134..."}

## 15. Immediate Tasks
- Add contracts & seeds.
- Implement SCD2 ingestion analogous to individual customer.
- Add validation (overlap, set presence, hash recompute).
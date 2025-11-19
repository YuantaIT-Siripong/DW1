# AI Context: DW1 (Phase 1 Standard Bundle)

## Purpose
Single reference for AI assistants and new contributors. Points to authoritative domain and modeling sources and sets rules for changes.

## Authoritative Source Files
- Business Domain: docs/business/domain_overview.md
- Glossary: docs/business/glossary.md
- Customer Module Spec: docs/business/modules/customer_module.md
- Investment Profile Module Spec: docs/business/modules/investment_profile_module.md
- Data Quality Rules: docs/business/data_quality_rules.md
- Service Hierarchy: docs/service_hierarchy_and_subscription.md
- SCD2 Contract (Customer Profile): contracts/customer/dim_customer_profile.yaml
- SCD2 Columns Contract (Customer Profile): contracts/scd2/dim_customer_profile_columns.yaml
- SCD2 Contracts (Investment Profile):
  - contracts/investment/dim_investment_profile_version.yaml
  - contracts/scd2/dim_investment_profile_version_columns.yaml
- Unified Enumerations: docs/data-modeling/enumerations.md
- Investment Enumerations Detailed: docs/data-modeling/investment-profile/enumerations.md
- Investment Profile ADR: docs/adr/ADR-INV-001-investment-profile.md
- Multi-Valued Sets ADR: docs/adr/ADR-002-multi-valued-sets.md

## Core Modeling Decisions
- SCD2 Dimension (Customer): dim_customer_profile (versioned attributes: marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set_hash, investment_purpose_set_hash, contact_channel_set_hash; Type 1: names TH/EN, email, phones, evidence).
- SCD2 Dimension (Investment): dim_investment_profile_version (versioned suitability, risk, acknowledgements, entitlements, vulnerability, review, scoring; Type 1 lineage fields only).
- Separate root scope entities: dim_investment_profile (CUSTOMER baseline + CUSTOMER_CODE overrides) to avoid demographic-driven churn in investment suitability history.
- Multi-valued sets via bridge tables (customer only): dim_customer_income_source_version, dim_customer_investment_purpose_version, dim_customer_contact_channel_version (re-written only on membership hash change).
- Acknowledgements events fact: fact_investment_acknowledgement (evidence for boolean flags in investment profile version).
- Hashing: SHA256 for profile/set change detection; deterministic ordering & normalization tokens.
- Vulnerability classification always triggers new investment profile version (auditability).
- Reliability & Data Quality scores stored per investment version snapshot.

## Fact vs Dimension Classification
| Entity | Classification | Grain |
|--------|----------------|-------|
| dim_customer_profile | Dimension (SCD2) | customer + profile_version |
| dim_investment_profile | Dimension Root | customer/customer_code scope |
| dim_investment_profile_version | Dimension (SCD2) | investment_profile_id + version |
| fact_investment_acknowledgement | Fact (event) | acknowledgement_event_id |
| fact_customer_profile_audit | Audit Fact | profile change event |
| dim_service | Dimension | service |
| dim_service_category | Dimension | category |
| dim_subscribe_scope | Dimension | scope level |
| fact_service_request | Fact | service request |
| fact_service_subscription_event | Fact | status event |
| dim_customer_income_source_version | Bridge Dimension | profile_version + income_source |
| dim_customer_investment_purpose_version | Bridge Dimension | profile_version + purpose |
| dim_customer_contact_channel_version | Bridge Dimension | profile_version + channel |

## Point-In-Time Query Pattern (Customer Profile)
```sql
select *
from dim.dim_customer_profile
where customer_id = :cid
  and effective_start_ts <= :as_of_ts
  and (effective_end_ts is null or effective_end_ts > :as_of_ts);
```

## Point-In-Time Query Pattern (Investment Profile)
Preferred code scope; fallback to customer scope:
```sql
-- Code scope
select *
from dim.dim_investment_profile_version
where investment_profile_id = :ip_code
  and effective_start_ts <= :trade_ts
  and (effective_end_ts is null or effective_end_ts > :trade_ts)
order by effective_start_ts desc
limit 1;
```
```sql
-- Fallback to customer baseline
select *
from dim.dim_investment_profile_version
where investment_profile_id = :ip_customer
  and effective_start_ts <= :trade_ts
  and (effective_end_ts is null or effective_end_ts > :trade_ts)
order by effective_start_ts desc
limit 1;
```

## Pending Backlog (See docs/backlog/phase1_tasks.yaml)
- Entitlement expansion view
- Change detection ETL scripts (customer + investment)
- PII masking view (Phase 2)
- Investment profile reliability scoring ETL implementation
- Monthly snapshot (optional)
- Bridge table contracts (income_source, investment_purpose, contact_channel) tests
- Profile & Investment hash macro implementation & tests
- Supervisory override audit fact (future)

## Interaction Guidance (Prompts)
- "Create PR for customer profile hash macro"
- "Generate change detection SQL for dim_investment_profile_version"
- "Add dbt tests for non-overlap & uniqueness for investment profile"
- "Produce ADR for investment profile audit fact"
- "List attributes affecting complex product eligibility"

## Change Discipline
Changes to SCD2 attribute lists, scope semantics, reliability scoring formula, or hash algorithm require ADR update and contract changes.

## Do Not
- Introduce new eligibility flags without enumeration + contract update.
- Rename scope codes silently.
- Add versioned attributes without contract + ADR update.
- Change hash algorithm without updating ADR + contracts.
- Derive authoritative InvestmentTimeHorizon from inference (must be client-declared).
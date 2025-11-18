# AI Context: DW1 (Phase 1 Standard Bundle)

## Purpose
Single reference for AI assistants and new contributors. Points to authoritative domain and modeling sources and sets rules for changes.

## Authoritative Source Files
- Business Domain: docs/business/domain_overview.md
- Glossary: docs/business/glossary.md
- Customer Module Spec: docs/business/modules/customer_module.md
- Data Quality Rules: docs/business/data_quality_rules.md
- Service Hierarchy: docs/service_hierarchy_and_subscription.md
- SCD2 Contract (Customer Profile): contracts/customer/dim_customer_profile.yaml
- Multi-Valued Sets ADR: docs/adr/ADR-002-multi-valued-sets.md

## Core Modeling Decisions
- SCD2 Dimension: dim_customer_profile (versioned: marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set_hash, investment_purpose_set_hash, contact_channel_set_hash; Type 1: names TH/EN, email, etc. — verify in contract).
- Multi-valued sets via bridge tables: dim_customer_income_source_version, dim_customer_investment_purpose_version, dim_customer_contact_channel_version (re-written only on membership hash change).
- Facts: fact_service_request (row per service_request_id); fact_service_subscription_event (row per status event); fact_customer_profile_audit (profile change events).
- Status codes: SUBMITTED, APPROVED, REJECTED, DEACTIVATED.
- Scope codes: PERSON, CUSTOMER_CODE, ACCOUNT_CODE.
- Hashing: SHA256 for profile and set change detection.

## Fact vs Dimension Classification
| Entity | Classification | Grain |
|--------|----------------|-------|
| dim_customer_profile | Dimension (SCD2) | customer + profile_version |
| fact_customer_profile_audit | Audit Fact | profile change event |
| dim_service | Dimension | service |
| dim_service_category | Dimension | category |
| dim_subscribe_scope | Dimension | scope level |
| fact_service_request | Fact | service request |
| fact_service_subscription_event | Fact | status event |
| dim_customer_income_source_version | Bridge Dimension | profile_version + income_source |
| dim_customer_investment_purpose_version | Bridge Dimension | profile_version + purpose |
| dim_customer_contact_channel_version | Bridge Dimension | profile_version + channel |

## Point-In-Time Query Pattern
```sql
select *
from dim.dim_customer_profile
where customer_id = :cid
  and effective_start_ts <= :as_of_ts
  and (effective_end_ts is null or effective_end_ts > :as_of_ts);
```

## Pending Backlog (See docs/backlog/phase1_tasks.yaml)
- Entitlement expansion view
- Change detection ETL scripts
- PII masking view (Phase 2)
- Investment profile SCD2 (future)
- Monthly snapshot (optional)
- Bridge table contracts (income_source, investment_purpose, contact_channel)
- Profile hash macro implementation & tests

## Interaction Guidance (Prompts)
- "Create PR for customer profile hash macro"
- "Add bridge contract for income source set"
- "Generate change detection SQL for dim_customer_profile using SHA256 hash"
- "Add dbt tests for non-overlap & uniqueness"
- "Produce ADR for investment profile SCD2 attributes"

## Change Discipline
Changes to SCD2 attribute list, status codes, scope semantics, or hash algorithm require ADR update (see docs/adr/ADR-001-scd2-customer-profile.md and related ADRs).

## Do Not
- Introduce new status without ADR.
- Rename scope codes silently.
- Add versioned attributes without contract + ADR update.
- Change hash algorithm without updating ADR + contracts.
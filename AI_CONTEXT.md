# AI Context: DW1 (Phase 1 Standard Bundle)

## Purpose
Single reference for AI assistants and new contributors. Points to authoritative domain and modeling sources and sets rules for changes.

## Authoritative Source Files
- Business Domain: docs/business/domain_overview.md
- Glossary: docs/business/glossary.md
- Data Quality Rules: docs/business/data_quality_rules.md
- Service Hierarchy: docs/service_hierarchy_and_subscription.md
- SCD2 Contract: contracts/scd2/dim_customer_profile_columns.yaml

## Core Modeling Decisions
- SCD2 Dimension: dim_customer_profile (versioned: marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set, investment_purpose_set; Type 1: names TH/EN, emails, phones, evidence_unique_key).
- Multi-valued sets: dim_customer_income_source_version, dim_customer_investment_purpose_version (re-written only on hash change).
- Facts: fact_service_request (row per service_request_id); fact_service_subscription_event (row per status event).
- Status codes: SUBMITTED, APPROVED, REJECTED, DEACTIVATED.
- Scope codes: PERSON, CUSTOMER_CODE, ACCOUNT_CODE.

## Fact vs Dimension Classification
| Entity | Classification | Grain |
|--------|----------------|-------|
| dim_customer_profile | Dimension (SCD2) | customer + version |
| customer_profile_audit | Audit Fact | change event |
| dim_service | Dimension | service |
| dim_service_category | Dimension | category |
| dim_subscribe_scope | Dimension | scope level |
| fact_service_request | Fact | service request |
| fact_service_subscription_event | Fact | status event |
| dim_customer_income_source_version | Bridge Dimension | profile version + source |
| dim_customer_investment_purpose_version | Bridge Dimension | profile version + purpose |

## Point-In-Time Query Pattern
```sql
select *
from dim.dim_customer_profile
where customer_id = :cid
  and effective_start_date <= :as_of_date
  and (effective_end_date is null or effective_end_date > :as_of_date);
```

## Pending Backlog (See docs/backlog/phase1_tasks.yaml)
- Entitlement expansion view
- Change detection ETL scripts
- PII masking view (Phase 2)
- Investment profile SCD2 (future)
- Monthly snapshot (optional)

## Interaction Guidance (Prompts)
- "Create PR for entitlement view logic"
- "Add SCD2 contract for investment profile with attributes <list>"
- "Generate change detection SQL for dim_customer_profile using hash fields"
- "Add dbt tests for non-overlap & uniqueness"

## Change Discipline
Changes to SCD2 attribute list, status codes, or scope semantics require ADR update (see docs/adr/ADR-001-scd2-customer-profile.md).

## Do Not
- Introduce new status without ADR.
- Rename scope codes silently.
- Add versioned attributes without contract + ADR update.

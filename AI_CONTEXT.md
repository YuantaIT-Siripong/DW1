# AI Context: DW1 (Phase 1 Standard Bundle)

## Purpose
Single reference for AI assistants and new contributors. Points to authoritative domain and modeling sources and sets rules for changes.

## Authoritative Source Files

### Thread & Manifest
- Context Manifest: CONTEXT_MANIFEST.yaml (machine index of versions and key artifacts)
- Thread Handover Guide: docs/THREAD_HANDOVER.md (instructions for resuming work across AI threads)

### Core Policies and Standards
- **Standard SCD2 Policy**: contracts/scd2/STANDARD_SCD2_POLICY.md
- **Hashing Standards**: docs/data-modeling/hashing_standards.md
- **Naming Conventions**: docs/data-modeling/naming_conventions.md
- **Data Quality Framework**: docs/data-quality/framework.md

### Business Domain
- Business Domain: docs/business/domain_overview.md
- Glossary: docs/business/glossary.md
- Customer Module Spec: docs/business/modules/customer_module.md
- Investment Profile Module Spec: docs/business/modules/investment_profile_module.md
- Data Quality Rules: docs/business/data_quality_rules.md
- Service Hierarchy: docs/service_hierarchy_and_subscription.md
- Company Module Spec: docs/business/modules/company_module.md

### SCD2 Contracts
- SCD2 Contract (Customer Profile): contracts/customer/dim_customer_profile.yaml
- SCD2 Columns Contract (Customer Profile): contracts/scd2/dim_customer_profile_columns.yaml
- SCD2 Contracts (Investment Profile):
  - contracts/investment/dim_investment_profile_version.yaml
  - contracts/scd2/dim_investment_profile_version_columns.yaml

### Enumerations and ADRs
- Unified Enumerations: docs/data-modeling/enumerations.md
- Investment Enumerations Detailed: docs/data-modeling/investment-profile/enumerations.md
- Investment Profile ADR: docs/adr/ADR-INV-001-investment-profile.md
- Multi-Valued Sets ADR: docs/adr/ADR-002-multi-valued-sets.md

## Core Modeling Decisions
- SCD2 Dimension (Customer): dim_customer_profile (versioned attributes: marital_status_id, nationality_id, occupation_id, education_level_id, birthdate, income_source_set_hash, investment_purpose_set_hash, contact_channel_set_hash; Type 1: names TH/EN, email, phones, evidence).
- SCD2 Dimension (Investment): dim_investment_profile_version (versioned suitability, risk, acknowledgements, entitlements, vulnerability, review; Type 1 lineage fields only).
- Separate root scope entities: dim_investment_profile (CUSTOMER baseline + CUSTOMER_CODE overrides) to avoid demographic-driven churn in investment suitability history.
- Multi-valued sets via bridge tables (customer only): dim_customer_income_source_version, dim_customer_investment_purpose_version, dim_customer_contact_channel_version (re-written only on membership hash change).
- Acknowledgements events fact: fact_investment_acknowledgement (evidence for boolean flags in investment profile version).
- Hashing: SHA256 for profile/set change detection; deterministic ordering & normalization tokens. **Derived metrics (e.g., data_quality_score, profile_reliability_score) EXCLUDED from hash** to prevent spurious versioning.
- Vulnerability classification always triggers new investment profile version (auditability).

## Fact vs Dimension Classification

### State vs Actions Separation
- **Dimensions (SCD2)** store current and historical **state** (what attributes were in effect at a point in time)
- **Audit Facts** capture **events** and **actions** that caused state changes (why and who)
- Dimensions answer "What was the profile state on date X?"
- Audit facts answer "Why did the profile change and who initiated it?"

| Entity | Classification | Grain | Surrogate Key Pattern |
|--------|----------------|-------|----------------------|
| dim_customer_profile | Dimension (SCD2) | customer_id + version_num | customer_profile_version_sk |
| dim_investment_profile | Dimension Root | customer/customer_code scope | investment_profile_sk |
| dim_investment_profile_version | Dimension (SCD2) | investment_profile_id + version_number | investment_profile_version_sk |
| fact_customer_profile_audit | Audit Fact | profile change event | audit_event_sk |
| fact_investment_acknowledgement | Audit Fact | acknowledgement event | acknowledgement_sk |
| fact_vulnerability_assessment | Audit Fact | vulnerability assessment event | vulnerability_assessment_sk |
| fact_supervisory_override | Audit Fact | override decision event | override_sk |
| dim_service | Dimension | service_id | service_sk |
| dim_service_category | Dimension | category_id | category_sk |
| dim_subscribe_scope | Dimension | scope level | scope_sk |
| fact_service_request | Fact | service request | service_request_sk |
| dim_customer_income_source_version | Bridge Dimension | profile_version + income_source | customer_income_source_version_sk |
| dim_customer_investment_purpose_version | Bridge Dimension | profile_version + purpose | customer_investment_purpose_version_sk |
| dim_customer_contact_channel_version | Bridge Dimension | profile_version + channel | customer_contact_channel_version_sk |

**Surrogate Key Naming**: All SCD2 dimensions use `<entity>_version_sk` pattern. Non-versioned dimensions and facts use `<entity>_sk` pattern. See [Naming Conventions](docs/data-modeling/naming_conventions.md) for complete rules.

## Audit Artifacts Overview
Per [Audit Artifacts Standard](docs/audit/audit_artifacts_standard.md) and [ADR-AUDIT-001](docs/adr/ADR-AUDIT-001-audit-artifacts-standard.md):

### Unified Audit Event Layer
- **Append-only** event capture (no updates/deletes)
- **Common attributes**: event_ts, actor_id, rationale_code, event_hash, event_hash_status
- **Sentinel defaults**: actor_id='SYSTEM', event_hash='__PENDING__' (async hash generation)
- **Integrity constraints**: Hash status enforcement, chronological validation, uniqueness per domain

### Audit Fact Tables
| Audit Fact | Domain | Event Types | Purpose |
|------------|--------|-------------|---------|
| fact_customer_profile_audit | Customer | INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, DATA_QUALITY_FIX | Profile version change tracking |
| fact_investment_acknowledgement | Investment | DERIVATIVE_RISK, FX_RISK, COMPLEX_PRODUCT | Risk disclosure evidence |
| fact_vulnerability_assessment | Investment | INITIAL_ASSESSMENT, PERIODIC_REVIEW, COMPLAINT_INVESTIGATION | Vulnerability classification |
| fact_supervisory_override | Investment | COMPLEX_PRODUCT_VULNERABLE, MARGIN_EXCEPTION, etc. | Suitability override decisions |

### SCD2 Linkage Requirements
- One audit event per dimension version creation (future enforcement)
- Event `event_ts` matches dimension `effective_start_ts`
- Profile hash in event matches dimension `profile_hash`
- Version surrogate keys nullable for early events (backfill job will populate)

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

### Audit Event Enumeration
A centralized machine-consumable enumeration file now exists: `enumerations/audit_event_types.yaml` (enumeration_version: 2025.11.25-1). It defines:
- event_type codes (e.g., PROFILE_VERSION_CREATE, ACK_ACCEPT, VULNERABILITY_CLASSIFIED, SUPERVISORY_OVERRIDE, SCOPE_FALLBACK_USED, PROFILE_HASH_RECOMPUTE)
- rationale_code values (e.g., INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, BACKDATED, DISCLOSURE_ACCEPTANCE, PERIODIC_REVIEW, SUPERVISORY_OVERRIDE, FALLBACK_APPLIED, UNKNOWN)
Governance:
- Additions/deprecations require ADR-AUDIT-001 reference and enumeration_version bump.
- ETL validation rejects unknown event_type/rationale_code outside controlled backfill mode.
Monitoring (planned): UNKNOWN rationale_code usage > 2% triggers alert; backdated events must carry approval reference when required.

## Pending Backlog (See docs/backlog/phase1_tasks.yaml)
- Entitlement expansion view
- Change detection ETL scripts (customer + investment)
- PII masking view (Phase 2)
- Investment profile reliability scoring ETL implementation (gold layer)
- Monthly snapshot (optional)
- Bridge table contracts (income_source, investment_purpose, contact_channel) tests
- Profile & Investment hash macro implementation & tests
- Audit quality monitoring view (vw_audit_quality_issues)


## Interaction Guidance (Prompts)
- "Create PR for customer profile hash macro"
- "Generate change detection SQL for dim_investment_profile_version"
- "Add dbt tests for non-overlap & uniqueness for investment profile"
- "List attributes affecting complex product eligibility"
- "Create monitoring view for pending audit event hashes"

## Change Discipline
Changes to SCD2 attribute lists, scope semantics, or hash algorithm require ADR update and contract changes. 

**Derived Quality Metrics**: Reliability scores, data quality scores, and similar derived metrics are NOT stored in SCD2 dimensions. They are computed downstream in the gold layer (planned implementation - see docs/data-quality/framework.md). This prevents spurious versioning driven by metric recalculations rather than business state changes.

## Do Not
- Introduce new eligibility flags without enumeration + contract update.
- Rename scope codes silently.
- Add versioned attributes without contract + ADR update.
- Change hash algorithm without updating ADR + contracts.
- Derive authoritative InvestmentTimeHorizon from inference (must be client-declared).

## Change Log (Context)
| Date | Change | Commit |
|------|--------|--------|
| 2025-11-25 | Added Thread & Manifest section (CONTEXT_MANIFEST.yaml, THREAD_HANDOVER.md) | a9f221a |
| 2025-11-25 | Integrated audit event enumeration reference | 348daee |

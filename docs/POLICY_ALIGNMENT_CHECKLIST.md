# Policy Alignment Checklist

## Purpose
This document tracks the alignment of repository documents with the new core policies:
- [Standard SCD2 Policy](../contracts/scd2/STANDARD_SCD2_POLICY.md)
- [Hashing Standards](../docs/data-modeling/hashing_standards.md)
- [Naming Conventions](../docs/data-modeling/naming_conventions.md)

## Status Legend
- ✅ **Aligned**: Document has been reviewed and updated to reference/conform to new policies
- ⚠️ **Needs Review**: Document may contain outdated information or missing references
- ❌ **Requires Update**: Document contains information that conflicts with policies
- 📝 **New Content Needed**: Document needs new sections to align with policies
- N/A **Not Applicable**: Policies do not apply to this document

## Documentation Alignment Status

### Customer Profile Module (✅ Complete - Phase 1)

**Status**: All customer profile artifacts aligned with policies and fully implemented. 

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| contracts/customer/dim_customer_profile.yaml | ✅ | SCD2, Naming, Hashing | References all policies; SHA256 hash specified; 31 attributes complete |
| contracts/customer/bridge_customer_income_source_version. yaml | ✅ | Naming | Follows bridge table naming conventions |
| contracts/customer/bridge_customer_investment_purpose_version.yaml | ✅ | Naming | Follows bridge table naming conventions |
| contracts/customer/fact_customer_profile_audit.yaml | ✅ | Hashing, Audit | References audit_artifacts_standard.md; enumeration cross-links |
| contracts/bronze/customer_profile_standardized.yaml | ✅ | Naming | Follows Bronze layer naming conventions; 25 columns |
| contracts/silver/customer_profile_standardized.yaml | ✅ | Hashing, Naming | SHA256 hash computation documented; 37 columns with DQ flags |
| db/bronze/customer_profile_standardized. sql | ✅ | Naming | PostgreSQL DDL follows naming conventions; comments complete |
| db/silver/customer_profile_standardized.sql | ✅ | Hashing | Includes SHA256 hash computation functions; helper functions documented |
| db/gold/dimensions/dim_customer_profile.sql | ✅ | SCD2, Naming | SCD2 policy compliant; effective_start_ts/effective_end_ts implemented |
| db/gold/bridges/bridge_customer_source_of_income.sql | ✅ | Naming | Bridge table conventions followed; FK constraints enforced |
| db/gold/bridges/bridge_customer_purpose_of_investment.sql | ✅ | Naming | Bridge table conventions followed; FK constraints enforced |
| db/gold/audit/fact_customer_profile_audit.sql | ✅ | Audit, Hashing | Follows audit_artifacts_standard.md; JSON change tracking |
| docs/business/modules/customer_module.md | ✅ | All | Section 5 (attributes), Section 8 (hashing), Section 18 (IT view spec) complete |
| enumerations/customer_person_title. yaml | ✅ | Naming | UPPERCASE enumeration codes; lifecycle_status tracked |
| enumerations/customer_marital_status.yaml | ✅ | Naming | UPPERCASE enumeration codes; lifecycle_status tracked |
| enumerations/customer_nationality.yaml | ✅ | Naming | ISO 3166-1 alpha-2 codes; lifecycle_status tracked |
| enumerations/customer_occupation.yaml | ✅ | Naming | UPPERCASE enumeration codes; lifecycle_status tracked |
| enumerations/customer_education_level.yaml | ✅ | Naming | UPPERCASE enumeration codes; lifecycle_status tracked |
| enumerations/customer_business_type.yaml | ✅ | Naming | UPPERCASE enumeration codes; lifecycle_status tracked |
| enumerations/customer_total_asset_bands.yaml | ✅ | Naming | UPPERCASE enumeration codes; no OTHER option |
| enumerations/customer_monthly_income_bands.yaml | ✅ | Naming | UPPERCASE enumeration codes; no OTHER option |
| enumerations/customer_income_country.yaml | ✅ | Naming | ISO 3166-1 alpha-2 codes; lifecycle_status tracked |
| enumerations/customer_source_of_income. yaml | ✅ | Naming | UPPERCASE enumeration codes; lifecycle_status tracked |
| enumerations/customer_purpose_of_investment.yaml | ✅ | Naming | UPPERCASE enumeration codes; lifecycle_status tracked |
| enumerations/customer_profile_audit_change_reason.yaml | ✅ | Naming, Audit | Change reason codes for audit fact; business rules documented |
| enumerations/customer_profile_attribute_names.yaml | ✅ | Naming | Attribute validation for audit JSON fields; PII flags included |
| AI_CONTEXT. md | ✅ | All | Customer profile section complete with hash rules, SCD2 patterns, enumeration references |
| CONTEXT_MANIFEST.yaml | ✅ | All | Customer profile enumeration files indexed; contract paths documented |

### Core Documentation Files

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| README.md | ✅ | All | Updated with policy reference table and consistency section |
| AI_CONTEXT.md | ✅ | All | Added policies to Authoritative Source Files; updated hash exclusions and surrogate key patterns |
| STANDARDS_INDEX.md | ✅ | All | Customer profile module indexed; all standards cross-referenced |

### Data Modeling Documentation

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/data-modeling/README.md | ✅ | SCD2, Naming, Hashing | Already links to all core standards; serves as index |
| docs/data-modeling/naming_and_quality_cheatsheet.md | ✅ | Naming, Hashing | Updated to reference new policies and SHA256 |
| docs/data-modeling/hashing_standards.md | ✅ | Hashing | Authoritative SHA256 specification |
| docs/data-modeling/naming_conventions.md | ✅ | Naming | Authoritative naming standard; snake_case, surrogate key patterns |
| docs/data-modeling/fact_vs_dimension_decisions.md | ✅ | All | Cross-links section references all three policies (lines 169-174) |
| docs/data-modeling/enumerations.md | ✅ | Naming | ENUM_VERSION tracking; governance rules documented |
| docs/data-modeling/enumeration_standards.md | ✅ | Naming | YAML structure, lifecycle management, versioning rules |

### Architecture Decision Records (ADRs)

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/adr/ADR-001-scd2-customer-profile.md | ✅ | SCD2, Hashing, Naming | References all three policies (lines 21-47); SHA256 specified |
| docs/adr/ADR-002-multi-valued-sets.md | ✅ | Hashing | References hashing standards for set hash algorithm |
| docs/adr/ADR-AUDIT-001-audit-artifacts-standard.md | ✅ | Audit, Hashing | Audit artifacts architecture; SHA256 event hash |
| docs/adr/ADR-INV-001-investment-profile.md | ⏸️ | SCD2, Hashing | Investment profile (Phase 2 - deferred until investment module work begins) |

### Business Documentation

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/business/modules/customer_module.md | ✅ | All | Complete specification; Section 5 (attributes), Section 8 (hashing), Section 18 (IT view) |
| docs/business/modules/investment_profile_module. md | ⏸️ | Naming | Investment profile module (Phase 2 - deferred until investment work begins) |
| docs/business/data_quality_rules.md | ⚠️ | Hashing, SCD2 | Should reference hashing_standards.md for hash integrity rules and STANDARD_SCD2_POLICY.md for temporal rules |
| docs/business/domain_overview.md | N/A | N/A | Business domain definitions; policies not directly applicable |
| docs/business/glossary.md | ⚠️ | Naming | Should include policy terms (snake_case, camelCase, SHA256, SCD2, surrogate_key, etc.) if file exists |

### Audit and Quality Documentation

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/audit/audit_artifacts_standard.md | ✅ | Audit, Hashing | Authoritative audit fact standard; sentinel defaults, event hash algorithm (SHA256) |
| docs/data-quality/framework. md | ✅ | Quality | Updated with Phase 1 (Silver DQ flags) complete; Phase 2 (Gold composite) planned |

### Modeling Decisions and Specifications

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/modeling_decisions. md | ⚠️ | SCD2, Naming, Hashing | Should reference all three policies as authoritative sources |
| docs/service_hierarchy_and_subscription. md | N/A | N/A | Business domain; policies not directly applicable |

### Other Documentation Areas

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/architecture/README.md | ⚠️ | Naming | Should reference naming conventions for architectural components |
| docs/etl-elt/README.md | 📝 | Hashing, SCD2 | Should reference SCD2 policy and hashing standards for ETL change detection |
| docs/governance/README.md | 📝 | All | Should reference policies as governance standards |
| docs/layers/README.md | ⚠️ | Naming | Should reference naming conventions for layer naming |
| docs/metadata/README.md | N/A | N/A | Metadata management; policies not directly applicable |

### Contract Files (YAML)

| Contract | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| contracts/scd2/STANDARD_SCD2_POLICY.md | ✅ | SCD2 | Authoritative SCD2 policy document |
| contracts/scd2/dim_customer_profile_columns.yaml | ⚠️ | SCD2, Hashing | Should add reference to STANDARD_SCD2_POLICY. md; hash algorithm should specify SHA256 not implicit |
| contracts/scd2/dim_investment_profile_version_columns.yaml | ⚠️ | SCD2, Hashing | Should add reference to STANDARD_SCD2_POLICY.md; change_detection notes SHA256 but should reference hashing_standards.md |
| contracts/customer/* (all 6 files) | ✅ | All | Complete and policy-compliant |
| contracts/bronze/customer_profile_standardized.yaml | ✅ | Naming | Complete Bronze layer contract |
| contracts/silver/customer_profile_standardized.yaml | ✅ | Hashing | Complete Silver layer contract with hash specifications |
| contracts/INDEX.yaml | 📝 | All | Should add section for policies/standards with links to new policy files |

### Examples

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| examples/README.md | ⚠️ | All | Should reference policies for example code standards |
| examples/retail_sales_example.md | N/A | N/A | Example use case; policies not directly applicable unless it contains code |

## Priority Alignment Tasks

### ✅ Completed (Customer Profile Module)
1. ✅ **Customer profile enumeration files (13 files)** - All enumeration codes follow UPPERCASE_SNAKE_CASE pattern
2. ✅ **Customer profile contracts (6 files)** - All contracts reference appropriate policies
3. ✅ **Customer profile DDL (5 files)** - PostgreSQL DDL follows naming conventions, includes SHA256 functions
4. ✅ **AI_CONTEXT.md** - Customer profile section complete with hash normalization rules
5. ✅ **CONTEXT_MANIFEST. yaml** - Customer profile artifacts indexed
6. ✅ **docs/business/modules/customer_module.md** - Complete specification with hashing standard (Section 8)
7. ✅ **docs/audit/audit_artifacts_standard.md** - Authoritative audit fact standard
8. ✅ **docs/data-quality/framework.md** - Updated with Phase 1 implementation status

### High Priority (Required for Consistency)
1. ❌ **Update ADR-001-scd2-customer-profile.md**: Add explicit references to STANDARD_SCD2_POLICY.md and hashing_standards.md
2. ❌ **Update ADR-INV-001-investment-profile. md**: Add explicit references to STANDARD_SCD2_POLICY. md and hashing_standards.md
3. ❌ **Update contracts/scd2 YAML files**: Add policy_reference fields linking to STANDARD_SCD2_POLICY.md and hashing_standards.md
4. ❌ **Update docs/modeling_decisions.md**: Reference all three policies as authoritative sources

### Medium Priority (Improve Discoverability)
5. ⚠️ **Update docs/data-modeling/README.md**: Add policy references section; update SCD2 examples to reference policy
6. ⚠️ **Update docs/business/glossary.md**: Add policy-related terms and definitions
7. ⚠️ **Update contracts/INDEX.yaml**: Add policies/standards section

### Low Priority (Enhancement)
8. 📝 **Update docs/etl-elt/README.md**: Reference SCD2 policy and hashing standards for change detection
9. 📝 **Update docs/governance/README. md**: Reference policies as governance standards

## Verification Checklist

To verify alignment, check that each document:

- [x] Customer profile module: All documents reference appropriate policies
- [x] Customer profile module: SHA256 hash algorithm consistently specified
- [x] Customer profile module: Naming conventions followed (snake_case, *_sk pattern)
- [x] Customer profile module: Enumeration files use UPPERCASE codes with lifecycle_status
- [ ] Investment profile module: Pending alignment (future phase)
- [ ] Company module: Pending alignment (future phase)
- [ ] Cross-domain documents updated with policy references
- [ ] No conflicting guidance across repository

## Maintenance Notes

**Update Frequency**: This checklist should be reviewed whenever:
- A new policy is introduced or updated
- A new document is added to the repository
- An existing document undergoes major revision
- A new module (investment, company) reaches completion

**Ownership**: Data Architecture team maintains this checklist and coordinates alignment updates with document owners.

**Version**: 2.0 (2025-12-01)

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-11-21 | Initial alignment checklist created | Data Architecture |
| 2025-12-01 | Updated with customer profile module completion (Phase 1); added 26 customer profile artifacts as ✅ Aligned | Data Architecture |
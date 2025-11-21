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

### Core Documentation Files

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| README.md | ✅ | All | Updated with policy reference table and consistency section |
| AI_CONTEXT.md | ✅ | All | Added policies to Authoritative Source Files; updated hash exclusions and surrogate key patterns |
| CONTRIBUTING.md | ⚠️ | Naming, Hashing | Should reference new policies for contributors |

### Data Modeling Documentation

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/data-modeling/README.md | ⚠️ | SCD2, Naming, Hashing | Contains SCD2 examples using DATE instead of TIMESTAMP; update to reference new policies |
| docs/data-modeling/naming_and_quality_cheatsheet.md | ✅ | Naming, Hashing | Updated to reference new policies and change MD5 to SHA256 |
| docs/data-modeling/fact_vs_dimension_decisions.md | ⚠️ | Naming | Should reference naming conventions for surrogate keys |
| docs/data-modeling/enumerations.md | ⚠️ | Naming | Should reference naming conventions for UPPERCASE_SNAKE_CASE pattern |
| docs/data-modeling/investment-profile/enumerations.md | ⚠️ | Naming | Should reference naming conventions for enumeration casing |
| docs/data-modeling/investment-profile/INVESTMENT_PROFILE_MODULE.md | ⚠️ | SCD2, Hashing | Should reference SCD2 policy and hashing standards |

### Architecture Decision Records (ADRs)

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/adr/ADR-001-scd2-customer-profile.md | ⚠️ | SCD2, Hashing | Should reference Standard SCD2 Policy; mentions hash but not SHA256 specification |
| docs/adr/ADR-INV-001-investment-profile.md | ⚠️ | SCD2, Hashing | Should reference Standard SCD2 Policy and hashing standards |
| docs/adr/ADR-002-multi-valued-sets.md | ⚠️ | Hashing | Should reference hashing standards for set hash algorithm |

### Business Documentation

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/business/modules/customer_module.md | ⚠️ | Naming | Should reference naming conventions for attribute names |
| docs/business/modules/investment_profile_module.md | ⚠️ | Naming | Should reference naming conventions for attribute names |
| docs/business/data_quality_rules.md | ⚠️ | Hashing, SCD2 | Should reference policies for hash-based validation and SCD2 integrity rules |
| docs/business/domain_overview.md | N/A | N/A | Business domain definitions; policies not directly applicable |
| docs/business/glossary.md | ⚠️ | Naming | Should include policy terms (snake_case, camelCase, SHA256, SCD2, etc.) |

### Modeling Decisions and Specifications

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/modeling_decisions.md | ⚠️ | SCD2, Naming, Hashing | Should reference all three policies as authoritative sources |
| docs/service_hierarchy_and_subscription.md | N/A | N/A | Business domain; policies not directly applicable |

### Other Documentation Areas

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| docs/architecture/README.md | ⚠️ | Naming | Should reference naming conventions for architectural components |
| docs/ai-methodology/README.md | 📝 | All | Should mention policies as AI-assisted development anchors |
| docs/copilot/ai_usage_guidelines.md | 📝 | All | Should reference policies for AI-assisted code generation |
| docs/etl-elt/README.md | 📝 | Hashing, SCD2 | Should reference SCD2 policy and hashing standards for ETL change detection |
| docs/governance/README.md | 📝 | All | Should reference policies as governance standards |
| docs/layers/README.md | ⚠️ | Naming | Should reference naming conventions for layer naming |
| docs/metadata/README.md | N/A | N/A | Metadata management; policies not directly applicable |

### Contract Files (YAML)

| Contract | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| contracts/scd2/dim_customer_profile_columns.yaml | ⚠️ | SCD2, Hashing | Should add reference to STANDARD_SCD2_POLICY.md; hash algorithm should specify SHA256 not implicit |
| contracts/scd2/dim_investment_profile_version_columns.yaml | ⚠️ | SCD2, Hashing | Should add reference to STANDARD_SCD2_POLICY.md; change_detection notes SHA256 but should reference hashing_standards.md |
| contracts/customer/dim_customer_profile.yaml | ⚠️ | SCD2 | Should reference STANDARD_SCD2_POLICY.md |
| contracts/investment/dim_investment_profile_version.yaml | ⚠️ | SCD2 | Should reference STANDARD_SCD2_POLICY.md |
| contracts/INDEX.yaml | 📝 | All | Should add section for policies/standards with links to new policy files |

### Examples

| Document | Status | Policy Area | Notes |
|----------|--------|-------------|-------|
| examples/README.md | ⚠️ | All | Should reference policies for example code standards |
| examples/retail_sales_example.md | N/A | N/A | Example use case; policies not directly applicable unless it contains code |

## Priority Alignment Tasks

### High Priority (Required for Consistency)
1. ❌ **Update ADR-001-scd2-customer-profile.md**: Add explicit references to STANDARD_SCD2_POLICY.md and hashing_standards.md
2. ❌ **Update ADR-INV-001-investment-profile.md**: Add explicit references to STANDARD_SCD2_POLICY.md and hashing_standards.md
3. ❌ **Update contracts/scd2 YAML files**: Add policy_reference fields linking to STANDARD_SCD2_POLICY.md and hashing_standards.md
4. ❌ **Update docs/modeling_decisions.md**: Reference all three policies as authoritative sources

### Medium Priority (Improve Discoverability)
5. ⚠️ **Update docs/data-modeling/README.md**: Add policy references section; update SCD2 examples to reference policy
6. ⚠️ **Update docs/business/glossary.md**: Add policy-related terms and definitions
7. ⚠️ **Update CONTRIBUTING.md**: Add section on following naming conventions, hashing standards, and SCD2 policy
8. ⚠️ **Update contracts/INDEX.yaml**: Add policies/standards section

### Low Priority (Enhancement)
9. 📝 **Update docs/ai-methodology/README.md**: Reference policies as AI development anchors
10. 📝 **Update docs/copilot/ai_usage_guidelines.md**: Reference policies for AI-generated code
11. 📝 **Update docs/etl-elt/README.md**: Reference SCD2 policy and hashing standards for change detection
12. 📝 **Update docs/governance/README.md**: Reference policies as governance standards

## Verification Checklist

To verify alignment, check that each document:

- [ ] References the appropriate policy document(s) where applicable
- [ ] Uses consistent terminology from the policies (e.g., SHA256 not MD5, snake_case, surrogate key patterns)
- [ ] Links to policy documents in "Related Documents" or "References" sections
- [ ] Does not contain conflicting guidance (e.g., different hash algorithms, different naming conventions)
- [ ] Includes policy version number or date if referencing specific policy details

## Maintenance Notes

**Update Frequency**: This checklist should be reviewed whenever:
- A new policy is introduced or updated
- A new document is added to the repository
- An existing document undergoes major revision

**Ownership**: Data Architecture team maintains this checklist and coordinates alignment updates with document owners.

**Version**: 1.0 (2025-11-21)

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-11-21 | Initial alignment checklist created | Data Architecture |

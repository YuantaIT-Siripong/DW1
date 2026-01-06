# Deprecated Directory

**Purpose**: Historical artifacts from previous development iterations  
**Status**: **DEPRECATED** - Do not use for new development  
**Owner**: Data Architecture Team  
**Last Updated**: 2026-01-06

---

## ⚠️ IMPORTANT: This Directory is Deprecated

**All files in this directory are DEPRECATED and should NOT be used for new development.**

These files are kept for:
- Historical reference
- Migration context
- Understanding evolution of the repository
- Audit trail

---

## Deprecation Policy

### Why Keep Deprecated Files? 

1. **Historical Context**: Shows how architecture evolved
2. **Migration Reference**: Helps understand changes made
3. **Audit Trail**:  Maintains record of decisions
4. **Rollback Safety**: If needed, can reference old patterns

### What Belongs Here?

Files moved to this directory typically fall into these categories: 
- Old documentation superseded by newer versions
- Workflow documentation from earlier development phases
- Temporary documentation used during transitions
- Legacy seed files before YAML migration
- **Point-in-time assessments and analysis whose purpose is complete**

---

## Files Inventory

### Assessment & Analysis Documents (NEW - Added 2026-01-06)

#### ai_onboarding_gap_analysis.md
- **Type**: Gap Analysis (Point-in-Time Assessment)
- **Created**: ~2025-12
- **Deprecated**:  2026-01-06
- **Replaced By**:  
  - `docs/_ai-first-employee-boarding-guide/` (complete onboarding workflow)
  - `REPOSITORY_FILE_INDEX.md` (current repository state)
  - `STANDARDS_INDEX.md` (complete standards inventory)
- **Purpose**: Initial gap analysis for AI agent onboarding readiness
- **Why Deprecated**:  Gaps identified have been addressed; repository is now production-ready

#### ai_onboarding_readiness_assessment.md
- **Type**: Readiness Assessment (Point-in-Time)
- **Created**: ~2025-12
- **Deprecated**: 2026-01-06
- **Replaced By**: 
  - `AI_CONTEXT.md` (current AI assistant reference)
  - `STANDARDS_INDEX.md` (complete standards)
  - Production-ready repository structure
- **Purpose**: Evaluated repository readiness for AI-assisted development
- **Why Deprecated**: Assessment completed; repository validated and in production use

#### documentation_assessment.md
- **Type**: Documentation Maturity Assessment (Point-in-Time)
- **Created**: ~2025-12
- **Deprecated**: 2026-01-06
- **Replaced By**: 
  - `REPOSITORY_FILE_INDEX.md` (complete file inventory with descriptions)
  - Individual standard documents in `docs/`
  - `README.md` (current documentation guide)
- **Purpose**: Assessed documentation completeness, organization, and quality
- **Why Deprecated**: Documentation is now mature and comprehensive; assessment purpose fulfilled

#### final_ai_onboarding_assessment.md
- **Type**: Final Comprehensive Assessment (Point-in-Time)
- **Created**: ~2025-12
- **Deprecated**:  2026-01-06
- **Replaced By**: 
  - Production-ready repository
  - `README.md` (getting started guide)
  - `docs/HOW_TO_REPLICATE_MODULE.md` (implementation guide)
- **Purpose**: Final validation before declaring repository production-ready
- **Why Deprecated**:  Validation completed; repository in production use; assessment archived

### Module Documentation (NEW - Added 2026-01-06)

#### investment_profile_implementation_summary.md
- **Type**: Implementation Summary (Legacy Format)
- **Created**: ~2025-11
- **Deprecated**: 2026-01-06
- **Replaced By**: 
  - `docs/business/modules/investment_profile_module.md` (18-section complete specification)
  - `docs/HOW_TO_REPLICATE_MODULE.md` (implementation guide)
  - `docs/MODULE_DEVELOPMENT_CHECKLIST.md` (validation checklist)
- **Purpose**: Summarized Investment Profile module implementation details
- **Why Deprecated**: Summary documents now integrated into main module specifications; separate summaries no longer needed or maintained

### Workflow & Process Documentation

#### STATUS.md
- **Type**: Development Status (Historical)
- **Created**: Earlier phase
- **Deprecated**: 2025-12
- **Replaced By**: Current phase documentation in main docs/
- **Purpose**: Tracked development status in earlier iteration
- **Why Deprecated**: Newer status tracking in place

#### WORKFLOW.md
- **Type**: Workflow Documentation (Historical)
- **Created**: Earlier phase
- **Deprecated**: 2025-12
- **Replaced By**: docs/_ai-first-employee-boarding-guide/
- **Purpose**: Old workflow for AI-assisted development
- **Why Deprecated**:  Replaced by structured 10-step boarding guide

#### THREAD_HANDOVER.md
- **Type**: AI Thread Handover Procedure (Historical)
- **Created**: Earlier phase
- **Deprecated**:  2025-12
- **Replaced By**: AI_CONTEXT.md + CONTEXT_MANIFEST.yaml
- **Purpose**: How to hand off context between AI conversations
- **Why Deprecated**: Better context loading mechanism established

#### CHANGES_SUMMARY.md
- **Type**: Change Log (Historical)
- **Created**: Earlier phase
- **Deprecated**: 2025-12
- **Purpose**: Summarized changes in earlier iteration
- **Why Deprecated**: Git history provides complete change log

#### GAP_ANALYSIS.md
- **Type**: Gap Analysis (Historical)
- **Created**: Earlier phase
- **Deprecated**: 2026-01
- **Replaced By**: docs/AI_ONBOARDING_GAP_ANALYSIS.md → ai_onboarding_gap_analysis.md (now also in this directory)
- **Purpose**: Identified documentation gaps
- **Why Deprecated**: Superseded by comprehensive new gap analysis (which itself is now deprecated after completion)

### Data Files (seeds/)

#### seeds/company/*.csv
- **Type**: dbt Seed Files (Historical)
- **Created**: Earlier phase
- **Deprecated**: 2025-11
- **Replaced By**: enumerations/*.yaml (YAML-based enumerations)
- **Purpose**: Lookup table data for company domain
- **Why Deprecated**: Migration from CSV seeds to YAML enumerations
- **Files**:
  - dim_funding_source.csv
  - dim_industry.csv
  - dim_investment_objective.csv
  - dim_legal_form.csv

---

## Migration Context

### Assessment Phase → Production Readiness (NEW - 2025-12 → 2026-01-06)

**Timeline**: December 2025 → January 2026

**The Journey**:
1. **Initial Assessment** (2025-12): Identified gaps in documentation, standards, and AI readiness
2. **Gap Remediation** (2025-12): Created missing standards, examples, templates, and guides
3. **Documentation Maturity** (2025-12): Achieved comprehensive documentation coverage
4. **Final Validation** (2025-12): Confirmed repository production-ready for AI-assisted development
5. **Deprecation** (2026-01-06): Assessment documents archived; their work is complete

**Key Improvements Delivered**:
- ✅ Complete AI-first onboarding workflow (`docs/_ai-first-employee-boarding-guide/`)
- ✅ Comprehensive file index with descriptions (`REPOSITORY_FILE_INDEX.md`)
- ✅ All standards documented and indexed (`STANDARDS_INDEX.md`)
- ✅ Module replication guide (`docs/HOW_TO_REPLICATE_MODULE.md`)
- ✅ dbt macro documentation (`dbt/macros/README.md`)
- ✅ Complete customer profile reference implementation
- ✅ Policy alignment checklist
- ✅ Development checklist

**Outcome**: Repository validated as production-ready for AI-assisted module development

**Why These Assessments Are Now Deprecated**:
- They are **point-in-time snapshots** that served their purpose
- The **gaps they identified have been addressed**
- **Current state** is documented in production files
- Keeping them active would be misleading (they show old gaps, not current reality)
- Historical value preserved by archiving here

### CSV Seeds → YAML Enumerations

**Timeline**: 2025-11

**Old Pattern**:
```
deprecated/seeds/company/dim_industry.csv
  ↓ dbt seed
dbt/seeds/reference/industry.csv
  ↓ loaded as table
gold.dim_industry (lookup dimension)
```

**New Pattern**:
```
enumerations/company_industry.yaml
  ↓ reference in validation
Direct VARCHAR codes in dimensions (no lookup table)
```

**Rationale**: 
- Simplifies queries (no JOIN needed)
- Easier to maintain (YAML version control)
- Self-documenting (YAML structure clearer than CSV)
- Consistent with enumeration pattern

### Old Workflow → New Boarding Guide

**Timeline**: 2025-12

**Old**: Informal workflow in WORKFLOW.md  
**New**: Structured 10-step process in docs/_ai-first-employee-boarding-guide/

**Improvements**:
- Explicit steps with validation checkpoints
- Standard file generation sequence
- Comprehensive validation checklist
- Expected outputs documented

---

## What NOT to Use

**DO NOT**:
- ❌ Copy patterns from files in this directory
- ❌ Reference these files in new documentation
- ❌ Use CSV seed approach for new enumerations
- ❌ Follow old workflow patterns
- ❌ Treat assessment documents as current repository state
- ❌ Use implementation summary format (now integrated into module specs)
- ❌ Reference gap analyses as if gaps still exist (they've been resolved)

**INSTEAD**:
- ✅ Use current documentation in docs/
- ✅ Follow AI-first employee boarding guide
- ✅ Use YAML enumerations
- ✅ Follow ARCHITECTURAL_CONSTRAINTS.md
- ✅ Reference `REPOSITORY_FILE_INDEX.md` for current state
- ✅ Use main module specification documents (e.g., `customer_module.md`)
- ✅ Check `STANDARDS_INDEX.md` for all current standards

---

## Current Equivalents (NEW SECTION)

If you're looking for current information, use these active documents:

### For AI Agent Onboarding
- **Quick Start**:  `README.md`
- **AI Context**: `AI_CONTEXT.md` 
- **Standards Index**: `STANDARDS_INDEX.md`
- **Complete File Inventory**: `REPOSITORY_FILE_INDEX.md`
- **Onboarding Workflow**: `docs/_ai-first-employee-boarding-guide/` (10-step process)
- **Module Replication**:  `docs/HOW_TO_REPLICATE_MODULE.md`
- **Development Checklist**: `docs/MODULE_DEVELOPMENT_CHECKLIST. md`
- **Policy Validation**: `docs/POLICY_ALIGNMENT_CHECKLIST.md`

### For Module Development
- **Reference Implementation**: `docs/business/modules/customer_module.md` ⭐ (31 attributes, 18 sections)
- **Investment Profile**: `docs/business/modules/investment_profile_module.md`
- **Company Profile**: `docs/business/modules/company_module.md`
- **Implementation Guide**: `docs/HOW_TO_REPLICATE_MODULE.md`

### For Standards & Policies
- **SCD2 Policy**: `contracts/scd2/STANDARD_SCD2_POLICY.md` (authoritative)
- **Hashing Standards**: `docs/data-modeling/hashing_standards.md` (SHA256)
- **Naming Conventions**: `docs/data-modeling/naming_conventions.md` (snake_case/camelCase)
- **File/Folder Naming**: `docs/FOUNDATION_NAMING_CONVENTIONS.md`
- **dbt Macros**: `dbt/macros/README.md` (complete macro guide)

### For Repository Organization
- **File Index**: `REPOSITORY_FILE_INDEX.md` (every file documented)
- **Standards Index**: `STANDARDS_INDEX.md` (all standards listed)
- **Context Manifest**: `CONTEXT_MANIFEST.yaml` (machine-readable inventory)

---

## If You Need Old Pattern

If you absolutely need to understand old patterns:

1. **Read for context only** - Don't implement
2. **Check replacement** - What superseded it? 
3. **Understand "why"** - Why was it changed? 
4. **Follow new pattern** - Implement the new way

**Example**: 
- ❌ Don't copy workflow from `WORKFLOW.md`
- ✅ Instead, understand it was informal and replaced by structured 10-step guide
- ✅ Use `docs/_ai-first-employee-boarding-guide/` for current workflow

---

## Cleanup Policy

### When to Remove Files

Files may be permanently removed from this directory when: 
1. No longer needed for historical reference (> 2 years old)
2. No migration dependencies remain
3. All stakeholders confirm safe to remove
4. Documented in removal ADR

### Before Removing

1. Verify no dependencies in active code
2. Check if migration documentation needs update
3. Archive externally if needed
4. Document removal rationale

---

## Related Documentation

- `docs/migrations/CURATED_TO_GOLD_MIGRATION.md` - Schema migration
- `docs/_ai-first-employee-boarding-guide/` - Current AI workflow
- `enumerations/README.txt` - Current enumeration approach
- `REPOSITORY_FILE_INDEX.md` - Complete file inventory
- `AI_CONTEXT.md` - AI agent reference guide
- `STANDARDS_INDEX.md` - Master standards index

---

## Questions?

**Q**: Can I use STATUS.md template?  
**A**: No, use current project management tools. 

**Q**: Are CSV seeds still supported?  
**A**: Technically yes for backward compatibility, but use YAML for new enumerations. 

**Q**: Can I copy patterns from WORKFLOW.md?  
**A**: No, use docs/_ai-first-employee-boarding-guide/ instead.

**Q**: How do I know what replaced a deprecated file?  
**A**: Check "Replaced By" in inventory above or ask Data Architecture Team.

**Q**: Why are assessment documents deprecated if they're useful?  (NEW)  
**A**: They are **point-in-time snapshots**.  Their value was identifying gaps during development. Now that gaps are addressed, they're archived as historical context.  **Current state** is in production documentation, not in these old assessments.

**Q**: Should I reference investment_profile_implementation_summary.md?  (NEW)  
**A**: No, use `docs/business/modules/investment_profile_module.md` instead. Summary documents are now integrated into main module specifications (18-section format).

**Q**: Are the gaps mentioned in ai_onboarding_gap_analysis.md still open? (NEW)  
**A**: No!  All identified gaps have been addressed. The repository is now production-ready.  See `REPOSITORY_FILE_INDEX.md` and `STANDARDS_INDEX.md` for current complete state.

---

## Change Log (UPDATED)

| Date | Files Added | Reason |
|------|-------------|--------|
| Earlier | STATUS.md, WORKFLOW.md, THREAD_HANDOVER.md, CHANGES_SUMMARY.md | Initial deprecated files |
| 2025-11 | seeds/company/*.csv | CSV to YAML migration |
| 2026-01 | GAP_ANALYSIS.md | Superseded by new analysis |
| **2026-01-06** | **ai_onboarding_gap_analysis.md** | **Assessment complete; gaps resolved; production ready** |
| **2026-01-06** | **ai_onboarding_readiness_assessment.md** | **Readiness confirmed; repository validated** |
| **2026-01-06** | **documentation_assessment.md** | **Documentation now mature and comprehensive** |
| **2026-01-06** | **final_ai_onboarding_assessment.md** | **Final validation complete; repository in production** |
| **2026-01-06** | **investment_profile_implementation_summary.md** | **Summary format deprecated; integrated into main module spec** |

---

**Last Updated**: 2026-01-06  
**Maintained By**: Data Architecture Team  
**Policy**: Keep for 2 years minimum, then review for removal
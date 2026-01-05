# Deprecated Directory

**Purpose**: Historical artifacts from previous development iterations  
**Status**: **DEPRECATED** - Do not use for new development  
**Owner**: Data Architecture Team  
**Last Updated**: 2026-01-05

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
3. **Audit Trail**: Maintains record of decisions
4. **Rollback Safety**: If needed, can reference old patterns

### What Belongs Here?

Files moved to this directory typically fall into these categories:
- Old documentation superseded by newer versions
- Workflow documentation from earlier development phases
- Temporary documentation used during transitions
- Legacy seed files before YAML migration

---

## Files Inventory

### Documentation Files

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
- **Why Deprecated**: Replaced by structured 10-step boarding guide

#### THREAD_HANDOVER.md
- **Type**: AI Thread Handover Procedure (Historical)
- **Created**: Earlier phase
- **Deprecated**: 2025-12
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
- **Replaced By**: docs/AI_ONBOARDING_GAP_ANALYSIS.md
- **Purpose**: Identified documentation gaps
- **Why Deprecated**: Superseded by comprehensive new gap analysis

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

**INSTEAD**:
- ✅ Use current documentation in docs/
- ✅ Follow AI-first employee boarding guide
- ✅ Use YAML enumerations
- ✅ Follow ARCHITECTURAL_CONSTRAINTS.md

---

## If You Need Old Pattern

If you absolutely need to understand old patterns:

1. **Read for context only** - Don't implement
2. **Check replacement** - What superseded it?
3. **Understand "why"** - Why was it changed?
4. **Follow new pattern** - Implement the new way

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
- `docs/AI_ONBOARDING_GAP_ANALYSIS.md` - Current gap analysis
- `docs/_ai-first-employee-boarding-guide/` - Current workflow
- `enumerations/README.txt` - Current enumeration approach

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

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team  
**Policy**: Keep for 2 years minimum, then review for removal

# AI-First Onboarding - Quick Start Guide

**Purpose**: Quick reference for AI agents starting a new conversation thread  
**Status**: READY ✅  
**Last Updated**: 2026-01-05

---

## 🚀 Quick Start for AI Agents

### Step 1: Load Foundation Documents (5 minutes)

Load these documents in this order:

1. **README.md** - Project overview and architecture
2. **AI_CONTEXT.md** - Quick reference patterns and standards
3. **REPOSITORY_FILE_INDEX.md** - Complete file inventory (205 files)
4. **docs/architecture/ARCHITECTURAL_CONSTRAINTS.md** - All architectural rules
5. **contracts/scd2/STANDARD_SCD2_POLICY.md** - SCD2 rules
6. **docs/data-modeling/naming_conventions.md** - Naming standards
7. **docs/data-modeling/hashing_standards.md** - Hashing standards

**Result**: You now have complete context to work independently.

### Step 2: Understand Your Task

**For Module Creation**:
- Load: `docs/HOW_TO_REPLICATE_MODULE.md`
- Load: `docs/business/modules/customer_module.md` (reference pattern)
- Follow: `docs/_ai-first-employee-boarding-guide/` (10-step process)

**For Code Changes**:
- Use `REPOSITORY_FILE_INDEX.md` to locate relevant files
- Check `ARCHITECTURAL_CONSTRAINTS.md` for rules
- Reference Customer Profile pattern as template

### Step 3: Validate Your Work

**Before Committing**:
- Run through: `docs/MODULE_REPLICATION_VALIDATION.md` (47 checkpoints)
- Verify: All architectural constraints followed
- Check: Alignment with Customer Profile pattern

---

## 📋 Critical Rules (Must Know)

### Schema Naming
- ✅ Use `gold` schema (NOT `curated`)
- ✅ Use `silver` schema for cleaned data
- ✅ Use `bronze` schema for raw landing

### Data Types
- ✅ Natural keys = BIGINT (NOT STRING)
- ✅ Timestamps = TIMESTAMP (NOT DATE)
- ✅ Booleans = BOOLEAN (NOT CHAR)
- ✅ Enumerations = VARCHAR with direct codes (NOT INT FK)

### SCD2 Requirements
- ✅ Must have 6 required indexes (see ARCHITECTURAL_CONSTRAINTS.md)
- ✅ effective_end_ts = NULL for current (NOT '9999-12-31')
- ✅ Use LEAD() for effective_end_ts calculation
- ✅ Use ROW_NUMBER() for version_num

### Hash Computation
- ✅ Include all Type 2 attributes
- ❌ Exclude *_other freetext fields
- ❌ Exclude ETL metadata
- ❌ Exclude temporal columns
- ❌ Exclude surrogate keys

### Enumeration Pattern
- ✅ All enumerations have YAML files
- ✅ Enumerations with "OTHER" have *_other freetext field
- ❌ No lookup dimensions (deprecated pattern)

---

## 📂 Key Reference Files

### Templates (Copy & Customize)
- `docs/business/modules/customer_module.md` - Module specification
- `contracts/gold/dim_customer_profile.yaml` - SCD2 dimension contract
- `db/gold/dim_customer_profile.sql` - SCD2 dimension DDL
- `dbt/models/gold/dim_customer_profile.sql` - SCD2 dimension dbt

### Standards
- `ARCHITECTURAL_CONSTRAINTS.md` - All rules explicit
- `contracts/scd2/STANDARD_SCD2_POLICY.md` - SCD2 policy
- `docs/data-modeling/naming_conventions.md` - Naming
- `docs/data-modeling/hashing_standards.md` - Hashing

### Validation
- `MODULE_REPLICATION_VALIDATION.md` - 47 validation points
- `MODULE_DEVELOPMENT_CHECKLIST.md` - Complete checklist
- `POLICY_ALIGNMENT_CHECKLIST.md` - Policy compliance

---

## 🎯 Success Criteria

You're successful if:
- ✅ No clarification questions needed
- ✅ Module aligns 100% with Customer Profile
- ✅ Passes all 47 validation points
- ✅ Follows all architectural constraints
- ✅ Documentation complete

---

## ⚠️ Prohibited Patterns

Never do these:
- ❌ Use `curated` schema
- ❌ Create lookup dimensions for enumerations
- ❌ Use STRING for entity IDs
- ❌ Use '9999-12-31' for effective_end_ts
- ❌ Include *_other fields in hash
- ❌ Put star schema in Silver layer
- ❌ Missing any of 6 required SCD2 indexes

---

## 📊 Repository Status

**Files Documented**: 205/205 (100%)  
**Readiness**: 95% (READY ✅)  
**Last Updated**: 2026-01-05

---

## 🔗 Quick Links

**Getting Started**:
- [README.md](../README.md)
- [AI_CONTEXT.md](../AI_CONTEXT.md)

**Core Documentation**:
- [Repository File Index](../REPOSITORY_FILE_INDEX.md)
- [Architectural Constraints](architecture/ARCHITECTURAL_CONSTRAINTS.md)
- [Module Replication Validation](MODULE_REPLICATION_VALIDATION.md)

**Guides**:
- [How to Replicate Module](HOW_TO_REPLICATE_MODULE.md)
- [Module Development Checklist](MODULE_DEVELOPMENT_CHECKLIST.md)
- [AI-First Employee Boarding Guide](_ai-first-employee-boarding-guide/)

**Reference Module**:
- [Customer Module Specification](business/modules/customer_module.md)

**Assessment**:
- [Gap Analysis](AI_ONBOARDING_GAP_ANALYSIS.md)
- [Readiness Assessment](AI_ONBOARDING_READINESS_ASSESSMENT.md)

---

**You're Ready! 🚀**

With these documents loaded, you have complete context to:
- Create new modules aligned with Customer Profile
- Make code changes following all standards
- Validate your work independently
- Work without human clarification

**Questions?** Everything is documented. Use REPOSITORY_FILE_INDEX.md to find what you need.

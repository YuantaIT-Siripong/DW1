# AI-First Employee Boarding Guide

**Purpose**: Step-by-step workflow for AI agents to create new modules  
**Target Audience**: AI agents, automation tools  
**Reference Module**: Customer Profile (SCD Type 2)  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains a **10-step workflow** that enables AI agents to create new data warehouse modules from business requirements with zero human intervention. The workflow is fully parameterized and can be used for any module type.

---

## Workflow Steps

### Loading and Preparation

#### Step 010: Load Repository Context
**File**: `010_load_repositories_context_into_ai.md`  
**Purpose**: Load all foundation documents into AI context  
**Input**: None (fresh AI conversation)  
**Output**: AI confirms understanding of patterns  
**Parameterization**: ✅ Fully generic

**Key Documents to Load**:
1. README.md - Project overview
2. AI_CONTEXT.md - Quick reference
3. STANDARDS_INDEX.md - Standards index
4. ARCHITECTURAL_CONSTRAINTS.md - All rules
5. REPOSITORY_FILE_INDEX.md - File locations
6. All standard documents

#### Step 011: Expected Result
**File**: `011_expected_result_from_ai.md`  
**Purpose**: Validation checkpoint - AI confirms readiness  
**Parameterization**: ✅ Fully generic

### Requirements Analysis

#### Step 020: Convert Requirements to Specification
**File**: `020_ai_converts_requirements.md`  
**Purpose**: Convert business requirements to structured specification  
**Input**: Business requirements (natural language)  
**Output**: Structured module specification  
**Parameterization**: ✅ Fully generic (uses `<ENTITY>` placeholders)

**Analysis Includes**:
- Entity classification
- Attribute analysis (Type 1 vs Type 2)
- Enumeration identification
- Multi-valued set identification
- Surrogate key pattern
- Hash computation specification

#### Step 021: Expected Result
**File**: `021_expected_result_from_ai.md`  
**Purpose**: Validation checkpoint - AI outputs structured spec  
**Parameterization**: ✅ Fully generic

### File Generation

#### Step 030: Generate Module Files
**File**: `030_ai_generate_module_files.md`  
**Purpose**: Generate all module artifacts (contracts, DDL, dbt)  
**Input**: Structured specification from Step 020  
**Output**: 9+ files (enumerations, contracts, DDL, dbt models)  
**Parameterization**: ⚠️ **Partially generic** (Customer examples as reference)

**Files Generated** (conditional based on module characteristics):
1. Enumeration YAML(s) - If enumerations exist
2. Bronze Contract
3. Bronze DDL
4. Silver Contract
5. Silver dbt Model
6. Gold Contract
7. Gold DDL
8. Gold dbt Model
9. Bridge Tables - If multi-valued sets exist

**Reference Examples Used**:
- Customer Profile (for all patterns)
- Can substitute with any completed module

#### Step 031: Generate Test Files
**File**: `031_ai_generate_module_files_test.md`  
**Purpose**: Generate test artifacts  
**Parameterization**: ✅ Generic

### Validation and Refinement

#### Step 040: Validate Against Standards
**File**: `040_ai_validates_against_standards.md`  
**Purpose**: Comprehensive validation checklist  
**Input**: Generated files from Step 030  
**Output**: Validation report with pass/fail for each check  
**Parameterization**: ✅ Fully generic

**Validation Categories**:
1. Naming Conventions (6 checks)
2. SCD2 Pattern (8 checks) - If SCD Type 2
3. Hash Computation (8 checks)
4. Required Indexes (6 checks) - For SCD2
5. Enumeration Pattern (5 checks)
6. Contract Alignment (5 checks)
7. dbt Model Structure (5 checks)
8. Documentation (2 checks)

#### Step 041: Fix Issues
**File**: `041_fix_issue.md`  
**Purpose**: Guidance for fixing validation failures  
**Parameterization**: ✅ Generic

#### Step 042: Re-validate
**File**: `042_re_validate.md`  
**Purpose**: Re-run validation after fixes  
**Parameterization**: ✅ Generic

### Reference Output

#### Step 100: Sample Output
**File**: `100_sample.md`  
**Purpose**: Example output showing expected results  
**Parameterization**: ⚠️ **Customer-specific** (can add more examples)

---

## Module Type Support

### Currently Documented

**SCD Type 2 Dimension** (Customer Profile):
- ✅ Complete workflow
- ✅ All 10 steps documented
- ✅ Reference example available

### To Be Added

**SCD Type 1 Dimension**:
- Differences from Type 2:
  - No versioning columns
  - No effective_*_ts
  - Simpler hash (no version detection)
  - 3 indexes instead of 6

**SCD Type 0 (Static) Dimension**:
- Differences:
  - No change tracking
  - No hash column
  - Simple primary key

**Fact Table**:
- Different file set:
  - No bridge tables
  - Fact-specific contracts
  - Measure definitions
  - Grain specification

---

## Parameterization Guide

### How to Use This Workflow

**For AI Agents**:
1. Start with Step 010 - Load all context
2. Follow steps sequentially (010 → 011 → 020 → 021 → 030 → 031 → 040 → 041/042)
3. At Step 020: Substitute business requirements
4. At Step 030: Use appropriate reference module (Customer Profile for SCD2)
5. At each checkpoint (011, 021): Self-validate before proceeding

**For New Module Types**:
1. Use Customer Profile as template for SCD Type 2
2. Adjust Step 030 for other module types:
   - Remove SCD2 columns for Type 1
   - Remove versioning for Type 0
   - Change file set for Fact tables

### Placeholder Syntax

Throughout the workflow, use these placeholders:

| Placeholder | Replace With | Example |
|-------------|--------------|---------|
| `<ENTITY_NAME>` | Entity name | `customer_profile`, `investment_profile` |
| `<DOMAIN>` | Domain name | `customer`, `investment`, `company` |
| `<entity>` | Entity (lowercase) | `customer`, `investment` |
| `<ENUMERATION_NAME>` | Enum name | `marital_status`, `occupation` |
| `<set>` | Set name | `income_source`, `investment_purpose` |

---

## Conditional File Generation Logic

### Decision Tree

```
START: Business Requirement
    ↓
Q1: Does entity have enumerations?
    YES → Generate enumeration YAML(s)
    NO  → Skip enumeration files
    ↓
Q2: What SCD Type?
    Type 0 → Generate without versioning
    Type 1 → Generate with simple overwrite pattern
    Type 2 → Generate with full SCD2 pattern (6 indexes)
    ↓
Q3: Does entity have multi-valued attributes?
    YES → Generate bridge tables
    NO  → Skip bridge tables
    ↓
Q4: Is this a fact table?
    YES → Use fact template instead of dimension
    NO  → Continue with dimension template
    ↓
END: Generate files based on decisions
```

### File Count Variations

| Module Type | Files Generated | Notes |
|-------------|-----------------|-------|
| **SCD Type 2 with Multi-Valued** | 9 files | Full set (enumerations + contracts + DDL + dbt + bridges) |
| **SCD Type 2 without Multi-Valued** | 7 files | No bridge tables |
| **SCD Type 1** | 7 files | No versioning columns, simpler validation |
| **SCD Type 0 (Static)** | 7 files | No change tracking at all |
| **Fact Table** | 5 files | Different template (no bridges) |

---

## SCD Type Decision Matrix

Use this matrix to determine SCD type during Step 020:

| Criterion | Type 0 | Type 1 | Type 2 | Type 3 |
|-----------|--------|--------|--------|--------|
| **Change Frequency** | Never/Rare | Changes | Changes | Changes |
| **History Requirement** | Not needed | Current only | Full history | Limited history |
| **Use Case** | Static reference | Current state | Full audit trail | Previous + current |
| **Examples** | Date dimension, Product categories | Customer email, phone | Customer marital status, occupation | Customer previous address |
| **Versioning** | No | No | Yes | Partial (1-2 previous) |
| **Complexity** | Low | Low | High | Medium |

**Recommendation for DW1**: 
- **Default to Type 2** for all master data (enables audit trail)
- **Use Type 1** only for non-critical attributes or `*_other` freetext
- **Type 0** for true static dimensions (rare)
- **Type 3** not currently implemented (use Type 2 instead)

---

## Validation Quick Reference

### Critical Validation Points

**Step 020 Output**:
- ✅ SCD type determined
- ✅ Type 1 vs Type 2 attributes classified
- ✅ Enumerations identified
- ✅ Multi-valued sets identified

**Step 030 Output**:
- ✅ File count matches expectations
- ✅ All file paths follow naming convention
- ✅ Reference examples appropriate for module type

**Step 040 Checks**:
- ✅ 100% validation pass rate
- ✅ All contracts match DDL
- ✅ All SCD2 requirements met (if Type 2)
- ✅ All indexes created

---

## Common Issues and Solutions

### Issue: Wrong SCD Type Selected
**Symptom**: Business needs history but Type 1 selected  
**Solution**: Re-run Step 020, reclassify as Type 2  
**Prevention**: Always question if history might be needed in future

### Issue: Missing Bridge Tables
**Symptom**: Multi-valued attribute in dimension table  
**Solution**: Identify multi-valued sets in Step 020, generate bridges in Step 030  
**Prevention**: Carefully analyze 1-to-many relationships

### Issue: Type 1 Attributes in Hash
**Symptom**: Spurious versioning on *_other field changes  
**Solution**: Exclude Type 1 attributes from profile_hash  
**Prevention**: Clear classification in Step 020

### Issue: Incomplete Validation
**Symptom**: Some validation checks skipped  
**Solution**: Run Step 040 comprehensively  
**Prevention**: Use checklist in 040, verify 100% completion

---

## Enhancement Recommendations

### Future Additions

1. **Module Type Templates**:
   - Add `030b_generate_type1_files.md`
   - Add `030c_generate_fact_files.md`
   - Add `030d_generate_bridge_only.md`

2. **Decision Matrices**:
   - Expand SCD type decision matrix with more examples
   - Add fact vs dimension decision tree
   - Add when to use bridge vs denormalize

3. **Validation Profiles**:
   - Create validation profile for Type 1 (fewer checks)
   - Create validation profile for Type 0 (minimal checks)
   - Create validation profile for Fact tables

4. **More Examples**:
   - Add Investment Profile example (Type 2)
   - Add Product Dimension example (Type 0/1)
   - Add Transaction Fact example

---

## Integration with Repository Standards

### Documents This Workflow Depends On

**Foundation** (loaded in Step 010):
- README.md
- AI_CONTEXT.md
- ARCHITECTURAL_CONSTRAINTS.md
- REPOSITORY_FILE_INDEX.md

**Standards** (referenced in Step 030):
- contracts/scd2/STANDARD_SCD2_POLICY.md
- docs/data-modeling/naming_conventions.md
- docs/data-modeling/hashing_standards.md
- docs/FOUNDATION_NAMING_CONVENTIONS.md

**Validation** (used in Step 040):
- docs/MODULE_DEVELOPMENT_CHECKLIST.md
- docs/MODULE_REPLICATION_VALIDATION.md
- docs/POLICY_ALIGNMENT_CHECKLIST.md

### Documents This Workflow Produces

**Module Artifacts**:
- Module specification: `docs/business/modules/<entity>_module.md`
- Enumeration YAMLs: `enumerations/<domain>_<enum>.yaml`
- Contracts: `contracts/{bronze,silver,gold}/<entity>*.yaml`
- DDL: `db/{bronze,silver,gold}/<entity>*.sql`
- dbt Models: `dbt/models/{silver,gold}/<entity>*.sql`

**Updates Required**:
- REPOSITORY_FILE_INDEX.md (add new files)
- CONTEXT_MANIFEST.yaml (add new module)

---

## Success Metrics

### Workflow Success Criteria

**Process Efficiency**:
- ✅ 100% of steps completed without human intervention
- ✅ Zero back-and-forth for clarification (if requirements clear)
- ✅ All validation checks pass on first or second attempt

**Output Quality**:
- ✅ All files match repository standards
- ✅ All contracts align with DDL
- ✅ All dbt models execute successfully
- ✅ Module aligns with Customer Profile patterns

**Documentation Quality**:
- ✅ Module specification complete
- ✅ All files documented in REPOSITORY_FILE_INDEX.md
- ✅ CONTEXT_MANIFEST.yaml updated

---

## Continuous Improvement

### Feedback Loop

**After Each Module**:
1. Review validation failures (Step 040)
2. Identify common mistakes
3. Update workflow to prevent recurrence
4. Add to validation checklist

**Quarterly Review**:
1. Review all modules created via this workflow
2. Identify patterns and anti-patterns
3. Update reference examples
4. Enhance documentation

---

## Related Documentation

- **Parent**: `docs/README.md`
- **Module Replication Guide**: `docs/HOW_TO_REPLICATE_MODULE.md`
- **Module Development Checklist**: `docs/MODULE_DEVELOPMENT_CHECKLIST.md`
- **Module Replication Validation**: `docs/MODULE_REPLICATION_VALIDATION.md`
- **Architectural Constraints**: `docs/architecture/ARCHITECTURAL_CONSTRAINTS.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team  
**Version**: 2.0 (Parameterized)

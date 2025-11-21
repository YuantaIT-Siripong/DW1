# Data Quality & Reliability Framework (Stub - Phase 1)

## Purpose
This document outlines the planned unified Data Quality & Reliability Framework for DW1. This framework will standardize component metrics across all modules and establish a consistent taxonomy for derived quality scoring.

**Status**: **PLANNED** - Components defined but not yet implemented. Implementation planned for gold layer in future phase.

## Background
Gap 4 identified fragmentation in quality metrics:
- Customer module: Bespoke completeness KPI formula (conceptual, not stored)
- Investment module: DataQualityScore and ProfileReliabilityScore were stored as SCD2 attributes without shared taxonomy

**Resolution**: Remove derived scoring fields from SCD2 dimensions (silver layer); implement unified framework in gold layer with shared component metrics and taxonomy.

## Core Principles
1. **Separation of Concerns**: Base attributes stored in SCD2 dimensions; derived quality metrics computed in gold layer
2. **Standardized Components**: Shared taxonomy of quality metrics across all modules
3. **Reproducibility**: Metrics recomputable from base attributes + versioned formulas
4. **Auditability**: Formula versions tracked; historical scores reproducible
5. **No Version Pollution**: Quality metrics excluded from SCD2 hash logic to prevent spurious versioning

## Planned Component Metrics

### 1. dq_completeness_score
**Definition**: Proportion of mandatory attributes populated for a given profile or entity version.

**Formula** (planned):
```
dq_completeness_score = count(populated_mandatory_fields) / count(total_mandatory_fields)
```

**Range**: 0.0 to 1.0

**Application Scope**:
- Customer profiles
- Investment profiles
- Company profiles
- Any entity with mandatory attribute requirements

**Future Implementation Location**: `gold.mart_profile_quality` (or similar gold layer view/table)

---

### 2. dq_consistency_score
**Definition**: Measure of logical consistency between related attributes within a profile.

**Examples of Consistency Rules**:
- Investment: If RiskLevelCode = CONSERVATIVE, then ComplexProductAllowed should be FALSE
- Investment: If Objective = SPECULATION, then RiskLevelCode should be SPECULATIVE or AGGRESSIVE
- Customer: If age < 18, then certain product entitlements must be restricted

**Formula** (planned):
```
dq_consistency_score = count(passed_consistency_rules) / count(applicable_consistency_rules)
```

**Range**: 0.0 to 1.0

**Penalty Approach**: Each failed rule reduces score by a configurable weight.

**Future Implementation Location**: Gold layer with rule engine

---

### 3. dq_timeliness_score
**Definition**: Measure of data freshness relative to expected review cycles or update cadences.

**Formula** (planned):
```
dq_timeliness_score = 1.0 - (age_penalty_factor)

where:
  age_penalty_factor = CASE
    WHEN days_since_last_review <= expected_review_cycle_days THEN 0.0
    WHEN days_since_last_review > expected_review_cycle_days + grace_period THEN 1.0
    ELSE (days_since_last_review - expected_review_cycle_days) / grace_period
  END
```

**Range**: 0.0 to 1.0

**Application Examples**:
- Investment profiles: Penalty if LastRiskReviewTs exceeds ReviewCycle threshold
- Customer profiles: Penalty if profile attributes stale beyond expected update frequency

**Future Implementation Location**: Gold layer with configurable thresholds per profile type

---

### 4. dq_regulatory_penalty_factor
**Definition**: Penalty factor for regulatory risk indicators (PEP flags, sanction screening failures, KYC/AML high risk ratings).

**Formula** (planned):
```
dq_regulatory_penalty_factor = 
  pep_penalty + 
  sanction_penalty + 
  kyc_risk_penalty + 
  aml_risk_penalty

where each component is a configurable weight (e.g., 0.05 to 0.20) if the risk flag is active.
```

**Range**: 0.0 to 1.0 (capped; sum of penalties)

**Application**: Investment profiles, customer profiles (compliance-sensitive entities)

**Future Implementation Location**: Gold layer compliance view

---

### 5. reliability_score
**Definition**: Composite reliability measure combining completeness, consistency, timeliness, and regulatory penalty factors.

**Formula** (planned):
```
reliability_score = 
  dq_completeness_score * 
  dq_consistency_score * 
  dq_timeliness_score * 
  (1.0 - dq_regulatory_penalty_factor) *
  (1.0 - vulnerability_penalty_if_unknown_reason)

where:
  vulnerability_penalty_if_unknown_reason = 
    CASE 
      WHEN VulnerableInvestorFlag = TRUE AND VulnerabilityReasonCode = 'UNKNOWN' 
      THEN 0.10 
      ELSE 0.0 
    END
```

**Range**: 0.0 to 1.0

**Application Scope**: Customer profiles, investment profiles, company profiles

**Future Implementation Location**: `gold.mart_profile_quality` or module-specific gold views

---

## Excluded from SCD2 Dimensions
All derived scoring and quality metrics are **explicitly excluded** from SCD2 dimension storage and hash logic:
- Prevents spurious versioning when scores recalculated without business attribute changes
- Ensures SCD2 versions driven solely by business state changes
- Scores remain reproducible from base attributes + formula version

**SCD2 Exclusion Policy**: See [Standard SCD2 Policy - Derived Metrics Exclusion](../../contracts/scd2/STANDARD_SCD2_POLICY.md#derived-metrics-exclusion)

## Future Implementation Plan

### Phase 2: Gold Layer Implementation (Planned)
1. **Create gold layer view/table**: `gold.mart_profile_quality`
   - Join to SCD2 dimensions (customer, investment, company)
   - Compute all component metrics
   - Store reliability_score as final composite

2. **Versioned Formula Registry**:
   - Track formula versions with effective dates
   - Enable historical score reproducibility
   - ADR: ADR-DQ-Framework (to be created)

3. **dbt/SQL Tests**:
   - Test component metric calculations
   - Validate score ranges (0.0 to 1.0)
   - Consistency rule validation

4. **Governance**:
   - Reliability formula change control process
   - Threshold/weight tuning governance
   - Exception handling (manual overrides)

### Migration Guidance
**For Downstream Consumers**:
- Queries currently referencing `data_quality_score` or `profile_reliability_score` from `dim_investment_profile_version` will fail after removal.
- **Action Required**: Update queries to reference future gold layer view `gold.mart_profile_quality` once implemented.
- **Interim Workaround**: If scores needed before gold layer ready, compute ad-hoc using base attributes + component formulas outlined in this document.

## Related Documents
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md)
- [Investment Profile Module Spec](../business/modules/investment_profile_module.md)
- [Customer Module Spec](../business/modules/customer_module.md)
- [Data Quality Rules](../business/data_quality_rules.md)
- [AI Context](../../AI_CONTEXT.md)

## Change Control
- Formula weight/threshold changes require data governance approval
- Component metric additions require ADR + contract update
- Formula version bumps require documentation in versioned formula registry (future)

## Glossary
- **SCD2**: Slowly Changing Dimension Type 2 (versioned dimensions)
- **Gold Layer**: Presentation/mart layer with aggregated, derived, and analytical datasets
- **Silver Layer**: Conformed, cleansed dimension and fact tables (current SCD2 location)
- **Component Metric**: Individual quality measurement (completeness, consistency, timeliness, etc.)
- **Composite Score**: Aggregated metric combining multiple component metrics (e.g., reliability_score)

---

**Document Version**: 0.1  
**Status**: Stub - Planned for Future Implementation  
**Author**: Data Architecture  
**Date**: 2025-11-21

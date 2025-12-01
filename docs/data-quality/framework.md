# Data Quality & Reliability Framework

## Purpose
This document outlines the Data Quality & Reliability Framework for DW1, covering both implemented (Phase 1) and planned (Phase 2) capabilities.  This framework standardizes component metrics across all modules and establishes a consistent taxonomy for data quality measurement.

## Implementation Status

### Phase 1: Silver Layer Data Quality (✅ IMPLEMENTED)

**Module**: Customer Profile  
**Implementation**: `silver. customer_profile_standardized`  
**Status**: Complete (2025-12-01)

**Implemented Features**:
- 12 validation flags for enumeration and data integrity
- Composite data quality score (0.0 to 1.0)
- Data quality status classification (5 categories)
- Hash computation for change detection (profile hash, set hashes)

See [Phase 1 Implementation Details](#phase-1-silver-layer-implementation) below. 

---

### Phase 2: Gold Layer Composite Reliability (📋 PLANNED)

**Scope**: Cross-module unified framework  
**Implementation**: `gold.mart_profile_quality` (planned)  
**Status**: Specification complete; implementation pending

**Planned Features**:
- Component metrics: completeness, consistency, timeliness, regulatory penalty
- Composite reliability score combining all components
- Versioned formula registry for reproducibility
- Cross-module standardization

See [Phase 2 Planned Implementation](#phase-2-gold-layer-composite-reliability) below.

---

## Background

### Gap Identified (Pre-Phase 1)
Gap 4 identified fragmentation in quality metrics:
- Customer module: Bespoke completeness KPI formula (conceptual, not stored)
- Investment module: DataQualityScore and ProfileReliabilityScore were stored as SCD2 attributes without shared taxonomy

### Resolution Strategy
1. **Phase 1 (Silver)**: Remove derived scoring fields from SCD2 dimensions; implement enumeration validation flags and basic DQ scoring in Silver layer
2. **Phase 2 (Gold)**: Implement unified framework in gold layer with shared component metrics and taxonomy

---

## Core Principles

1. **Separation of Concerns**: Base attributes stored in SCD2 dimensions; derived quality metrics computed in Silver (Phase 1) or Gold (Phase 2)
2. **Standardized Components**: Shared taxonomy of quality metrics across all modules
3. **Reproducibility**: Metrics recomputable from base attributes + versioned formulas
4. **Auditability**: Formula versions tracked; historical scores reproducible
5. **No Version Pollution**: Quality metrics excluded from SCD2 hash logic to prevent spurious versioning

---

## Phase 1: Silver Layer Implementation

### Customer Profile Module (✅ Complete)

**Table**: `silver.customer_profile_standardized`  
**DDL**: `db/silver/customer_profile_standardized.sql`  
**Contract**: `contracts/silver/customer_profile_standardized.yaml`

### Data Quality Validation Flags (12 Flags)

| Flag Name | Purpose | Validation Rule |
|-----------|---------|-----------------|
| `is_valid_person_title` | Enumeration check | Code in enumerations/customer_person_title.yaml |
| `is_valid_marital_status` | Enumeration check | Code in enumerations/customer_marital_status.yaml |
| `is_valid_nationality` | Enumeration check | Code in enumerations/customer_nationality.yaml |
| `is_valid_occupation` | Enumeration check | Code in enumerations/customer_occupation. yaml |
| `is_valid_education_level` | Enumeration check | Code in enumerations/customer_education_level.yaml |
| `is_valid_business_type` | Enumeration check | Code in enumerations/customer_business_type.yaml |
| `is_valid_total_asset` | Enumeration check | Code in enumerations/customer_total_asset_bands.yaml |
| `is_valid_monthly_income` | Enumeration check | Code in enumerations/customer_monthly_income_bands.yaml |
| `is_valid_income_country` | Enumeration check | Code in enumerations/customer_income_country.yaml |
| `is_valid_birthdate` | Business rule | birthdate IS NOT NULL AND birthdate <= CURRENT_DATE AND age BETWEEN 18 AND 120 |
| `is_valid_source_of_income_list` | Set validation | All codes in enumerations/customer_source_of_income.yaml |
| `is_valid_purpose_of_investment_list` | Set validation | All codes in enumerations/customer_purpose_of_investment.yaml |

### Composite Data Quality Score

**Formula**:
```sql
data_quality_score = COUNT(TRUE validation flags) / 12. 0
```

**Range**: 0.0000 to 1.0000 (DECIMAL(5,4))

**Example**:
- 12 TRUE flags = 1.0000 (perfect quality)
- 10 TRUE flags = 0.8333 (good quality)
- 6 TRUE flags = 0.5000 (marginal quality)

### Data Quality Status Classification

**Column**: `_silver_dq_status VARCHAR(50)`

| Status Code | Condition | Meaning |
|-------------|-----------|---------|
| `VALID` | All enumeration flags TRUE, birthdate valid, no "OTHER" values | Perfect quality |
| `VALID_WITH_OTHER` | All enumeration flags TRUE, birthdate valid, has "OTHER" values | Good quality with freetext |
| `INVALID_ENUMERATION` | At least one enumeration flag FALSE | Enumeration code not recognized |
| `INVALID_BIRTHDATE` | Birthdate validation failed | Age out of range or NULL |
| `MULTIPLE_ISSUES` | Multiple validation failures | Requires data correction |

### Hash Computation (Change Detection)

**Three hash types computed in Silver**:

1. **Set Hashes** (for multi-valued attributes):
   ```sql
   source_of_income_set_hash = SHA256(sorted, normalized codes)
   purpose_of_investment_set_hash = SHA256(sorted, normalized codes)
   ```

2. **Profile Hash** (for SCD2 change detection):
   ```sql
   profile_hash = SHA256(17 version-driving attributes)
   ```
   - See: `docs/data-modeling/hashing_standards.md`
   - Helper function: `silver.compute_profile_hash()`

### Exclusion from Gold SCD2 Dimensions

**CRITICAL**: Data quality scores and flags are **NOT** propagated to `curated.dim_customer_profile`:

**Excluded Columns**:
- All `is_valid_*` flags (12 columns)
- `data_quality_score`
- `_silver_dq_status`
- `_silver_processed_ts`

**Reason**: Prevent version pollution.  Changes to DQ scores should NOT create new SCD2 versions in Gold layer.  Only business attribute changes drive versioning.

**Gold Dimension Contains**:
- Business attributes (31 columns)
- Set hashes (for change detection)
- Profile hash (for change detection)
- SCD2 metadata (version_num, effective_start_ts, effective_end_ts, is_current)

**Reference**: [STANDARD_SCD2_POLICY. md](../../contracts/scd2/STANDARD_SCD2_POLICY. md#derived-metrics-exclusion)

---

## Phase 2: Gold Layer Composite Reliability

**Status**: 📋 PLANNED - Specification complete; implementation pending

### Planned Component Metrics

#### 1. dq_completeness_score
**Definition**: Proportion of mandatory attributes populated for a given profile or entity version. 

**Formula** (planned):
```sql
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

#### 2. dq_consistency_score
**Definition**: Measure of logical consistency between related attributes within a profile.

**Examples of Consistency Rules**:
- Investment: If RiskLevelCode = CONSERVATIVE, then ComplexProductAllowed should be FALSE
- Investment: If Objective = SPECULATION, then RiskLevelCode should be SPECULATIVE or AGGRESSIVE
- Customer: If age < 18, then certain product entitlements must be restricted

**Formula** (planned):
```sql
dq_consistency_score = count(passed_consistency_rules) / count(applicable_consistency_rules)
```

**Range**: 0.0 to 1.0

**Penalty Approach**: Each failed rule reduces score by a configurable weight. 

**Future Implementation Location**: Gold layer with rule engine

---

#### 3. dq_timeliness_score
**Definition**: Measure of data freshness relative to expected review cycles or update cadences.

**Formula** (planned):
```sql
dq_timeliness_score = 1. 0 - (age_penalty_factor)

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

#### 4.  dq_regulatory_penalty_factor
**Definition**: Penalty factor for regulatory risk indicators (PEP flags, sanction screening failures, KYC/AML high risk ratings).

**Formula** (planned):
```sql
dq_regulatory_penalty_factor = 
  pep_penalty + 
  sanction_penalty + 
  kyc_risk_penalty + 
  aml_risk_penalty

where each component is a configurable weight (e.g., 0.05 to 0.20) if the risk flag is active.
```

**Range**: 0.0 to 1. 0 (capped; sum of penalties)

**Application**: Investment profiles, customer profiles (compliance-sensitive entities)

**Future Implementation Location**: Gold layer compliance view

---

#### 5. reliability_score
**Definition**: Composite reliability measure combining completeness, consistency, timeliness, and regulatory penalty factors.

**Formula** (planned):
```sql
reliability_score = 
  dq_completeness_score * 
  dq_consistency_score * 
  dq_timeliness_score * 
  (1. 0 - dq_regulatory_penalty_factor) *
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
   - Validate score ranges (0.0 to 1. 0)
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

**For Customer Profile (Phase 1)**:
- Silver layer `data_quality_score` available in `silver.customer_profile_standardized`
- Gold layer `dim_customer_profile` does NOT contain DQ scores (by design)
- Use Silver for ETL quality monitoring; use Gold for business analysis

---

## Related Documents

- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md) - Derived metrics exclusion policy
- [Hashing Standards](../data-modeling/hashing_standards. md) - SHA256 hash algorithm specification
- [Audit Artifacts Standard](../audit/audit_artifacts_standard.md) - Audit fact design patterns
- [Investment Profile Module Spec](../business/modules/investment_profile_module.md) - Investment domain (future Phase 2)
- [Customer Module Spec](../business/modules/customer_module.md) - Customer domain (Phase 1 complete)
- [Data Quality Rules](../business/data_quality_rules.md) - Business validation rules
- [AI Context](../../AI_CONTEXT.md) - AI-assisted development standards
- [Silver Layer Contract](../../contracts/silver/customer_profile_standardized.yaml) - Customer profile Silver schema
- [Silver Layer DDL](../../db/silver/customer_profile_standardized.sql) - PostgreSQL implementation

---

## Change Control

- Formula weight/threshold changes require data governance approval
- Component metric additions require ADR + contract update
- Formula version bumps require documentation in versioned formula registry (future)
- Silver layer DQ flag additions require enumeration file update + contract amendment

---

## Glossary

- **SCD2**: Slowly Changing Dimension Type 2 (versioned dimensions)
- **Gold Layer**: Presentation/mart layer with aggregated, derived, and analytical datasets
- **Silver Layer**: Conformed, cleansed data with validation flags and computed hashes
- **Bronze Layer**: Raw landing zone (exact mirror of source)
- **Component Metric**: Individual quality measurement (completeness, consistency, timeliness, etc.)
- **Composite Score**: Aggregated metric combining multiple component metrics (e.g., reliability_score)
- **DQ**: Data Quality
- **Enumeration**: Controlled vocabulary with versioned codes (e.g., person_title, marital_status)
- **Version Pollution**: Unwanted SCD2 version creation due to derived metric changes (prevented by exclusion policy)

---

## Change Log

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 0.1 | 2025-11-21 | Initial stub - Planned for Future Implementation | Data Architecture |
| 1.0 | 2025-12-01 | Phase 1 implementation documented (Silver layer DQ flags for customer profile); Phase 2 remains planned | Data Architecture |

---

**Document Version**: 1.0  
**Status**: Phase 1 (Silver) - Implemented; Phase 2 (Gold) - Planned  
**Author**: Data Architecture  
**Last Updated**: 2025-12-01
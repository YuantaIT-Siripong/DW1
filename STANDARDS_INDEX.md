# DW1 Data Warehouse Standards - Quick Reference

**Purpose**: Single entry point for all authoritative standards.  AI agents and contributors should reference this index first.

## Core Standards

| Standard | File Location | Version | Purpose |
|----------|--------------|---------|---------|
| **Naming Conventions** | [docs/data-modeling/naming_conventions.md](docs/data-modeling/naming_conventions.md) | 1.0 | snake_case physical, camelCase API, suffix patterns |
| **Hashing Standards** | [docs/data-modeling/hashing_standards.md](docs/data-modeling/hashing_standards.md) | 1.0 | SHA256 algorithm, profile/set hashing, normalization |
| **SCD2 Policy** | [contracts/scd2/STANDARD_SCD2_POLICY.md](contracts/scd2/STANDARD_SCD2_POLICY.md) | 1.1 | Temporal precision, closure rules, surrogate keys |
| **Data Quality Framework** | [docs/data-quality/framework.md](docs/data-quality/framework.md) | 0.1 | Component metrics, gold layer scoring (planned) |
| **Enumeration Management** | [enumerations/audit_event_types.yaml](enumerations/audit_event_types.yaml) | 2025.11.25-1 | Enumeration versioning, governance |

## Quick Lookup Tables

### Naming Standards
```sql
-- Physical Layer (Database)
dim_customer_profile              -- Tables: snake_case
customer_profile_version_sk       -- Surrogate keys: <entity>_version_sk
is_current, has_margin_agreement  -- Booleans: is_, has_
effective_start_ts                -- Timestamps: _ts suffix
effective_start_date              -- Dates: _date suffix
profile_hash                      -- Hashes: _hash suffix
data_quality_score                -- Scores: _score suffix
MARRIED, APPROVED                 -- Enumerations: UPPERCASE_SNAKE_CASE
```

```json
// API Layer (JSON)
{
  "customerProfileVersionSk": 1001,      // camelCase
  "isCurrent": true,                     // camelCase booleans
  "effectiveStartTs": "2025-01-15.. .",  // camelCase timestamps
  "maritalStatusId": "MARRIED"           // Keep enums UPPERCASE
}
```

### Hashing Standards
```
Algorithm: SHA256 (64-char hex)
Profile Hash: Concatenate sorted normalized SCD2 attributes with '|'
Set Hash: Concatenate sorted member IDs with ','
NULL Token: "__NULL__"
Exclusions: Surrogate keys, timestamps, derived scores, audit fields
```

### SCD2 Standards
```
Temporal Precision: TIMESTAMP(6) for investment, DATE for customer
Closure Rule: prev. effective_end_ts = new.effective_start_ts - 1 microsecond
Surrogate Key Pattern: <entity>_version_sk
Current Flag: is_current (exactly one TRUE per natural key)
```

## Domain-Specific Standards

### Customer Module
- **Contract**: [contracts/scd2/dim_customer_profile_columns.yaml](contracts/scd2/dim_customer_profile_columns.yaml)
- **Spec**: [docs/business/modules/customer_module.md](docs/business/modules/customer_module.md)
- **Granularity**: DATE (effective_start_date, effective_end_date)
- **Versioned Attributes**: marital_status, nationality, occupation, education_level, birthdate, income_source_set, investment_purpose_set

### Investment Module
- **Contract**: [contracts/scd2/dim_investment_profile_version_columns.yaml](contracts/scd2/dim_investment_profile_version_columns.yaml)
- **Spec**: [docs/business/modules/investment_profile_module.md](docs/business/modules/investment_profile_module.md)
- **Granularity**: TIMESTAMP(6) with microsecond precision
- **Versioned Attributes**: risk_level_code, suitability_score, kyc_status, product eligibility flags, acknowledgements, vulnerability classification

## Governance Rules

### Standard Changes Require
| Change Type | Approval Required | Files to Update |
|------------|-------------------|-----------------|
| Naming pattern change | Team approval | This index + naming_conventions.md |
| Hash algorithm change | ADR + all contracts | hashing_standards.md + all SCD2 contracts |
| SCD2 attribute addition | ADR + contract update | Module spec + contract YAML + SCD2 policy |
| Enumeration value addition | Governance ticket | enumeration YAML + version bump |

### AI Agent Prompts
Use these reference patterns when working with AI:

```
"Follow naming conventions from STANDARDS_INDEX.md section 'Naming Standards'"
"Apply SHA256 hashing per STANDARDS_INDEX.md 'Hashing Standards'"
"Implement SCD2 dimension following STANDARDS_INDEX.md 'SCD2 Standards'"
```

## Related Documentation
- [AI_CONTEXT.md](AI_CONTEXT.md) - AI agent entry point
- [CONTEXT_MANIFEST.yaml](CONTEXT_MANIFEST.yaml) - Machine-readable artifact index
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [README.md](README.md) - Repository overview

**Last Updated**: 2025-12-01  
**Maintained By**: Data Architecture
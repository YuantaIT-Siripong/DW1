# Customer Module Domain Specification (Phase 1)

## 1. Module Overview
The Customer Module establishes the canonical representation of an individual client and their evolving profile attributes (demographics, suitability-related fields, multi-valued preference sets). It supports regulatory auditability (KYC/AML), segmentation, entitlement logic, and suitability assessments.

## 2. Business Goals / KPIs
- Profile completeness rate (percentage of required attributes populated)
- Average time from source change to warehouse version availability
- Version churn rate (versions per active customer per quarter)
- Suitability assessment coverage (customers with valid current profile)
- Data quality error rate (invalid codes, overlap violations)

## 3. Core Use Cases
- Point-in-time retrieval of a customer’s profile for entitlement or suitability checks
- Historical audits (e.g., what attributes were in force on a trade date)
- Marketing segmentation on stable + evolving attributes
- Trigger downstream rules when key profile attributes change (risk flags)

## 4. Entity Inventory
| Entity | Type | Description |
|--------|------|-------------|
| Customer | Dimension (Type 1) | Stable identity / linkage anchor |
| Customer Profile | Dimension (SCD2) | Versioned demographic & suitability attributes |
| Income Source | Bridge | Multi-valued set per profile version |
| Investment Purpose | Bridge | Multi-valued set per profile version |
| Contact Channel | Bridge | Multi-valued active communication channels per profile version |
| Customer Profile Audit Event | Fact (Audit) | Each detected profile change & its cause |
| Potential Identity Duplicate | Auxiliary / Future | Mapping for potential duplicate national IDs (Phase 2) |

## 5. Attribute Inventory
| attribute_name | business_definition | datatype (warehouse) | classification | SCD_type | version_trigger | quality_rules | example_value | glossary_refs | decision_note |
|----------------|---------------------|----------------------|---------------|----------|-----------------|---------------|---------------|---------------|---------------|
| customer_id | Stable unique identifier for a person | string | non-PII | 1 | N | not null | C123456 | Customer Code | Generated from source master |
| person_id | Internal person surrogate (optional future) | string | PII-linkable | 1 | N | optional | P998877 | Person | Phase 2 linking |
| national_id | Government-issued identifier | string | PII | 1 | N | len=13; checksum (future) | 1234567890123 | National ID | Stored hashed for non-privileged roles |
| birthdate | Date of birth | date | PII | 2 | Y | <= current_date | 1985-03-10 | Birthdate | Always triggers version on change |
| marital_status_id | Marital status code | int | non-PII | 2 | Y | fk: dim_marital_status | 2 | MaritalStatus | |
| nationality_id | Nationality code | int | non-PII | 2 | Y | fk: dim_nationality | 66 | Nationality | |
| occupation_id | Occupation code | int | non-PII | 2 | Y | fk: dim_occupation | 301 | Occupation | |
| education_level_id | Education level code | int | non-PII | 2 | Y | fk: dim_education_level | 5 | EducationLevel | |
| income_source_set | Income sources selected | array<string> (logical) | non-PII | Bridge | Y | members in dim_income_source | ["SALARY","DIVIDEND"] | SourceOfIncome, Multi-Valued Set | Stored via bridge |
| investment_purpose_set | Investment purposes | array<string> (logical) | non-PII | Bridge | Y | members in dim_investment_purpose | ["RETIREMENT"] | PurposeOfInvestment, Multi-Valued Set | Stored via bridge |
| contact_channel_set | Preferred/active communication channels | array<string> (logical) | non-PII | Bridge | Y | members in dim_contact_channel | ["EMAIL","APP"] | ContactChannel, Multi-Valued Set | Stored via bridge |
| profile_hash | SHA256 of ordered versioning attributes & set hashes | string | non-PII | Derived | Y logic | not null; length=64 hex | a9f0e61... | Attribute Hash | Change detection basis |
| effective_start_ts | Start timestamp of version validity | timestamp | non-PII | 2 | N | not null | 2024-09-01T08:00:00Z | Effective Start Date | |
| effective_end_ts | End timestamp (null=current) | timestamp | non-PII | 2 | N | end > start or null | null | Effective End Date | |
| load_ts | Ingestion timestamp | timestamp | non-PII | Audit | N | not null | 2024-09-01T08:02:10Z | - | ETL metadata |
| change_reason | Categorized reason (SOURCE_UPDATE / CORRECTION / MERGE_FLAG) | string | non-PII | Audit | N | whitelist set | SOURCE_UPDATE | - | From audit feed |

## 6. Semantic & Regulatory Notes
- Birthdate and national_id treated as sensitive; access governed by role-based masking.
- National ID stored hashed (SHA256 + salt) for non-privileged analytical views.
- Backdated corrections produce a new version with effective_start_ts reflecting the business-effective date (not ingestion date) and logged in audit table.

## 7. Change Behavior (SCD2 Rules)
Trigger new version when any of:
1. Any scalar versioning attribute changes (birthdate, marital_status_id, nationality_id, occupation_id, education_level_id).
2. Any multi-valued set membership changes (addition, removal, replacement in income_source, investment_purpose, contact_channel).
3. Explicit correction events flagged by source (change_reason=CORRECTION).

Hashing:
- Compute set hashes by sorting codes ascending, joining with "|", substituting "__NULL__" for missing; then SHA256.
- profile_hash = SHA256 of concatenated ordered scalar values + set hashes (same delimiter).

Version closure:
- Prior row effective_end_ts = new_effective_start_ts - microsecond.
- Backdated correction: effective_start_ts may be earlier than load_ts; ensure no overlap by adjusting previous version.

## 8. Relationships & Cardinality
- customer_id 1:M profile_versions
- profile_version 1:M income_source entries
- profile_version 1:M investment_purpose entries
- profile_version 1:M contact_channel entries
- profile_version 1:1 profile_hash
- profile_version 1:M audit events (one initial + corrections)

## 9. Edge Cases / Exceptions
- Duplicate national_id across distinct customer_id → flagged for investigation (no auto merge).
- Removal of all entries from a multi-valued set results in empty set (recorded with empty set hash).
- Backdated changes cannot produce overlapping intervals; ETL reconciliation adjusts prior end timestamp.

## 10. Source Systems & Cadence
| Source | Feed Type | Cadence | Notes |
|--------|-----------|--------|-------|
| CRM Master | Batch | Daily | Core demographics, some occupation data |
| KYC System | Batch | Nightly | National ID, birthdate corrections |
| Preference Center | Event | Near real-time | Contact channel, investment purpose updates |
| Income Source Survey | Batch | Monthly | Income source refresh |

## 11. Data Quality Rules
- No overlapping (effective_start_ts, effective_end_ts) intervals per customer_id.
- Scalar FK codes must exist in lookup dimensions.
- Birthdate <= current_date and age >= 15 (configurable).
- Set entries valid; no duplicates within a set per version.
- profile_hash unique within (customer_id, profile_version_id).
- effective_end_ts IS NULL OR effective_end_ts > effective_start_ts.

## 12. Open Questions (Answered as Decisions)
| Question | Decision |
|----------|----------|
| Handle corporate customers separately? | Phase 1: individual only; corporate Phase 2 (dim_customer_corporate). |
| Merge logic for duplicate national_id? | No auto merge; create duplicate review record. |
| Backdated profile corrections policy? | New version with historical effective_start_ts (no retro edit). |
| Birthdate retro changes trigger? | Yes, always new version. |
| Hash algorithm? | SHA256 standard. |
| Timestamp vs date granularity? | Timestamp UTC (intraday changes). |
| Corporate vs individual key separation? | Reserve person_id; customer_id remains Customer Code. |

## 13. Mapping to Schema Artifacts
- dim_customer (identity)
- dim_customer_profile (SCD2)
- dim_customer_income_source_version
- dim_customer_investment_purpose_version
- dim_customer_contact_channel_version
- fact_customer_profile_audit
- staging: stg_customer_profile_raw, stg_customer_sets_raw

## 14. ADR Links
- ADR-001-scd2-customer-profile.md
- ADR-002-multi-valued-sets.md

## 15. Sample Records
```json
{
  "customer_id": "C123456",
  "profile_versions": [
    {
      "profile_version_id": 10,
      "effective_start_ts": "2024-09-01T08:00:00Z",
      "effective_end_ts": null,
      "marital_status_id": 2,
      "nationality_id": 66,
      "occupation_id": 301,
      "education_level_id": 5,
      "birthdate": "1985-03-10",
      "income_source_set": ["SALARY","DIVIDEND"],
      "investment_purpose_set": ["RETIREMENT","EDUCATION"],
      "contact_channel_set": ["EMAIL","APP"],
      "profile_hash": "37b51d194a7513e45b56f6524f2d51f2..."
    }
  ]
}
```

## 16. Next Clarification Tasks
- Bridge table contracts (income_source, investment_purpose, contact_channel)
- Audit fact grain & columns (fact_customer_profile_audit)
- SQL macro for profile hash computation
- dbt tests (overlap, FK integrity, set validity)
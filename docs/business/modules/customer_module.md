# Customer Module Domain Specification (Phase 1)

## 1. Module Overview
The Customer Module establishes the canonical representation of an individual client and their evolving profile attributes (demographics, suitability-related fields, multi-valued preference sets). It supports regulatory auditability (KYC/AML), segmentation, entitlement logic, and suitability assessments.

## 2. Business Goals / KPIs
- Profile completeness rate (percentage of required attributes populated + set presence)
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
| Customer Profile Audit Event | Fact (Audit) | (Future) Each profile change & reason |
| Potential Identity Duplicate | Auxiliary / Future | Duplicate national IDs review staging |

## 5. Attribute Inventory
| attribute_name | business_definition | datatype | classification | SCD_type | version_trigger | quality_rules | example_value | glossary_refs | decision_note |
|----------------|---------------------|----------|---------------|----------|-----------------|---------------|---------------|---------------|---------------|
| customer_id | Stable unique identifier for a person | string | non-PII | 1 | N | not null | C123456 | Customer Code | Generated from source master |
| person_id | Internal person surrogate (future) | string | PII-linkable | 1 | N | optional | P998877 | Person | Phase 2 linking |
| national_id | Government-issued identifier (raw) | string | PII | 1 | N | len=13 (future checksum) | 1234567890123 | National ID | Stored raw + hashed derivative |
| national_id_hash | SHA256(salt + normalized national_id) | string | masked PII | Derived | N | length=64 hex | a9f0e61... | National ID Hash | Non-privileged joins |
| birthdate | Date of birth | date | PII | 2 | Y | <= current_date | 1985-03-10 | Birthdate | Always triggers version |
| marital_status_id | Marital status code | int | non-PII | 2 | Y | fk: dim_marital_status | 2 | MaritalStatus | |
| nationality_id | Nationality code | int | non-PII | 2 | Y | fk: dim_nationality | 66 | Nationality | |
| occupation_id | Occupation code | int | non-PII | 2 | Y | fk: dim_occupation | 301 | Occupation | |
| education_level_id | Education level code | int | non-PII | 2 | Y | fk: dim_education_level | 5 | EducationLevel | |
| income_source_set | Income sources selected | array<string> logical | non-PII | Bridge | Y | members valid in dim_income_source | ["SALARY","DIVIDEND"] | SourceOfIncome | Stored via bridge |
| investment_purpose_set | Investment purposes selected | array<string> logical | non-PII | Bridge | Y | members valid in dim_investment_purpose | ["RETIREMENT"] | PurposeOfInvestment | Stored via bridge |
| profile_hash | SHA256 of ordered versioning attributes + set hashes | string | non-PII | Derived | Y logic | not null; length=64 hex | 5e884898... | Profile Hash | Change detection |
| effective_start_ts | Start timestamp of version validity (UTC) | timestamp | non-PII | 2 | N | not null | 2024-09-01T08:00:00Z | Effective Start | |
| effective_end_ts | End timestamp (null=current) | timestamp | non-PII | 2 | N | end > start or null | null | Effective End | |
| load_ts | Ingestion timestamp | timestamp | non-PII | Audit | N | not null | 2024-09-01T08:02:10Z | Load Timestamp | ETL metadata |

(Note: change_reason deferred to future audit workflow fact.)

## 6. Semantic & Regulatory Notes
- Raw national_id stored only in privileged schema; national_id_hash available broadly.
- Salt for hashing maintained in secure config; rotation produces new hashes (future re-hash batch process).
- Birthdate and national_id classified as sensitive; masking rules apply for non-privileged access.

## 7. Change Behavior (SCD2 Rules)
Triggers new version when:
1. Any versioning scalar changes (birthdate, marital_status_id, nationality_id, occupation_id, education_level_id).
2. Multi-valued set membership change (income_source OR investment_purpose).
3. Backdated corrections (future workflow).

Hashing:
- Empty set membership → SHA256("") (documented constant e3b0c44298fc1c149afbf4c8996fb924...).
- For non-empty sets: sort codes ascending, join with "|" (no trailing delimiter), hash joined string.
- profile_hash = SHA256(ordered scalar values + income_source_set_hash + investment_purpose_set_hash joined by "|").

Version closure:
- previous_row.effective_end_ts = new_effective_start_ts - microsecond (precision standard: microsecond).
- Backdated corrections insert new version; no retro edits.

## 8. Relationships & Cardinality
- customer_id 1:M profile_versions
- profile_version_id globally unique
- profile_version 1:M income_source rows
- profile_version 1:M investment_purpose rows
- profile_version 1:1 profile_hash

## 9. Edge Cases / Exceptions
- Empty both sets simultaneously is NOT allowed (at least one set must have >=1 entry).
- Empty individual set allowed (hash = SHA256("")).
- Backdated change must not create overlapping intervals.

## 10. Source Systems & Cadence (Attribute-level mapping pending)
| Source | Feed Type | Cadence | High-Level Coverage |
|--------|-----------|--------|---------------------|
| CRM Master | Batch | Daily | Marital status, nationality, occupation, education level |
| KYC System | Batch | Nightly | national_id, birthdate corrections |
| Income Source Survey | Batch | Monthly | Income source set |
| Investment Purpose Capture | Event/Batch | Variable | Investment purpose set |

## 11. Data Quality Rules
- No overlapping (effective_start_ts, effective_end_ts) intervals per customer_id.
- Birthdate <= current_date.
- At least one of (income_source_set, investment_purpose_set) non-empty.
- All FK codes exist in lookup dimensions.
- profile_version_id globally unique.
- profile_hash length = 64 hex; deterministic recomputation matches stored value.
- Empty set hash equals SHA256("") when a set is empty.
- national_id format len=13 (future checksum) OR null when genuinely unavailable.

## 12. Profile Completeness KPI
Required attributes: birthdate, marital_status_id, nationality_id, occupation_id, education_level_id, national_id (if legally required), set_presence_flag (1 if either set non-empty else 0).  
completeness_score = (count_present(required_attributes_without_flag) + set_presence_flag) / (total_required_without_flag + 1)

**Note**: This KPI is conceptual only. No derived quality columns (e.g., completeness_score, data_quality_score) are stored in `dim_customer_profile` SCD2 dimension. Derived metrics will be computed in future gold layer implementation (see [Data Quality Framework](../../data-quality/framework.md)).

## 13. Mapping to Schema Artifacts
- dim_customer (identity)
- dim_customer_profile (SCD2)
- dim_customer_income_source_version (bridge)
- dim_customer_investment_purpose_version (bridge)
- fact_customer_profile_audit (future)
- staging: stg_customer_profile_raw, stg_customer_sets_raw

## 14. ADR Links
- ADR-001-scd2-customer-profile.md
- ADR-002-multi-valued-sets.md

## 15. Sample Record
```json
{
  "customer_id": "C123456",
  "profile_versions": [
    {
      "profile_version_id": 9870,
      "effective_start_ts": "2024-09-01T08:00:00Z",
      "effective_end_ts": null,
      "marital_status_id": 2,
      "nationality_id": 66,
      "occupation_id": 301,
      "education_level_id": 5,
      "birthdate": "1985-03-10",
      "national_id": "1234567890123",
      "income_source_set": ["SALARY","DIVIDEND"],
      "investment_purpose_set": ["RETIREMENT","EDUCATION"],
      "profile_hash": "5e884898da28047151d0e56f8dc62927..."
    }
  ]
}
```

## 16. Next Clarification Tasks
- Audit fact contract (fact_customer_profile_audit) design.
- Attribute-level source mapping matrix.
- Hash macro (future) + test queries.
- Salt rotation ADR supplement.
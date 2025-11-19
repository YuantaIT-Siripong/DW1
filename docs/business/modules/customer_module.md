# Customer Module Domain Specification (Phase 1)

## 1. Module Overview
The Customer Module establishes the canonical representation of an individual client and their evolving profile attributes (demographics, suitability-related fields, multi-valued preference sets). It supports regulatory auditability (KYC/AML), segmentation, entitlement logic, and suitability assessments.

(Original content moved from docs/business/customer_module.md. This version is now authoritative in modules/.)

[... FULL ORIGINAL CONTENT REMAINS BELOW ...]

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
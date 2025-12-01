# AI Context: DW1 (Phase 1 Standard Bundle)

## Purpose
Single reference for AI assistants.   Points to authoritative sources and establishes rules for code generation and changes.

## Standards Authority
**All standards referenced from**: [STANDARDS_INDEX.md](STANDARDS_INDEX.md)

## Project Status
- **Phase**: Customer Profile Module - Gold/Curated Layer Complete
- **Completed**: Enumeration files, Gold/Curated contracts (dimension, bridges, audit fact)
- **Next**: Bronze and Silver layer contracts + DDL generation
- **Repository**: YuantaIT-Siripong/DW1

---

## Core Modeling Decisions

### Architecture Layers
- **Bronze**: Raw landing from IT operational view (exact mirror + ETL metadata)
- **Silver**: Cleaned data with computed columns (hashes, validation flags, still flat tables)
- **Gold/Curated**: Star schema (dimensions, facts, bridges) - SCD2 version management
- **Mart**: Business-specific aggregates (future)

**CRITICAL**: Star schema exists ONLY in Gold/Curated layer, NOT in Silver

### Enumeration + Freetext Pattern
**Decision**: Use direct enumeration codes (VARCHAR) in dimensions with `_other` freetext fields for flexibility

**Type 2 Enumeration Fields** (versioned, included in hash):
- person_title, marital_status, nationality, occupation, education_level, business_type
- total_asset, monthly_income (NO "OTHER" option - must select from bands)
- income_country
- All stored as VARCHAR codes directly in dimension (e.g., "MR", "MARRIED", "TH")

**Type 1 Freetext Fields** (NOT versioned, NOT in hash):
- person_title_other, nationality_other, occupation_other
- education_level_other, business_type_other, income_country_other
- Populated ONLY when corresponding enumeration field = "OTHER"
- Changes to these fields do NOT create new SCD2 versions

**No Separate Lookup Dimensions**: Replaced dim_marital_status, dim_nationality, etc. with enumeration YAML files

### Multi-Valued Sets
- **Storage**: Bridge tables (bridge_customer_source_of_income, bridge_customer_purpose_of_investment)
- **Change Detection**: Set hash (SHA256 of sorted, pipe-delimited codes)
- **Empty Set**: SHA256("") = `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`

---

## Hash Normalization Rules

### Storage vs Hash Normalization
**Storage** (how data is saved in dimension):
- firstname, lastname: Preserve original case
- firstname_local, lastname_local: Preserve original case
- All text fields: TRIM whitespace only
- `_other` freetext fields: NOT included in hash (Type 1)

**Hash Normalization** (for change detection only):
- English text fields (firstname, lastname, person_title, etc.): UPPER(TRIM)
- Local text fields (firstname_local, lastname_local): TRIM only (preserve case for hash)
- Enumerations: UPPER(TRIM)
- Dates: YYYY-MM-DD format
- NULLs: "__NULL__" token
- Freetext `_other` fields: EXCLUDED from hash
- Delimiter: "|"

### Profile Hash Calculation
Algorithm: SHA256 → lowercase hex (64 characters)

**Canonical Order** (17 fields):
1. evidence_unique_key (UPPER(TRIM), format normalized)
2. firstname (UPPER(TRIM) for hash)
3. lastname (UPPER(TRIM) for hash)
4. firstname_local (TRIM only)
5. lastname_local (TRIM only)
6.  person_title (UPPER(TRIM))
7. marital_status (UPPER(TRIM))
8. nationality (UPPER(TRIM))
9. occupation (UPPER(TRIM))
10. education_level (UPPER(TRIM))
11. business_type (UPPER(TRIM))
12. birthdate (YYYY-MM-DD)
13. total_asset (UPPER(TRIM))
14. monthly_income (UPPER(TRIM))
15. income_country (UPPER(TRIM))
16. source_of_income_set_hash (SHA256 of sorted members)
17. purpose_of_investment_set_hash (SHA256 of sorted members)

**Assembly**:
```
canonical_string = 
    COALESCE(UPPER(TRIM(evidence_unique_key)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(firstname)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(lastname)), '__NULL__') || '|' ||
    COALESCE(TRIM(firstname_local), '__NULL__') || '|' ||
    COALESCE(TRIM(lastname_local), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(person_title)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(marital_status)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(nationality)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(occupation)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(education_level)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(business_type)), '__NULL__') || '|' ||
    COALESCE(birthdate::TEXT, '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(total_asset)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(monthly_income)), '__NULL__') || '|' ||
    COALESCE(UPPER(TRIM(income_country)), '__NULL__') || '|' ||
    COALESCE(source_of_income_set_hash, '__NULL__') || '|' ||
    COALESCE(purpose_of_investment_set_hash, '__NULL__')

profile_hash = SHA256(canonical_string)
```

### Set Hash Calculation
For source_of_income and purpose_of_investment:
1. Parse pipe-delimited list from source
2.  Normalize each member: UPPER(TRIM)
3.  Deduplicate
4. Sort ascending alphabetically
5. Join with "|" delimiter (empty set → "")
6. SHA256(joined_string) → set_hash

---

## SCD2 Customer Profile Dimension

### Schema
**Table**: dim_customer_profile  
**Layer**: Gold/Curated

### Key Structure
- **Surrogate Key**: customer_profile_version_sk (BIGINT) - globally unique across all versions
- **Natural Key**: customer_id (BIGINT, not STRING)
- **Business Key**: (customer_id, version_num)
- **Version Tracking**: version_num (INT - sequential 1, 2, 3.. .), is_current (BOOLEAN)
- **Temporal**: effective_start_ts, effective_end_ts (TIMESTAMP, UTC, microsecond precision)

### Core Attributes (31 total)
**Identity (PII)**:
- evidence_unique_key (VARCHAR(100)) - national ID or passport, NOT national_id

**Names (PII)**:
- firstname, lastname (VARCHAR(200)) - preserve case in storage
- firstname_local, lastname_local (VARCHAR(200)) - preserve case in storage

**Enumeration Fields** (Type 2, versioned):
- person_title (VARCHAR(50))
- marital_status (VARCHAR(50))
- nationality (VARCHAR(2)) - ISO 3166-1 alpha-2
- occupation (VARCHAR(100))
- education_level (VARCHAR(100))
- business_type (VARCHAR(100))
- birthdate (DATE)
- total_asset (VARCHAR(50)) - bands only, no OTHER
- monthly_income (VARCHAR(50)) - bands only, no OTHER
- income_country (VARCHAR(2)) - ISO 3166-1 alpha-2

**Freetext Fields** (Type 1, NOT versioned):
- person_title_other (VARCHAR(200))
- nationality_other (VARCHAR(200))
- occupation_other (VARCHAR(200))
- education_level_other (VARCHAR(200))
- business_type_other (VARCHAR(200))
- income_country_other (VARCHAR(200))

**Set Hashes**:
- source_of_income_set_hash (VARCHAR(64))
- purpose_of_investment_set_hash (VARCHAR(64))

**Change Detection**:
- profile_hash (VARCHAR(64)) - SHA256 of all version-driving attributes

**SCD2 Management**:
- version_num (INT)
- effective_start_ts, effective_end_ts (TIMESTAMP)
- is_current (BOOLEAN)
- load_ts (TIMESTAMP)

### Version Closure Rule
```
previous_row. effective_end_ts = new_row.effective_start_ts - 1 microsecond
```
- Exactly one is_current = TRUE per customer_id
- No overlapping intervals

---

## Bridge Tables

### bridge_customer_source_of_income
**Primary Key**: (customer_profile_version_sk, source_of_income_code)  
**Attributes**:
- customer_profile_version_sk (BIGINT FK)
- customer_id (BIGINT) - denormalized for convenience
- source_of_income_code (VARCHAR(100)) - direct enumeration code
- load_ts (TIMESTAMP)

**Valid Codes**: SALARY, DIVIDEND, RENTAL, BUSINESS, PENSION, INVESTMENT, INHERITANCE, GIFT, OTHER, UNKNOWN

### bridge_customer_purpose_of_investment
**Primary Key**: (customer_profile_version_sk, purpose_of_investment_code)  
**Attributes**:
- customer_profile_version_sk (BIGINT FK)
- customer_id (BIGINT) - denormalized
- purpose_of_investment_code (VARCHAR(100))
- load_ts (TIMESTAMP)

**Valid Codes**: RETIREMENT, EDUCATION, SPECULATION, INCOME, WEALTH_PRESERVATION, GROWTH, TAX_PLANNING, ESTATE_PLANNING, OTHER, UNKNOWN

---

## Audit Fact Table

### fact_customer_profile_audit
**Grain**: One row per profile change event that created new SCD2 version

**Key Attributes**:
- audit_event_id (BIGINT) - surrogate key
- customer_id (BIGINT)
- customer_profile_version_sk_new (BIGINT FK)
- customer_profile_version_sk_old (BIGINT FK, nullable)
- version_num_new, version_num_old (INT)
- change_reason (VARCHAR(50)) - INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, etc. 

**Change Tracking** (JSON):
- changed_scalar_attributes (TEXT) - array of attribute names
- changed_set_names (TEXT) - array of set names
- scalar_attribute_old_values (TEXT) - JSON object
- scalar_attribute_new_values (TEXT) - JSON object
- set_membership_diff_summary (TEXT) - add/remove counts

**Hashes**:
- old_profile_hash, new_profile_hash (VARCHAR(64))

**Timestamps**:
- event_source_ts, event_detected_ts, effective_start_ts_new (TIMESTAMP)
- processing_latency_seconds (INT)

**Audit Trail**:
- initiated_by_system, initiated_by_user_id (VARCHAR(100))
- load_ts (TIMESTAMP)

---

## Data Type Standards

| Concept | Data Type | Notes |
|---------|-----------|-------|
| customer_id | BIGINT | NOT STRING |
| Surrogate keys | BIGINT | *_sk suffix |
| Enumeration codes | VARCHAR(length) | Direct codes, not FK integers |
| Timestamps | TIMESTAMP | UTC, microsecond precision |
| Dates | DATE | YYYY-MM-DD |
| Booleans | BOOLEAN | is_*, has_* prefix |
| Hashes | VARCHAR(64) | SHA256 lowercase hex |
| Names | VARCHAR(200) | Preserve case |
| Freetext _other | VARCHAR(200) | Type 1 |

---

## Point-in-Time Query Patterns

### Current Version
```sql
SELECT * FROM dim_customer_profile
WHERE customer_id = :cid
  AND is_current = TRUE;
```

### Historical (as of timestamp)
```sql
SELECT * FROM dim_customer_profile
WHERE customer_id = :cid
  AND effective_start_ts <= :as_of_ts
  AND (effective_end_ts IS NULL OR effective_end_ts > :as_of_ts);
```

### With Bridge (Current)
```sql
SELECT 
    p.*,
    STRING_AGG(s.source_of_income_code, ', ' ORDER BY s.source_of_income_code) as income_sources
FROM dim_customer_profile p
LEFT JOIN bridge_customer_source_of_income s 
    ON p.customer_profile_version_sk = s.customer_profile_version_sk
WHERE p.customer_id = :cid
  AND p.is_current = TRUE
GROUP BY p.customer_profile_version_sk;
```

---

## AI Interaction Prompts

### For Bronze/Silver Contracts
```
"Generate Bronze contract mirroring IT view from customer_module.md Section 18"
"Generate Silver contract adding profile_hash and set_hash columns"
"Follow hash normalization rules from AI_CONTEXT.md"
```

### For DDL Generation
```
"Generate DDL for dim_customer_profile following contracts/customer/dim_customer_profile.yaml"
"Create bridge table DDL per contracts/customer/bridge_customer_source_of_income.yaml"
"Apply SCD2 indexes per AI_CONTEXT.md standards"
```

### For Validation
```
"Validate enumeration codes against enumerations/customer_occupation.yaml"
"Check profile_hash calculation matches AI_CONTEXT.md specification"
"Verify _other fields are Type 1 (not in hash)"
```

---

## Change Discipline

### Requires ADR + Contract Update
- Adding/removing SCD2 versioned attributes
- Changing hash algorithm or attribute order
- Modifying enumeration field to/from Type 1/Type 2
- Changing surrogate key patterns

### Requires Enumeration YAML Update Only
- Adding new valid enumeration values
- Deprecating enumeration values
- Updating display names or descriptions

### Requires Contract Update Only
- Adding `_other` freetext fields (always Type 1)
- Changing data types or lengths
- Adding non-versioned metadata columns

---

## Do Not

❌ **Never**:
- Create separate lookup dimensions (dim_marital_status, dim_nationality, etc.) - use enumerations instead
- Include `_other` freetext fields in hash calculation
- Version `_other` fields (always Type 1)
- Use national_id field name (use evidence_unique_key)
- Use STRING/VARCHAR for customer_id (use BIGINT)
- Put star schema in Silver layer (only in Gold/Curated)
- Store case-normalized names (preserve original case in storage)
- Add enumeration fields without corresponding `_other` field (except bands)
- Create new versions for `_other` field changes

---

## File References

### Core Documentation
- [Customer Module Spec](docs/business/modules/customer_module.md) - Section 5 (Attributes), Section 8 (Hashing), Section 18 (IT View Spec)
- [Enumeration Standards](docs/standards/enumeration_standards.md)
- [Hashing Standards](docs/data-modeling/hashing_standards.md)
- [SCD2 Policy](contracts/scd2/STANDARD_SCD2_POLICY.md)

### Contracts (Gold/Curated)
- [Dimension: Customer Profile](contracts/customer/dim_customer_profile.yaml) - 31 attributes, complete
- [Bridge: Source of Income](contracts/customer/bridge_customer_income_source_version.yaml) - complete
- [Bridge: Investment Purpose](contracts/customer/bridge_customer_investment_purpose_version. yaml) - complete
- [Fact: Profile Audit](contracts/customer/fact_customer_profile_audit.yaml) - complete

### Contracts (Pending)
- contracts/bronze/customer_profile_standardized.yaml - placeholder (needs generation)
- contracts/silver/customer_profile_standardized.yaml - placeholder (needs generation)

### Enumeration Files (Complete)
All in `enumerations/` folder:
- customer_person_title.yaml - MR, MRS, MS, MISS, DR, PROF, REV, OTHER
- customer_marital_status.yaml - SINGLE, MARRIED, DIVORCED, WIDOWED, SEPARATED, UNKNOWN
- customer_nationality.yaml - ISO 3166-1 alpha-2 codes + OTHER
- customer_occupation.yaml - EMPLOYEE, SELF_EMPLOYED, BUSINESS_OWNER, etc.  + OTHER, UNKNOWN
- customer_education_level.yaml - PRIMARY, SECONDARY, BACHELOR, MASTER, etc. + OTHER, UNKNOWN
- customer_business_type.yaml - FINANCE, MANUFACTURING, RETAIL, etc. + OTHER, UNKNOWN
- customer_total_asset_bands.yaml - ASSET_BAND_1.. 5, UNKNOWN (NO OTHER)
- customer_monthly_income_bands.yaml - INCOME_BAND_1..5, UNKNOWN (NO OTHER)
- customer_income_country.yaml - ISO 3166-1 alpha-2 codes + OTHER
- customer_source_of_income.yaml - SALARY, DIVIDEND, RENTAL, etc. + OTHER, UNKNOWN
- customer_purpose_of_investment. yaml - RETIREMENT, EDUCATION, SPECULATION, etc. + OTHER, UNKNOWN

---

## Artifact Index
See [CONTEXT_MANIFEST.yaml](CONTEXT_MANIFEST.yaml) for machine-readable index.  

**Last Updated**: 2025-12-01  
**Current Phase**: Gold/Curated contracts complete; Bronze/Silver contracts pending  
**Maintained By**: Data Architecture
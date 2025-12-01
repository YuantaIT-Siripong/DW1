# Customer Module Domain Specification (Revised)

Revision Date: 2025-12-01

**For AI Assistants**: See [AI_CONTEXT.md](../../AI_CONTEXT.md) for quick reference and cross-chat standards. 

## 1. Module Overview
The Customer Module establishes the canonical, versioned representation of a client's profile (identity evidence, demographics, names, economic bands, and multi‑valued investment context).  It provides the foundation for suitability assessment, regulatory compliance, and customer segmentation.

## 2. Business Goals / KPIs
- Profile completeness rate (required attributes present + at least one multi‑valued set)
- Time from source change to published profile version (batch latency)
- Version churn rate (versions per active customer per quarter)
- Data quality error rate (invalid enumerations, normalization failures)
- Identity evidence consistency (rate of corrections)

## 3. Core Use Cases
- Point‑in‑time retrieval of a customer's profile for entitlement/suitability
- Historical audits (state in force at any business date)
- Trigger downstream rules when profile_hash changes (e.g., suitability reassessment)
- Segmentation on occupation, business_type, total_asset, monthly_income bands

## 4. Entity Inventory
| Entity | Type | Description |
|--------|------|-------------|
| Customer | Dimension (Type 1) | Stable internal person surrogate (customer_id) |
| Customer Profile | Dimension (SCD2) | Versioned demographic & economic attributes |
| Customer Income Source | Bridge | Multi‑valued source_of_income per profile version |
| Customer Investment Purpose | Bridge | Multi‑valued purpose_of_investment per profile version |
| Customer Profile Audit Event | Fact (Audit; future) | Records each version creation + rationale |
| Customer Contact Info (planned) | Dimension/Versioned | Contact channels separated (no profile churn) |

## 5. Attribute Inventory (Revised)
All listed version‑driving attributes participate in profile_hash (single hash per record).  Local name fields preserve case in storage; normalization rules for hashing are defined in Section 8.

| attribute_name | business_definition | datatype | classification | SCD_type | version_trigger | quality_rules | example_value | decision_note |
|----------------|---------------------|----------|---------------|----------|-----------------|---------------|---------------|---------------|
| customer_profile_version_sk | Surrogate key for profile version | bigint | non‑PII | N/A | N | unique | 102938 | Generated identity |
| customer_id | Stable internal person identifier | bigint | non‑PII | 1 | N | not null | 556677 | Type 1 anchor |
| evidence_unique_key | Raw identity evidence (national ID or passport) | string | PII | 2 | Y | normalization/format valid | AB1234567890 | Included in hash |
| firstname | Given name (preserve case) | string | PII | 2 | Y | trim; length > 0 | John | Included in hash |
| lastname | Family name (preserve case) | string | PII | 2 | Y | trim; length > 0 | Doe | Included in hash |
| firstname_local | Local language given name (preserve case) | string | PII | 2 | Y | trim | สมชาย | Included in hash |
| lastname_local | Local language family name (preserve case) | string | PII | 2 | Y | trim | โด | Included in hash |
| person_title | Honorific/title enumeration | string | non‑PII | 2 | Y | enum membership | MR | Included in hash |
| person_title_other | Freetext title when person_title=OTHER | string | non‑PII | 1 | N | populated only if person_title=OTHER | Reverend | NOT in hash; Type 1 |
| marital_status | Marital status enumeration | string | non‑PII | 2 | Y | enum membership | MARRIED | Included in hash |
| nationality | Nationality enumeration (ISO alpha-2) | string | non‑PII | 2 | Y | enum membership | TH | Included in hash |
| nationality_other | Freetext nationality when nationality=OTHER | string | non‑PII | 1 | N | populated only if nationality=OTHER | Stateless | NOT in hash; Type 1 |
| occupation | Occupational classification enumeration | string | non‑PII | 2 | Y | enum membership | EMPLOYEE | Included in hash |
| occupation_other | Freetext occupation when occupation=OTHER | string | non‑PII | 1 | N | populated only if occupation=OTHER | Astronaut | NOT in hash; Type 1 |
| education_level | Education attainment enumeration | string | non‑PII | 2 | Y | enum membership | BACHELOR | Included in hash |
| education_level_other | Freetext education when education_level=OTHER | string | non‑PII | 1 | N | populated only if education_level=OTHER | Online Bootcamp | NOT in hash; Type 1 |
| business_type | Business activity type enumeration | string | non‑PII | 2 | Y | enum membership | FINANCE | Included in hash |
| business_type_other | Freetext business type when business_type=OTHER | string | non‑PII | 1 | N | populated only if business_type=OTHER | Space Tourism | NOT in hash; Type 1 |
| birthdate | Date of birth | date | PII | 2 | Y | <= current_date; age 18–120 | 1985-03-10 | Included in hash |
| total_asset | Asset band/category enumeration (no OTHER) | string | non‑PII | 2 | Y | enum membership | ASSET_BAND_3 | Included in hash; always from bands |
| monthly_income | Monthly income band enumeration (no OTHER) | string | non‑PII | 2 | Y | enum membership | INCOME_BAND_2 | Included in hash; always from bands |
| income_country | Country of income origin enumeration (ISO alpha-2) | string | non‑PII | 2 | Y | enum membership | TH | Included in hash |
| income_country_other | Freetext income country when income_country=OTHER | string | non‑PII | 1 | N | populated only if income_country=OTHER | International Waters | NOT in hash; Type 1 |
| source_of_income (bridge) | Multi‑valued sources of income | set<string> logical | non‑PII | Bridge | Y (membership) | members valid in enum | ["SALARY","DIVIDEND"] | Stored via bridge; used in hash as set_hash |
| purpose_of_investment (bridge) | Multi‑valued investment purposes | set<string> logical | non‑PII | Bridge | Y (membership) | members valid in enum | ["RETIREMENT"] | Stored via bridge; used in hash as set_hash |
| profile_hash | SHA256 over ordered normalized scalars + set hashes | string | non‑PII | Derived | Y (logic) | length=64 hex | 5e884898...  | Single hash per version |
| version_num | Sequential version number per customer_id | int | non‑PII | 2 | N | >0 | 7 | Monotonic |
| effective_start_ts | UTC start timestamp of version validity | timestamp | non‑PII | 2 | N | not null | 2025‑12‑01T08:00:00Z | PIT queries |
| effective_end_ts | UTC end timestamp (null=current) | timestamp | non‑PII | 2 | N | end>start or null | null | |
| is_current | Flag for active version | boolean | non‑PII | 2 | N | single TRUE per customer_id | true | Performance flag |
| load_ts | Ingestion timestamp into warehouse | timestamp | non‑PII | Audit | N | not null | 2025‑12‑01T08:05:10Z | ETL metadata |

Notes:
- **Enumeration + Freetext pattern**: When enumeration field = "OTHER", corresponding `_other` field contains freetext value
- **Freetext fields are Type 1**: Changes do NOT trigger new version, NOT included in profile_hash
- **total_asset & monthly_income**: No "OTHER" option - customers must select from defined bands
- Local names preserve case in storage; hash normalization rules ensure deterministic change detection

### Valid Enumeration Values (for IT view creation):

**Enumeration Definitions**: See `enumerations/` folder for valid values:
- `customer_person_title.yaml`
- `customer_marital_status.yaml`
- `customer_nationality.yaml`
- `customer_occupation.yaml`
- `customer_education_level.yaml`
- `customer_business_type.yaml`
- `customer_total_asset_bands.yaml`
- `customer_monthly_income_bands.yaml`
- `customer_income_country.yaml`
- `customer_source_of_income.yaml`
- `customer_purpose_of_investment.yaml`

**For IT**: 
- Reference enumeration files for exact valid values and mapping rules.
- Populate `_other` fields ONLY when enumeration = "OTHER"
- If source data doesn't match and no freetext available, map to UNKNOWN

## 6.   Semantic & Regulatory Notes
- Identity evidence (evidence_unique_key) is raw PII; enforce least‑privilege access controls and masking in non‑privileged contexts.  
- Local name fields (firstname_local, lastname_local) preserve original case; normalization trims only leading/trailing spaces.
- Nationality and income_country will share a unified enumeration file (ISO‑based) but represent different semantics (citizenship vs economic origin).
- Freetext `_other` fields are Type 1 (non-versioned) to avoid creating new versions on typo corrections. 
- No hashed PII surrogate (national_id_hash) is used at this time; may be introduced later for privacy‑preserving joins.

## 7. Change Behavior (SCD2 Rules)
New version is created when:
1. Any normalized change in a version‑driving scalar (evidence_unique_key, firstname, lastname, firstname_local, lastname_local, person_title, marital_status, nationality, occupation, education_level, business_type, birthdate, total_asset, monthly_income, income_country).  
2. Any membership change (add/remove) in source_of_income or purpose_of_investment (order‑insensitive).
3.  Backdated corrections (effective_start_ts earlier than current).  
4. Identity evidence correction (evidence_unique_key change).

No new version when:
- Pure whitespace changes or non‑material formatting differences that normalization removes (e.g., casing if normalization uppercases for hash, except local names where case is preserved per rules). 
- Changes to Type 1 freetext fields (person_title_other, nationality_other, occupation_other, education_level_other, business_type_other, income_country_other).
- Non‑material changes outside the attribute set above.  

Version closure:
- previous_row. effective_end_ts = new_effective_start_ts − microsecond (precision standard: microsecond).  
- No overlapping intervals per customer_id. 

## 8.   Hashing Standard (Profile)

### Storage vs Hash Normalization

**Storage** (how data is saved in dimension):
- firstname, lastname: Preserve original case
- firstname_local, lastname_local: Preserve original case
- All text fields: TRIM whitespace only
- `_other` freetext fields: NOT included in hash (Type 1)

**Hash Normalization** (for change detection only):
- English text fields (firstname, lastname, person_title, etc.): UPPER(TRIM)
- Local text fields (firstname_local, lastname_local): TRIM only (preserve case)
- Enumerations: UPPER(TRIM)
- Dates: YYYY-MM-DD format
- NULLs: "__NULL__" token
- Freetext `_other` fields: EXCLUDED from hash

### Canonical order for profile_hash:
1. evidence_unique_key (UPPER(TRIM), format normalized)
2. firstname (TRIM; for hash use UPPER to avoid case churn)
3. lastname (TRIM; for hash use UPPER)
4. firstname_local (TRIM; for hash use exact original characters)
5. lastname_local (TRIM; for hash use exact original characters)
6. person_title (UPPER(TRIM))
7. marital_status (UPPER(TRIM))
8. nationality (UPPER(TRIM))
9. occupation (UPPER(TRIM))
10. education_level (UPPER(TRIM))
11. business_type (UPPER(TRIM))
12. birthdate (YYYY‑MM‑DD)
13. total_asset (UPPER(TRIM))
14. monthly_income (UPPER(TRIM))
15. income_country (UPPER(TRIM))
16.  source_of_income_set_hash (SHA256 of sorted, normalized members; empty set → SHA256(""))
17. purpose_of_investment_set_hash (same rule)

Assembly:
- Nulls become "__NULL__".  
- Concatenate with '|' delimiter (explicit, not concat_ws):
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
  ```
- profile_hash = SHA256(canonical_string) → lowercase hex.  

**Note**: Freetext `_other` fields (person_title_other, nationality_other, occupation_other, education_level_other, business_type_other, income_country_other) are EXCLUDED from hash calculation.

Set hash rules:
- Normalize members (UPPER(TRIM)), deduplicate, sort ascending, join with "|", SHA256(joined).  
- Empty set → SHA256("") constant (e3b0c44298fc1c149afbf4c8996fb924.. .). 

Optional:
- Track hash_algorithm_version if you foresee changes to normalization/hash composition.

## 9.  Relationships & Cardinality
- customer_id 1:M dim_customer_profile versions
- Each profile version 1:M source_of_income members (bridge)
- Each profile version 1:M purpose_of_investment members (bridge)
- Exactly one current version per customer_id (is_current = TRUE)
- profile_hash identifies material state of a version (collisions negligible with SHA256)

## 10. Edge Cases / Exceptions
- At least one of source_of_income or purpose_of_investment should have ≥1 member (recommended; can be relaxed for initial incomplete loads).  
- Birthdate may be temporarily null in initial loads; not recommended.   Monitor and remediate.
- Excessive churn due to name corrections should be monitored; if needed, exclude names from hash via ADR + hash version bump.
- When enumeration = "OTHER", corresponding `_other` field should be populated; monitor for NULL `_other` when enum = "OTHER". 

## 11. Source Systems & Cadence (Revised)

### Upstream Standardization Flow

```
IT Operational DB → IT Standardized View → Bronze → Silver → SCD2 Curated
(IT owns)           (IT creates)          (DW lands) (DW)    (DW)
```

### IT View Specification

**View Name**: `opdb.vw_customer_profile_standardized`

**Owner**: IT Department

**Status**: ⏳ Pending creation by IT

**Requirements Document**: `upstream/requirements/customer_profile_requirements.md`

**Responsibilities**:
- **IT Team**: 
  - Create view from operational databases
  - Map operational schema → DW requirements
  - Apply basic standardization (TRIM, enumeration mapping)
  - Handle "OTHER" enumeration values + populate corresponding `_other` freetext fields
  
- **DW Team**:
  - Land view to Bronze (exact copy)
  - Apply SCD2 logic in Curated layer
  - Calculate profile_hash
  - Version management

### Data Flow Stages:

1. **Operational DB (IT-owned)**
   - Multiple source tables (customer_master, customer_detail, etc.)
   - IT's operational schema

2. **IT Standardized View (IT creates)**
   - Artifact: `opdb.vw_customer_profile_standardized`
   - Schema: Matches DW Silver requirements (95%+)

3. **Bronze (DW Landing)**
   - Artifact: `bronze. customer_profile_standardized` (table)
   - Schema: Exact mirror of IT view + ETL metadata
   - Purpose: Historical archive

4. **Silver (DW Passthrough)**
   - Artifact: `silver.vw_customer_profile_standardized` (view)
   - Add: Set hashes, validation flags
   
5. **Curated (DW SCD2)**
   - Artifact: `dim. dim_customer_profile` (table)
   - SCD2 version management
   - Profile hash change detection

Alignment Principle:
- Schema parity across IT View, Bronze, and Silver (>95% identical).   Differences:
  - Bronze adds lineage columns
  - Silver may add validation flags
  - Hashing and version persistence occur post‑Silver

Monitoring (planned):
- Batch parity (counts across IT view → bronze → silver)
- Enumeration readiness checks (once catalogs exist)
- Version churn monitoring (e.g., names, business_type)
- Birthdate sanity and identity evidence consistency
- `_other` field population when enum = "OTHER"

## 12. Data Quality Rules
- No overlapping effective intervals per customer_id.  
- birthdate ≤ current_date; age 18–120 (monitor exceptions).  
- Normalized text values length > 0 for mandatory fields (firstname, lastname, evidence_unique_key).
- Enumeration validation must pass once catalogs published.  
- profile_hash length = 64 hex; recomputation integrity tests must match.  
- Set memberships deduplicated, normalized, hashed deterministically.
- When enumeration field = "OTHER", corresponding `_other` field should be populated (monitor NULL violations).

## 13.   Completeness KPI (Conceptual)
Required core fields: evidence_unique_key, firstname, lastname, birthdate, occupation, nationality, (total_asset OR monthly_income), plus at least one of (source_of_income, purpose_of_investment).  
completeness_score = (#present_required / total_required)  
This KPI is computed analytically; not persisted in the dimension.

## 14. Mapping to Schema Artifacts
- dim_customer_profile (SCD2 dimension)
- dim_customer_income_source_version (bridge)
- dim_customer_investment_purpose_version (bridge)
- fact_customer_profile_audit (future)
- bronze. customer_profile_standardized (landing table)
- silver.vw_customer_profile_standardized (passthrough view)
- upstream: opdb.vw_customer_profile_standardized (IT-owned)

## 15. Sample Record (Illustrative)
```json
{
  "customer_id": 556677,
  "profile_versions": [
    {
      "customer_profile_version_sk": 12045,
      "version_num": 3,
      "effective_start_ts": "2025-12-01T08:00:00Z",
      "effective_end_ts": null,
      "is_current": true,
      "evidence_unique_key": "AB1234567890",
      "firstname": "John",
      "lastname": "Doe",
      "firstname_local": "สมชาย",
      "lastname_local": "โด",
      "person_title": "MR",
      "person_title_other": null,
      "marital_status": "MARRIED",
      "nationality": "TH",
      "nationality_other": null,
      "occupation": "OTHER",
      "occupation_other": "Astronaut",
      "education_level": "BACHELOR",
      "education_level_other": null,
      "business_type": "FINANCE",
      "business_type_other": null,
      "birthdate": "1985-03-10",
      "total_asset": "ASSET_BAND_3",
      "monthly_income": "INCOME_BAND_2",
      "income_country": "TH",
      "income_country_other": null,
      "source_of_income": ["SALARY","DIVIDEND"],
      "purpose_of_investment": ["RETIREMENT","EDUCATION"],
      "profile_hash": "5e884898da28047151d0e56f8dc62927..."
    }
  ]
}
```

## 16.   Audit Events (Future)
Event types (PROFILE_VERSION_CREATE, PROFILE_VERSION_CORRECTION).   Each event references:
- event_ts == effective_start_ts for created version
- previous_profile_hash (nullable on initial load)
- new_profile_hash
- diff summary (attributes changed + set membership deltas)
- rationale_code (INITIAL_LOAD, SOURCE_UPDATE, CORRECTION)

## 17. Pending Tasks

### Blockers for Silver Completion
- [ ] IT to create `opdb.vw_customer_profile_standardized` view
- [ ] Validate IT view schema matches Section 18 requirements

### Backlog (Post-Silver)
- [ ] Publish enumeration YAMLs for customer profile attributes
- [ ] Define normalization macros/UDFs for hash assembly
- [ ] Implement Bronze landing pipeline
- [ ] Implement SCD2 change detection job
- [ ] Introduce optional evidence_type for identity classification
- [ ] Add monitoring views for excessive version churn
- [ ] Create upstream/requirements/customer_profile_requirements.md (detailed spec for IT)
- [ ] Monitor `_other` field population quality

## 18. Upstream Requirements for IT View

### View Specification: opdb.vw_customer_profile_standardized

**Purpose**: Provide standardized customer profile data for data warehouse SCD2 dimension. 

**Required Fields**:

```sql
CREATE VIEW opdb.vw_customer_profile_standardized AS
SELECT 
    customer_id VARCHAR(50) NOT NULL,              -- Unique business key
    evidence_unique_key VARCHAR(100),              -- National ID/Passport (trimmed, uppercase)
    firstname VARCHAR(200),                        -- Given name (trimmed, preserve case)
    lastname VARCHAR(200),                         -- Family name (trimmed, preserve case)
    firstname_local VARCHAR(200),                  -- Local script (trimmed, preserve case)
    lastname_local VARCHAR(200),                   -- Local script (trimmed, preserve case)
    person_title VARCHAR(50),                      -- Valid: MR, MRS, MS, DR, PROF, OTHER
    person_title_other VARCHAR(200),               -- Freetext when person_title=OTHER
    marital_status VARCHAR(50),                    -- Valid: SINGLE, MARRIED, DIVORCED, WIDOWED, UNKNOWN
    nationality VARCHAR(2),                        -- ISO 3166-1 alpha-2 (uppercase) or OTHER
    nationality_other VARCHAR(200),                -- Freetext when nationality=OTHER
    occupation VARCHAR(100),                       -- Valid: See enumeration table above
    occupation_other VARCHAR(200),                 -- Freetext when occupation=OTHER
    education_level VARCHAR(100),                  -- Valid: See enumeration table above
    education_level_other VARCHAR(200),            -- Freetext when education_level=OTHER
    business_type VARCHAR(100),                    -- Valid: See enumeration table above
    business_type_other VARCHAR(200),              -- Freetext when business_type=OTHER
    birthdate DATE,                                -- YYYY-MM-DD format
    total_asset VARCHAR(50),                       -- Valid: ASSET_BAND_1.. 5, UNKNOWN (no OTHER)
    monthly_income VARCHAR(50),                    -- Valid: INCOME_BAND_1..5, UNKNOWN (no OTHER)
    income_country VARCHAR(2),                     -- ISO 3166-1 alpha-2 (uppercase) or OTHER
    income_country_other VARCHAR(200),             -- Freetext when income_country=OTHER
    source_of_income_list TEXT,                    -- Pipe-delimited: "SALARY|DIVIDEND|RENTAL"
    purpose_of_investment_list TEXT,               -- Pipe-delimited: "RETIREMENT|EDUCATION"
    last_modified_ts TIMESTAMP                     -- For change tracking
FROM ...  ;
```

**Data Quality Requirements**:
- `customer_id`: Must be unique, not null
- Trimming: Apply TRIM() to all text fields
- Enumeration mapping: Map operational codes to standard values above
- **OTHER handling**: When enumeration field = "OTHER", populate corresponding `_other` field with freetext value
- Multi-valued attributes: Pipe-delimited format, sorted alphabetically
- Invalid values: Map to 'UNKNOWN' or 'OTHER' (don't reject records)

**Documentation**: See `upstream/requirements/customer_profile_requirements.md` for detailed spec.

Change Log
| Date | Change | Author | Notes |
|------|--------|--------|-------|
| 2025-12-01 | Added enumeration + freetext pattern for flexible attributes; marked `_other` fields as Type 1 | Data Architecture | Silver layer foundation complete |
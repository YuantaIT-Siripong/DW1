# Customer Module Domain Specification (Revised)

Revision Date: 2025-12-01

## 1. Module Overview
The Customer Module establishes the canonical, versioned representation of a client’s profile (identity evidence, demographics, names, economic bands, and multi‑valued investment context). It produces an SCD2 dimension (dim_customer_profile) used for regulatory, suitability, entitlement, and segmentation. Multi‑valued sets (source_of_income, purpose_of_investment) are modeled via bridge tables per profile version. Contact information is intentionally separated into a future contact info module to avoid unnecessary profile version churn.

## 2. Business Goals / KPIs
- Profile completeness rate (required attributes present + at least one multi‑valued set)
- Time from source change to published profile version (batch latency)
- Version churn rate (versions per active customer per quarter)
- Data quality error rate (invalid enumerations, normalization failures)
- Identity evidence consistency (rate of corrections)

## 3. Core Use Cases
- Point‑in‑time retrieval of a customer’s profile for entitlement/suitability
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
All listed version‑driving attributes participate in profile_hash (single hash per record). Local name fields preserve case in storage; normalization rules for hashing are defined in Section 8.

| attribute_name | business_definition | datatype | classification | SCD_type | version_trigger | quality_rules | example_value | decision_note |
|----------------|---------------------|----------|---------------|----------|-----------------|---------------|---------------|---------------|
| customer_profile_version_sk | Surrogate key for profile version | bigint | non‑PII | N/A | N | unique | 102938 | Generated identity |
| customer_id | Stable internal person identifier | bigint | non‑PII | 1 | N | not null | 556677 | Type 1 anchor |
| evidence_unique_key | Raw identity evidence (national ID or passport) | string | PII | 2 | Y | normalization/format valid | AB1234567890 | Included in hash |
| firstname | Given name (preserve case) | string | PII | 2 | Y | trim; length > 0 | John | Included in hash |
| lastname | Family name (preserve case) | string | PII | 2 | Y | trim; length > 0 | Doe | Included in hash |
| firstname_local | Local language given name (preserve case) | string | PII | 2 | Y | trim | สมชาย | Included in hash |
| lastname_local | Local language family name (preserve case) | string | PII | 2 | Y | trim | โด | Included in hash |
| person_title | Honorific/title (enum later; text now) | string | non‑PII | 2 | Y | future enum membership | MR | Enumeration pending |
| marital_status | Status descriptor (enum later; text now) | string | non‑PII | 2 | Y | future enum membership | MARRIED | Replaces marital_status_id |
| nationality | Nationality (shares enumeration with income_country; prefer ISO) | string | non‑PII | 2 | Y | future enum membership | TH | Text now, enum later |
| occupation | Occupational classification (enum later; text now) | string | non‑PII | 2 | Y | future enum membership | ENGINEER | Text now |
| education_level | Education attainment band (enum later; text now) | string | non‑PII | 2 | Y | future enum membership | BACHELOR | Text replaces id |
| business_type | Business activity type (enum later; text now) | string | non‑PII | 2 | Y | future enum membership | FINANCE | Thai examples provided |
| birthdate | Date of birth | date | PII | 2 | Y | <= current_date; age 18–120 | 1985-03-10 | Version‑driving |
| total_asset | Asset band/category (enum later; text now) | string | non‑PII | 2 | Y | future enum membership | ASSET_BAND_3 | Version‑driving |
| monthly_income | Monthly income band (enum later; text now) | string | non‑PII | 2 | Y | future enum membership | INCOME_BAND_2 | Version‑driving |
| income_country | Country of income origin (shares enum with nationality) | string | non‑PII | 2 | Y | future enum membership | TH | Distinct from nationality |
| source_of_income (bridge) | Multi‑valued sources of income | set<string> logical | non‑PII | Bridge | Y (membership) | members valid in enum | ["SALARY","DIVIDEND"] | Stored via bridge; used in hash via set hash |
| purpose_of_investment (bridge) | Multi‑valued investment purposes | set<string> logical | non‑PII | Bridge | Y (membership) | members valid in enum | ["RETIREMENT"] | Stored via bridge; used in hash via set hash |
| profile_hash | SHA256 over ordered normalized scalars + set hashes | string | non‑PII | Derived | Y (logic) | length=64 hex | 5e884898... | Single hash per version |
| version_num | Sequential version number per customer_id | int | non‑PII | 2 | N | >0 | 7 | Monotonic |
| effective_start_ts | UTC start timestamp of version validity | timestamp | non‑PII | 2 | N | not null | 2025‑12‑01T08:00:00Z | PIT queries |
| effective_end_ts | UTC end timestamp (null=current) | timestamp | non‑PII | 2 | N | end>start or null | null | |
| is_current | Flag for active version | boolean | non‑PII | 2 | N | single TRUE per customer_id | true | Performance flag |
| load_ts | Ingestion timestamp into warehouse | timestamp | non‑PII | Audit | N | not null | 2025‑12‑01T08:05:10Z | ETL metadata |

Notes:
- We removed coded FK IDs (marital_status_id, nationality_id, occupation_id, education_level_id) in favor of text fields with future enum validation.
- Local names preserve case in storage; hash normalization rules ensure deterministic change detection.

## 6. Semantic & Regulatory Notes
- Identity evidence (evidence_unique_key) is raw PII; enforce least‑privilege access controls and masking in non‑privileged contexts.
- Local name fields (firstname_local, lastname_local) preserve original case; normalization trims only leading/trailing spaces.
- Nationality and income_country will share a unified enumeration file (ISO‑based) but represent different semantics (citizenship vs economic origin).
- Person_title and business_type enumerations are deferred; values currently stored as text with future validation.
- No hashed PII surrogate (national_id_hash) is used at this time; may be introduced later for privacy‑preserving joins.

## 7. Change Behavior (SCD2 Rules)
New version is created when:
1. Any normalized change in a version‑driving scalar (evidence_unique_key, firstname, lastname, firstname_local, lastname_local, person_title, marital_status, nationality, occupation, education_level, business_type, birthdate, total_asset, monthly_income, income_country).
2. Any membership change (add/remove) in source_of_income or purpose_of_investment (order‑insensitive).
3. Backdated corrections (effective_start_ts earlier than current).
4. Identity evidence correction (evidence_unique_key change).

No new version when:
- Pure whitespace changes or non‑material formatting differences that normalization removes (e.g., casing if normalization uppercases for hash, except local names where case is preserved per rule).
- Non‑material changes outside the attribute set above.

Version closure:
- previous_row.effective_end_ts = new_effective_start_ts − microsecond (precision standard: microsecond).
- No overlapping intervals per customer_id.

## 8. Hashing Standard (Profile)
Canonical order for profile_hash:
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
16. source_of_income_set_hash (SHA256 of sorted, normalized members; empty set → SHA256(""))
17. purpose_of_investment_set_hash (same rule)

Assembly:
- Nulls become "__NULL__".
- Canonical string = concat_ws('|', values in the order above).
- profile_hash = SHA256(canonical string) → lowercase hex.

Set hash rules:
- Normalize members (UPPER(TRIM)), deduplicate, sort ascending, join with “|”, SHA256(joined).
- Empty set → SHA256("") constant (e3b0c44298fc1c149afbf4c8996fb924...).

Optional:
- Track hash_algorithm_version if you foresee changes to normalization/hash composition.

## 9. Relationships & Cardinality
- customer_id 1:M dim_customer_profile versions
- Each profile version 1:M source_of_income members (bridge)
- Each profile version 1:M purpose_of_investment members (bridge)
- Exactly one current version per customer_id (is_current = TRUE)
- profile_hash identifies material state of a version (collisions negligible with SHA256)

## 10. Edge Cases / Exceptions
- At least one of source_of_income or purpose_of_investment should have ≥1 member (recommended; can be relaxed for initial incomplete loads).
- Birthdate may be temporarily null in initial loads; not recommended. Monitor and remediate.
- Excessive churn due to name corrections should be monitored; if needed, exclude names from hash via ADR + hash version bump.

## 11. Source Systems & Cadence (Revised)
Upstream Standardization Flow:
- Operational DB View (IT) → Bronze → Silver → SCD2 Change Detection → Curated Dimensions & Bridges

Stages:
1. Operational DB (IT-owned)
   - Artifact: opdb.vw_customer_profile_standardized
   - Responsibility: Emit standardized columns per upstream view contract; apply canonical trimming/casing; enum‑ready values; dedup for sets if feasible.

2. Bronze (Landing)
   - Artifact: bronze.customer_profile_standardized (table)
   - Responsibility: Land upstream view as‑is; add ETL lineage fields (ingested_at, batch_id, source_system, load_file_name optional).

3. Silver (Standardized Passthrough)
   - Artifact: silver.vw_customer_profile_standardized (view)
   - Responsibility: Passthrough from Bronze; enforce guardrail validations (not null, basic format); compute set hashes if upstream does not.

4. SCD2 Change Detection (Curated write)
   - Responsibility: Assemble profile_hash; compare to current; close/open versions; write dim_customer_profile and bridge tables.

Cadence:
- Daily batch (day‑by‑day)
  - Ingestion window: once per day (e.g., 01:00 UTC)
  - Replay by batch_id/date supported
  - Latency target: publish SCD2 versions within same batch day

Alignment Principle:
- Schema parity across Operational View, Bronze, and Silver (>95% identical). Differences:
  - Bronze adds lineage columns
  - Silver may add validation flags
  - Hashing and version persistence occur post‑Silver

Monitoring (planned):
- Batch parity (counts across opdb → bronze → silver)
- Enumeration readiness checks (once catalogs exist)
- Version churn monitoring (e.g., names, business_type)
- Birthdate sanity and identity evidence consistency

## 12. Data Quality Rules
- No overlapping effective intervals per customer_id.
- birthdate ≤ current_date; age 18–120 (monitor exceptions).
- Normalized text values length > 0 for mandatory fields (firstname, lastname, evidence_unique_key).
- Enumeration validation must pass once catalogs published.
- profile_hash length = 64 hex; recomputation integrity tests must match.
- Set memberships deduplicated, normalized, hashed deterministically.

## 13. Completeness KPI (Conceptual)
Required core fields: evidence_unique_key, firstname, lastname, birthdate, occupation, nationality, (total_asset OR monthly_income), plus at least one of (source_of_income, purpose_of_investment).  
completeness_score = (#present_required / total_required)  
This KPI is computed analytically; not persisted in the dimension.

## 14. Mapping to Schema Artifacts
- dim_customer_profile (SCD2 dimension)
- dim_customer_income_source_version (bridge)
- dim_customer_investment_purpose_version (bridge)
- fact_customer_profile_audit (future)
- bronze.customer_profile_standardized (landing table)
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
      "marital_status": "MARRIED",
      "nationality": "TH",
      "occupation": "ENGINEER",
      "education_level": "BACHELOR",
      "business_type": "FINANCE",
      "birthdate": "1985-03-10",
      "total_asset": "ASSET_BAND_3",
      "monthly_income": "INCOME_BAND_2",
      "income_country": "TH",
      "source_of_income": ["SALARY","DIVIDEND"],
      "purpose_of_investment": ["RETIREMENT","EDUCATION"],
      "profile_hash": "5e884898da28047151d0e56f8dc62927..."
    }
  ]
}
```

## 16. Audit Events (Future)
Event types (PROFILE_VERSION_CREATE, PROFILE_VERSION_CORRECTION). Each event references:
- event_ts == effective_start_ts for created version
- previous_profile_hash (nullable on initial load)
- new_profile_hash
- diff summary (attributes changed + set membership deltas)
- rationale_code (INITIAL_LOAD, SOURCE_UPDATE, CORRECTION)

## 17. Pending Tasks
- Publish enumeration YAMLs for text‑coded attributes (nationality/income_country shared, occupation, marital_status, education_level, business_type, person_title, total_asset, monthly_income, source_of_income, purpose_of_investment).
- Define normalization macros/UDFs for hash assembly.
- Implement change detection job (compare recomputed profile_hash to current).
- Introduce optional evidence_type for identity classification.
- Add monitoring views for excessive version churn.

Change Log
| Date | Change | Author | Notes |
|------|--------|--------|-------|
| 2025-12-01 | Revised attribute inventory (text enums, names included, added business_type & person_title); aligned flow and cadence; confirmed single profile_hash per record | Data Architecture | Enumerations pending
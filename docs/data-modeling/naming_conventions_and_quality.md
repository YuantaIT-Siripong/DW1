# Naming Conventions and Data Quality Standards

Revision Date: 2025-12-01
Scope: Consolidates and reconciles “naming_conventions.md” and “naming_and_quality_cheatsheet.md” into a single authoritative standard for DW1.

1. Purpose
- Physical data warehouse artifacts (tables, columns, views, indexes, constraints)
- API-facing field names
- Hashing and data quality normalization hints
- SCD2 effective dating and flags
- Multi-valued set handling

2. Case Conventions
- Physical layer: snake_case
- API layer: camelCase
- URLs: prefer kebab-case

3. Table Naming
- Pattern: <layer_prefix>_<subject_area>_<entity>
- Prefixes: dim_, fact_, bridge_ (allowed), stg_, int_, rpt_, audit_
- Prefer dim_ for bridge dimensions under dimensional schema (bridge_ acceptable if a domain chooses it consistently).

Examples:
- dim_customer_profile
- dim_customer_income_source_version
- dim_customer_investment_purpose_version

4. Column Naming
- Pattern: <entity>_<attribute>_<modifier> (snake_case)
- Suffixes:
  - Keys: _sk, _version_sk, _id, _code
  - Time: _date (DATE), _ts (TIMESTAMP). Prefer _ts in physical layer; _timestamp acceptable in API layer.
  - Booleans: is_<state>, has_<attribute>, <attribute>_flag
  - Hashes: *_hash
  - Scores/Ratings: *_score, *_rating
- Bridge member storage:
  - Text members: *_text (e.g., income_source_text)
  - Coded members: *_code with UPPERCASE_SNAKE_CASE values

5. View/Index/Constraint Naming
- Views: vw_<subject_area>_<purpose>
- Indexes: idx_<table>_<column(s)>
- Constraints: <type>_<table>_<column(s)> (pk_, fk_, uq_, ck_)

6. API Field Naming
- Physical customer_id → API customerId
- effective_start_ts → effectiveStartTimestamp
- profile_hash → profileHash
- Use descriptive, full words.

7. SCD2 Standards
- effective_start_ts inclusive; effective_end_ts exclusive (NULL=current)
- One is_current = TRUE per business key
- version_num is monotonic per business key
- *_version_sk is surrogate per row

8. Hashing Standards (Summary)
- SHA256; 64-char lowercase hex
- Include only version-driving attributes; exclude keys, timestamps, flags, derived scores, audit fields, and the hash itself
- Ordering: alphabetical by default; allow module-specific override (e.g., Customer Profile uses fixed canonical order)
- Normalization defaults:
  - Strings: LOWER(TRIM); module-specific overrides allowed (e.g., local names preserve case, other text UPPER(TRIM))
  - Nulls: default __NULL__; overrides allowed (Customer Profile uses empty string)
  - Dates: YYYY-MM-DD; Timestamps: ISO to seconds
- Set hashes:
  - Normalize, dedupe, sort asc, join with '|', SHA256; empty set → SHA256("")

9. Multi-Valued Sets (Bridge Dimensions)
- Key on (profile_version_sk, member column)
- Member column uses *_text (or *_code if coded)
- Enforce uniqueness per version
- Parent SCD2 dimension uses set hash to detect changes

10. Data Quality Checklist
- Uniqueness: (business key, version_num)
- Non-overlap: effective_end_ts >= effective_start_ts or NULL
- Hash integrity matches recomputation
- Enumeration validation once catalogs exist
- PII least-privilege access
- Required fields enforced where mandated

11. Abbreviations/Acronyms
- Allowed: id, sk, ts, num, max, min, avg, pct
- Avoid ambiguous abbreviations; domain acronyms OK if documented (kyc, aml, pep, fatca, sbl, esg)

12. Plural vs Singular
- Table names: singular (prefer)
- Bridge tables: singular preferred for consistency
- Column names: singular, plural only for array types

13. File Naming
- Docs: snake_case
- SQL scripts: <sequence>_<action>_<subject>.sql
- dbt models: <layer>__<entity>.sql

14. Enforcement
- Lint (SQLFluff), code review, dbt macros/tests, API schema validators

15. Examples
- dim_customer_profile: customer_profile_version_sk, customer_id, version_num, is_current, effective_start_ts, effective_end_ts, profile_hash
- dim_customer_income_source_version: customer_profile_version_sk, income_source_text, load_ts
- dim_customer_investment_purpose_version: customer_profile_version_sk, investment_purpose_text, load_ts

16. Change Log
| Version | Date | Change | Author |
| 2.0 | 2025-12-01 | Merged naming conventions + cheatsheet; resolved conflicts and clarified overrides | Data Architecture |
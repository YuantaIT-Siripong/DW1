# Naming Conventions

## Purpose
This document establishes authoritative naming conventions for database objects, API contracts, and code artifacts in DW1. Consistent naming ensures:
- **Readability:** Clear, predictable names
- **Maintainability:** Easy to navigate schema and code
- **AI-Assisted Development:** LLMs and AI tools benefit from consistent patterns
- **Cross-Team Collaboration:** Unified standards across data engineering, analytics, and application teams

## Scope
These conventions apply to:
- **Physical layer:** Database tables, columns, views, indexes, constraints
- **API layer:** JSON fields, REST endpoints, GraphQL schemas
- **Code artifacts:** Functions, macros, dbt models, scripts
- **Documentation:** File names, section headers

## Physical Layer: snake_case

### Rule
All physical database objects **MUST** use **snake_case** (lowercase with underscores).

**Rationale:**
- Standard practice in PostgreSQL, Snowflake, Redshift, BigQuery
- Case-insensitive SQL benefits from lowercase consistency
- Avoids quoting requirements for mixed-case identifiers

### Table Names

**Pattern:**
```
<layer_prefix>_<subject_area>_<entity>
```

**Examples:**
```
dim_customer_profile
dim_investment_profile_version
fact_service_request
fact_customer_profile_audit
bridge_customer_income_source_version
```

**Layer Prefixes:**
- `dim_`: Dimension tables
- `fact_`: Fact tables
- `bridge_`: Bridge tables (many-to-many)
- `stg_`: Staging tables
- `int_`: Integration/intermediate tables
- `rpt_`: Reporting/presentation tables
- `audit_`: Audit tables

### Column Names

**Pattern:**
```
<entity>_<attribute>_<modifier>
```

**Examples:**
```
customer_id
customer_profile_version_sk
effective_start_ts
effective_end_date
is_current
marital_status_id
income_source_set_hash
data_quality_score
```

**Special Cases:**
- Avoid redundant prefixes: Use `email_address` not `customer_email_address` in `dim_customer_profile`
- Exception: Foreign keys should include the referenced table hint: `service_category_id` (FK to `dim_service_category`)

### View Names

**Pattern:**
```
vw_<subject_area>_<purpose>
```

**Examples:**
```
vw_customer_current_profile
vw_investment_entitlement_expanded
vw_service_subscription_summary
```

### Index Names

**Pattern:**
```
idx_<table>_<column(s)>
```

**Examples:**
```
idx_dim_customer_profile_customer_id
idx_dim_investment_profile_version_effective_start_ts
idx_fact_service_request_service_id_request_date
```

### Constraint Names

**Pattern:**
```
<constraint_type>_<table>_<column(s)>
```

**Constraint Types:**
- `pk_`: Primary key
- `fk_`: Foreign key
- `uq_`: Unique constraint
- `ck_`: Check constraint

**Examples:**
```
pk_dim_customer_profile_version_sk
fk_fact_service_request_service_id
uq_dim_customer_profile_customer_id_version_num
ck_dim_investment_profile_version_effective_dates
```

## API Layer: camelCase

### Rule
All API-facing fields **MUST** use **camelCase** (lowercase first letter, capitalize subsequent words).

**Rationale:**
- Standard in JSON, JavaScript, REST APIs
- Improves readability in API documentation
- Aligns with frontend frameworks (React, Angular, Vue)

### JSON Field Names

**Pattern:**
```
<entity><Attribute><Modifier>
```

**Examples:**
```json
{
  "customerId": "C12345",
  "customerProfileVersionSk": 1001,
  "effectiveStartDate": "2025-01-15",
  "effectiveEndDate": null,
  "isCurrent": true,
  "maritalStatusId": "MARRIED",
  "incomeSourceSetHash": "a3f2c...",
  "dataQualityScore": 92.5
}
```

### Mapping: Physical to API

| Physical Layer (snake_case) | API Layer (camelCase) |
|-----------------------------|----------------------|
| `customer_id` | `customerId` |
| `customer_profile_version_sk` | `customerProfileVersionSk` |
| `effective_start_ts` | `effectiveStartTs` or `effectiveStartTimestamp` |
| `is_current` | `isCurrent` |
| `income_source_set_hash` | `incomeSourceSetHash` |
| `data_quality_score` | `dataQualityScore` |

**Note:** Use full words in API layer for clarity (e.g., `effectiveStartTimestamp` preferred over `effectiveStartTs`).

### REST Endpoint Naming

**Pattern:**
```
/<resource>/<identifier>/<sub-resource>
```

**Examples:**
```
GET /customers/C12345/profile
GET /customers/C12345/profile/versions
GET /investmentProfiles/IP-C12345/entitlements
POST /customers/C12345/profile/update
```

**Case:** Use kebab-case or camelCase for endpoint paths (be consistent; prefer kebab-case for URLs).

## Surrogate Key Suffix Patterns

### Rule
All surrogate keys **MUST** use the `_sk` suffix (physical) or `Sk` suffix (API).

### Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| `<entity>_sk` | Non-versioned dimension surrogate key | `customer_sk`, `service_sk` |
| `<entity>_version_sk` | SCD2 version surrogate key | `customer_profile_version_sk`, `investment_profile_version_sk` |
| `<fact>_sk` | Fact table surrogate key | `service_request_sk`, `subscription_event_sk` |

### Distinguishing Business Keys vs Surrogate Keys

| Key Type | Suffix | Example |
|----------|--------|---------|
| **Business/Natural Key** | `_id` or `_code` | `customer_id`, `service_code`, `investment_profile_id` |
| **Surrogate Key** | `_sk` | `customer_profile_version_sk`, `service_sk` |
| **Foreign Key** | `_id` or `_sk` | `marital_status_id` (FK to constant), `customer_profile_version_sk` (FK to SCD2 dimension) |

**Rule of Thumb:**
- If it's a **generated, meaningless identifier** (auto-increment, UUID), use `_sk`.
- If it's a **business-meaningful code** (e.g., `customer_id = "C12345"`), use `_id` or `_code`.

### Version Number vs Version Surrogate Key

Do **not** confuse:
- `version_num` (INTEGER, monotonically increasing version number: 1, 2, 3, ...)
- `<entity>_version_sk` (BIGINT, unique surrogate key for each version row: 1001, 1002, 1003, ...)

**Example:**
```sql
customer_profile_version_sk: 1001  -- Surrogate key
customer_id: "C12345"              -- Business key
version_num: 1                     -- Version number (first version)
```

## Boolean Flag Patterns

### Rule
All boolean flags **MUST** use one of the following prefixes: `is_`, `has_`, or suffix `_flag`.

### Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| `is_<state>` | Indicates a state or condition | `is_current`, `is_active`, `is_deleted` |
| `has_<attribute>` | Indicates possession or presence | `has_dependents`, `has_margin_agreement` |
| `<attribute>_flag` | General boolean indicator | `pep_flag`, `vulnerable_investor_flag`, `current_flag` |

### Examples

| Column Name | Meaning |
|-------------|---------|
| `is_current` | Is this the current/active version? |
| `is_deleted` | Is this record soft-deleted? |
| `has_derivatives_approval` | Does the investor have derivatives approval? |
| `pep_flag` | Is the person a Politically Exposed Person? |
| `vulnerable_investor_flag` | Is the investor classified as vulnerable? |
| `complex_product_allowed` | Is the investor allowed to trade complex products? (NOTE: Not a boolean flag pattern, but treated as boolean) |

### Avoid Ambiguous Names
❌ **Bad:**
```
active  (active what? active customer? active subscription?)
deleted (is this a flag or a timestamp?)
flag    (too generic)
```

✅ **Good:**
```
is_active
is_deleted
approval_flag
```

### API Mapping
Physical `is_current` → API `isCurrent`
Physical `pep_flag` → API `pepFlag`
Physical `vulnerable_investor_flag` → API `vulnerableInvestorFlag`

## Enumeration Casing

### Rule
All enumeration values stored in the database **MUST** use **UPPERCASE_SNAKE_CASE**.

**Rationale:**
- Distinguishes enumerations from regular data
- Standard practice in many databases (Oracle, PostgreSQL)
- Clear visual distinction between code values and descriptive text

### Examples

| Enumeration Type | Valid Values |
|------------------|--------------|
| `marital_status_id` | `SINGLE`, `MARRIED`, `DIVORCED`, `WIDOWED`, `UNKNOWN` |
| `risk_level_code` | `VERY_LOW`, `LOW`, `MODERATE`, `HIGH`, `VERY_HIGH` |
| `investor_category` | `RETAIL`, `PROFESSIONAL`, `INSTITUTIONAL`, `ACCREDITED` |
| `kyc_status` | `PENDING`, `IN_REVIEW`, `APPROVED`, `REJECTED`, `EXPIRED` |
| `vulnerability_reason_code` | `ELDERLY`, `LOW_LITERACY`, `DISABILITY`, `LOW_INCOME`, `UNKNOWN` |

### Constant Tables
Enumeration values should be stored in constant/reference tables:

```sql
CREATE TABLE dim_marital_status (
    marital_status_id VARCHAR(20) PRIMARY KEY,  -- UPPERCASE_SNAKE_CASE
    description_en VARCHAR(100),
    description_th VARCHAR(100),
    display_order INTEGER
);

INSERT INTO dim_marital_status VALUES 
    ('SINGLE', 'Single', 'โสด', 1),
    ('MARRIED', 'Married', 'สมรส', 2),
    ('DIVORCED', 'Divorced', 'หย่าร้าง', 3);
```

### API Mapping
Physical enumerations remain UPPERCASE in API responses for consistency:

```json
{
  "maritalStatusId": "MARRIED",
  "riskLevelCode": "MODERATE",
  "kycStatus": "APPROVED"
}
```

**Alternative:** If API consumer requires lowercase, perform case conversion in the API layer, not the database.

## Hash & Score Suffix Patterns

### Hash Suffixes

**Rule:** All hash columns **MUST** end with `_hash`.

**Pattern:**
```
<subject>_hash
```

**Examples:**
```
profile_change_hash
profile_hash
income_source_set_hash
investment_purpose_set_hash
contact_channel_set_hash
record_fingerprint_hash
```

### Score Suffixes

**Rule:** All score/metric columns **MUST** end with `_score` or `_rating`.

**Pattern:**
```
<metric>_score
<metric>_rating
```

**Examples:**
```
data_quality_score
profile_reliability_score
suitability_score
kyc_risk_rating
aml_risk_rating
```

### Distinguishing Hashes vs Scores

| Type | Suffix | Purpose | Example |
|------|--------|---------|---------|
| **Hash** | `_hash` | Change detection, deduplication | `profile_change_hash` |
| **Score** | `_score` | Quantitative metric (0-100 scale) | `data_quality_score` |
| **Rating** | `_rating` | Qualitative assessment (e.g., LOW/MEDIUM/HIGH) | `kyc_risk_rating` |

**Important:** Hashes are **immutable deterministic outputs** of input data. Scores are **derived metrics** that may be recalculated. See [Hashing Standards](hashing_standards.md) for exclusion rules.

## Special Conventions

### Timestamp vs Date Suffixes

| Suffix | Data Type | Precision | Example |
|--------|-----------|-----------|---------|
| `_date` | DATE | Day | `effective_start_date`, `birthdate` |
| `_ts` | TIMESTAMP | Second or Microsecond | `effective_start_ts`, `created_ts` |
| `_timestamp` | TIMESTAMP | Second or Microsecond | `effective_start_timestamp` (verbose alternative) |

**Rule:**
- Use `_date` for day-level granularity (no time component).
- Use `_ts` for timestamp granularity (includes time).
- **Prefer `_ts`** for brevity in physical layer; use `_timestamp` in API layer for clarity.

### Abbreviations

**General Rule:** Avoid abbreviations unless they are industry-standard or widely understood.

**Acceptable Abbreviations:**
- `id`: identifier
- `sk`: surrogate key
- `ts`: timestamp
- `num`: number
- `max`: maximum
- `min`: minimum
- `avg`: average
- `pct`: percent

**Avoid:**
- `cust` → Use `customer`
- `inv` → Use `investment` or `invoice` (ambiguous)
- `addr` → Use `address`
- `qty` → Use `quantity`

**Exception:** Domain-specific acronyms are acceptable if documented:
- `kyc`: Know Your Customer
- `aml`: Anti-Money Laundering
- `pep`: Politically Exposed Person
- `fatca`: Foreign Account Tax Compliance Act
- `sbl`: Securities-Based Lending
- `esg`: Environmental, Social, Governance

### Plural vs Singular

**Table Names:** Use **singular** form.
```
dim_customer (not dim_customers)
fact_service_request (not fact_service_requests)
```

**Rationale:** Each row represents **one** customer, **one** service request.

**Exception:** Bridge tables may use plural if representing a set:
```
bridge_customer_income_sources (acceptable if preferred)
bridge_customer_income_source_version (singular, preferred for consistency)
```

**Column Names:** Use **singular** for single values, **plural** for arrays/sets (if supported).
```
customer_id (singular: one ID)
income_source_ids (plural: array of IDs, if using PostgreSQL array type)
```

## File Naming Conventions

### Documentation Files

**Pattern:**
```
<subject>_<topic>.md
```

**Examples:**
```
naming_conventions.md
hashing_standards.md
fact_vs_dimension_decisions.md
STANDARD_SCD2_POLICY.md
```

**Case:** Use **snake_case** for documentation filenames, **UPPERCASE** for policy/specification documents (e.g., `STANDARD_SCD2_POLICY.md`, `README.md`).

### SQL Scripts

**Pattern:**
```
<sequence>_<action>_<subject>.sql
```

**Examples:**
```
001_create_dim_customer_profile.sql
002_create_fact_service_request.sql
010_insert_constant_marital_status.sql
```

### dbt Models

**Pattern:**
```
<layer>_<subject_area>__<entity>.sql
```

**Examples:**
```
dim__customer_profile.sql
fact__service_request.sql
int__customer_profile_dedupe.sql
```

**Note:** dbt uses double underscores `__` to separate layer from entity.

## Validation Checklist

Use this checklist to validate naming conventions:

- [ ] **Physical layer:** All table and column names use snake_case
- [ ] **API layer:** All JSON fields use camelCase
- [ ] **Surrogate keys:** Use `_sk` or `_version_sk` suffix
- [ ] **Boolean flags:** Use `is_`, `has_`, or `_flag` pattern
- [ ] **Enumerations:** Use UPPERCASE_SNAKE_CASE for values
- [ ] **Hashes:** Use `_hash` suffix
- [ ] **Scores:** Use `_score` or `_rating` suffix
- [ ] **Timestamps:** Use `_ts` or `_timestamp` (not `_dt` or `_time`)
- [ ] **Dates:** Use `_date` suffix
- [ ] **Abbreviations:** Avoid unless standard (id, sk, ts, num)
- [ ] **Table names:** Use singular form
- [ ] **Constraint names:** Follow `<type>_<table>_<column>` pattern

## Enforcement

### Database Level
- Use naming conventions in DDL scripts and migrations.
- Enforce via code review and linting tools (e.g., SQLFluff).

### dbt Level
- Use dbt macros to enforce naming patterns.
- Validate with dbt tests (e.g., `dbt test --schema`).

### API Level
- Use API schema validators (JSON Schema, OpenAPI).
- Transform physical names to camelCase in ORM/serialization layer.

## Examples: Full Stack Naming

### Example 1: Customer Profile Dimension

| Layer | Name | Case |
|-------|------|------|
| **Physical Table** | `dim_customer_profile` | snake_case |
| **Surrogate Key** | `customer_profile_version_sk` | snake_case |
| **Business Key** | `customer_id` | snake_case |
| **Boolean Flag** | `is_current` | snake_case |
| **Hash Column** | `profile_change_hash` | snake_case |
| **API Endpoint** | `/customers/{id}/profile` | kebab-case |
| **API JSON Field** | `customerProfileVersionSk` | camelCase |
| **dbt Model** | `dim__customer_profile.sql` | snake_case |

### Example 2: Investment Profile Version

| Layer | Name | Case |
|-------|------|------|
| **Physical Table** | `dim_investment_profile_version` | snake_case |
| **Surrogate Key** | `investment_profile_version_sk` | snake_case |
| **Business Key** | `investment_profile_id` | snake_case |
| **Boolean Flag** | `vulnerable_investor_flag` | snake_case |
| **Score Column** | `profile_reliability_score` | snake_case |
| **Enumeration** | `risk_level_code = 'MODERATE'` | UPPERCASE_SNAKE_CASE |
| **API Endpoint** | `/investmentProfiles/{id}/versions` | camelCase |
| **API JSON Field** | `vulnerableInvestorFlag` | camelCase |

## Related Documents
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md)
- [Hashing Standards](hashing_standards.md)
- [Data Modeling README](README.md)
- [Naming & Quality Cheatsheet](naming_and_quality_cheatsheet.md)
- [AI_CONTEXT.md](../../AI_CONTEXT.md)

## Change Log
| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-11-21 | Initial naming conventions (snake_case, camelCase, suffixes, enumerations) | Data Architecture |

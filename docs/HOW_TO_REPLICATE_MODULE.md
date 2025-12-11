# How to Replicate a Module Pattern

**Purpose**: Step-by-step guide for building a new module following the Customer Profile pattern  
**Target Audience**: AI agents, developers, data engineers  
**Reference Module**: Customer Profile (Bronze → Silver → Gold pattern with SCD2)  
**Estimated Time**: 4-8 hours for a standard module

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [10-Step Implementation Process](#10-step-implementation-process)
4. [Validation & Testing](#validation--testing)
5. [Common Patterns](#common-patterns)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Knowledge
- ✅ Understanding of medallion architecture (Bronze/Silver/Gold layers)
- ✅ Familiarity with SCD Type 2 dimensions
- ✅ Basic SQL and dbt knowledge
- ✅ Understanding of SHA256 hashing for change detection

### Required Tools
- PostgreSQL database access
- dbt installed and configured
- Text editor or IDE
- Git for version control

### Reference Materials
- Customer Profile Module: `docs/business/modules/customer_module.md`
- Standards Index: `STANDARDS_INDEX.md`
- AI Context: `AI_CONTEXT.md`
- Naming Conventions: `docs/data-modeling/naming_conventions.md`
- Hashing Standards: `docs/data-modeling/hashing_standards.md`

---

## Architecture Overview

### Medallion Architecture Pattern

```
Source System (IT Operational DB)
    ↓
    ↓ (IT creates standardized view)
    ↓
┌───────────────────────────────────────┐
│  BRONZE LAYER (Raw Landing)           │
│  - Exact mirror of source + metadata  │
│  - Immutable append-only              │
│  - No transformations                 │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│  SILVER LAYER (Cleaned & Validated)   │
│  - Type conversions                   │
│  - Normalization (TRIM, UPPER)        │
│  - Hash computation                   │
│  - Data quality flags                 │
│  - Still flat table (not dimensional) │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│  GOLD LAYER (Dimensional Model)       │
│  - SCD Type 2 dimensions              │
│  - Surrogate keys                     │
│  - Bridge tables (multi-valued sets)  │
│  - Star schema structure              │
└───────────────────────────────────────┘
```

### Key Concepts

**Bronze Layer** = Raw historical archive  
**Silver Layer** = Cleaned data with computed columns  
**Gold Layer** = Analytics-ready dimensional model  

**SCD Type 1** = Overwrite (no history)  
**SCD Type 2** = Versioning (full history)  

**Profile Hash** = SHA256 of all version-driving attributes  
**Set Hash** = SHA256 of sorted, pipe-delimited multi-valued set  

---

## 10-Step Implementation Process

### Step 1: Define Business Requirements

**Objective**: Create comprehensive business specification for the new module

**Actions**:
1. Create business specification document
2. Define entities and relationships
3. Identify all attributes and their characteristics
4. Determine SCD type for each attribute (Type 1 or Type 2)
5. Document multi-valued sets (if any)
6. Define data quality rules

**Deliverable**: `docs/business/modules/{module_name}_module.md`

**Template Sections**:
```markdown
1. Module Overview
2. Business Goals / KPIs
3. Core Use Cases
4. Entity Inventory
5. Attribute Inventory (with SCD types)
6. Semantic & Regulatory Notes
7. Change Behavior (SCD2 Rules)
8. Hashing Standard
9. Relationships & Cardinality
10. Edge Cases / Exceptions
11. Source Systems & Cadence
12. Data Quality Rules
13. Completeness KPI
14. Mapping to Schema Artifacts
15. Sample Record
16. Audit Events (Future)
17. Pending Tasks
18. Upstream Requirements for IT View
```

**Example** (Investment Profile):
```markdown
# Investment Profile Module Domain Specification

## 1. Module Overview
The Investment Profile Module establishes the canonical, versioned representation of 
a client's investment characteristics (risk appetite, knowledge level, experience, 
suitability assessment, KYC/AML status).

## 5. Attribute Inventory
| attribute_name | datatype | classification | SCD_type | version_trigger |
|----------------|----------|---------------|----------|-----------------|
| investment_profile_version_sk | bigint | non-PII | N/A | N |
| customer_id | bigint | non-PII | 1 | N |
| risk_appetite | varchar(50) | non-PII | 2 | Y |
| knowledge_level | varchar(50) | non-PII | 2 | Y |
| experience_level | varchar(50) | non-PII | 2 | Y |
| suitability_score | decimal | non-PII | 2 | Y |
| kyc_status | varchar(50) | non-PII | 2 | Y |
| aml_status | varchar(50) | non-PII | 2 | Y |
| assessment_date | date | non-PII | 2 | Y |
```

---

### Step 2: Create Enumeration Files

**Objective**: Define all valid enumeration values for the new module

**Actions**:
1. Identify all enumeration fields from Step 1
2. Create YAML file for each enumeration
3. Follow enumeration standards
4. Include code, description, sort_order
5. Document "OTHER" handling (if applicable)

**Deliverables**: Multiple YAML files in `/enumerations/` folder

**File Naming**: `{domain}_{attribute_name}.yaml`

**Example** (Investment Risk Appetite):
```yaml
# File: enumerations/investment_risk_appetite.yaml
enumeration_name: investment_risk_appetite
domain: investment
description: Investment risk appetite classification for suitability assessment
version: 1.0
last_updated: 2025-12-11

values:
  - code: CONSERVATIVE
    description: Low risk tolerance, capital preservation focus
    sort_order: 1
    
  - code: MODERATE_CONSERVATIVE
    description: Below-average risk tolerance, stability preferred
    sort_order: 2
    
  - code: MODERATE
    description: Balanced risk-return profile
    sort_order: 3
    
  - code: MODERATE_AGGRESSIVE
    description: Above-average risk tolerance for growth
    sort_order: 4
    
  - code: AGGRESSIVE
    description: High risk tolerance, maximum growth focus
    sort_order: 5
    
  - code: UNKNOWN
    description: Risk appetite not yet assessed
    sort_order: 99

notes: |
  - No "OTHER" option - must select from defined risk levels
  - Assessment should be refreshed annually or on major life events
  - Used in suitability calculations and investment recommendations
```

**Required Enumerations** (Example for Investment Profile):
- `investment_risk_appetite.yaml`
- `investment_knowledge_level.yaml`
- `investment_experience_level.yaml`
- `investment_objective.yaml` (if multi-valued, separate enumeration)
- `kyc_status.yaml`
- `aml_status.yaml`
- `suitability_rating.yaml`

---

### Step 3: Create Bronze Contract

**Objective**: Define the schema for raw landing zone

**Actions**:
1. Copy `contracts/bronze/customer_profile_standardized.yaml`
2. Rename to `{module}_standardized.yaml`
3. Update entity_name, domain, table_type
4. Replace attributes with module-specific fields
5. Keep Bronze metadata columns (_bronze_load_ts, _bronze_batch_id, _bronze_source_file)
6. Document source system and IT view

**Deliverable**: `contracts/bronze/{module}_standardized.yaml`

**Key Sections**:
```yaml
entity_name: {module}_standardized
domain: {domain}
table_type: landing
layer: bronze
grain_description: One record per {entity} from IT operational view

upstream_source:
  system: IT Operational Database
  view_name: opdb.vw_{module}_standardized
  owner: IT Department
  
primary_keys:
  - {entity}_id
  
attributes:
  # Natural Key
  - name: {entity}_id
    datatype: VARCHAR(50)
    business_definition: Unique business key
    nullable: false
    primary_key: true
    
  # Domain-specific attributes
  - name: risk_appetite
    datatype: VARCHAR(50)
    business_definition: Risk appetite enumeration code
    enumeration_ref: enumerations/investment_risk_appetite.yaml
    nullable: true
    
  # ETL Metadata (Standard for all Bronze tables)
  - name: _bronze_load_ts
    datatype: TIMESTAMP
    business_definition: UTC timestamp when landed into Bronze
    nullable: false
    default: CURRENT_TIMESTAMP
    etl_metadata: true
    
  - name: _bronze_source_file
    datatype: VARCHAR(500)
    business_definition: Source view or file identifier
    nullable: true
    etl_metadata: true
    
  - name: _bronze_batch_id
    datatype: BIGINT
    business_definition: ETL batch identifier for lineage
    nullable: true
    etl_metadata: true

immutability_policy: |
  Bronze records are immutable once landed. 
  Never UPDATE or DELETE Bronze records.
  Append-only pattern for historical audit trail.
```

---

### Step 4: Create Silver Contract

**Objective**: Define schema for cleaned and validated data with computed columns

**Actions**:
1. Copy `contracts/silver/customer_profile_standardized.yaml`
2. Update attributes for the new module
3. Add computed columns (hashes, DQ flags)
4. Define validation rules for each attribute
5. Specify data quality score calculation

**Deliverable**: `contracts/silver/{module}_standardized.yaml`

**Additional Columns in Silver** (vs Bronze):
```yaml
# Computed Set Hashes (if multi-valued sets exist)
- name: {set_name}_set_hash
  datatype: VARCHAR(64)
  business_definition: SHA256 hash of sorted, normalized {set_name} codes
  computation: SHA256(sorted_pipe_delimited_codes)
  nullable: true

# Profile Hash (for SCD2 change detection)
- name: profile_hash
  datatype: VARCHAR(64)
  business_definition: SHA256 hash of all version-driving attributes
  nullable: false
  length: 64

# Data Quality Flags
- name: dq_{attribute}_valid
  datatype: BOOLEAN
  business_definition: Validation flag for {attribute}
  nullable: false
  default: false

# Data Quality Score
- name: dq_score
  datatype: NUMERIC(5,2)
  business_definition: Percentage of passed validations (0-100)
  nullable: false

# Data Quality Status
- name: dq_status
  datatype: VARCHAR(20)
  business_definition: Categorical quality classification
  valid_values: [VALID, WARNING, INVALID]
  nullable: false

# Silver Metadata
- name: _silver_load_ts
  datatype: TIMESTAMP
  business_definition: UTC timestamp when processed to Silver
  nullable: false
  default: CURRENT_TIMESTAMP
```

---

### Step 5: Create Gold Contract

**Objective**: Define SCD Type 2 dimension schema with version management

**Actions**:
1. Copy `contracts/customer/dim_customer_profile.yaml`
2. Rename to `dim_{module}.yaml`
3. Update surrogate key name ({module}_version_sk)
4. Define versioning attributes (Type 2)
5. Define non-versioning attributes (Type 1)
6. Specify hash logic and canonical order
7. Add SCD2 temporal columns

**Deliverable**: `contracts/{domain}/dim_{module}.yaml`

**Key Additions**:
```yaml
# Surrogate Key
- name: {module}_version_sk
  datatype: BIGINT
  business_definition: Surrogate key for version
  scd_role: surrogate_key
  nullable: false
  primary_key: true

# Natural Key
- name: {entity}_id
  datatype: BIGINT
  business_definition: Stable identifier
  scd_role: natural_key
  nullable: false

# SCD2 Temporal Columns
- name: effective_start_ts
  datatype: TIMESTAMP
  business_definition: Version start timestamp (UTC)
  scd_role: effective_from
  nullable: false

- name: effective_end_ts
  datatype: TIMESTAMP
  business_definition: Version end timestamp (NULL = current)
  scd_role: effective_to
  nullable: true

- name: is_current
  datatype: BOOLEAN
  business_definition: Current version flag
  scd_role: current_flag
  nullable: false
  quality_rules:
    - Exactly one TRUE per {entity}_id

- name: version_num
  datatype: INT
  business_definition: Sequential version number
  scd_role: version_number
  nullable: false
  quality_rules:
    - version_num > 0
    - Monotonic increasing per {entity}_id

# Profile Hash (for change detection)
- name: profile_hash
  datatype: VARCHAR(64)
  business_definition: SHA256 hash for change detection
  hash_participation: false
  nullable: false

# Hash Specification
hash_spec:
  algorithm: SHA256
  ordered_attribute_list:
    - risk_appetite
    - knowledge_level
    - experience_level
    - suitability_score
    - kyc_status
    - aml_status
    - assessment_date
    # ... all Type 2 attributes in order
  normalization:
    risk_appetite: UPPER(TRIM)
    knowledge_level: UPPER(TRIM)
    suitability_score: ROUND(2)  # Decimal precision
    assessment_date: YYYY-MM-DD
  delimiter: "|"
  null_token: "__NULL__"

# Change Detection Logic
change_detection_logic: |
  1. Compute profile_hash for incoming record
  2. Compare with latest version's profile_hash
  3. If different: Create new version
     - Close previous: effective_end_ts = new_start - 1 microsecond
     - Set previous is_current = FALSE
     - Insert new: is_current = TRUE, effective_end_ts = NULL
     - Increment version_num
  4. If same: No action
```

---

### Step 6: Create Bridge Contracts (If Multi-Valued Sets)

**Objective**: Define bridge tables for many-to-many relationships

**When to Use**: When an attribute can have multiple values per version

**Examples**: 
- Investment objectives (multiple per profile)
- Income sources (multiple per customer)
- Contact channels (multiple per customer)

**Actions**:
1. Identify multi-valued attributes
2. Create bridge contract for each set
3. Define composite primary key (version_sk, code)
4. Reference enumeration file

**Deliverable**: `contracts/{domain}/bridge_{entity}_{set_name}_version.yaml`

**Example**:
```yaml
# File: contracts/investment/bridge_investment_objective_version.yaml
entity_name: bridge_investment_objective_version
domain: investment
table_type: bridge
layer: gold
grain_description: One record per investment objective per profile version

primary_keys:
  - investment_profile_version_sk
  - objective_code

attributes:
  - name: investment_profile_version_sk
    datatype: BIGINT
    business_definition: FK to versioned dimension
    nullable: false
    foreign_key: gold.dim_investment_profile(investment_profile_version_sk)
    
  - name: objective_code
    datatype: VARCHAR(50)
    business_definition: Investment objective enumeration code
    nullable: false
    enumeration_ref: enumerations/investment_objective.yaml
    
  - name: created_ts
    datatype: TIMESTAMP
    business_definition: Record creation timestamp
    nullable: false
    default: CURRENT_TIMESTAMP

indexes:
  - name: pk_bridge_investment_objective
    type: primary_key
    columns: [investment_profile_version_sk, objective_code]
    
  - name: idx_bridge_investment_objective_version
    type: non_unique
    columns: [investment_profile_version_sk]
    description: Lookup by version (most common)
    
  - name: idx_bridge_investment_objective_code
    type: non_unique
    columns: [objective_code]
    description: Reverse lookup by code
```

---

### Step 7: Implement Bronze DDL

**Objective**: Create database table definition for raw landing zone

**Actions**:
1. Create SQL file in `db/bronze/`
2. Follow Bronze contract exactly
3. Add comprehensive column comments
4. Create indexes for metadata columns
5. Add immutability policy note

**Deliverable**: `db/bronze/{module}_standardized.sql`

**Template**:
```sql
-- =====================================================================
-- Bronze Layer: {module}_standardized
-- Raw landing zone - exact mirror of IT operational view
-- =====================================================================
-- Source Contract: contracts/bronze/{module}_standardized.yaml
-- Database: PostgreSQL
-- Layer: Bronze
-- Created: {date}
-- =====================================================================

-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS bronze;

-- Create table
CREATE TABLE bronze.{module}_standardized (
    -- Natural Key
    {entity}_id VARCHAR(50) NOT NULL,
    
    -- Domain Attributes (from IT view)
    risk_appetite VARCHAR(50),
    knowledge_level VARCHAR(50),
    experience_level VARCHAR(50),
    -- ... more attributes ...
    
    -- Source Metadata
    last_modified_ts TIMESTAMP,
    
    -- Bronze ETL Metadata
    _bronze_load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _bronze_source_file VARCHAR(500) DEFAULT 'opdb.vw_{module}_standardized',
    _bronze_batch_id BIGINT,
    
    -- Primary Key
    CONSTRAINT pk_bronze_{module} PRIMARY KEY ({entity}_id, last_modified_ts)
);

-- Indexes
CREATE INDEX idx_bronze_{module}_load_ts 
    ON bronze.{module}_standardized (_bronze_load_ts);

CREATE INDEX idx_bronze_{module}_batch_id 
    ON bronze.{module}_standardized (_bronze_batch_id);

-- Comments on table
COMMENT ON TABLE bronze.{module}_standardized IS 
'Raw landing zone for {module} data from IT operational view. Immutable append-only.';

-- Comments on key columns
COMMENT ON COLUMN bronze.{module}_standardized.{entity}_id IS 
'Unique business key from operational system';

COMMENT ON COLUMN bronze.{module}_standardized._bronze_load_ts IS 
'UTC timestamp when record was landed into Bronze';

-- Grant permissions
GRANT SELECT, INSERT ON bronze.{module}_standardized TO dw_etl_service;
GRANT SELECT ON bronze.{module}_standardized TO dw_privileged;

-- Immutability policy note
-- Bronze records are append-only. Never UPDATE or DELETE.
```

---

### Step 8: Implement Silver dbt Model

**Objective**: Create dbt model for cleaned and validated data

**Actions**:
1. Create dbt model in `dbt/models/silver/`
2. Use incremental materialization
3. Structure with CTEs (source, validated, with_hashes, with_profile_hash, final)
4. Add data quality validations
5. Compute hashes using macros
6. Calculate DQ score and status

**Deliverable**: `dbt/models/silver/{module}_standardized.sql`

**Template Structure**:
```sql
{{
    config(
        materialized='incremental',
        unique_key=['{entity}_id', 'last_modified_ts'],
        on_schema_change='fail',
        schema='silver'
    )
}}

WITH source AS (
    SELECT *
    FROM {{ source('bronze', '{module}_standardized') }}
    {% if is_incremental() %}
    WHERE _bronze_load_ts > (SELECT MAX(_bronze_load_ts) FROM {{ this }})
    {% endif %}
),

validated AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- DATA QUALITY FLAGS
        -- ====================================================================
        
        -- Flag 1: risk_appetite validation
        CASE 
            WHEN risk_appetite IS NULL THEN TRUE
            WHEN risk_appetite IN (SELECT code FROM {{ ref('_investment_risk_appetite') }}) 
                THEN TRUE
            ELSE FALSE
        END AS dq_risk_appetite_valid,
        
        -- Flag 2: knowledge_level validation
        CASE 
            WHEN knowledge_level IS NULL THEN TRUE
            WHEN knowledge_level IN (SELECT code FROM {{ ref('_investment_knowledge_level') }}) 
                THEN TRUE
            ELSE FALSE
        END AS dq_knowledge_level_valid,
        
        -- ... more validation flags ...
        
    FROM source
),

with_hashes AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- SET HASHES (If multi-valued sets exist)
        -- ====================================================================
        
        {{ compute_set_hash('objective_list') }} AS objective_set_hash
        
    FROM validated
),

with_profile_hash AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- PROFILE HASH (For SCD2 change detection)
        -- ====================================================================
        
        {{ compute_profile_hash(
            'risk_appetite',
            'knowledge_level',
            'experience_level',
            'suitability_score',
            'kyc_status',
            'aml_status',
            'assessment_date',
            'objective_set_hash'
        ) }} AS profile_hash
        
    FROM with_hashes
),

final AS (
    SELECT 
        *,
        
        -- ====================================================================
        -- DATA QUALITY SCORE & STATUS
        -- ====================================================================
        
        -- DQ Score: Percentage of passed validations (0-100)
        ROUND(
            (
                CASE WHEN dq_risk_appetite_valid THEN 1 ELSE 0 END +
                CASE WHEN dq_knowledge_level_valid THEN 1 ELSE 0 END +
                -- ... more flags ...
            )::NUMERIC / {total_flags} * 100,
            2
        ) AS dq_score,
        
        -- DQ Status: Categorical classification
        CASE 
            WHEN ({all_flags_sum}) = {total_flags} THEN 'VALID'
            WHEN ({all_flags_sum}) >= {threshold} THEN 'WARNING'
            ELSE 'INVALID'
        END AS dq_status,
        
        -- Silver Metadata
        CURRENT_TIMESTAMP AS _silver_load_ts
        
    FROM with_profile_hash
)

SELECT * FROM final
```

**Don't Forget**:
- Create enumeration reference tables in `dbt/models/silver/enums/`
- Add source definition in `dbt/models/bronze/_sources.yml`
- Add tests in `dbt/models/silver/schema.yml`

---

### Step 9: Implement Gold dbt Model

**Objective**: Create SCD Type 2 dimension with version management

**Actions**:
1. Create dbt model in `dbt/models/gold/`
2. Implement SCD2 merge logic
3. Generate surrogate keys
4. Manage effective dates and is_current flag
5. Handle version numbering

**Deliverable**: `dbt/models/gold/dim_{module}.sql`

**SCD2 Logic Template**:
```sql
{{
    config(
        materialized='incremental',
        unique_key='investment_profile_version_sk',
        on_schema_change='fail',
        schema='gold'
    )
}}

WITH source_data AS (
    SELECT *
    FROM {{ ref('silver_{module}_standardized') }}
    {% if is_incremental() %}
    WHERE _silver_load_ts > (SELECT MAX(load_ts) FROM {{ this }})
    {% endif %}
),

-- Get current versions from existing dimension
{% if is_incremental() %}
current_versions AS (
    SELECT *
    FROM {{ this }}
    WHERE is_current = TRUE
),

-- Identify changes (profile_hash different)
changed_records AS (
    SELECT 
        s.*,
        c.investment_profile_version_sk AS prev_version_sk,
        c.version_num AS prev_version_num,
        c.profile_hash AS prev_profile_hash
    FROM source_data s
    LEFT JOIN current_versions c 
        ON s.{entity}_id = c.{entity}_id
    WHERE c.profile_hash IS NULL  -- New record
       OR c.profile_hash != s.profile_hash  -- Changed record
),

-- Close previous versions
closed_versions AS (
    SELECT 
        c.*,
        s.last_modified_ts AS new_effective_start_ts,
        s.last_modified_ts - INTERVAL '1 microsecond' AS new_effective_end_ts,
        FALSE AS new_is_current
    FROM current_versions c
    INNER JOIN changed_records s 
        ON c.{entity}_id = s.{entity}_id
),
{% endif %}

-- Generate new versions
new_versions AS (
    SELECT 
        -- Surrogate Key (generate new)
        ROW_NUMBER() OVER (ORDER BY {entity}_id) + 
            COALESCE((SELECT MAX(investment_profile_version_sk) FROM {{ this }}), 0) 
            AS investment_profile_version_sk,
        
        -- Natural Key
        {entity}_id,
        
        -- Profile Attributes
        risk_appetite,
        knowledge_level,
        experience_level,
        suitability_score,
        kyc_status,
        aml_status,
        assessment_date,
        
        -- Hashes
        profile_hash,
        objective_set_hash,
        
        -- Version Management
        {% if is_incremental() %}
        COALESCE(cr.prev_version_num, 0) + 1 AS version_num,
        {% else %}
        1 AS version_num,
        {% endif %}
        
        -- SCD2 Temporal
        last_modified_ts AS effective_start_ts,
        NULL AS effective_end_ts,
        TRUE AS is_current,
        
        -- Metadata
        CURRENT_TIMESTAMP AS load_ts
        
    FROM 
        {% if is_incremental() %}
        changed_records cr
        {% else %}
        source_data
        {% endif %}
),

-- Combine updates and inserts
final AS (
    {% if is_incremental() %}
    -- Updated closed versions
    SELECT * FROM closed_versions
    UNION ALL
    {% endif %}
    -- New versions
    SELECT * FROM new_versions
)

SELECT * FROM final
```

---

### Step 10: Implement Bridge Tables (If Needed)

**Objective**: Create bridge tables for multi-valued sets

**Actions**:
1. Create dbt model for each bridge table
2. Parse pipe-delimited list from Silver
3. Unnest and normalize codes
4. Create distinct pairs (version_sk, code)

**Deliverable**: `dbt/models/gold/bridge_{entity}_{set_name}.sql`

**Template**:
```sql
{{
    config(
        materialized='table',
        schema='gold'
    )
}}

WITH dimension_versions AS (
    SELECT 
        investment_profile_version_sk,
        {entity}_id,
        objective_list
    FROM {{ ref('dim_{module}') }}
    WHERE objective_list IS NOT NULL
),

unnested AS (
    SELECT 
        investment_profile_version_sk,
        TRIM(UPPER(code)) AS objective_code
    FROM dimension_versions,
    LATERAL unnest(string_to_array(objective_list, '|')) AS code
    WHERE TRIM(code) != ''
),

distinct_pairs AS (
    SELECT DISTINCT
        investment_profile_version_sk,
        objective_code
    FROM unnested
)

SELECT 
    investment_profile_version_sk,
    objective_code,
    CURRENT_TIMESTAMP AS created_ts,
    'dbt_etl' AS created_by
FROM distinct_pairs
ORDER BY investment_profile_version_sk, objective_code
```

---

## Validation & Testing

### Pre-Deployment Checklist

```
[ ] All contracts created and validated against standards
[ ] All enumeration files created with valid codes
[ ] Bronze DDL created with proper comments and indexes
[ ] Silver dbt model compiles without errors
[ ] Gold dbt model compiles without errors
[ ] Bridge models compile (if applicable)
[ ] Source definitions added to _sources.yml
[ ] Schema tests added to schema.yml files
[ ] Hash computation verified against sample data
[ ] SCD2 logic tested with changing data
```

### Testing Sequence

#### 1. **Syntax Validation**
```bash
# Compile dbt models
cd dbt
dbt compile --models {module}

# Expected: All models compile successfully
```

#### 2. **Sample Data Testing**
```sql
-- Insert sample data to Bronze
INSERT INTO bronze.{module}_standardized 
VALUES (...sample data...);

-- Run Silver model
dbt run --models silver_{module}_standardized

-- Verify Silver transformations
SELECT 
    {entity}_id,
    profile_hash,
    dq_score,
    dq_status
FROM silver.{module}_standardized;

-- Expected: 
-- - profile_hash is 64-character hex string
-- - dq_score is between 0 and 100
-- - dq_status is VALID, WARNING, or INVALID
```

#### 3. **SCD2 Version Testing**
```sql
-- Initial load (creates version 1)
dbt run --models dim_{module}

SELECT * FROM gold.dim_{module}
WHERE {entity}_id = 'TEST001';
-- Expected: 1 row, version_num=1, is_current=TRUE

-- Change data in Bronze (same entity, different attributes)
INSERT INTO bronze.{module}_standardized 
VALUES (...changed data...);

-- Run Silver and Gold
dbt run --models {module}

SELECT * FROM gold.dim_{module}
WHERE {entity}_id = 'TEST001'
ORDER BY version_num;
-- Expected: 2 rows
-- Row 1: version_num=1, is_current=FALSE, effective_end_ts populated
-- Row 2: version_num=2, is_current=TRUE, effective_end_ts=NULL
```

#### 4. **Bridge Table Testing** (If Applicable)
```sql
SELECT 
    b.investment_profile_version_sk,
    b.objective_code,
    d.version_num
FROM gold.bridge_investment_objective b
JOIN gold.dim_investment_profile d 
    ON b.investment_profile_version_sk = d.investment_profile_version_sk
WHERE d.{entity}_id = 'TEST001'
ORDER BY d.version_num, b.objective_code;

-- Expected: All codes from objective_list present
-- Each version shows its set members
```

#### 5. **Data Quality Testing**
```sql
-- Check DQ score distribution
SELECT 
    dq_status,
    COUNT(*) AS record_count,
    AVG(dq_score) AS avg_score
FROM silver.{module}_standardized
GROUP BY dq_status;

-- Expected:
-- VALID: dq_score = 100
-- WARNING: dq_score between threshold and 100
-- INVALID: dq_score below threshold
```

---

## Common Patterns

### Pattern 1: Enumeration + Freetext (Type 1)

**When to Use**: Flexible enumerations where users might need "Other" option

**Implementation**:
- Main enumeration field: Type 2 (versioned, in hash)
- Freetext `_other` field: Type 1 (not versioned, NOT in hash)
- Populate `_other` only when enumeration = 'OTHER'

**Example**:
```yaml
# Type 2 - Versioned
- name: occupation
  scd_type: 2
  hash_participation: true
  valid_values: [EMPLOYEE, SELF_EMPLOYED, ..., OTHER, UNKNOWN]

# Type 1 - Not Versioned
- name: occupation_other
  scd_type: 1
  hash_participation: false
  population_rule: "Only when occupation = 'OTHER'"
```

### Pattern 2: Multi-Valued Sets with Bridge Tables

**When to Use**: Attribute can have multiple values

**Implementation**:
- Store pipe-delimited list in dimension (for reference)
- Compute set_hash (for change detection)
- Create bridge table (for querying individual members)

**Example**:
```sql
-- In Dimension
SELECT 
    investment_profile_version_sk,
    objective_list,  -- "GROWTH|INCOME|PRESERVATION"
    objective_set_hash  -- SHA256 of sorted codes
FROM gold.dim_investment_profile;

-- In Bridge Table
SELECT 
    investment_profile_version_sk,
    objective_code  -- One row per code
FROM gold.bridge_investment_objective;
```

### Pattern 3: Banded/Categorical Values (No "OTHER")

**When to Use**: Values must fit into predefined bands/categories

**Implementation**:
- No "OTHER" option in enumeration
- All values must map to defined bands
- Use "UNKNOWN" if mapping unclear

**Example**:
```yaml
# Asset bands - no OTHER
values:
  - code: ASSET_BAND_1  # < 100K
  - code: ASSET_BAND_2  # 100K - 500K
  - code: ASSET_BAND_3  # 500K - 1M
  - code: ASSET_BAND_4  # 1M - 5M
  - code: ASSET_BAND_5  # > 5M
  - code: UNKNOWN  # Not disclosed
```

### Pattern 4: Case Preservation for Names

**Storage**: Preserve original case  
**Hash Normalization**: UPPER() for English, preserve case for local scripts

**Example**:
```yaml
- name: firstname
  storage: preserve_case  # "John"
  normalization: UPPER(TRIM)  # "JOHN" in hash

- name: firstname_local
  storage: preserve_case  # "สมชาย"
  normalization: TRIM  # "สมชาย" in hash (preserve case)
```

---

## Troubleshooting

### Issue 1: Profile Hash Not Matching

**Symptom**: New versions created even when data hasn't changed

**Causes**:
- Attribute order in hash computation doesn't match contract
- NULL handling inconsistent (should use '__NULL__' token)
- Case normalization not applied correctly
- Whitespace not trimmed

**Fix**:
1. Verify canonical order matches contract
2. Check NULL token usage
3. Verify normalization rules (UPPER, TRIM)
4. Test hash computation with known values

### Issue 2: SCD2 Not Creating Versions

**Symptom**: Updated records overwrite instead of creating versions

**Causes**:
- Incremental logic not detecting changes
- profile_hash comparison failing
- is_incremental() condition wrong

**Fix**:
1. Check `{% if is_incremental() %}` block
2. Verify profile_hash comparison logic
3. Test with `dbt run --full-refresh` first

### Issue 3: Bridge Table Missing Records

**Symptom**: Bridge table has fewer records than expected

**Causes**:
- Pipe-delimited list not parsed correctly
- Empty strings not filtered
- DISTINCT removing valid pairs

**Fix**:
1. Check unnest logic
2. Add filter for empty strings: `WHERE TRIM(code) != ''`
3. Verify DISTINCT only on (version_sk, code) pair

### Issue 4: Data Quality Score Incorrect

**Symptom**: DQ score doesn't match manual calculation

**Causes**:
- Wrong number of flags in denominator
- Boolean logic error in CASE statements
- Missing flags in score calculation

**Fix**:
1. Count all DQ flags in SELECT
2. Verify denominator matches flag count
3. Test each validation rule individually

---

## Summary

This guide provides a **complete, repeatable process** for building new modules following the established Customer Profile pattern. Key takeaways:

✅ **Follow the 10 steps sequentially** for best results  
✅ **Use contracts as single source of truth** for schema definitions  
✅ **Leverage dbt macros** for hash computation and validation  
✅ **Test incrementally** at each layer (Bronze → Silver → Gold)  
✅ **Document thoroughly** using existing standards  

### Time Estimates by Step

| Step | Task | Estimated Time |
|------|------|----------------|
| 1 | Business requirements | 2-4 hours |
| 2 | Enumeration files | 1-2 hours |
| 3-6 | Contracts (4 files) | 2-3 hours |
| 7 | Bronze DDL | 1 hour |
| 8 | Silver dbt model | 2-3 hours |
| 9 | Gold dbt model | 2-3 hours |
| 10 | Bridge tables (if needed) | 1-2 hours |
| Testing | Validation & fixes | 2-4 hours |
| **Total** | | **13-24 hours** |

### Next Steps

1. ✅ Complete all 10 steps for your new module
2. ✅ Run validation tests
3. ✅ Create PR with all artifacts
4. ✅ Update main README with new module reference
5. ✅ Add to STANDARDS_INDEX.md

---

**Questions?** Refer to:
- Customer Profile implementation: `docs/business/modules/customer_module.md`
- Naming conventions: `docs/data-modeling/naming_conventions.md`
- Hashing standards: `docs/data-modeling/hashing_standards.md`
- AI Context: `AI_CONTEXT.md`

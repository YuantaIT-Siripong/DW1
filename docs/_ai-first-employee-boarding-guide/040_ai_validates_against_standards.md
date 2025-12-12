Run comprehensive gap analysis on <ENTITY_NAME> module. 

Validate against these standards:
1. docs/MODULE_DEVELOPMENT_CHECKLIST.md
2. contracts/scd2/STANDARD_SCD2_POLICY.md
3. docs/FOUNDATION_NAMING_CONVENTIONS.md
4. docs/data-modeling/naming_conventions.md
5. docs/data-modeling/hashing_standards.md

Check these generated files: 
- enumerations/<domain>_<enum>. yaml
- contracts/bronze/<entity>_standardized.yaml
- contracts/silver/<entity>_standardized.yaml
- contracts/gold/dim_<entity>.yaml
- db/bronze/<entity>_standardized.sql
- db/gold/dim_<entity>.sql
- dbt/models/silver/<entity>_standardized.sql
- dbt/models/gold/dim_<entity>.sql

## Validation Checklist

### 1. Naming Conventions
- [ ] File names use snake_case
- [ ] Folder structure correct (contracts/, db/, dbt/models/)
- [ ] Schema is 'gold' (not 'curated')
- [ ] Surrogate key named <entity>_version_sk
- [ ] Temporal columns named effective_start_ts, effective_end_ts (not _date)
- [ ] Boolean column named is_current (not current_flag)

### 2. SCD2 Pattern (CRITICAL)
- [ ] effective_start_ts TIMESTAMP NOT NULL
- [ ] effective_end_ts TIMESTAMP NULL (no DEFAULT value)
- [ ] is_current BOOLEAN NOT NULL DEFAULT FALSE
- [ ] version_num INT NOT NULL
- [ ] Closure formula:   - INTERVAL '1 microsecond'
- [ ] NULL pattern for current version (not '9999-12-31')
- [ ] LEAD() window function for effective_end_ts calculation
- [ ] ROW_NUMBER() for version_num calculation

### 3. Hash Computation
- [ ] profile_hash VARCHAR(64) NOT NULL
- [ ] Hash INCLUDES all Type 2 attributes
- [ ] Hash EXCLUDES surrogate keys (_version_sk)
- [ ] Hash EXCLUDES temporal columns (effective_*, is_current, version_num)
- [ ] Hash EXCLUDES Type 1 attributes (*_other fields)
- [ ] Hash EXCLUDES ETL metadata (_bronze_*, _silver_*, load_ts)
- [ ] Hash EXCLUDES profile_hash itself
- [ ] Uses {{ compute_profile_hash() }} macro in dbt
- [ ] Columns in canonical alphabetical order

### 4. Required Indexes (MUST ALL EXIST)
- [ ] PRIMARY KEY on <entity>_version_sk
- [ ] UNIQUE INDEX on (<natural_key>, version_num)
- [ ] UNIQUE INDEX on (<natural_key>) WHERE is_current = TRUE
- [ ] INDEX on (<natural_key>, is_current) WHERE is_current = TRUE
- [ ] INDEX on (<natural_key>, effective_start_ts, effective_end_ts)
- [ ] INDEX on (profile_hash)

### 5. Enumeration Pattern
- [ ] Enumeration YAML has:  code, description, sort_order
- [ ] Enumeration includes OTHER and UNKNOWN values (if applicable)
- [ ] For enums with OTHER:   *_other freetext field exists
- [ ] *_other field is Type 1 (NOT in profile_hash)
- [ ] dbt uses {{ validate_enumeration() }} macro

### 6. Contract Alignment
- [ ] DDL column names match Gold contract exactly
- [ ] DDL data types match Gold contract exactly
- [ ] dbt model outputs all contract columns
- [ ] No extra columns in DDL not in contract
- [ ] Sample rows in contract are realistic

### 7. dbt Model Structure
- [ ] Config block present (materialized, unique_key, schema)
- [ ] CTEs in correct order:  source → validated → with_hashes → with_profile_hash → final
- [ ] Incremental filter on source CTE
- [ ] All dbt refs valid:  {{ ref('...') }}
- [ ] All macros have closing }}

### 8. Documentation
- [ ] All SQL files have COMMENT statements
- [ ] Contract has business_definition for each attribute
- [ ] Contract has sample_rows

---

## Output Format

For each category, show:
- ✅ PASS with count (e.g., "✅ Naming Conventions: 6/6 passed")
- ❌ FAIL with specific issues and line numbers

Example output:
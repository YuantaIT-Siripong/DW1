Generate complete <ENTITY_NAME> module for DW1 following all standards. 

Use these working examples as references:
- Enumeration: enumerations/customer_marital_status.yaml
- Bronze Contract: contracts/bronze/customer_profile_standardized.yaml
- Silver Contract: contracts/silver/customer_profile_standardized.yaml
- Gold Contract: contracts/gold/dim_customer_profile.yaml
- Bronze DDL: db/bronze/customer_profile_standardized.sql
- Silver DDL: db/silver/customer_profile_standardized.sql (if exists)
- Gold DDL: db/gold/dim_customer_profile.sql
- Silver dbt:  dbt/models/silver/customer_profile_standardized. sql
- Gold dbt: dbt/models/gold/dim_customer_profile.sql

Create these 9 files in order:

### File 1: Enumeration Definition(s)
Path: `enumerations/<domain>_<enumeration_name>.yaml`

For each enumeration, include:
- enumeration_name
- domain
- description
- version
- values (code, description, sort_order)

### File 2: Bronze Contract
Path: `contracts/bronze/<entity>_standardized.yaml`

Include:
- entity_name, domain, table_type (landing), layer (bronze)
- grain_description
- upstream_source (IT operational view spec)
- primary_keys, natural_keys
- All attributes from Step 2 (match IT view)
- ETL metadata columns (_bronze_load_ts, _bronze_source_file, _bronze_batch_id)
- sample_rows

### File 3: Bronze DDL
Path: `db/bronze/<entity>_standardized. sql`

Include:
- CREATE SCHEMA IF NOT EXISTS bronze
- CREATE TABLE with all attributes
- Primary key constraint
- Indexes on load_ts and batch_id
- COMMENT statements

### File 4: Silver Contract
Path: `contracts/silver/<entity>_standardized.yaml`

Include:
- Same structure as Bronze
- Add computed columns: 
  - profile_hash VARCHAR(64)
  - <set>_set_hash VARCHAR(64) for each multi-valued set
  - dq_* flags (boolean) for each validation
  - dq_score NUMERIC(5,2)
  - dq_status VARCHAR(20)
- Add _silver_load_ts

### File 5: Silver dbt Model
Path: `dbt/models/silver/<entity>_standardized.sql`

Include:
- Config block (materialized='incremental', unique_key, schema='silver')
- CTE structure: 
  1. source (with incremental filter)
  2. validated (with dq_* flags using {{ validate_enumeration() }})
  3. with_hashes (compute set hashes using {{ compute_set_hash() }})
  4. with_profile_hash (compute profile hash using {{ compute_profile_hash() }})
  5. final (compute dq_score, dq_status, add _silver_load_ts)

### File 6: Gold Contract
Path: `contracts/gold/dim_<entity>.yaml`

Include:
- entity_name:  dim_<entity>
- table_type: dimension_scd2
- layer: gold
- SCD2 columns:
  - <entity>_version_sk (surrogate key)
  - effective_start_ts, effective_end_ts, is_current, version_num
- All Type 2 attributes (no _other fields in versioned attributes)
- profile_hash
- Audit columns (load_ts)
- Indexes specification
- adr_refs (reference to STANDARD_SCD2_POLICY. md)

### File 7: Gold DDL
Path: `db/gold/dim_<entity>.sql`

Include:
- CREATE SCHEMA IF NOT EXISTS gold
- CREATE TABLE with: 
  - <entity>_version_sk BIGSERIAL PRIMARY KEY
  - <natural_key> (match Bronze type)
  - effective_start_ts TIMESTAMP NOT NULL
  - effective_end_ts TIMESTAMP NULL (no DEFAULT)
  - is_current BOOLEAN NOT NULL DEFAULT FALSE
  - version_num INT NOT NULL
  - All attributes
  - profile_hash VARCHAR(64) NOT NULL
  - load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
- CHECK constraints: 
  - effective_end_ts IS NULL OR effective_end_ts > effective_start_ts
  - version_num > 0
  - profile_hash ~ '^[a-f0-9]{64}$'
- Indexes (MUST CREATE ALL):
  1. Primary key on <entity>_version_sk
  2. Unique on (<natural_key>, version_num)
  3. Unique on (<natural_key>) WHERE is_current = TRUE
  4. Non-unique on (<natural_key>, is_current) WHERE is_current = TRUE
  5. Non-unique on (<natural_key>, effective_start_ts, effective_end_ts)
  6. Non-unique on (profile_hash)
- COMMENT statements for all columns

### File 8: Gold dbt Model
Path: `dbt/models/gold/dim_<entity>.sql`

Include:
- Config block (materialized='table', schema='gold')
- CTE structure:
  1. silver_all_versions (source from Silver)
  2. with_effective_dates (calculate SCD2 temporal columns):
     - effective_start_ts = source_last_modified_ts
     - effective_end_ts = LEAD(... ) - INTERVAL '1 microsecond' OR NULL
     - is_current = version_rank = 1
     - version_num = ROW_NUMBER() OVER (PARTITION BY <natural_key> ORDER BY effective_start_ts)
  3. final (select all columns, add load_ts)

### File 9: Bridge Table (if multi-valued sets exist)
Path: `contracts/gold/bridge_<entity>_<set_name>.yaml`
Path: `db/gold/bridge_<entity>_<set_name>.sql`
Path: `dbt/models/gold/bridge_<entity>_<set_name>.sql`

(Skip if no multi-valued sets)

---

Generate files one at a time.  After each file, wait for my confirmation before proceeding to next.

Start with File 1: Enumeration Definition(s)
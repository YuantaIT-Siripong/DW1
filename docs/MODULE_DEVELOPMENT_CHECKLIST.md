# Module Development Checklist

**Purpose**: Comprehensive checklist for building a new data warehouse module  
**Pattern**: Bronze → Silver → Gold (Medallion Architecture)  
**Reference**: Customer Profile Module  
**Usage**: Check off items as you complete them to ensure nothing is missed

---

## 📋 Pre-Development Phase

### Business Requirements
- [ ] Create module specification document (`docs/business/modules/{module}_module.md`)
- [ ] Define module overview and business goals
- [ ] Document core use cases
- [ ] Create entity inventory table
- [ ] Create attribute inventory with SCD types
- [ ] Document all enumeration fields needed
- [ ] Identify multi-valued sets (if any)
- [ ] Define data quality rules
- [ ] Document edge cases and exceptions
- [ ] Create sample record examples
- [ ] Get stakeholder approval

### Architecture Decisions
- [ ] Decide which attributes are SCD Type 1 (no history)
- [ ] Decide which attributes are SCD Type 2 (versioned)
- [ ] Define profile hash attribute order
- [ ] Document normalization rules for hash
- [ ] Identify if bridge tables are needed
- [ ] Document any "OTHER" + freetext patterns
- [ ] Define retention policies
- [ ] Document PII classification

---

## 📊 Enumeration Management

### Enumeration Files Creation
- [ ] List all enumeration fields from requirements
- [ ] Create YAML file for each enumeration (`enumerations/{domain}_{attribute}.yaml`)
- [ ] Follow enumeration_standards.md format
- [ ] Include: code, description, sort_order for each value
- [ ] Add "UNKNOWN" value where appropriate
- [ ] Add "OTHER" value if freetext fallback needed (with corresponding `_other` field)
- [ ] Document mapping rules from source systems
- [ ] Get business validation of codes and descriptions
- [ ] Commit enumeration files to repository

### Enumeration Validation
- [ ] Verify all codes are uppercase (unless ISO standard)
- [ ] Verify sort_order is logical
- [ ] Verify descriptions are clear
- [ ] No duplicate codes within an enumeration
- [ ] Cross-reference with existing enumerations (reuse if possible)

---

## 📜 Contract Development

### Bronze Layer Contract
**File**: `contracts/bronze/{module}_standardized.yaml`

- [ ] Copy template from existing bronze contract
- [ ] Update entity_name, domain, table_type, layer
- [ ] Update grain_description
- [ ] Define upstream_source (IT view details)
- [ ] List all primary_keys and natural_keys
- [ ] Define all source attributes with:
  - [ ] name, datatype, business_definition
  - [ ] nullable, pii classification
  - [ ] enumeration_ref for enumeration fields
  - [ ] source_field mapping
- [ ] Add Bronze ETL metadata columns:
  - [ ] _bronze_load_ts (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP)
  - [ ] _bronze_source_file (VARCHAR(500))
  - [ ] _bronze_batch_id (BIGINT)
- [ ] Document immutability_policy
- [ ] Define data_quality_rules
- [ ] Define transformation_rules (what IT applies, what DW applies)
- [ ] Add sample_rows with realistic data
- [ ] Document indexes needed
- [ ] Define PII policy and access control
- [ ] Validate YAML syntax

### Silver Layer Contract
**File**: `contracts/silver/{module}_standardized.yaml`

- [ ] Copy from Bronze contract as starting point
- [ ] Update layer to 'silver'
- [ ] Keep all source attributes from Bronze
- [ ] Add computed set_hash columns (if multi-valued sets)
- [ ] Add profile_hash column (VARCHAR(64), NOT NULL)
- [ ] Add data quality flag columns (dq_{attribute}_valid BOOLEAN)
- [ ] Add data quality score (dq_score NUMERIC(5,2))
- [ ] Add data quality status (dq_status VARCHAR(20))
- [ ] Add _silver_load_ts (TIMESTAMP, NOT NULL)
- [ ] Document hash_spec section:
  - [ ] algorithm: SHA256
  - [ ] ordered_attribute_list (all Type 2 attributes)
  - [ ] normalization rules for each attribute
  - [ ] delimiter: "|"
  - [ ] null_token: "__NULL__" (Note: dbt macro uses ''; normalize before macro call)
- [ ] Document validation rules for each DQ flag
- [ ] Update sample_rows with computed columns
- [ ] Validate YAML syntax

### Gold Layer Contract (Dimension)
**File**: `contracts/{domain}/dim_{module}.yaml`

- [ ] Copy from existing dimension contract template
- [ ] Update entity_name, domain, table_type, layer
- [ ] Update grain_description
- [ ] Define surrogate_keys ({module}_version_sk)
- [ ] Define natural_keys and business_keys
- [ ] List versioning_attributes (SCD Type 2)
- [ ] List non_versioning_attributes (SCD Type 1, like `_other` fields)
- [ ] Define all attributes with:
  - [ ] name, datatype, business_definition
  - [ ] scd_role (surrogate_key, natural_key, effective_from, etc.)
  - [ ] hash_participation (true/false)
  - [ ] storage rules (preserve_case, etc.)
  - [ ] normalization rules
- [ ] Add SCD2 temporal columns:
  - [ ] effective_start_ts (TIMESTAMP, NOT NULL)
  - [ ] effective_end_ts (TIMESTAMP, nullable)
  - [ ] is_current (BOOLEAN, NOT NULL)
  - [ ] version_num (INT, NOT NULL)
- [ ] Add profile_hash column
- [ ] Add set_hash columns (if applicable)
- [ ] Define hash_spec with canonical order
- [ ] Document change_detection_logic
- [ ] Define relationships (bridge tables, etc.)
- [ ] Document data_quality_rules
- [ ] Define indexes (PK, natural key, temporal, current flag)
- [ ] Add sample_rows showing version history
- [ ] Reference ADR documents
- [ ] Validate YAML syntax

### Bridge Table Contracts (If Needed)
**File**: `contracts/{domain}/bridge_{entity}_{set_name}_version.yaml`

For each multi-valued set:
- [ ] Create bridge contract
- [ ] Define entity_name, domain, table_type='bridge', layer='gold'
- [ ] Define composite primary_keys [version_sk, code]
- [ ] Define version_sk attribute with foreign key reference
- [ ] Define code attribute with enumeration_ref
- [ ] Add created_ts, created_by columns
- [ ] Define indexes (PK, version lookup, code lookup)
- [ ] Validate YAML syntax

---

## 🗄️ Database Objects (db/ folder)

### Bronze DDL
**File**: `db/bronze/{module}_standardized.sql`

- [ ] Create schema IF NOT EXISTS (bronze)
- [ ] Create table with all attributes from Bronze contract
- [ ] Match datatypes exactly from contract
- [ ] Add composite PRIMARY KEY
- [ ] Create index on _bronze_load_ts
- [ ] Create index on _bronze_batch_id
- [ ] Add COMMENT ON TABLE with description
- [ ] Add COMMENT ON COLUMN for each attribute (business_definition from contract)
- [ ] Add GRANT statements (dw_etl_service, dw_privileged)
- [ ] Add immutability policy note (append-only, never UPDATE/DELETE)
- [ ] Test SQL compiles

### Silver DDL (Optional - if not using dbt)
**File**: `db/silver/{module}_standardized.sql`

- [ ] Create schema IF NOT EXISTS (silver)
- [ ] Create table or view (depends on strategy)
- [ ] Include all Bronze columns
- [ ] Add computed columns (hashes, DQ flags)
- [ ] Add functions for hash computation (if needed)
- [ ] Test SQL compiles

### Gold Dimension DDL
**File**: `db/gold/dim_{module}.sql`

- [ ] Create schema IF NOT EXISTS (gold)
- [ ] Create table with all attributes from Gold contract
- [ ] Add surrogate key (BIGSERIAL or equivalent)
- [ ] Add composite UNIQUE constraint for one current per natural key
- [ ] Add CHECK constraint for effective_start_ts <= effective_end_ts
- [ ] Create index on natural_key
- [ ] Create index on (natural_key, is_current) WHERE is_current = TRUE
- [ ] Create index on (effective_start_ts, effective_end_ts)
- [ ] Create index on profile_hash
- [ ] Add comprehensive COMMENT statements
- [ ] Test SQL compiles

### Bridge Table DDL (If Needed)
**File**: `db/gold/bridges/bridge_{entity}_{set_name}.sql`

For each multi-valued set:
- [ ] Create schema IF NOT EXISTS (gold)
- [ ] Create table with composite PK (version_sk, code)
- [ ] Add FOREIGN KEY to dimension (version_sk)
- [ ] Create index on version_sk
- [ ] Create index on code (reverse lookup)
- [ ] Add COMMENT statements
- [ ] Test SQL compiles

### Quarantine DDL
**File**: `db/quarantine/{module}_quarantine.sql`

- [ ] Create schema IF NOT EXISTS (quarantine)
- [ ] Create table with same structure as Bronze
- [ ] Add rejection_reason (TEXT, NOT NULL)
- [ ] Add rejection_ts (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- [ ] Add rejection_rule (VARCHAR(100))
- [ ] Add reprocessing flags (is_reprocessed, reprocessed_ts, reprocessed_by)
- [ ] Create indexes on rejection_ts, rejection_rule
- [ ] Test SQL compiles

---

## 🔧 dbt Models

### Source Definition
**File**: `dbt/models/bronze/_sources.yml`

- [ ] Add new source definition for Bronze table
- [ ] Specify database and schema
- [ ] List table name
- [ ] Add description
- [ ] Document columns (optional but recommended)

### Silver Enumeration Models
**Files**: `dbt/models/silver/enums/_*{module}*_*.sql`

For each enumeration:
- [ ] Create SQL file to load enumeration from YAML
- [ ] Use seeds or CTEs to define valid values
- [ ] Select code, description, sort_order
- [ ] Materialized as table
- [ ] Schema = silver

**Or** use seeds:
- [ ] Create CSV files in `seeds/{domain}/`
- [ ] Add seed reference in `dbt_project.yml`

### Silver Model
**File**: `dbt/models/silver/{module}_standardized.sql`

- [ ] Add config block:
  - [ ] materialized='incremental'
  - [ ] unique_key=[list of keys]
  - [ ] on_schema_change='fail'
  - [ ] schema='silver'
- [ ] Create 'source' CTE:
  - [ ] SELECT from {{ source('bronze', '{module}_standardized') }}
  - [ ] Add incremental filter: WHERE _bronze_load_ts > (SELECT MAX(_bronze_load_ts) FROM {{ this }})
- [ ] Create 'validated' CTE:
  - [ ] Include all source columns
  - [ ] Add data quality flag for each attribute (CASE WHEN ... IN (SELECT code FROM {{ ref('enum_table') }}))
  - [ ] Add `_other` field completeness checks
- [ ] Create 'with_hashes' CTE:
  - [ ] Compute set_hash for each multi-valued set using {{ compute_set_hash() }}
- [ ] Create 'with_profile_hash' CTE:
  - [ ] Compute profile_hash using {{ compute_profile_hash() }} with all Type 2 attributes
- [ ] Create 'final' CTE:
  - [ ] Calculate dq_score (sum of flags / total flags * 100)
  - [ ] Determine dq_status (VALID/WARNING/INVALID)
  - [ ] Add _silver_load_ts = CURRENT_TIMESTAMP
- [ ] SELECT * FROM final
- [ ] Test dbt compile: `dbt compile --models {module}`

### Silver Schema YAML
**File**: `dbt/models/silver/schema.yml`

- [ ] Add model documentation
- [ ] Add column descriptions
- [ ] Add dbt tests:
  - [ ] unique test on primary key
  - [ ] not_null tests on required columns
  - [ ] accepted_values tests on enumeration columns
  - [ ] relationships tests (if applicable)
- [ ] Add custom tests (if needed)

### Gold Dimension Model
**File**: `dbt/models/gold/dim_{module}.sql`

- [ ] Add config block:
  - [ ] materialized='incremental' (or 'table' for full refresh approach)
  - [ ] unique_key='{module}_version_sk'
  - [ ] on_schema_change='fail'
  - [ ] schema='gold'
- [ ] Create 'source_data' CTE:
  - [ ] SELECT from {{ ref('silver_{module}_standardized') }}
  - [ ] Add incremental filter if applicable
- [ ] If incremental:
  - [ ] Create 'current_versions' CTE (existing records with is_current=TRUE)
  - [ ] Create 'changed_records' CTE (compare profile_hash)
  - [ ] Create 'closed_versions' CTE (update effective_end_ts, set is_current=FALSE)
- [ ] Create 'new_versions' CTE:
  - [ ] Generate surrogate key (ROW_NUMBER + MAX from existing)
  - [ ] Map all attributes from Silver
  - [ ] Add version_num (increment or start at 1)
  - [ ] Set effective_start_ts from source timestamp
  - [ ] Set effective_end_ts = NULL
  - [ ] Set is_current = TRUE
  - [ ] Add load_ts = CURRENT_TIMESTAMP
- [ ] Create 'final' CTE:
  - [ ] UNION closed_versions and new_versions
- [ ] SELECT * FROM final
- [ ] Test dbt compile: `dbt compile --models dim_{module}`

### Gold Schema YAML
**File**: `dbt/models/gold/schema.yml`

- [ ] Add dimension model documentation
- [ ] Add column descriptions
- [ ] Add dbt tests:
  - [ ] unique test on surrogate key
  - [ ] not_null tests on required columns
  - [ ] unique combination test on (natural_key, is_current) where is_current=TRUE
- [ ] Document SCD2 behavior in description

### Bridge Models (If Needed)
**File**: `dbt/models/gold/bridge_{entity}_{set_name}.sql`

For each multi-valued set:
- [ ] Add config block (materialized='table', schema='gold')
- [ ] Create CTE to get versions with non-null set list
- [ ] Create 'unnested' CTE using string_to_array and LATERAL unnest
- [ ] Normalize codes (TRIM, UPPER)
- [ ] Create 'distinct_pairs' CTE (SELECT DISTINCT version_sk, code)
- [ ] SELECT with created_ts, created_by
- [ ] Test dbt compile

### Quarantine Model
**File**: `dbt/models/quarantine/{module}_rejected.sql`

- [ ] Add config block (materialized='incremental', schema='quarantine')
- [ ] SELECT records from Silver where dq_status='INVALID'
- [ ] Add rejection_reason (concatenate failed validation rules)
- [ ] Add rejection_ts, rejection_rule
- [ ] Test dbt compile

---

## 📝 Documentation

### Module Specification
- [ ] docs/business/modules/{module}_module.md is complete
- [ ] All 18 sections filled out
- [ ] Sample records provided
- [ ] Cross-references to contracts added

### Architectural Decision Records (If New Patterns)
- [ ] Create ADR document in docs/adr/
- [ ] Follow ADR template (Context, Decision, Consequences)
- [ ] Document any deviations from standard patterns

### Update Main README
- [ ] Add module reference to README.md
- [ ] Update "Key References" section
- [ ] Add to table of contents if needed

### Update Standards Index
- [ ] Add to STANDARDS_INDEX.md if new standards introduced
- [ ] Reference new enumeration files
- [ ] Reference new contracts

### Update AI Context (If Needed)
- [ ] Update AI_CONTEXT.md if patterns change
- [ ] Add module-specific notes if needed

### dbt Documentation
- [ ] Run `dbt docs generate`
- [ ] Verify all models appear in documentation
- [ ] Check column descriptions are clear
- [ ] Verify lineage graph is correct

---

## 🧪 Testing & Validation

### Syntax & Compilation
- [ ] All SQL files compile without errors
- [ ] `dbt compile --models {module}` succeeds
- [ ] `dbt parse` shows no errors
- [ ] YAML files are valid (use YAML linter)

### Sample Data Testing
- [ ] Create sample data for Bronze layer (3-5 records)
- [ ] Load sample data: INSERT INTO bronze.{module}_standardized
- [ ] Run Silver model: `dbt run --models silver_{module}_standardized`
- [ ] Verify Silver transformations:
  - [ ] profile_hash is 64-char hex string
  - [ ] set_hash values are correct (if applicable)
  - [ ] dq_score calculated correctly
  - [ ] dq_status assigned correctly
  - [ ] All DQ flags have expected values
- [ ] Run Gold model: `dbt run --models dim_{module}`
- [ ] Verify Gold dimension:
  - [ ] Surrogate key generated
  - [ ] version_num = 1 for initial load
  - [ ] is_current = TRUE
  - [ ] effective_start_ts populated
  - [ ] effective_end_ts = NULL

### SCD2 Version Testing
- [ ] Modify sample data (change one Type 2 attribute)
- [ ] Load changed data to Bronze
- [ ] Run Silver model
- [ ] Run Gold model
- [ ] Verify SCD2 behavior:
  - [ ] Previous version: is_current=FALSE, effective_end_ts set
  - [ ] New version: version_num incremented, is_current=TRUE
  - [ ] No overlapping effective dates
  - [ ] profile_hash different between versions
- [ ] Modify Type 1 attribute only (`_other` field)
- [ ] Verify NO new version created (Type 1 behavior)

### Bridge Table Testing (If Applicable)
- [ ] Run bridge model: `dbt run --models bridge_{entity}_{set_name}`
- [ ] Verify bridge records:
  - [ ] One row per (version_sk, code) pair
  - [ ] All codes from pipe-delimited list present
  - [ ] No duplicate pairs
  - [ ] Foreign key references valid
- [ ] Query to reconstruct set:
  ```sql
  SELECT string_agg(code, '|' ORDER BY code)
  FROM bridge_{entity}_{set_name}
  WHERE version_sk = {test_version_sk};
  ```
- [ ] Verify reconstructed set matches original

### Data Quality Testing
- [ ] Create invalid sample data (fails enumeration validation)
- [ ] Run Silver model
- [ ] Verify quarantine model:
  - [ ] Invalid records moved to quarantine
  - [ ] rejection_reason populated correctly
  - [ ] Invalid records NOT in Silver
- [ ] Check DQ score distribution:
  ```sql
  SELECT 
      dq_status,
      COUNT(*) AS record_count,
      AVG(dq_score) AS avg_score,
      MIN(dq_score) AS min_score,
      MAX(dq_score) AS max_score
  FROM silver.{module}_standardized
  GROUP BY dq_status;
  ```

### Hash Verification
- [ ] Manually calculate profile_hash for one record
- [ ] Verify computed hash matches manual calculation
- [ ] Test with NULL values (should use '__NULL__' token)
- [ ] Test with empty strings
- [ ] Test case normalization (UPPER for English, preserve for local)

### Performance Testing (Optional but Recommended)
- [ ] Load larger dataset (1000+ records)
- [ ] Measure Silver model execution time
- [ ] Measure Gold model execution time
- [ ] Check index usage in queries
- [ ] Verify incremental logic works efficiently

### Integration Testing
- [ ] Full pipeline run: Bronze → Silver → Gold → Bridge
- [ ] Verify referential integrity
- [ ] Check data counts match at each layer:
  ```sql
  SELECT 'Bronze' AS layer, COUNT(*) FROM bronze.{module}_standardized
  UNION ALL
  SELECT 'Silver', COUNT(*) FROM silver.{module}_standardized
  UNION ALL
  SELECT 'Gold', COUNT(DISTINCT {entity}_id) FROM gold.dim_{module};
  ```

---

## 🚀 Deployment

### Pre-Deployment
- [ ] Code review completed
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Change log updated

### Deployment Sequence
1. [ ] Deploy enumeration files (if using database tables)
2. [ ] Deploy Bronze DDL: `psql -f db/bronze/{module}_standardized.sql`
3. [ ] Deploy Silver DDL: `psql -f db/silver/{module}_standardized.sql` (if not using dbt)
4. [ ] Deploy Gold DDL: `psql -f db/gold/dim_{module}.sql`
5. [ ] Deploy Bridge DDL: `psql -f db/gold/bridges/bridge_*.sql` (if applicable)
6. [ ] Deploy Quarantine DDL: `psql -f db/quarantine/{module}_quarantine.sql`
7. [ ] Deploy dbt models: `dbt run --models {module}`
8. [ ] Verify deployment: Check all objects created

### Post-Deployment Validation
- [ ] Run full pipeline with production data
- [ ] Check data quality metrics
- [ ] Verify version history is building correctly
- [ ] Monitor performance
- [ ] Check for any errors in logs
- [ ] Validate counts and aggregations

### Rollback Plan (If Needed)
- [ ] Document rollback steps
- [ ] Backup production data before deployment
- [ ] Test rollback procedure in dev/staging

---

## 📊 Monitoring & Maintenance

### Monitoring Setup
- [ ] Create data quality dashboard
- [ ] Set up alerts for DQ score thresholds
- [ ] Monitor version churn (excessive versioning)
- [ ] Track quarantine record counts
- [ ] Monitor ETL execution times

### Documentation Maintenance
- [ ] Schedule periodic review of documentation
- [ ] Update sample records as patterns evolve
- [ ] Keep enumeration files current
- [ ] Update ADRs if decisions change

---

## ✅ Completion Checklist

### All Artifacts Created
- [ ] Business specification document
- [ ] Enumeration YAML files (all)
- [ ] Bronze contract
- [ ] Silver contract
- [ ] Gold contract(s)
- [ ] Bridge contract(s) (if applicable)
- [ ] Bronze DDL
- [ ] Gold DDL
- [ ] Bridge DDL (if applicable)
- [ ] Quarantine DDL
- [ ] dbt source definition
- [ ] dbt Silver model
- [ ] dbt Gold model
- [ ] dbt Bridge model(s) (if applicable)
- [ ] dbt Quarantine model
- [ ] dbt schema.yml files with tests
- [ ] Updated README.md
- [ ] Updated STANDARDS_INDEX.md
- [ ] ADR documents (if needed)

### All Tests Passing
- [ ] dbt compile succeeds
- [ ] dbt test succeeds
- [ ] Sample data tests pass
- [ ] SCD2 version tests pass
- [ ] Bridge table tests pass (if applicable)
- [ ] Hash verification tests pass
- [ ] Data quality tests pass

### Deployment Complete
- [ ] All database objects created
- [ ] dbt models deployed
- [ ] Initial data load successful
- [ ] Monitoring setup complete

### Documentation Complete
- [ ] All markdown files complete
- [ ] All YAML contracts complete
- [ ] dbt documentation generated
- [ ] Knowledge transfer completed (if team-based)

---

## 🎉 Module Complete!

Congratulations! Your new module is ready for production use.

**Final Steps**:
1. ✅ Close development ticket/issue
2. ✅ Update project board/tracker
3. ✅ Communicate completion to stakeholders
4. ✅ Schedule follow-up review (30/60/90 days)

---

**Need Help?**
- Review customer profile implementation as reference
- Check troubleshooting section in HOW_TO_REPLICATE_MODULE.md
- Consult standards documents in /docs/data-modeling/
- Refer to AI_CONTEXT.md for quick reference

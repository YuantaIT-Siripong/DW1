# DW1 Workflow Guide

**Quick Start Guide**: How to build a new data warehouse module from scratch. 

---

## 🎯 The Big Picture

Building a new module follows this simple flow:

```
1. Business Spec → 2. Contract → 3. Database → 4. ETL → 5. Test → 6. Views
```

**Time**: 1-2 days per module with AI assistance. 

---

## 📋 7-Step Workflow

### Step 1: Write Business Requirements

**What**: Document what data you need and why.

**Create**: `docs/business/modules/<your_module>. md`

**Copy template from**: `docs/business/modules/customer_module.md`

**Must include**:
- Business goals (what questions will this answer?)
- List of attributes (fields you need)
- SCD2 rules (what triggers a new version?)
- Data quality rules

**AI Prompt**:
```
Create a business module specification for [your domain] 
following customer_module.md as template.  
Apply standards from STANDARDS_INDEX.md. 
```

**Done when**:
- ✅ All attributes listed
- ✅ SCD2 triggers defined
- ✅ Business stakeholders reviewed

---

### Step 2: Create Data Contract

**What**: Define the technical schema. 

**Create**: `contracts/scd2/<your_entity>_columns.yaml`

**Copy template from**: `contracts/scd2/dim_customer_profile_columns.yaml`

**Key parts**:
```yaml
scd2_attributes:           # Fields that trigger versions
  - name: field_1
    data_type: VARCHAR(100)

hash_fields:               # Fields in change detection
  - field_1
  - field_2

excluded_from_hash:        # Never include these
  - effective_start_ts
  - data_quality_score     # Derived metrics excluded! 
```

**AI Prompt**:
```
Generate SCD2 contract YAML for [entity] from 
[module]. md attribute inventory.  
Follow STANDARD_SCD2_POLICY. md.
```

**Done when**:
- ✅ All SCD2 attributes listed
- ✅ Hash fields defined (no derived metrics!)
- ✅ Added to `contracts/INDEX.yaml`

---

### Step 3: Generate Database Tables

**What**: Create the table structure.

**Create**: `db/ddl/<sequence>_create_dim_<entity>.sql`

**AI Prompt**:
```
Generate PostgreSQL DDL for [entity] from 
contracts/scd2/[entity]_columns.yaml. 
Include indexes and constraints per naming_conventions.md.
```

**What you get**:
```sql
CREATE TABLE dim. <entity> (
    -- Surrogate key
    <entity>_version_sk BIGSERIAL PRIMARY KEY,
    
    -- Business key
    <entity>_id VARCHAR(50) NOT NULL,
    
    -- Your SCD2 attributes
    field_1 VARCHAR(100),
    field_2 INTEGER,
    
    -- Profile hash
    profile_hash VARCHAR(64) NOT NULL,
    
    -- SCD2 temporal fields
    effective_start_ts TIMESTAMP(6) NOT NULL,
    effective_end_ts TIMESTAMP(6),
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    version_num INTEGER NOT NULL,
    
    -- Constraints
    UNIQUE (<entity>_id, version_num)
);
```

**Done when**:
- ✅ Table created in database
- ✅ Indexes created
- ✅ Constraints working

---

### Step 4: Build ETL Pipeline

**What**: Load data with SCD2 version control.

#### 4a.  Staging (Bronze)
```sql
CREATE TABLE staging. stg_<entity> (
    -- Your source fields
    field_1 TEXT,
    field_2 TEXT,
    
    -- ETL metadata
    ingested_at TIMESTAMP(6),
    batch_id VARCHAR(100)
);
```

#### 4b. Calculate Profile Hash (Silver)

**AI Prompt**:
```
Generate SQL to calculate profile_hash for [entity] 
following hashing_standards.md. 
Hash these fields: [list]. 
```

**Example**:
```sql
encode(
    digest(
        COALESCE(LOWER(TRIM(field_1)), '__NULL__') || '|' ||
        COALESCE(field_2::TEXT, '__NULL__'),
        'sha256'
    ),
    'hex'
) AS profile_hash
```

**Key rules**:
- Use `__NULL__` for NULL values (not empty string!)
- Use `|` as delimiter
- SHA256 algorithm
- Lowercase and trim strings

#### 4c. SCD2 Merge Logic

**AI Prompt**:
```
Generate SCD2 merge procedure for [entity] 
following STANDARD_SCD2_POLICY.md closure rules.
```

**What it does**:
1. Compare new hash vs current hash
2. If different:
   - Close old version: `effective_end_ts = new_start_ts - 1 microsecond`
   - Insert new version with incremented `version_num`

**Done when**:
- ✅ Staging table loads successfully
- ✅ Hash calculation tested
- ✅ SCD2 merge creates versions correctly
- ✅ No overlapping time intervals

---

### Step 5: Create Tests

**What**: Validate data integrity.

**Create**: `tests/test_<entity>.sql`

**Three essential tests**:

```sql
-- Test 1: No overlapping intervals
SELECT <entity>_id, COUNT(*)
FROM dim.<entity> a
JOIN dim.<entity> b
  ON a. <entity>_id = b.<entity>_id
 AND a. <entity>_version_sk <> b.<entity>_version_sk
 AND a. effective_start_ts < COALESCE(b.effective_end_ts, '9999-12-31')
 AND COALESCE(a.effective_end_ts, '9999-12-31') > b.effective_start_ts
GROUP BY <entity>_id;
-- Expected: 0 rows

-- Test 2: Exactly one current per business key
SELECT <entity>_id, COUNT(*)
FROM dim.<entity>
WHERE is_current = TRUE
GROUP BY <entity>_id
HAVING COUNT(*) <> 1;
-- Expected: 0 rows

-- Test 3: Hash matches recalculation
WITH recalc AS (
    SELECT 
        <entity>_version_sk,
        encode(digest(
            COALESCE(LOWER(TRIM(field_1)), '__NULL__') || '|' ||
            COALESCE(field_2::TEXT, '__NULL__'),
            'sha256'
        ), 'hex') AS calc_hash,
        profile_hash
    FROM dim.<entity>
)
SELECT * FROM recalc
WHERE calc_hash <> profile_hash;
-- Expected: 0 rows
```

**Done when**:
- ✅ All tests return 0 rows
- ✅ No data integrity issues

---

### Step 6: Create Views

**What**: Make data easy to query.

**Create current state view**:
```sql
-- db/views/vw_<entity>_current. sql
CREATE VIEW gold.vw_<entity>_current AS
SELECT 
    <entity>_id,
    <entity>_version_sk,
    field_1,
    field_2,
    effective_start_ts,
    version_num
FROM dim.<entity>
WHERE is_current = TRUE;
```

**Create data quality view** (optional):
```sql
-- db/views/vw_<entity>_quality.sql
CREATE VIEW gold.vw_<entity>_quality AS
SELECT 
    <entity>_id,
    -- Completeness score
    (CASE WHEN field_1 IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN field_2 IS NOT NULL THEN 1 ELSE 0 END
    )::DECIMAL / 2. 0 AS completeness_score
FROM dim.<entity>
WHERE is_current = TRUE;
```

**Reference**: `docs/data-quality/framework.md`

**Done when**:
- ✅ Current view created
- ✅ Quality view created (if needed)

---

### Step 7: Update Documentation

**What**: Keep the manifest current.

**Update**: `CONTEXT_MANIFEST.yaml`

```yaml
modules:
  <your_module>: "docs/business/modules/<your_module>.md"

contracts:
  - name: <entity>_columns.yaml
    path: contracts/scd2/<entity>_columns.yaml
    type: scd2
    entity: dim_<entity>
    authoritative: true
```

**Done when**:
- ✅ CONTEXT_MANIFEST. yaml updated
- ✅ Module spec committed
- ✅ Workflow complete! 

---

## 🎯 Quick Reference

### Must-Know Files

| File | What It Does |
|------|--------------|
| `STANDARDS_INDEX.md` | All standards in one place - READ THIS FIRST |
| `AI_CONTEXT. md` | How to work with AI on this repo |
| `naming_conventions.md` | How to name tables, columns, etc. |
| `hashing_standards.md` | How to calculate profile hashes |
| `STANDARD_SCD2_POLICY. md` | SCD2 implementation rules |

### Critical Standards

| What | Standard |
|------|----------|
| **NULL in hash** | Use `__NULL__` (not empty string!) |
| **Hash algorithm** | SHA256 (64-char hex) |
| **Hash delimiter** | Use `\|` for profile hashes |
| **Timestamps** | TIMESTAMP(6) with microsecond precision |
| **Close version** | `prev_end = new_start - 1 microsecond` |
| **Surrogate key** | `<entity>_version_sk BIGSERIAL` |
| **Naming** | snake_case for database, camelCase for API |
| **Enumerations** | UPPERCASE_SNAKE_CASE |

### Common Mistakes to Avoid ❌

| Don't Do This | Do This Instead |
|---------------|-----------------|
| ❌ Include `data_quality_score` in hash | ✅ Exclude all derived metrics from hash |
| ❌ Use empty string for NULL | ✅ Use `__NULL__` token |
| ❌ Allow overlapping intervals | ✅ Close previous: `end = start - 1 microsecond` |
| ❌ Use MD5 | ✅ Use SHA256 |
| ❌ Multiple `is_current = TRUE` | ✅ Exactly one current per business key |
| ❌ Skip hash calculation | ✅ Always calculate profile hash |

---

## 🤖 Working with AI

### Best Practices

**1. Always reference standards**:
```
Following STANDARDS_INDEX.md, create...
```

**2. Use existing examples as templates**:
```
Use customer_module.md as template for...
```

**3. Be specific about which standard to apply**:
```
Apply hashing_standards.md NULL handling rules...
```

**4.  Verify AI outputs**:
- Check against standards documents
- Run all tests
- Validate with contracts

### Example AI Prompts

**Business Spec**:
```
Create business module specification for Product 
following customer_module.md structure. 
Apply standards from STANDARDS_INDEX.md.
```

**Contract**:
```
Generate SCD2 contract YAML for dim_product 
from Product module attribute inventory. 
Follow STANDARD_SCD2_POLICY.md.
```

**DDL**:
```
Generate PostgreSQL DDL for dim_product 
from contracts/scd2/product_columns.yaml. 
Include indexes per naming_conventions.md.
```

**Hash Calculation**:
```
Generate SQL for calculating profile_hash for Product 
following hashing_standards.md. 
Hash fields: product_name, category, price.
```

**Tests**:
```
Generate SQL tests for dim_product to validate:
- No overlapping intervals
- Single current per product_id
- Hash integrity
```

---

## ✅ Complete Workflow Checklist

Use this for each new module:

- [ ] **Step 1**: Business spec created (`docs/business/modules/`)
- [ ] **Step 2**: Contract created (`contracts/scd2/`)
- [ ] **Step 3**: DDL executed (table created in database)
- [ ] **Step 4**: ETL pipeline built and tested
  - [ ] Staging table loads
  - [ ] Hash calculation correct
  - [ ] SCD2 merge working
- [ ] **Step 5**: All tests passing
  - [ ] No overlaps
  - [ ] Single current
  - [ ] Hash integrity
- [ ] **Step 6**: Views created and tested
- [ ] **Step 7**: CONTEXT_MANIFEST.yaml updated

**Done! ** Your module is production-ready.  🎉

---

## 🆘 Troubleshooting

### Hash Mismatch
**Problem**: Recalculated hash doesn't match stored hash. 

**Check**:
- Are you using `__NULL__` for NULL values? 
- Are you lowercasing and trimming strings?
- Are you using `|` delimiter? 
- Are attributes in the correct order?

### Overlapping Intervals
**Problem**: Test shows overlapping time intervals.

**Check**:
- Closure rule: `prev_end = new_start - 1 microsecond`
- No duplicate inserts
- Merge logic closes previous version before inserting new

### Multiple Current Versions
**Problem**: More than one `is_current = TRUE` per business key.

**Check**:
- Merge logic sets `is_current = FALSE` on old version
- No concurrent updates
- Unique constraint enforced

---

## 📚 Additional Resources

- **Standards**: See `STANDARDS_INDEX.md` for all standards
- **Examples**: Review `customer_module.md` and `investment_profile_module.md`
- **Contracts**: Browse `contracts/scd2/` for examples
- **Tests**: See existing test files in `tests/`

---

**Last Updated**: 2025-12-01  
**Maintained By**: Data Architecture  
**Questions?** Check STANDARDS_INDEX.md first








I'm working on YuantaIT-Siripong/DW1.  
Please read AI_CONTEXT.md to load all project standards. 

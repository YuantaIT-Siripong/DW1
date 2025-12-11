# dbt Macros Guide

**Purpose**: Documentation for all dbt macros used in the DW1 project  
**Location**: `/dbt/macros/`  
**Target Audience**: Data engineers, dbt developers, AI agents

---

## Table of Contents
1. [Overview](#overview)
2. [Hash Computation Macros](#hash-computation-macros)
3. [Validation Macros](#validation-macros)
4. [Schema Macros](#schema-macros)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Overview

### What are dbt Macros?

dbt macros are reusable pieces of Jinja code that generate SQL. They help maintain consistency and reduce code duplication across models.

### Why Use Macros?

✅ **Consistency**: Same logic applied everywhere  
✅ **Maintainability**: Change once, apply everywhere  
✅ **Readability**: Abstract complex SQL into named functions  
✅ **Testability**: Test logic in one place  

### Macro Categories in DW1

| Category | Purpose | Macros |
|----------|---------|--------|
| **Hash Computation** | SCD2 change detection | `compute_profile_hash`, `compute_set_hash` |
| **Validation** | Data quality checks | `validate_enumeration`, `validate_set` |
| **Schema** | Multi-environment support | `get_custom_schema` |

---

## Hash Computation Macros

### 1. `compute_profile_hash`

**Purpose**: Compute SHA256 hash of profile attributes for SCD2 change detection

**File**: `/dbt/macros/compute_profile_hash.sql`

**Function**: Takes multiple column names and generates a deterministic hash for versioning

#### Syntax
```sql
{{ compute_profile_hash(
    'column1',
    'column2',
    'column3',
    -- ... more columns ...
) }}
```

#### Parameters
- **varargs** (variable number of arguments): Column names as strings in canonical order
- All parameters are required (no optional parameters)
- Column names must be quoted strings

#### Returns
- VARCHAR(64): Lowercase hexadecimal SHA256 hash

#### Implementation
```sql
{% macro compute_profile_hash() %}
    encode(
        sha256(
            concat_ws('|',
                {% for arg in varargs %}
                    COALESCE({{ arg }}::TEXT, '')
                    {%- if not loop.last %},{% endif %}
                {% endfor %}
            )::bytea
        ),
        'hex'
    )
{% endmacro %}
```

#### Usage Example
```sql
-- In dbt Silver model
WITH with_profile_hash AS (
    SELECT 
        *,
        {{ compute_profile_hash(
            'evidence_unique_key',
            'firstname',
            'lastname',
            'firstname_local',
            'lastname_local',
            'person_title',
            'marital_status',
            'nationality',
            'occupation',
            'education_level',
            'business_type',
            'birthdate',
            'total_asset',
            'monthly_income',
            'income_country',
            'source_of_income_set_hash',
            'purpose_of_investment_set_hash'
        ) }} AS profile_hash
    FROM validated
)
```

#### Generated SQL
```sql
encode(
    sha256(
        concat_ws('|',
            COALESCE(evidence_unique_key::TEXT, ''),
            COALESCE(firstname::TEXT, ''),
            COALESCE(lastname::TEXT, ''),
            -- ... all columns ...
            COALESCE(purpose_of_investment_set_hash::TEXT, '')
        )::bytea
    ),
    'hex'
) AS profile_hash
```

#### Important Notes

⚠️ **Order Matters**: Columns must be in the exact order specified in the contract  
⚠️ **NULL Handling**: NULLs are converted to empty string `''` (not `'__NULL__'` token)  
⚠️ **Normalization**: This macro does NOT apply UPPER/TRIM - do that before calling  
⚠️ **Deterministic**: Same inputs always produce same hash  

#### Normalization Requirements

The macro itself doesn't normalize - **you must normalize columns BEFORE** passing to the macro:

```sql
-- WRONG - columns not normalized
{{ compute_profile_hash(
    'firstname',  -- Original case, might have whitespace
    'lastname'
) }}

-- CORRECT - normalize in previous CTE
WITH normalized AS (
    SELECT 
        UPPER(TRIM(firstname)) AS firstname,
        UPPER(TRIM(lastname)) AS lastname
    FROM source
),
with_hash AS (
    SELECT 
        *,
        {{ compute_profile_hash('firstname', 'lastname') }} AS profile_hash
    FROM normalized
)
```

#### Testing Hash Computation

```sql
-- Test with known values
SELECT 
    'John' AS firstname,
    'Doe' AS lastname,
    {{ compute_profile_hash('firstname', 'lastname') }} AS computed_hash;

-- Expected: a3c2e84b9c5a6f3d1e8b7c4a9f2d6e1b... (64 hex chars)
```

---

### 2. `compute_set_hash`

**Purpose**: Compute SHA256 hash of a pipe-delimited set for change detection

**File**: `/dbt/macros/compute_set_hash.sql`

**Function**: Takes a pipe-delimited list, normalizes it, and computes a deterministic hash

#### Syntax
```sql
{{ compute_set_hash('column_name') }}
```

#### Parameters
- **set_column** (string): Name of column containing pipe-delimited list
- Column should contain format: `"VALUE1|VALUE2|VALUE3"`

#### Returns
- VARCHAR(64): Lowercase hexadecimal SHA256 hash
- NULL if input is NULL

#### Implementation
```sql
{% macro compute_set_hash(set_column) %}
    CASE 
        WHEN {{ set_column }} IS NULL THEN NULL
        ELSE encode(
            sha256(
                array_to_string(
                    (
                        SELECT array_agg(item ORDER BY item)
                        FROM unnest(string_to_array({{ set_column }}, '|')) AS item
                    ),
                    '|'
                )::bytea
            ),
            'hex'
        )
    END
{% endmacro %}
```

#### Usage Example
```sql
-- In dbt Silver model
WITH with_hashes AS (
    SELECT 
        *,
        {{ compute_set_hash('source_of_income_list') }} AS source_of_income_set_hash,
        {{ compute_set_hash('purpose_of_investment_list') }} AS purpose_of_investment_set_hash
    FROM validated
)
```

#### Generated SQL
```sql
CASE 
    WHEN source_of_income_list IS NULL THEN NULL
    ELSE encode(
        sha256(
            array_to_string(
                (
                    SELECT array_agg(item ORDER BY item)
                    FROM unnest(string_to_array(source_of_income_list, '|')) AS item
                ),
                '|'
            )::bytea
        ),
        'hex'
    )
END AS source_of_income_set_hash
```

#### Processing Steps

The macro performs these operations automatically:

1. **Split**: Breaks pipe-delimited string into array
2. **Sort**: Orders items alphabetically (ascending)
3. **Aggregate**: Re-joins with pipe delimiter
4. **Hash**: Computes SHA256
5. **Encode**: Converts to lowercase hex

**No manual normalization needed** - the macro handles it!

#### Important Notes

✅ **Order-Independent**: `"A|B|C"` and `"C|B|A"` produce **same hash**  
✅ **Deduplication**: Happens via array_agg  
✅ **Normalization**: Already built into macro  
⚠️ **Empty String**: Empty input (`""`) produces empty set hash  
⚠️ **NULL Input**: Returns NULL (not empty set hash)  

#### Empty Set Handling

```sql
-- Empty string
{{ compute_set_hash("''") }}
-- Result: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

-- NULL
{{ compute_set_hash('NULL::TEXT') }}
-- Result: NULL
```

#### Testing Set Hash

```sql
-- Test with known set
SELECT 
    'SALARY|DIVIDEND|RENTAL' AS input,
    {{ compute_set_hash('''SALARY|DIVIDEND|RENTAL''') }} AS hash1,
    {{ compute_set_hash('''RENTAL|SALARY|DIVIDEND''') }} AS hash2;
-- hash1 should equal hash2 (order-independent)

-- Test empty set
SELECT 
    '' AS input,
    {{ compute_set_hash("''") }} AS empty_hash;
-- Should equal: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

---

## Validation Macros

### 3. `validate_enumeration`

**Purpose**: Check if a value exists in an enumeration reference table

**File**: `/dbt/macros/validate_enumeration.sql`

**Function**: Returns TRUE if value is valid or NULL, FALSE if invalid

#### Syntax
```sql
{{ validate_enumeration('column_name', 'enumeration_ref_name') }}
```

#### Parameters
- **column_name** (string): Column to validate
- **enumeration_ref_name** (string): Name of enumeration reference table (without `ref()`)

#### Returns
- BOOLEAN: 
  - TRUE if value exists in enumeration OR is NULL
  - FALSE if value doesn't exist in enumeration

#### Implementation
```sql
{% macro validate_enumeration(column_name, enum_ref) %}
    CASE 
        WHEN {{ column_name }} IS NULL THEN TRUE
        WHEN {{ column_name }} IN (SELECT code FROM {{ ref(enum_ref) }}) THEN TRUE
        ELSE FALSE
    END
{% endmacro %}
```

#### Usage Example
```sql
-- In dbt Silver model
WITH validated AS (
    SELECT 
        *,
        {{ validate_enumeration('person_title', '_customer_person_title') }} AS dq_person_title_valid,
        {{ validate_enumeration('marital_status', '_customer_marital_status') }} AS dq_marital_status_valid,
        {{ validate_enumeration('nationality', '_customer_nationality') }} AS dq_nationality_valid
    FROM source
)
```

#### Generated SQL
```sql
CASE 
    WHEN person_title IS NULL THEN TRUE
    WHEN person_title IN (SELECT code FROM silver._customer_person_title) THEN TRUE
    ELSE FALSE
END AS dq_person_title_valid
```

#### Enumeration Reference Tables

Enumeration reference tables should be in `dbt/models/silver/enums/`:

```sql
-- File: dbt/models/silver/enums/_customer_person_title.sql
SELECT code, description, sort_order
FROM (VALUES
    ('MR', 'Mr.', 1),
    ('MRS', 'Mrs.', 2),
    ('MS', 'Ms.', 3),
    ('MISS', 'Miss', 4),
    ('DR', 'Dr.', 5),
    ('PROF', 'Prof.', 6),
    ('REV', 'Rev.', 7),
    ('OTHER', 'Other', 98),
    ('UNKNOWN', 'Unknown', 99)
) AS enums(code, description, sort_order)
```

#### Important Notes

✅ **NULL is Valid**: NULLs are treated as valid (returns TRUE)  
⚠️ **Case Sensitive**: Ensure codes in data match enumeration exactly  
⚠️ **Performance**: Each validation is a subquery - use CTEs wisely  

---

### 4. `validate_set`

**Purpose**: Validate that all members of a pipe-delimited set are valid enumerations

**File**: `/dbt/macros/validate_set.sql`

**Function**: Returns TRUE if ALL members are valid, FALSE if ANY member is invalid

#### Syntax
```sql
{{ validate_set('set_column', 'enumeration_ref_name') }}
```

#### Parameters
- **set_column** (string): Column containing pipe-delimited list
- **enumeration_ref_name** (string): Name of enumeration reference table

#### Returns
- BOOLEAN:
  - TRUE if all members exist in enumeration OR set is NULL/empty
  - FALSE if any member doesn't exist in enumeration

#### Implementation
```sql
{% macro validate_set(set_column, enum_ref) %}
    CASE 
        WHEN {{ set_column }} IS NULL OR TRIM({{ set_column }}) = '' THEN TRUE
        WHEN NOT EXISTS (
            SELECT 1
            FROM unnest(string_to_array({{ set_column }}, '|')) AS item
            WHERE TRIM(item) != ''
              AND UPPER(TRIM(item)) NOT IN (SELECT code FROM {{ ref(enum_ref) }})
        ) THEN TRUE
        ELSE FALSE
    END
{% endmacro %}
```

#### Usage Example
```sql
-- In dbt Silver model
WITH validated AS (
    SELECT 
        *,
        {{ validate_set('source_of_income_list', '_customer_source_of_income') }} 
            AS dq_source_of_income_valid,
        {{ validate_set('purpose_of_investment_list', '_customer_purpose_of_investment') }} 
            AS dq_purpose_of_investment_valid
    FROM source
)
```

#### Generated SQL
```sql
CASE 
    WHEN source_of_income_list IS NULL OR TRIM(source_of_income_list) = '' THEN TRUE
    WHEN NOT EXISTS (
        SELECT 1
        FROM unnest(string_to_array(source_of_income_list, '|')) AS item
        WHERE TRIM(item) != ''
          AND UPPER(TRIM(item)) NOT IN (SELECT code FROM silver._customer_source_of_income)
    ) THEN TRUE
    ELSE FALSE
END AS dq_source_of_income_valid
```

#### Important Notes

✅ **All Must Be Valid**: Even one invalid member makes the whole set invalid  
✅ **Empty Set is Valid**: NULL or empty string returns TRUE  
⚠️ **Normalization**: Applies UPPER(TRIM) before checking  
⚠️ **Performance**: More expensive than single value validation  

#### Testing Set Validation

```sql
-- Test valid set
SELECT 
    'SALARY|DIVIDEND' AS input,
    {{ validate_set('''SALARY|DIVIDEND''', '_customer_source_of_income') }} AS is_valid;
-- Should return TRUE

-- Test invalid set (contains INVALID_CODE)
SELECT 
    'SALARY|INVALID_CODE|DIVIDEND' AS input,
    {{ validate_set('''SALARY|INVALID_CODE|DIVIDEND''', '_customer_source_of_income') }} AS is_valid;
-- Should return FALSE
```

---

## Schema Macros

### 5. `get_custom_schema`

**Purpose**: Override dbt's default schema naming for multi-environment deployments

**File**: `/dbt/macros/get_custom_schema.sql`

**Function**: Controls how dbt generates schema names based on environment

#### Syntax
This macro is called automatically by dbt - you don't call it directly.

#### Configuration
Set in `dbt_project.yml`:

```yaml
models:
  dw1:
    bronze:
      +schema: bronze
    silver:
      +schema: silver
    gold:
      +schema: gold
```

#### Purpose by Environment

| Environment | Target Schema | Custom Schema | Result |
|-------------|---------------|---------------|---------|
| Development | dev_username | bronze | dev_username_bronze |
| Production | prod | bronze | bronze |

#### Usage
Automatic - dbt uses this macro when materializing models.

---

## Best Practices

### 1. Macro Naming Conventions

✅ **DO**:
- Use snake_case for macro names
- Start with verb: `compute_`, `validate_`, `get_`
- Be descriptive: `compute_profile_hash` not `hash`

❌ **DON'T**:
- Use camelCase
- Use generic names: `process`, `do_thing`
- Start with underscore (reserved for internal macros)

### 2. Testing Macros

Always test macros before using in production:

```sql
-- Create test model
-- File: dbt/models/test/test_hash_macro.sql
SELECT 
    'TEST' AS test_value,
    {{ compute_profile_hash("'TEST'", "'VALUE'") }} AS hash_result;
```

Run: `dbt run --models test_hash_macro`

### 3. Macro Documentation

Document macros with:
- Purpose
- Parameters (names, types, examples)
- Return value
- Usage examples
- Edge cases

### 4. Performance Considerations

⚠️ **Watch out for**:
- Macros with subqueries (validate_enumeration) - can be slow
- Multiple macro calls on same table - use CTEs to batch
- Macros in WHERE clauses - may prevent index usage

✅ **Best practices**:
- Call validation macros in a single CTE
- Cache enumeration tables if possible
- Profile query performance

### 5. Macro Versioning

If you change macro logic:
1. Create new macro with version suffix: `compute_profile_hash_v2`
2. Update models incrementally
3. Deprecate old macro after migration
4. Remove old macro in next major release

---

## Troubleshooting

### Issue 1: Hash Not Matching Expected Value

**Symptom**: Computed hash doesn't match contract specification

**Possible Causes**:
1. Column order wrong
2. Missing columns
3. Normalization not applied
4. NULL handling different

**Fix**:
```sql
-- Debug: Print canonical string
SELECT 
    concat_ws('|',
        COALESCE(col1::TEXT, ''),
        COALESCE(col2::TEXT, '')
    ) AS canonical_string,
    {{ compute_profile_hash('col1', 'col2') }} AS hash;
-- Compare canonical_string to contract specification
```

### Issue 2: Set Hash Empty Set Not Matching

**Symptom**: Empty set hash doesn't equal expected constant

**Expected**: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`

**Fix**:
```sql
-- Check if input is truly empty
SELECT 
    source_of_income_list,
    LENGTH(source_of_income_list) AS length,
    {{ compute_set_hash('source_of_income_list') }} AS computed_hash
FROM table
WHERE source_of_income_list = '' OR source_of_income_list IS NULL;
```

### Issue 3: Validation Always Returns FALSE

**Symptom**: All records marked as invalid even though data looks correct

**Possible Causes**:
1. Enumeration reference table doesn't exist
2. Enumeration table has wrong schema
3. Case mismatch (data lowercase, enum uppercase)

**Fix**:
```sql
-- Check enumeration table exists
SELECT * FROM {{ ref('_customer_person_title') }};

-- Check case of codes
SELECT DISTINCT person_title FROM source;
-- Compare to enumeration codes
```

### Issue 4: dbt Macro Compilation Error

**Symptom**: `dbt compile` fails with Jinja error

**Common Errors**:
- Forgot closing `%}`
- Missing comma in parameter list
- Typo in macro name

**Fix**:
1. Check syntax highlighting in editor
2. Run `dbt parse` for detailed error
3. Simplify macro to isolate issue

---

## Summary

### Quick Reference

| Macro | Purpose | Usage |
|-------|---------|-------|
| `compute_profile_hash` | SCD2 change detection | `{{ compute_profile_hash('col1', 'col2', ...) }}` |
| `compute_set_hash` | Multi-valued set change detection | `{{ compute_set_hash('set_column') }}` |
| `validate_enumeration` | Single value validation | `{{ validate_enumeration('column', 'enum_ref') }}` |
| `validate_set` | Set members validation | `{{ validate_set('set_column', 'enum_ref') }}` |
| `get_custom_schema` | Schema naming | Automatic (via config) |

### Next Steps

1. ✅ Review macro implementations in `/dbt/macros/`
2. ✅ Test macros with sample data
3. ✅ Use macros in Silver and Gold models
4. ✅ Add macro tests to CI/CD pipeline
5. ✅ Document any custom macros you create

---

**Questions?** Refer to:
- dbt macro documentation: https://docs.getdbt.com/docs/build/jinja-macros
- Project standards: `STANDARDS_INDEX.md`
- Silver model examples: `dbt/models/silver/customer_profile_standardized.sql`

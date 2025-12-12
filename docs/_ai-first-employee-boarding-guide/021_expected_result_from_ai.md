### 1. Entity Classification
- Entity name: Product
- Domain: product
- SCD Type needed: Type 2
- Rationale: Need to track price and category changes over time

### 2. Attribute Analysis

| Attribute | Data Type | Type 1 or Type 2? | Nullable? | Notes |
|-----------|-----------|-------------------|-----------|-------|
| product_id | VARCHAR(50) | Type 2 | No | Natural key |
| product_name | VARCHAR(200) | Type 2 | Yes | Product display name |
| product_category | VARCHAR(50) | Type 2 | Yes | Enumeration |
| product_category_other | VARCHAR(200) | Type 1 | Yes | Freetext when category=OTHER |
| product_price | NUMERIC(10,2) | Type 2 | Yes | Track price changes |
| is_active | BOOLEAN | Type 2 | No | Active status |
| created_date | DATE | Type 2 | Yes | Original creation |

### 3. Enumeration Identification

| Enumeration Name | Valid Values | Has OTHER? | Needs _other field? |
|------------------|--------------|------------|---------------------|
| product_category | ELECTRONICS, CLOTHING, FOOD, OTHER, UNKNOWN | Yes | Yes (product_category_other) |

### 4. Multi-Valued Sets

None identified. 

### 5. Surrogate Key Pattern

- Primary key name:  `product_version_sk`
- Natural key: `product_id`
- Version tracking: Yes (version_num column)

### 6. Hash Computation

Fields to INCLUDE in profile_hash:
- ✅ product_id
- ✅ product_name
- ✅ product_category
- ✅ product_price
- ✅ is_active
- ✅ created_date

Fields to EXCLUDE from profile_hash:
- ❌ product_version_sk (surrogate key)
- ❌ effective_start_ts, effective_end_ts, is_current, version_num (temporal/SCD2)
- ❌ product_category_other (Type 1 attribute)
- ❌ profile_hash (the hash itself)
- ❌ load_ts, _bronze_load_ts, _silver_load_ts (ETL metadata)
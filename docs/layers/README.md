# Data Warehouse Layers

## Architecture Note

This data warehouse implements **Medallion Architecture** (Bronze/Silver/Gold).

### Layer Naming:
- **Bronze** = Raw landing zone (replaces "Staging")
- **Silver** = Cleaned & validated (replaces "Integration")
- **Gold** = Dimensional models (replaces "Presentation")

### Why Medallion?
Modern cloud-native standard adopted by Databricks, Snowflake, AWS, Azure. Simple 3-layer model with clear responsibilities at each stage.

## Overview
This document details the specific layers of the data warehouse architecture, their purposes, design patterns, and implementation guidelines.

## Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Source Systems                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    1. BRONZE LAYER                          │
│  Purpose: Raw data landing zone                             │
│  Pattern: Minimal transformation                            │
│  Technology: Python ETL scripts (etl/ folder)               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  2. SILVER LAYER                            │
│  Purpose: Cleansed, integrated enterprise data              │
│  Pattern: Data Vault, 3NF, or hybrid                        │
│  Technology: dbt models (dbt/models/silver/)                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                 3. GOLD LAYER                               │
│  Purpose: Dimensional models for analytics                  │
│  Pattern: Star schema, snowflake, cubes                     │
│  Technology: dbt models (dbt/models/gold/)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   4. ACCESS LAYER                           │
│  Purpose: Views, APIs, data services                        │
│  Pattern: Virtual, materialized, secured views              │
└─────────────────────────────────────────────────────────────┘
```

## 1. Bronze Layer

### Purpose
- Land raw data with minimal transformation
- Provide data replay capability
- Enable data auditing and reconciliation
- Serve as source of truth for raw data

### Design Principles

**Minimal Transformation**:
- Store data as-is from source
- Only apply basic data type conversions
- Add technical metadata (load timestamp, batch ID)
- No business logic applied

**Schema Design**:
```sql
-- Staging table template
CREATE TABLE stg_<source>_<entity>_raw (
    -- Technical keys
    stg_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id VARCHAR(100) NOT NULL,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Source columns (as-is from source)
    source_column1 VARCHAR(MAX),  -- Use flexible types
    source_column2 VARCHAR(MAX),
    source_column3 VARCHAR(MAX),
    -- ... all source columns ...
    
    -- Source metadata
    source_system VARCHAR(50),
    source_file_name VARCHAR(255),
    source_row_number BIGINT,
    
    -- Data quality
    record_hash VARCHAR(64),  -- MD5/SHA hash of record
    is_processed BOOLEAN DEFAULT FALSE,
    processing_status VARCHAR(50)
);

-- Example: Staging table for customer data
CREATE TABLE stg_crm_customers_raw (
    stg_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id VARCHAR(100) NOT NULL,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Raw source data (all as VARCHAR for flexibility)
    customer_id VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(255),
    created_date VARCHAR(255),
    updated_date VARCHAR(255),
    
    -- Metadata
    source_system VARCHAR(50) DEFAULT 'CRM',
    source_file_name VARCHAR(255),
    source_row_number BIGINT,
    record_hash VARCHAR(64),
    is_processed BOOLEAN DEFAULT FALSE
);
```

### Data Loading Patterns

**Full Load**:
```sql
-- Truncate and load
TRUNCATE TABLE stg_orders_raw;

INSERT INTO stg_orders_raw 
SELECT 
    UUID() as batch_id,
    CURRENT_TIMESTAMP as load_timestamp,
    order_id,
    customer_id,
    order_date,
    total_amount,
    'ERP' as source_system,
    'orders_2024.csv' as source_file_name
FROM external_source.orders;
```

**Incremental Load**:
```sql
-- Load only new/changed records
INSERT INTO stg_orders_raw 
SELECT 
    UUID() as batch_id,
    CURRENT_TIMESTAMP as load_timestamp,
    order_id,
    customer_id,
    order_date,
    total_amount,
    'ERP' as source_system,
    'orders_delta.csv' as source_file_name
FROM external_source.orders
WHERE updated_date > (
    SELECT COALESCE(MAX(load_timestamp), '1900-01-01')
    FROM stg_orders_raw
);
```

### Data Retention
- **Short-term retention**: 7-30 days for recent data
- **Archive strategy**: Move to cold storage after processing
- **Replay capability**: Keep for regulatory or reprocessing needs

## 2. Silver Layer

### Purpose
- Create cleansed, integrated enterprise data
- Establish single source of truth
- Maintain historical accuracy
- Support data quality and governance

### Design Patterns

#### Pattern A: Data Vault

**Hub Table**:
```sql
CREATE TABLE hub_customer (
    customer_hub_key CHAR(32) PRIMARY KEY,  -- MD5 hash
    customer_id VARCHAR(50) NOT NULL,       -- Business key
    load_timestamp TIMESTAMP NOT NULL,
    record_source VARCHAR(50) NOT NULL,
    
    UNIQUE (customer_id)
);
```

**Link Table**:
```sql
CREATE TABLE link_customer_order (
    customer_order_link_key CHAR(32) PRIMARY KEY,  -- MD5 hash
    customer_hub_key CHAR(32) NOT NULL,
    order_hub_key CHAR(32) NOT NULL,
    load_timestamp TIMESTAMP NOT NULL,
    record_source VARCHAR(50) NOT NULL,
    
    FOREIGN KEY (customer_hub_key) REFERENCES hub_customer(customer_hub_key),
    FOREIGN KEY (order_hub_key) REFERENCES hub_order(order_hub_key),
    UNIQUE (customer_hub_key, order_hub_key)
);
```

**Satellite Table**:
```sql
CREATE TABLE sat_customer_details (
    customer_hub_key CHAR(32) NOT NULL,
    load_timestamp TIMESTAMP NOT NULL,
    load_end_timestamp TIMESTAMP,
    
    -- Descriptive attributes
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(500),
    
    -- Metadata
    record_source VARCHAR(50),
    record_hash CHAR(32),
    
    PRIMARY KEY (customer_hub_key, load_timestamp),
    FOREIGN KEY (customer_hub_key) REFERENCES hub_customer(customer_hub_key)
);
```

#### Pattern B: Third Normal Form (3NF)

**Normalized Tables**:
```sql
-- Customer master table
CREATE TABLE int_customer_master (
    customer_key BIGINT PRIMARY KEY,
    customer_id VARCHAR(50) UNIQUE NOT NULL,
    customer_type_id INTEGER,
    customer_segment_id INTEGER,
    created_date TIMESTAMP,
    updated_date TIMESTAMP,
    
    FOREIGN KEY (customer_type_id) REFERENCES int_customer_type(customer_type_id),
    FOREIGN KEY (customer_segment_id) REFERENCES int_customer_segment(customer_segment_id)
);

-- Customer details
CREATE TABLE int_customer_details (
    customer_key BIGINT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    date_of_birth DATE,
    
    FOREIGN KEY (customer_key) REFERENCES int_customer_master(customer_key)
);

-- Customer address
CREATE TABLE int_customer_address (
    address_key BIGINT PRIMARY KEY,
    customer_key BIGINT,
    address_type VARCHAR(50),
    street_address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    is_primary BOOLEAN,
    
    FOREIGN KEY (customer_key) REFERENCES int_customer_master(customer_key)
);
```

### Data Quality Processing

```sql
-- Cleansing and standardization
CREATE TABLE int_customer_clean AS
SELECT 
    customer_key,
    customer_id,
    -- Standardize names
    INITCAP(TRIM(first_name)) as first_name,
    INITCAP(TRIM(last_name)) as last_name,
    -- Standardize email
    LOWER(TRIM(email)) as email,
    -- Standardize phone
    REGEXP_REPLACE(phone, '[^0-9]', '') as phone_clean,
    -- Data quality indicators
    CASE 
        WHEN first_name IS NOT NULL 
         AND last_name IS NOT NULL 
         AND email IS NOT NULL 
        THEN 100.0
        WHEN first_name IS NOT NULL 
         AND last_name IS NOT NULL 
        THEN 75.0
        ELSE 50.0
    END as completeness_score,
    created_date,
    updated_date
FROM int_customer_master;
```

## 3. Gold Layer

### Purpose
- Optimize for query performance
- Support business intelligence and reporting
- Enable self-service analytics
- Provide business-friendly data models

### Design Patterns

#### Star Schema

**Dimension Tables**:
```sql
-- Date dimension (essential for all warehouses)
CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,  -- YYYYMMDD format
    full_date DATE NOT NULL,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    week_of_year INTEGER,
    day_of_month INTEGER,
    day_of_week INTEGER,
    day_name VARCHAR(20),
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    fiscal_period INTEGER
);

-- Customer dimension (Type 2 SCD)
CREATE TABLE dim_customer (
    customer_key BIGINT PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(200),
    customer_type VARCHAR(50),
    customer_segment VARCHAR(50),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(100),
    
    -- SCD Type 2 columns
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_timestamp TIMESTAMP,
    updated_timestamp TIMESTAMP
);

-- Product dimension
CREATE TABLE dim_product (
    product_key BIGINT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    product_name VARCHAR(200),
    product_category VARCHAR(100),
    product_subcategory VARCHAR(100),
    product_brand VARCHAR(100),
    unit_price DECIMAL(18,2),
    
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    is_current BOOLEAN DEFAULT TRUE
);
```

**Fact Tables**:
```sql
-- Transactional fact table
CREATE TABLE fact_sales (
    sales_key BIGINT PRIMARY KEY,
    
    -- Dimension foreign keys
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    store_key BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    
    -- Degenerate dimensions
    order_number VARCHAR(50),
    line_number INTEGER,
    
    -- Additive measures
    quantity DECIMAL(18,4),
    unit_price DECIMAL(18,2),
    discount_amount DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    total_amount DECIMAL(18,2),
    cost_amount DECIMAL(18,2),
    profit_amount DECIMAL(18,2),
    
    -- Metadata
    created_timestamp TIMESTAMP,
    batch_id VARCHAR(100),
    
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);

-- Periodic snapshot fact table
CREATE TABLE fact_inventory_snapshot (
    inventory_key BIGINT PRIMARY KEY,
    
    product_key BIGINT NOT NULL,
    warehouse_key BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    
    -- Semi-additive measures
    quantity_on_hand DECIMAL(18,4),
    quantity_allocated DECIMAL(18,4),
    quantity_available DECIMAL(18,4),
    reorder_point DECIMAL(18,4),
    
    -- Fully additive measures
    units_received_today DECIMAL(18,4),
    units_shipped_today DECIMAL(18,4),
    
    created_timestamp TIMESTAMP,
    
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (warehouse_key) REFERENCES dim_warehouse(warehouse_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);
```

#### Aggregate Tables

```sql
-- Daily sales summary
CREATE TABLE fact_sales_daily (
    date_key INTEGER,
    customer_key BIGINT,
    product_category VARCHAR(100),
    
    order_count INTEGER,
    total_quantity DECIMAL(18,4),
    total_revenue DECIMAL(18,2),
    total_cost DECIMAL(18,2),
    total_profit DECIMAL(18,2),
    avg_order_value DECIMAL(18,2),
    
    PRIMARY KEY (date_key, customer_key, product_category)
);

-- Monthly sales summary
CREATE TABLE fact_sales_monthly (
    year INTEGER,
    month INTEGER,
    customer_segment VARCHAR(50),
    product_category VARCHAR(100),
    
    customer_count INTEGER,
    order_count INTEGER,
    total_revenue DECIMAL(18,2),
    total_profit DECIMAL(18,2),
    avg_customer_value DECIMAL(18,2),
    
    PRIMARY KEY (year, month, customer_segment, product_category)
);
```

## 4. Access Layer

### Purpose
- Provide secure, optimized data access
- Enable different consumption patterns
- Implement business logic consistency
- Support various analytics tools

### Virtual Views

```sql
-- Business-friendly view
CREATE VIEW vw_customer_sales_summary AS
SELECT 
    c.customer_name,
    c.customer_segment,
    d.year,
    d.quarter,
    d.month_name,
    COUNT(DISTINCT f.order_number) as order_count,
    SUM(f.quantity) as total_quantity,
    SUM(f.total_amount) as total_revenue,
    SUM(f.profit_amount) as total_profit,
    AVG(f.total_amount) as avg_order_value
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
JOIN dim_date d ON f.date_key = d.date_key
WHERE c.is_current = TRUE
GROUP BY 
    c.customer_name,
    c.customer_segment,
    d.year,
    d.quarter,
    d.month_name;
```

### Materialized Views

```sql
-- Materialized view for performance
CREATE MATERIALIZED VIEW mv_product_performance AS
SELECT 
    p.product_category,
    p.product_subcategory,
    p.product_name,
    d.year,
    d.quarter,
    SUM(f.quantity) as units_sold,
    SUM(f.total_amount) as revenue,
    SUM(f.profit_amount) as profit,
    SUM(f.total_amount) / NULLIF(SUM(f.quantity), 0) as avg_selling_price
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY 
    p.product_category,
    p.product_subcategory,
    p.product_name,
    d.year,
    d.quarter;

-- Refresh strategy
REFRESH MATERIALIZED VIEW mv_product_performance;
```

### Secure Views

```sql
-- Row-level security view
CREATE VIEW vw_sales_regional AS
SELECT 
    f.*,
    c.customer_name,
    s.store_region
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
JOIN dim_store s ON f.store_key = s.store_key
WHERE s.store_region IN (
    SELECT authorized_region 
    FROM user_permissions 
    WHERE user_name = CURRENT_USER
);
```

## Layer Interactions

### Data Flow Pattern
```sql
-- Staging → Integration → Presentation flow
-- Step 1: Extract from staging
INSERT INTO int_customer_clean
SELECT 
    ROW_NUMBER() OVER (ORDER BY customer_id) as customer_key,
    customer_id,
    TRIM(first_name) as first_name,
    TRIM(last_name) as last_name,
    LOWER(TRIM(email)) as email
FROM stg_crm_customers_raw
WHERE is_processed = FALSE;

-- Step 2: Update staging status
UPDATE stg_crm_customers_raw
SET is_processed = TRUE
WHERE is_processed = FALSE;

-- Step 3: Load to presentation (SCD Type 2)
-- Expire current records that changed
UPDATE dim_customer
SET effective_end_date = CURRENT_DATE - 1,
    is_current = FALSE
WHERE customer_id IN (
    SELECT customer_id 
    FROM int_customer_clean 
    WHERE record_hash != (
        SELECT record_hash 
        FROM dim_customer 
        WHERE customer_id = int_customer_clean.customer_id 
          AND is_current = TRUE
    )
)
AND is_current = TRUE;

-- Insert new/changed records
INSERT INTO dim_customer
SELECT 
    customer_key,
    customer_id,
    first_name || ' ' || last_name as customer_name,
    CURRENT_DATE as effective_start_date,
    NULL as effective_end_date,
    TRUE as is_current
FROM int_customer_clean;
```

## Best Practices by Layer

### Staging
- Keep data in raw format
- Use flexible data types (VARCHAR)
- Add comprehensive metadata
- Implement data archival strategy
- Enable replay capability

### Integration
- Apply data quality rules
- Maintain referential integrity
- Track data lineage
- Implement master data management
- Use appropriate normalization

### Presentation
- Optimize for query performance
- Use surrogate keys
- Pre-calculate aggregates
- Implement SCD appropriately
- Create semantic models

### Access
- Secure sensitive data
- Optimize view performance
- Consider materialized views
- Implement caching strategies
- Document business logic

## 5. Quarantine Layer

### Purpose
- Isolate invalid records for review and correction
- Prevent bad data from polluting Silver and Gold layers
- Enable data quality reporting and monitoring
- Support data governance and compliance requirements
- Facilitate root cause analysis of data quality issues

### When to Use Quarantine

**Quarantine records when**:
- ❌ **Enumeration validation fails** - Value not in allowed list
- ❌ **Required fields are missing** - NULL in NOT NULL columns
- ❌ **Data type conversion fails** - Invalid format (e.g., "ABC" as BIGINT)
- ❌ **Date ranges are invalid** - Future birthdates, negative durations
- ❌ **Referential integrity violations** - Foreign key doesn't exist
- ❌ **Business rule violations** - Age < 18, negative amounts, etc.
- ❌ **Duplicate keys detected** - Multiple records with same natural key

**Don't quarantine when**:
- ✅ Minor formatting issues that can be corrected (trim whitespace)
- ✅ Case normalization needed (convert to uppercase)
- ✅ Type 1 attribute changes (non-versioned fields)
- ✅ Optional fields are NULL

### Schema Design

```sql
-- Quarantine table template
CREATE TABLE quarantine.<entity>_rejected (
    -- Original record (all columns from Bronze source)
    -- ... mirror all source columns here ...
    
    -- Quarantine metadata
    rejection_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rejection_reason TEXT NOT NULL,
    rejection_rule VARCHAR(100),
    rejection_severity VARCHAR(20),  -- CRITICAL, ERROR, WARNING
    
    -- Source tracking
    source_batch_id BIGINT,
    source_load_ts TIMESTAMP,
    
    -- Reprocessing workflow
    is_reprocessed BOOLEAN DEFAULT FALSE,
    reprocessed_ts TIMESTAMP,
    reprocessed_by VARCHAR(100),
    reprocessing_notes TEXT,
    
    -- Primary Key (original key + rejection timestamp for uniqueness)
    CONSTRAINT pk_quarantine_<entity> 
        PRIMARY KEY ({natural_key}, rejection_ts)
);

-- Indexes for querying
CREATE INDEX idx_quarantine_<entity>_ts 
    ON quarantine.<entity>_rejected(rejection_ts);

CREATE INDEX idx_quarantine_<entity>_rule 
    ON quarantine.<entity>_rejected(rejection_rule);

CREATE INDEX idx_quarantine_<entity>_reprocessed 
    ON quarantine.<entity>_rejected(is_reprocessed);
```

### Rejection Reason Examples

**Format**: `{rule_name}: {specific_issue}`

```sql
-- Enumeration validation
rejection_reason: "INVALID_ENUMERATION: marital_status='INVALID' not in [SINGLE, MARRIED, DIVORCED, WIDOWED, SEPARATED, UNKNOWN]"

-- Required field missing
rejection_reason: "MISSING_REQUIRED_FIELD: firstname is NULL"

-- Data type conversion
rejection_reason: "TYPE_CONVERSION_FAILED: customer_id='ABC123' cannot convert to BIGINT"

-- Date validation
rejection_reason: "INVALID_DATE_RANGE: birthdate=2030-01-01 is in future"

-- Business rule
rejection_reason: "BUSINESS_RULE_VIOLATION: age=15 is below minimum age 18"

-- Multiple issues
rejection_reason: "MULTIPLE_ISSUES: [INVALID_ENUMERATION: person_title, MISSING_REQUIRED_FIELD: lastname]"
```

### dbt Quarantine Model Pattern

```sql
-- File: dbt/models/quarantine/<entity>_rejected.sql
{{
    config(
        materialized='incremental',
        unique_key=['customer_id', 'rejection_ts'],
        on_schema_change='fail',
        schema='quarantine'
    )
}}

WITH source_data AS (
    SELECT *
    FROM {{ ref('silver_<entity>_standardized') }}
    {% if is_incremental() %}
    WHERE _silver_load_ts > (SELECT MAX(rejection_ts) FROM {{ this }})
    {% endif %}
),

failed_validations AS (
    SELECT 
        *,
        -- Build rejection reasons array
        ARRAY_CAT(
            CASE WHEN NOT dq_person_title_valid 
                THEN ARRAY['INVALID_ENUMERATION: person_title'] 
                ELSE ARRAY[]::TEXT[] END,
            CASE WHEN NOT dq_marital_status_valid 
                THEN ARRAY['INVALID_ENUMERATION: marital_status'] 
                ELSE ARRAY[]::TEXT[] END
            -- ... more validation checks ...
        ) AS rejection_reasons_array,
        
        -- Determine rejection severity
        CASE 
            WHEN dq_score < 50 THEN 'CRITICAL'
            WHEN dq_score < 75 THEN 'ERROR'
            ELSE 'WARNING'
        END AS rejection_severity
        
    FROM source_data
    WHERE dq_status IN ('INVALID', 'WARNING')  -- Only quarantine invalid records
),

final AS (
    SELECT 
        -- Original columns (all from source)
        customer_id,
        evidence_unique_key,
        firstname,
        lastname,
        -- ... all source columns ...
        
        -- Quarantine metadata
        CURRENT_TIMESTAMP AS rejection_ts,
        array_to_string(rejection_reasons_array, '; ') AS rejection_reason,
        CASE 
            WHEN array_length(rejection_reasons_array, 1) > 1 
            THEN 'MULTIPLE_ISSUES'
            ELSE rejection_reasons_array[1]
        END AS rejection_rule,
        rejection_severity,
        
        -- Source tracking
        _bronze_batch_id AS source_batch_id,
        _bronze_load_ts AS source_load_ts,
        
        -- Reprocessing flags
        FALSE AS is_reprocessed,
        NULL::TIMESTAMP AS reprocessed_ts,
        NULL::VARCHAR AS reprocessed_by,
        NULL::TEXT AS reprocessing_notes
        
    FROM failed_validations
)

SELECT * FROM final
```

### Reprocessing Workflow

**Step 1: Identify Issues**
```sql
-- Query quarantine to find common issues
SELECT 
    rejection_rule,
    rejection_severity,
    COUNT(*) AS record_count
FROM quarantine.customer_profile_rejected
WHERE NOT is_reprocessed
GROUP BY rejection_rule, rejection_severity
ORDER BY record_count DESC;
```

**Step 2: Correct Source Data**
- Fix data in operational system (preferred)
- OR update Bronze records if one-time correction
- OR update validation rules if rule was wrong

**Step 3: Mark as Reprocessed**
```sql
-- After fixing source data, mark records for reprocessing
UPDATE quarantine.customer_profile_rejected
SET is_reprocessed = TRUE,
    reprocessed_ts = CURRENT_TIMESTAMP,
    reprocessed_by = CURRENT_USER,
    reprocessing_notes = 'Fixed enumeration mapping in source system'
WHERE rejection_rule = 'INVALID_ENUMERATION: person_title'
  AND NOT is_reprocessed;
```

**Step 4: Re-run ETL**
```bash
# Re-run Bronze → Silver → Gold pipeline
dbt run --models customer_profile

# Verify records moved from quarantine to Silver
SELECT COUNT(*) FROM silver.customer_profile_standardized 
WHERE customer_id IN (
    SELECT customer_id 
    FROM quarantine.customer_profile_rejected 
    WHERE is_reprocessed = TRUE
);
```

### Monitoring & Alerting

**Key Metrics to Monitor**:
1. **Quarantine Rate**: % of records going to quarantine
2. **Rejection Reasons Distribution**: Most common issues
3. **Reprocessing Time**: How long issues stay in quarantine
4. **Severity Distribution**: Critical vs Error vs Warning

**Alert Thresholds**:
```sql
-- Alert if quarantine rate exceeds 5%
SELECT 
    (COUNT(*) FILTER (WHERE in_quarantine))::FLOAT / COUNT(*) * 100 AS quarantine_rate
FROM (
    SELECT TRUE AS in_quarantine FROM quarantine.customer_profile_rejected 
        WHERE rejection_ts > CURRENT_DATE
    UNION ALL
    SELECT FALSE FROM silver.customer_profile_standardized 
        WHERE _silver_load_ts > CURRENT_DATE
) t;
-- Alert if > 5.0

-- Alert if critical issues present
SELECT COUNT(*) 
FROM quarantine.customer_profile_rejected
WHERE rejection_severity = 'CRITICAL'
  AND NOT is_reprocessed;
-- Alert if > 0
```

### Retention Policy

**Recommendations**:
- **Unresolved Issues**: Keep until resolved + 30 days
- **Resolved Issues**: Keep 90 days after resolution for audit
- **Archive**: Move to cold storage after 1 year
- **Delete**: After regulatory retention period (typically 7 years)

```sql
-- Archive old resolved records
INSERT INTO quarantine_archive.customer_profile_rejected_archive
SELECT * FROM quarantine.customer_profile_rejected
WHERE is_reprocessed = TRUE
  AND reprocessed_ts < CURRENT_DATE - INTERVAL '90 days';

DELETE FROM quarantine.customer_profile_rejected
WHERE is_reprocessed = TRUE
  AND reprocessed_ts < CURRENT_DATE - INTERVAL '90 days';
```

### Best Practices

✅ **DO**:
- Quarantine at the Silver layer (after validation)
- Provide detailed rejection reasons
- Track all reprocessing activities
- Monitor quarantine rates
- Set up alerts for critical issues
- Document common issues and resolutions

❌ **DON'T**:
- Let records sit in quarantine indefinitely
- Delete quarantine records without archiving
- Quarantine records with minor fixable issues
- Ignore patterns in rejection reasons
- Skip root cause analysis

### Quarantine vs Silver Split Pattern

```
┌─────────────────┐
│  Bronze Layer   │
│  (Raw Data)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Silver Process  │
│ (Validation)    │
└────┬───────┬────┘
     │       │
     ▼       ▼
┌────────┐ ┌──────────┐
│ Silver │ │Quarantine│
│ (Valid)│ │(Invalid) │
└────┬───┘ └────┬─────┘
     │          │
     ▼          ▼
┌────────┐ ┌──────────┐
│  Gold  │ │ Review & │
│ (Star) │ │Reprocess │
└────────┘ └──────────┘
```

---

## Next Steps
1. Review architecture overview in `/docs/architecture/`
2. Explore data modeling in `/docs/data-modeling/`
3. Check ETL patterns in `/docs/etl-elt/`
4. Use templates from `/templates/` for layer implementations
5. Review quarantine template in `/templates/` (if exists)
6. See module replication guide: `/docs/HOW_TO_REPLICATE_MODULE.md`

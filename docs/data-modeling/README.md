# Data Modeling Standards and Guidelines

## Overview
This document provides comprehensive guidelines for data modeling in the data warehouse, ensuring consistency, scalability, and maintainability.

## Data Modeling Approaches

### 1. Dimensional Modeling (Kimball)

**When to Use**:
- User-facing analytics and reporting
- Business intelligence applications
- Query performance is critical
- User-friendly data access required

**Key Concepts**:
- **Fact Tables**: Contain measurable business events
- **Dimension Tables**: Provide context for facts
- **Star Schema**: Facts surrounded by dimensions
- **Snowflake Schema**: Normalized dimension tables

**Design Principles**:
- Business process orientation
- Grain definition (most atomic level)
- Conformed dimensions
- Slowly Changing Dimensions (SCD)

### 2. Data Vault (Linstedt)

**When to Use**:
- Long-term historical tracking
- Audit and compliance requirements
- Complex source integrations
- Agile data warehouse development

**Core Entities**:
- **Hubs**: Unique business keys
- **Links**: Relationships between hubs
- **Satellites**: Descriptive attributes and history

**Benefits**:
- Auditability and traceability
- Flexibility for change
- Parallel loading capability
- Historical accuracy

### 3. Hybrid Approaches

**Combination Strategies**:
- Data Vault for integration layer
- Dimensional models for presentation layer
- Denormalized views for performance
- Virtual data marts using views

## Naming Conventions

### Tables

```
Pattern: <layer>_<subject_area>_<entity>_<type>

Examples:
- stg_sales_orders_raw          (Staging layer)
- int_customer_master_clean     (Integration layer)
- dim_customer                  (Dimension table)
- fact_sales_daily             (Fact table)
- hub_customer                 (Data Vault hub)
- sat_customer_details         (Data Vault satellite)
```

### Columns

```
Pattern: <entity>_<attribute>_<modifier>

Examples:
- customer_id                  (Primary key)
- customer_first_name          (Attribute)
- order_total_amount           (Measure)
- effective_start_date         (SCD attribute)
- is_active_flag              (Boolean flag)
- created_timestamp           (Audit column)
```

### Keys and Constraints

```
Primary Keys:      <table>_pk
Foreign Keys:      <table>_<reference>_fk
Unique Constraints: <table>_<column>_uk
Indexes:           <table>_<column>_idx
```

## Standard Table Structures

### Dimension Table Template

```sql
CREATE TABLE dim_customer (
    -- Surrogate Key
    customer_key BIGINT PRIMARY KEY,
    
    -- Natural Key
    customer_id VARCHAR(50) NOT NULL,
    
    -- Attributes
    customer_first_name VARCHAR(100),
    customer_last_name VARCHAR(100),
    customer_email VARCHAR(255),
    customer_phone VARCHAR(20),
    customer_type VARCHAR(50),
    customer_segment VARCHAR(50),
    
    -- Address Information
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    
    -- SCD Type 2 Attributes
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    
    -- Audit Columns
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    source_system VARCHAR(50),
    
    -- Data Quality
    data_quality_score DECIMAL(5,2),
    is_complete BOOLEAN
);
```

### Fact Table Template

```sql
CREATE TABLE fact_sales (
    -- Surrogate Key
    sales_key BIGINT PRIMARY KEY,
    
    -- Foreign Keys (Dimension References)
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    store_key BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    time_key INTEGER NOT NULL,
    
    -- Degenerate Dimensions
    order_number VARCHAR(50),
    invoice_number VARCHAR(50),
    
    -- Measures (Additive)
    quantity_sold DECIMAL(18,4),
    unit_price DECIMAL(18,2),
    discount_amount DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    total_amount DECIMAL(18,2),
    cost_amount DECIMAL(18,2),
    profit_amount DECIMAL(18,2),
    
    -- Measures (Semi-Additive)
    inventory_level DECIMAL(18,4),
    account_balance DECIMAL(18,2),
    
    -- Audit Columns
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(50),
    batch_id VARCHAR(100),
    
    -- Foreign Key Constraints
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);
```

## Slowly Changing Dimensions (SCD)

### Type 0: Retain Original
No changes allowed; original values preserved.

### Type 1: Overwrite
```sql
UPDATE dim_customer 
SET customer_email = 'new.email@example.com',
    updated_timestamp = CURRENT_TIMESTAMP
WHERE customer_id = '12345';
```

### Type 2: Add New Row (Most Common)
```sql
-- Expire current record
UPDATE dim_customer 
SET effective_end_date = CURRENT_DATE - INTERVAL '1 day',
    is_current = FALSE
WHERE customer_id = '12345' AND is_current = TRUE;

-- Insert new record
INSERT INTO dim_customer (
    customer_id, customer_email, 
    effective_start_date, effective_end_date, is_current
) VALUES (
    '12345', 'new.email@example.com',
    CURRENT_DATE, NULL, TRUE
);
```

### Type 3: Add New Column
```sql
ALTER TABLE dim_customer 
ADD COLUMN previous_email VARCHAR(255),
ADD COLUMN email_change_date DATE;

UPDATE dim_customer 
SET previous_email = customer_email,
    customer_email = 'new.email@example.com',
    email_change_date = CURRENT_DATE
WHERE customer_id = '12345';
```

### Type 6: Hybrid (1+2+3)
Combines Type 1, 2, and 3 approaches for different attributes.

## AI-Assisted Data Modeling

### Automated Model Generation
- **Schema Inference**: AI analyzes source data to suggest models
- **Relationship Discovery**: ML identifies foreign key relationships
- **Dimension Detection**: Automatic classification of dimensions vs facts
- **Normalization Suggestions**: AI recommends optimal normalization level

### Intelligent Naming
- **Naming Consistency**: AI ensures consistent naming across models
- **Business Term Mapping**: ML maps technical to business terms
- **Synonym Detection**: Identifies and standardizes synonyms

### Model Optimization
- **Performance Prediction**: AI predicts query performance
- **Partitioning Recommendations**: Suggests optimal partitioning strategies
- **Index Suggestions**: Recommends indexes based on query patterns
- **Denormalization Opportunities**: Identifies when to denormalize

## Data Types and Standards

### Numeric Types
```
Integer:     INT, BIGINT
Decimal:     DECIMAL(p,s) for money and precise calculations
Float:       FLOAT, DOUBLE for scientific calculations
```

### String Types
```
Fixed:       CHAR(n) for codes
Variable:    VARCHAR(n) for names, descriptions
Text:        TEXT for large text fields
```

### Date/Time Types
```
Date:        DATE for calendar dates
Time:        TIME for time of day
Timestamp:   TIMESTAMP for point in time
Interval:    INTERVAL for duration
```

### Boolean Types
```
Boolean:     BOOLEAN or BIT
Flags:       Use meaningful names (is_active, has_discount)
```

## Data Quality Standards

### Mandatory Audit Columns
Every table should include:
- `created_timestamp`: Record creation time
- `updated_timestamp`: Last update time
- `created_by`: User/process that created record
- `updated_by`: User/process that last updated
- `source_system`: Origin system identifier
- `batch_id`: ETL batch identifier

### Data Quality Indicators
```sql
data_quality_score DECIMAL(5,2)  -- 0-100 quality score
is_complete BOOLEAN               -- All required fields populated
is_valid BOOLEAN                  -- Passes validation rules
validation_errors TEXT            -- JSON array of validation issues
```

## Metadata Documentation

### Table Documentation
Each table should have:
- Business purpose and description
- Data grain and level of detail
- Update frequency
- Data retention policy
- Ownership and stewardship
- Related tables and dependencies

### Column Documentation
Each column should document:
- Business definition
- Data type and format
- Valid values or ranges
- Nullable or required
- Default values
- Derivation logic (for calculated fields)

## Best Practices

1. **Use Surrogate Keys**: Auto-generated integer keys for dimensions
2. **Natural Keys**: Preserve original business keys
3. **Consistent Granularity**: Match fact and dimension grain
4. **Conformed Dimensions**: Share dimensions across fact tables
5. **Avoid Nulls in Keys**: Use special values for unknown/not applicable
6. **Date Dimension**: Always use a complete date dimension
7. **Bridge Tables**: Handle many-to-many relationships
8. **Junk Dimensions**: Combine low-cardinality flags
9. **Role-Playing Dimensions**: Reuse dimensions in different contexts
10. **Aggregate Tables**: Pre-calculate common aggregations

## Version Control

- Store all DDL scripts in version control
- Use migration tools (Flyway, Liquibase) for schema changes
- Document breaking changes
- Maintain schema version numbers
- Tag releases with version numbers

## Next Steps
1. Review specific layer documentation in `/docs/layers/`
2. Explore ETL patterns in `/docs/etl-elt/`
3. Implement governance standards from `/docs/governance/`
4. Use templates from `/templates/` for new models

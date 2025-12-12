# Retail Sales Data Warehouse Example

## Overview
This example demonstrates a complete retail sales data warehouse implementation using dimensional modeling (star schema). It's designed as a learning resource for understanding core data warehouse concepts.

## Business Context

### Business Questions
This data warehouse answers questions like:
- What are our daily/monthly/yearly sales trends?
- Which products are top performers?
- Who are our most valuable customers?
- What's the average order value by customer segment?
- How does sales performance vary by store location?
- What's the profit margin by product category?

## Data Model

### Dimensional Model (Star Schema)

```
                    ┌──────────────┐
                    │  dim_date    │
                    └──────┬───────┘
                           │
    ┌──────────────┐       │       ┌──────────────┐
    │ dim_customer │───────┼───────│ dim_product  │
    └──────────────┘       │       └──────────────┘
                           │
                    ┌──────▼───────┐
                    │  fact_sales  │
                    └──────┬───────┘
                           │
    ┌──────────────┐       │       ┌──────────────┐
    │  dim_store   │───────┴───────│  dim_time    │
    └──────────────┘               └──────────────┘
```

### Dimensions

#### dim_date
- **Grain**: One row per day
- **Attributes**: Year, quarter, month, week, day of week, is_holiday
- **SCD Type**: Type 0 (no changes)
- **Rows**: ~10 years = 3,650 rows

#### dim_customer
- **Grain**: One row per customer version
- **Attributes**: Name, type, segment, contact info, location
- **SCD Type**: Type 2 (track history)
- **Estimated Rows**: 100,000 customers × 1.5 versions = 150,000 rows

#### dim_product
- **Grain**: One row per product version
- **Attributes**: Name, category, subcategory, brand, price
- **SCD Type**: Type 2 (track price changes)
- **Estimated Rows**: 10,000 products × 2 versions = 20,000 rows

#### dim_store
- **Grain**: One row per store
- **Attributes**: Name, type, location, size, opening date
- **SCD Type**: Type 1 (overwrite)
- **Estimated Rows**: 500 stores

#### dim_time
- **Grain**: One row per minute
- **Attributes**: Hour, minute, period (AM/PM), business hours flag
- **SCD Type**: Type 0 (no changes)
- **Rows**: 1,440 minutes per day

### Facts

#### fact_sales
- **Grain**: One row per order line item
- **Measures**: Quantity, amount, discount, tax, profit
- **Estimated Rows**: 50M transactions per year
- **Partitioning**: By date (monthly partitions)

## Sample Schema

### Dimension Tables

```sql
-- Date Dimension
CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    day_of_month INTEGER,
    day_of_week INTEGER,
    day_name VARCHAR(20),
    is_weekend BOOLEAN,
    is_holiday BOOLEAN
);

-- Customer Dimension
CREATE TABLE dim_customer (
    customer_key BIGINT PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(200),
    customer_type VARCHAR(50),
    customer_segment VARCHAR(50),
    email VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(100),
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    is_current BOOLEAN
);

-- Product Dimension
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
    is_current BOOLEAN
);

-- Store Dimension
CREATE TABLE dim_store (
    store_key BIGINT PRIMARY KEY,
    store_id VARCHAR(50) NOT NULL,
    store_name VARCHAR(200),
    store_type VARCHAR(50),
    city VARCHAR(100),
    state VARCHAR(50),
    region VARCHAR(50)
);
```

### Fact Table

```sql
-- Sales Fact
CREATE TABLE fact_sales (
    sales_key BIGINT PRIMARY KEY,
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    store_key BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    
    order_number VARCHAR(50),
    line_number INTEGER,
    
    quantity DECIMAL(18,4),
    unit_price DECIMAL(18,2),
    discount_amount DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    total_amount DECIMAL(18,2),
    cost_amount DECIMAL(18,2),
    profit_amount DECIMAL(18,2),
    
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (store_key) REFERENCES dim_store(store_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);
```

## Sample Analytical Queries

### Sales Performance Analysis

```sql
-- Monthly sales trend
SELECT 
    d.year,
    d.month_name,
    COUNT(DISTINCT f.order_number) as order_count,
    SUM(f.quantity) as total_units,
    SUM(f.total_amount) as total_revenue,
    SUM(f.profit_amount) as total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.total_amount) * 100, 2) as profit_margin_pct
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- Top 10 customers by revenue
SELECT 
    c.customer_name,
    c.customer_segment,
    COUNT(DISTINCT f.order_number) as order_count,
    SUM(f.total_amount) as total_revenue,
    AVG(f.total_amount) as avg_order_value
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.is_current = TRUE
GROUP BY c.customer_name, c.customer_segment
ORDER BY total_revenue DESC
LIMIT 10;

-- Product category performance
SELECT 
    p.product_category,
    p.product_subcategory,
    SUM(f.quantity) as units_sold,
    SUM(f.total_amount) as revenue,
    SUM(f.profit_amount) as profit,
    ROUND(AVG(f.profit_amount / NULLIF(f.total_amount, 0)) * 100, 2) as avg_margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
WHERE p.is_current = TRUE
GROUP BY p.product_category, p.product_subcategory
ORDER BY revenue DESC;

-- Store performance comparison
SELECT 
    s.store_name,
    s.region,
    s.store_type,
    COUNT(DISTINCT f.customer_key) as unique_customers,
    SUM(f.total_amount) as total_revenue,
    SUM(f.total_amount) / COUNT(DISTINCT f.order_number) as avg_transaction_value
FROM fact_sales f
JOIN dim_store s ON f.store_key = s.store_key
GROUP BY s.store_name, s.region, s.store_type
ORDER BY total_revenue DESC;

-- Weekend vs Weekday sales
SELECT 
    CASE WHEN d.is_weekend THEN 'Weekend' ELSE 'Weekday' END as day_type,
    COUNT(*) as transaction_count,
    SUM(f.total_amount) as total_revenue,
    AVG(f.total_amount) as avg_transaction
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY CASE WHEN d.is_weekend THEN 'Weekend' ELSE 'Weekday' END;
```

## ETL Process Flow

### 1. Staging Layer
```
Source Systems → Extract → Staging Tables (Raw Data)
```

### 2. Integration Layer
```
Staging → Cleanse/Validate → Integration Tables (Clean Data)
```

### 3. Presentation Layer
```
Integration → Transform → Dimensions & Facts (Star Schema)
```

## Data Quality Checks

```sql
-- Check for orphaned records in fact table
SELECT 'Orphaned Customers' as check_name, COUNT(*) as error_count
FROM fact_sales f
LEFT JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL

UNION ALL

SELECT 'Orphaned Products', COUNT(*)
FROM fact_sales f
LEFT JOIN dim_product p ON f.product_key = p.product_key
WHERE p.product_key IS NULL

UNION ALL

-- Check for negative amounts
SELECT 'Negative Quantities', COUNT(*)
FROM fact_sales
WHERE quantity < 0

UNION ALL

SELECT 'Negative Amounts', COUNT(*)
FROM fact_sales
WHERE total_amount < 0;
```

## Performance Optimization

### Recommended Indexes
```sql
CREATE INDEX idx_sales_date ON fact_sales(date_key);
CREATE INDEX idx_sales_customer ON fact_sales(customer_key);
CREATE INDEX idx_sales_product ON fact_sales(product_key);
CREATE INDEX idx_sales_store ON fact_sales(store_key);
CREATE INDEX idx_sales_order ON fact_sales(order_number);
```

### Aggregate Tables
```sql
-- Daily sales summary for faster reporting
CREATE TABLE fact_sales_daily AS
SELECT 
    date_key,
    product_key,
    store_key,
    COUNT(*) as transaction_count,
    SUM(quantity) as total_quantity,
    SUM(total_amount) as total_revenue,
    SUM(profit_amount) as total_profit
FROM fact_sales
GROUP BY date_key, product_key, store_key;
```

## Implementation Checklist

- [ ] Create dimension tables
- [ ] Create fact tables
- [ ] Populate date dimension
- [ ] Load customer dimension (with SCD Type 2)
- [ ] Load product dimension (with SCD Type 2)
- [ ] Load store dimension
- [ ] Load historical sales data
- [ ] Create indexes for performance
- [ ] Create aggregate tables
- [ ] Implement data quality checks
- [ ] Set up ETL scheduling
- [ ] Create analytical views
- [ ] Document data lineage
- [ ] Set up monitoring and alerts

## Next Steps
1. Review the detailed schema files in `schema/` directory
2. Explore ETL scripts in `etl/` directory
3. Execute sample queries in `queries/` directory
4. Study data quality checks in `quality/` directory

-- ==================================================================
-- FACT TABLE TEMPLATE
-- ==================================================================
-- Purpose: Standard fact table for transactional or event data
-- Usage: Replace <PLACEHOLDERS> with actual values
-- ==================================================================

CREATE TABLE fact_<FACT_NAME> (
    -- Surrogate Key (Optional for fact tables)
    <fact>_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Foreign Keys to Dimensions
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    store_key BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    time_key INTEGER,
    
    -- Additional dimension foreign keys
    <dimension1>_key BIGINT,
    <dimension2>_key BIGINT,
    <dimension3>_key BIGINT,
    
    -- Degenerate Dimensions (high cardinality attributes)
    transaction_number VARCHAR(50),
    order_number VARCHAR(50),
    invoice_number VARCHAR(50),
    reference_number VARCHAR(50),
    
    -- Additive Measures (can be summed across all dimensions)
    quantity DECIMAL(18,4) DEFAULT 0,
    unit_price DECIMAL(18,2),
    gross_amount DECIMAL(18,2),
    discount_amount DECIMAL(18,2) DEFAULT 0,
    tax_amount DECIMAL(18,2) DEFAULT 0,
    shipping_amount DECIMAL(18,2) DEFAULT 0,
    net_amount DECIMAL(18,2),
    cost_amount DECIMAL(18,2),
    profit_amount DECIMAL(18,2),
    
    -- Semi-Additive Measures (sum across some dimensions, not time)
    balance_amount DECIMAL(18,2),
    inventory_quantity DECIMAL(18,4),
    
    -- Non-Additive Measures (cannot be summed)
    unit_cost DECIMAL(18,2),
    profit_margin_percent DECIMAL(5,2),
    discount_percent DECIMAL(5,2),
    
    -- Derived/Calculated Measures
    -- revenue_per_unit = net_amount / NULLIF(quantity, 0)
    -- markup_percent = (unit_price - unit_cost) / NULLIF(unit_cost, 0) * 100
    
    -- Status/Flag Attributes
    is_returned BOOLEAN DEFAULT FALSE,
    is_cancelled BOOLEAN DEFAULT FALSE,
    is_modified BOOLEAN DEFAULT FALSE,
    payment_status VARCHAR(50),
    fulfillment_status VARCHAR(50),
    
    -- Audit Columns
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT CURRENT_USER,
    source_system VARCHAR(50) NOT NULL,
    batch_id VARCHAR(100),
    etl_insert_date DATE DEFAULT CURRENT_DATE,
    
    -- Data Quality
    data_quality_score DECIMAL(5,2),
    validation_status VARCHAR(50),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_<fact>_customer 
        FOREIGN KEY (customer_key) 
        REFERENCES dim_customer(customer_key),
        
    CONSTRAINT fk_<fact>_product 
        FOREIGN KEY (product_key) 
        REFERENCES dim_product(product_key),
        
    CONSTRAINT fk_<fact>_store 
        FOREIGN KEY (store_key) 
        REFERENCES dim_store(store_key),
        
    CONSTRAINT fk_<fact>_date 
        FOREIGN KEY (date_key) 
        REFERENCES dim_date(date_key),
    
    -- Business Rule Constraints
    CHECK (quantity >= 0),
    CHECK (unit_price >= 0),
    CHECK (gross_amount >= 0),
    CHECK (net_amount = gross_amount - discount_amount + tax_amount)
);

-- Indexes for Performance
CREATE INDEX idx_fact_<fact>_customer ON fact_<FACT_NAME>(customer_key);
CREATE INDEX idx_fact_<fact>_product ON fact_<FACT_NAME>(product_key);
CREATE INDEX idx_fact_<fact>_store ON fact_<FACT_NAME>(store_key);
CREATE INDEX idx_fact_<fact>_date ON fact_<FACT_NAME>(date_key);
CREATE INDEX idx_fact_<fact>_transaction ON fact_<FACT_NAME>(transaction_number);

-- Composite indexes for common queries
CREATE INDEX idx_fact_<fact>_date_customer ON fact_<FACT_NAME>(date_key, customer_key);
CREATE INDEX idx_fact_<fact>_date_product ON fact_<FACT_NAME>(date_key, product_key);

-- Partitioning (PostgreSQL example - by date range)
-- ALTER TABLE fact_<FACT_NAME> PARTITION BY RANGE (date_key);
-- CREATE TABLE fact_<FACT_NAME>_2024_q1 PARTITION OF fact_<FACT_NAME>
--     FOR VALUES FROM (20240101) TO (20240401);

-- Comments for Documentation
COMMENT ON TABLE fact_<FACT_NAME> IS 'Fact table for <fact description>. Grain: One row per <transaction/event>.';
COMMENT ON COLUMN fact_<FACT_NAME>.<fact>_key IS 'Surrogate key for the fact record';
COMMENT ON COLUMN fact_<FACT_NAME>.quantity IS 'Number of units (additive measure)';
COMMENT ON COLUMN fact_<FACT_NAME>.net_amount IS 'Net transaction amount after discounts and taxes (additive)';
COMMENT ON COLUMN fact_<FACT_NAME>.date_key IS 'Foreign key to date dimension (format: YYYYMMDD)';

-- ==================================================================
-- AGGREGATE FACT TABLE (Optional)
-- ==================================================================
-- Pre-aggregated fact for common queries

CREATE TABLE fact_<FACT_NAME>_daily (
    date_key INTEGER NOT NULL,
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    
    -- Aggregated Measures
    transaction_count INTEGER,
    total_quantity DECIMAL(18,4),
    total_gross_amount DECIMAL(18,2),
    total_net_amount DECIMAL(18,2),
    total_profit_amount DECIMAL(18,2),
    avg_unit_price DECIMAL(18,2),
    avg_discount_percent DECIMAL(5,2),
    
    -- Audit
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    batch_id VARCHAR(100),
    
    PRIMARY KEY (date_key, customer_key, product_key),
    
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key)
);

-- ==================================================================
-- EXAMPLE USAGE
-- ==================================================================

-- Example: Sales Fact Table
/*
CREATE TABLE fact_sales (
    sales_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(50),
    
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);
*/

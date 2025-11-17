-- ==================================================================
-- DIMENSION TABLE TEMPLATE
-- ==================================================================
-- Purpose: Standard dimension table with SCD Type 2 support
-- Usage: Replace <PLACEHOLDERS> with actual values
-- ==================================================================

CREATE TABLE dim_<ENTITY_NAME> (
    -- Surrogate Key (Auto-generated)
    <entity>_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    
    -- Natural/Business Key
    <entity>_id VARCHAR(50) NOT NULL,
    
    -- Descriptive Attributes
    <entity>_name VARCHAR(200),
    <entity>_description TEXT,
    <entity>_type VARCHAR(50),
    <entity>_category VARCHAR(100),
    <entity>_status VARCHAR(50),
    
    -- Additional Attributes (customize as needed)
    attribute1 VARCHAR(255),
    attribute2 VARCHAR(255),
    attribute3 DECIMAL(18,2),
    attribute4 DATE,
    
    -- Hierarchical Attributes (optional)
    parent_<entity>_key BIGINT,
    hierarchy_level INTEGER,
    
    -- Geographic Attributes (optional)
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(100),
    region VARCHAR(100),
    
    -- Contact Information (optional)
    email VARCHAR(255),
    phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    postal_code VARCHAR(20),
    
    -- SCD Type 2 Attributes
    effective_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_end_date DATE DEFAULT '9999-12-31',
    is_current BOOLEAN DEFAULT TRUE,
    version_number INTEGER DEFAULT 1,
    
    -- Audit Columns
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT CURRENT_USER,
    updated_by VARCHAR(100) DEFAULT CURRENT_USER,
    source_system VARCHAR(50) NOT NULL,
    batch_id VARCHAR(100),
    
    -- Data Quality Indicators
    data_quality_score DECIMAL(5,2) CHECK (data_quality_score BETWEEN 0 AND 100),
    is_complete BOOLEAN,
    is_validated BOOLEAN DEFAULT FALSE,
    validation_errors TEXT,  -- JSON format
    
    -- Business Metadata
    record_hash CHAR(32),  -- MD5 hash for change detection
    
    -- Constraints
    UNIQUE (<entity>_id, effective_start_date),
    CHECK (effective_start_date <= effective_end_date),
    CHECK (is_current IN (TRUE, FALSE))
);

-- Indexes for Performance
CREATE INDEX idx_dim_<entity>_natural_key ON dim_<ENTITY_NAME>(<entity>_id);
CREATE INDEX idx_dim_<entity>_current ON dim_<ENTITY_NAME>(is_current) WHERE is_current = TRUE;
CREATE INDEX idx_dim_<entity>_dates ON dim_<ENTITY_NAME>(effective_start_date, effective_end_date);
CREATE INDEX idx_dim_<entity>_type ON dim_<ENTITY_NAME>(<entity>_type);

-- Comments for Documentation
COMMENT ON TABLE dim_<ENTITY_NAME> IS 'Dimension table for <entity description>. Implements SCD Type 2 for historical tracking.';
COMMENT ON COLUMN dim_<ENTITY_NAME>.<entity>_key IS 'Surrogate key - unique identifier for each version of the entity';
COMMENT ON COLUMN dim_<ENTITY_NAME>.<entity>_id IS 'Natural/Business key from source system';
COMMENT ON COLUMN dim_<ENTITY_NAME>.effective_start_date IS 'Date when this version became effective';
COMMENT ON COLUMN dim_<ENTITY_NAME>.effective_end_date IS 'Date when this version was superseded (9999-12-31 for current)';
COMMENT ON COLUMN dim_<ENTITY_NAME>.is_current IS 'Flag indicating if this is the current version';

-- ==================================================================
-- EXAMPLE USAGE
-- ==================================================================

-- Example: Customer Dimension
/*
CREATE TABLE dim_customer (
    customer_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(200),
    customer_type VARCHAR(50),
    customer_segment VARCHAR(100),
    customer_status VARCHAR(50),
    email VARCHAR(255),
    phone VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(100),
    effective_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_end_date DATE DEFAULT '9999-12-31',
    is_current BOOLEAN DEFAULT TRUE,
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_system VARCHAR(50) NOT NULL,
    data_quality_score DECIMAL(5,2)
);
*/

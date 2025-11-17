# Metadata Management

## Overview
Metadata management is critical for understanding, governing, and effectively utilizing data warehouse assets. This document outlines the framework for managing technical, business, and operational metadata.

## Types of Metadata

### 1. Technical Metadata
**Definition**: Information about the technical aspects of data structures and systems

**Components**:
- Database schemas and table structures
- Column names, data types, and constraints
- Indexes and partitions
- ETL job configurations
- System architecture diagrams

**Example**:
```sql
-- Technical metadata catalog
CREATE TABLE metadata.technical_catalog (
    catalog_id BIGINT PRIMARY KEY,
    object_type VARCHAR(50),  -- TABLE, VIEW, COLUMN, INDEX
    schema_name VARCHAR(100),
    object_name VARCHAR(255),
    parent_object VARCHAR(255),
    data_type VARCHAR(50),
    is_nullable BOOLEAN,
    default_value VARCHAR(500),
    constraint_type VARCHAR(50),
    created_date TIMESTAMP,
    modified_date TIMESTAMP,
    created_by VARCHAR(100)
);
```

### 2. Business Metadata
**Definition**: Information about the business context and meaning of data

**Components**:
- Business names and definitions
- Business rules and calculations
- Data ownership and stewardship
- Subject area classifications
- Business glossary terms

**Example**:
```sql
-- Business metadata catalog
CREATE TABLE metadata.business_catalog (
    business_id BIGINT PRIMARY KEY,
    technical_object_id BIGINT,
    business_name VARCHAR(255),
    business_definition TEXT,
    business_rules TEXT,
    subject_area VARCHAR(100),
    data_owner VARCHAR(100),
    data_steward VARCHAR(100),
    sensitivity_classification VARCHAR(50),  -- PUBLIC, INTERNAL, CONFIDENTIAL, RESTRICTED
    retention_period_days INTEGER,
    created_date TIMESTAMP,
    updated_date TIMESTAMP,
    
    FOREIGN KEY (technical_object_id) REFERENCES metadata.technical_catalog(catalog_id)
);
```

### 3. Operational Metadata
**Definition**: Information about data processing, quality, and usage

**Components**:
- ETL execution logs and statistics
- Data quality metrics
- Usage statistics and access patterns
- Performance metrics
- Error logs and exceptions

**Example**:
```sql
-- Operational metadata - ETL execution
CREATE TABLE metadata.etl_execution_log (
    execution_id BIGINT PRIMARY KEY,
    job_name VARCHAR(255),
    job_type VARCHAR(50),
    start_timestamp TIMESTAMP,
    end_timestamp TIMESTAMP,
    status VARCHAR(50),  -- SUCCESS, FAILED, RUNNING
    rows_read BIGINT,
    rows_written BIGINT,
    rows_rejected BIGINT,
    error_message TEXT,
    execution_duration_seconds INTEGER,
    server_name VARCHAR(100)
);

-- Operational metadata - Data quality
CREATE TABLE metadata.data_quality_metrics (
    metric_id BIGINT PRIMARY KEY,
    table_name VARCHAR(255),
    column_name VARCHAR(255),
    metric_type VARCHAR(50),  -- COMPLETENESS, ACCURACY, CONSISTENCY
    metric_value DECIMAL(10,2),
    measurement_timestamp TIMESTAMP,
    threshold_value DECIMAL(10,2),
    status VARCHAR(20)  -- PASS, FAIL, WARNING
);

-- Operational metadata - Usage statistics
CREATE TABLE metadata.table_usage_stats (
    usage_id BIGINT PRIMARY KEY,
    table_name VARCHAR(255),
    user_name VARCHAR(100),
    query_count INTEGER,
    total_rows_scanned BIGINT,
    total_execution_time_ms BIGINT,
    avg_execution_time_ms DECIMAL(10,2),
    last_accessed TIMESTAMP,
    access_date DATE
);
```

## Metadata Collection Strategies

### 1. Automated Collection

**Database Schema Extraction**:
```sql
-- Extract table metadata
INSERT INTO metadata.technical_catalog
SELECT 
    ROW_NUMBER() OVER (ORDER BY table_schema, table_name) as catalog_id,
    'TABLE' as object_type,
    table_schema as schema_name,
    table_name as object_name,
    NULL as parent_object,
    NULL as data_type,
    NULL as is_nullable,
    NULL as default_value,
    NULL as constraint_type,
    CURRENT_TIMESTAMP as created_date,
    CURRENT_TIMESTAMP as modified_date,
    'SYSTEM' as created_by
FROM information_schema.tables
WHERE table_schema NOT IN ('information_schema', 'pg_catalog');

-- Extract column metadata
INSERT INTO metadata.technical_catalog
SELECT 
    ROW_NUMBER() OVER (ORDER BY table_schema, table_name, ordinal_position) as catalog_id,
    'COLUMN' as object_type,
    table_schema as schema_name,
    column_name as object_name,
    table_name as parent_object,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN TRUE ELSE FALSE END as is_nullable,
    column_default as default_value,
    NULL as constraint_type,
    CURRENT_TIMESTAMP as created_date,
    CURRENT_TIMESTAMP as modified_date,
    'SYSTEM' as created_by
FROM information_schema.columns
WHERE table_schema NOT IN ('information_schema', 'pg_catalog');
```

**ETL Job Metadata Capture**:
```python
# Python example for capturing ETL metadata
class ETLMetadataCapture:
    def __init__(self, job_name):
        self.job_name = job_name
        self.start_time = None
        self.execution_id = None
        
    def start_execution(self):
        self.start_time = datetime.now()
        self.execution_id = self.log_start()
        
    def log_start(self):
        query = """
            INSERT INTO metadata.etl_execution_log 
            (job_name, start_timestamp, status)
            VALUES (%s, %s, 'RUNNING')
            RETURNING execution_id
        """
        return execute_query(query, [self.job_name, self.start_time])
    
    def log_completion(self, rows_read, rows_written, rows_rejected):
        end_time = datetime.now()
        duration = (end_time - self.start_time).total_seconds()
        
        query = """
            UPDATE metadata.etl_execution_log
            SET end_timestamp = %s,
                status = 'SUCCESS',
                rows_read = %s,
                rows_written = %s,
                rows_rejected = %s,
                execution_duration_seconds = %s
            WHERE execution_id = %s
        """
        execute_query(query, [
            end_time, rows_read, rows_written, 
            rows_rejected, duration, self.execution_id
        ])
    
    def log_failure(self, error_message):
        query = """
            UPDATE metadata.etl_execution_log
            SET end_timestamp = %s,
                status = 'FAILED',
                error_message = %s
            WHERE execution_id = %s
        """
        execute_query(query, [datetime.now(), error_message, self.execution_id])
```

### 2. Manual Documentation

**Business Glossary**:
```sql
-- Business glossary table
CREATE TABLE metadata.business_glossary (
    term_id BIGINT PRIMARY KEY,
    term_name VARCHAR(255) UNIQUE NOT NULL,
    definition TEXT,
    acronym VARCHAR(50),
    synonyms TEXT,  -- JSON array
    related_terms TEXT,  -- JSON array
    subject_area VARCHAR(100),
    owner VARCHAR(100),
    status VARCHAR(50),  -- DRAFT, APPROVED, DEPRECATED
    approval_date DATE,
    created_date TIMESTAMP,
    updated_date TIMESTAMP
);

-- Example entries
INSERT INTO metadata.business_glossary VALUES
(1, 'Customer Lifetime Value', 
 'The total worth of a customer to a business over the entirety of their relationship',
 'CLV', 
 '["LTV", "Lifetime Value"]',
 '["Customer Value", "Revenue"]',
 'Sales & Marketing',
 'marketing@example.com',
 'APPROVED',
 '2024-01-15',
 CURRENT_TIMESTAMP,
 CURRENT_TIMESTAMP);
```

## Data Lineage Tracking

### Column-Level Lineage

```sql
-- Lineage tracking table
CREATE TABLE metadata.data_lineage (
    lineage_id BIGINT PRIMARY KEY,
    source_schema VARCHAR(100),
    source_table VARCHAR(255),
    source_column VARCHAR(255),
    target_schema VARCHAR(100),
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    transformation_logic TEXT,
    transformation_type VARCHAR(50),  -- DIRECT, CALCULATED, AGGREGATED, LOOKUP
    dependency_level INTEGER,  -- How many hops from original source
    created_date TIMESTAMP,
    created_by VARCHAR(100)
);

-- Example lineage records
INSERT INTO metadata.data_lineage VALUES
(1, 'staging', 'stg_orders', 'customer_id', 
    'integration', 'int_customer', 'customer_id',
    'Direct mapping with data cleansing: TRIM(customer_id)',
    'DIRECT', 1, CURRENT_TIMESTAMP, 'ETL_PROCESS'),
    
(2, 'integration', 'int_customer', 'customer_id',
    'presentation', 'dim_customer', 'customer_id',
    'Direct mapping with SCD Type 2 logic',
    'DIRECT', 2, CURRENT_TIMESTAMP, 'ETL_PROCESS'),
    
(3, 'staging', 'stg_orders', 'order_total',
    'presentation', 'fact_sales', 'total_amount',
    'SUM(order_total) aggregated by order_id',
    'AGGREGATED', 1, CURRENT_TIMESTAMP, 'ETL_PROCESS');
```

### Lineage Visualization Query

```sql
-- Get complete lineage path for a column
WITH RECURSIVE lineage_path AS (
    -- Start with target column
    SELECT 
        lineage_id,
        source_schema,
        source_table,
        source_column,
        target_schema,
        target_table,
        target_column,
        transformation_logic,
        transformation_type,
        1 as level,
        CAST(target_table || '.' || target_column AS VARCHAR(1000)) as path
    FROM metadata.data_lineage
    WHERE target_schema = 'presentation'
      AND target_table = 'fact_sales'
      AND target_column = 'total_amount'
    
    UNION ALL
    
    -- Recursively find upstream sources
    SELECT 
        l.lineage_id,
        l.source_schema,
        l.source_table,
        l.source_column,
        l.target_schema,
        l.target_table,
        l.target_column,
        l.transformation_logic,
        l.transformation_type,
        lp.level + 1,
        l.source_table || '.' || l.source_column || ' -> ' || lp.path
    FROM metadata.data_lineage l
    JOIN lineage_path lp 
        ON l.target_schema = lp.source_schema
       AND l.target_table = lp.source_table
       AND l.target_column = lp.source_column
    WHERE lp.level < 10  -- Prevent infinite loops
)
SELECT 
    level,
    source_schema || '.' || source_table || '.' || source_column as source,
    target_schema || '.' || target_table || '.' || target_column as target,
    transformation_type,
    transformation_logic,
    path as complete_lineage_path
FROM lineage_path
ORDER BY level DESC;
```

## Data Catalog

### Comprehensive Data Catalog View

```sql
-- Unified catalog view
CREATE VIEW metadata.vw_data_catalog AS
SELECT 
    tc.catalog_id,
    tc.schema_name,
    tc.object_name,
    tc.object_type,
    tc.data_type,
    bc.business_name,
    bc.business_definition,
    bc.subject_area,
    bc.data_owner,
    bc.data_steward,
    bc.sensitivity_classification,
    -- Usage stats
    us.query_count,
    us.last_accessed,
    -- Quality metrics
    dq.metric_value as quality_score,
    dq.status as quality_status,
    -- Lineage
    (SELECT COUNT(*) 
     FROM metadata.data_lineage 
     WHERE target_table = tc.object_name) as downstream_dependencies,
    (SELECT COUNT(*) 
     FROM metadata.data_lineage 
     WHERE source_table = tc.object_name) as upstream_dependencies
FROM metadata.technical_catalog tc
LEFT JOIN metadata.business_catalog bc ON tc.catalog_id = bc.technical_object_id
LEFT JOIN (
    SELECT table_name, SUM(query_count) as query_count, MAX(last_accessed) as last_accessed
    FROM metadata.table_usage_stats
    GROUP BY table_name
) us ON tc.object_name = us.table_name
LEFT JOIN (
    SELECT table_name, AVG(metric_value) as metric_value, MIN(status) as status
    FROM metadata.data_quality_metrics
    WHERE metric_type = 'OVERALL'
    GROUP BY table_name
) dq ON tc.object_name = dq.table_name
WHERE tc.object_type IN ('TABLE', 'VIEW');
```

## AI-Assisted Metadata Management

### 1. Automated Metadata Discovery

**Schema Inference**:
```python
# AI-powered schema inference
class AIMetadataDiscovery:
    def infer_business_names(self, technical_name):
        """
        Use NLP to generate business-friendly names from technical names
        Example: cust_first_nm -> Customer First Name
        """
        # Remove common prefixes/suffixes
        cleaned = technical_name.replace('_id', '').replace('_key', '')
        
        # Split on underscores and capitalize
        words = cleaned.split('_')
        business_name = ' '.join(word.capitalize() for word in words)
        
        # Use ML model for better naming (pseudocode)
        # business_name = ml_model.predict_business_name(technical_name)
        
        return business_name
    
    def infer_data_type_classification(self, column_name, sample_data):
        """
        Classify data types: email, phone, SSN, address, etc.
        """
        patterns = {
            'email': r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            'phone': r'^\+?1?\d{9,15}$',
            'ssn': r'^\d{3}-\d{2}-\d{4}$',
            'date': r'^\d{4}-\d{2}-\d{2}$'
        }
        
        for data_type, pattern in patterns.items():
            if re.match(pattern, str(sample_data[0])):
                return data_type
        
        return 'unknown'
    
    def infer_relationships(self, table1, table2):
        """
        Use ML to identify potential foreign key relationships
        """
        # Analyze column names, data types, and value distributions
        # Return confidence score for relationship
        pass
```

### 2. Intelligent Cataloging

**Automatic Tagging**:
```sql
-- AI-generated tags table
CREATE TABLE metadata.ai_tags (
    tag_id BIGINT PRIMARY KEY,
    object_type VARCHAR(50),
    object_name VARCHAR(255),
    tag_category VARCHAR(100),  -- SUBJECT_AREA, DATA_DOMAIN, USAGE_PATTERN
    tag_value VARCHAR(255),
    confidence_score DECIMAL(5,2),  -- 0-100
    generated_timestamp TIMESTAMP,
    reviewed_by VARCHAR(100),
    is_approved BOOLEAN
);

-- Example AI-generated tags
INSERT INTO metadata.ai_tags VALUES
(1, 'TABLE', 'dim_customer', 'SUBJECT_AREA', 'Customer Data', 95.5, CURRENT_TIMESTAMP, NULL, FALSE),
(2, 'TABLE', 'dim_customer', 'DATA_DOMAIN', 'Master Data', 98.2, CURRENT_TIMESTAMP, NULL, FALSE),
(3, 'TABLE', 'dim_customer', 'SENSITIVITY', 'PII', 99.9, CURRENT_TIMESTAMP, 'admin', TRUE),
(4, 'TABLE', 'fact_sales', 'USAGE_PATTERN', 'High Query Volume', 87.3, CURRENT_TIMESTAMP, NULL, FALSE);
```

### 3. Smart Recommendations

**Metadata Quality Suggestions**:
```python
class MetadataQualityAnalyzer:
    def analyze_metadata_completeness(self, table_name):
        """
        Analyze metadata completeness and suggest improvements
        """
        issues = []
        
        # Check for missing business definitions
        missing_definitions = query("""
            SELECT tc.object_name
            FROM metadata.technical_catalog tc
            LEFT JOIN metadata.business_catalog bc 
                ON tc.catalog_id = bc.technical_object_id
            WHERE tc.object_type = 'COLUMN'
              AND tc.parent_object = %s
              AND bc.business_definition IS NULL
        """, [table_name])
        
        if missing_definitions:
            issues.append({
                'type': 'MISSING_DEFINITION',
                'severity': 'MEDIUM',
                'affected_columns': missing_definitions,
                'recommendation': 'Add business definitions for columns'
            })
        
        # Check for missing data owners
        missing_owners = query("""
            SELECT object_name
            FROM metadata.business_catalog
            WHERE data_owner IS NULL
        """)
        
        if missing_owners:
            issues.append({
                'type': 'MISSING_OWNER',
                'severity': 'HIGH',
                'affected_objects': missing_owners,
                'recommendation': 'Assign data owners'
            })
        
        return issues
```

## Metadata Search and Discovery

### Full-Text Search

```sql
-- Search across all metadata
CREATE VIEW metadata.vw_searchable_metadata AS
SELECT 
    'TABLE' as result_type,
    schema_name || '.' || object_name as full_name,
    object_name as name,
    business_name,
    business_definition as description,
    subject_area,
    data_owner
FROM metadata.vw_data_catalog
WHERE object_type = 'TABLE'

UNION ALL

SELECT 
    'COLUMN' as result_type,
    schema_name || '.' || parent_object || '.' || object_name as full_name,
    object_name as name,
    business_name,
    business_definition as description,
    subject_area,
    data_owner
FROM metadata.vw_data_catalog
WHERE object_type = 'COLUMN';

-- Search function
-- SELECT * FROM metadata.vw_searchable_metadata
-- WHERE business_name ILIKE '%customer%'
--    OR description ILIKE '%customer%'
--    OR name ILIKE '%customer%';
```

## Best Practices

1. **Automation First**: Automate metadata collection wherever possible
2. **Version Control**: Track metadata changes over time
3. **Quality Metrics**: Measure and improve metadata completeness
4. **Business Alignment**: Ensure business context is captured
5. **Regular Reviews**: Periodic metadata validation and updates
6. **Access Control**: Secure sensitive metadata appropriately
7. **Integration**: Link technical and business metadata
8. **Documentation**: Maintain comprehensive metadata documentation
9. **Search Capability**: Enable easy metadata discovery
10. **Governance**: Establish metadata ownership and stewardship

## Metadata Metrics

### Key Metrics to Track

```sql
-- Metadata completeness dashboard
SELECT 
    'Tables with Business Definitions' as metric,
    COUNT(*) FILTER (WHERE business_definition IS NOT NULL) as count,
    COUNT(*) as total,
    ROUND(100.0 * COUNT(*) FILTER (WHERE business_definition IS NOT NULL) / COUNT(*), 2) as percentage
FROM metadata.vw_data_catalog
WHERE object_type = 'TABLE'

UNION ALL

SELECT 
    'Tables with Data Owners' as metric,
    COUNT(*) FILTER (WHERE data_owner IS NOT NULL),
    COUNT(*),
    ROUND(100.0 * COUNT(*) FILTER (WHERE data_owner IS NOT NULL) / COUNT(*), 2)
FROM metadata.vw_data_catalog
WHERE object_type = 'TABLE'

UNION ALL

SELECT 
    'Tables with Quality Scores' as metric,
    COUNT(*) FILTER (WHERE quality_score IS NOT NULL),
    COUNT(*),
    ROUND(100.0 * COUNT(*) FILTER (WHERE quality_score IS NOT NULL) / COUNT(*), 2)
FROM metadata.vw_data_catalog
WHERE object_type = 'TABLE';
```

## Next Steps
1. Review governance framework in `/docs/governance/`
2. Explore AI methodology in `/docs/ai-methodology/`
3. Check architecture documentation in `/docs/architecture/`
4. Use templates from `/templates/` for metadata implementations

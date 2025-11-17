# ETL/ELT Process Documentation

## Overview
This document outlines the Extract, Transform, Load (ETL) and Extract, Load, Transform (ELT) patterns, processes, and best practices for the data warehouse.

## ETL vs ELT

### ETL (Extract, Transform, Load)
**Characteristics**:
- Transformation occurs before loading
- Processed data loaded into warehouse
- Traditional approach for on-premise systems
- Better for complex transformations

**When to Use**:
- Limited warehouse compute resources
- Complex business logic transformations
- Data cleansing before storage
- Sensitive data that must be masked before loading

**Flow**:
```
Source → Extract → Transform → Load → Target
```

### ELT (Extract, Load, Transform)
**Characteristics**:
- Raw data loaded first
- Transformation occurs in warehouse
- Leverages warehouse compute power
- Modern cloud-native approach

**When to Use**:
- Cloud data warehouses (Snowflake, BigQuery, Redshift)
- Need for data replay and reprocessing
- Rapid data availability required
- Scalable compute resources available

**Flow**:
```
Source → Extract → Load → Transform → Target
```

## Data Ingestion Patterns

### 1. Batch Processing

**Full Load**:
```python
# Pseudocode for full load
def full_load_batch():
    # Extract all data from source
    source_data = extract_from_source()
    
    # Transform data
    transformed_data = apply_transformations(source_data)
    
    # Truncate and load
    truncate_target_table()
    load_data(transformed_data)
    
    # Update metadata
    update_load_metadata(status='completed', rows=len(transformed_data))
```

**Incremental Load (Delta)**:
```python
# Pseudocode for incremental load
def incremental_load_batch():
    # Get last successful load timestamp
    last_load_time = get_last_load_timestamp()
    
    # Extract only changed/new data
    delta_data = extract_where_modified_date > last_load_time
    
    # Transform
    transformed_data = apply_transformations(delta_data)
    
    # Upsert (Update + Insert)
    upsert_data(transformed_data)
    
    # Update watermark
    update_load_timestamp(current_timestamp)
```

### 2. Real-Time / Streaming Processing

**Change Data Capture (CDC)**:
```
Source DB → CDC Tool (Debezium, AWS DMS) → Message Queue (Kafka) → Stream Processor → Target
```

**Event Streaming**:
```python
# Pseudocode for stream processing
def process_stream():
    stream = connect_to_kafka_topic('sales_events')
    
    for event in stream:
        # Validate event
        if validate_event(event):
            # Transform
            transformed = transform_event(event)
            
            # Load to warehouse
            append_to_table(transformed)
            
            # Commit offset
            commit_offset(event.offset)
```

### 3. Micro-Batch Processing

**Characteristics**:
- Small batches processed frequently (e.g., every 5-15 minutes)
- Balance between batch and real-time
- Lower latency than traditional batch

## Transformation Patterns

### 1. Data Cleansing

```sql
-- Remove duplicates
WITH ranked_data AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id, order_date 
               ORDER BY updated_timestamp DESC
           ) as rn
    FROM staging.orders
)
SELECT * FROM ranked_data WHERE rn = 1;

-- Standardize formats
SELECT 
    customer_id,
    UPPER(TRIM(customer_name)) as customer_name,
    REGEXP_REPLACE(phone, '[^0-9]', '') as phone_clean,
    LOWER(TRIM(email)) as email_normalized
FROM staging.customers;

-- Handle nulls
SELECT 
    COALESCE(customer_email, 'unknown@example.com') as email,
    COALESCE(customer_phone, 'N/A') as phone,
    COALESCE(address, 'Address Not Provided') as address
FROM staging.customers;
```

### 2. Data Validation

```sql
-- Data quality checks
SELECT 
    'NULL check' as check_type,
    COUNT(*) as failed_records
FROM staging.orders
WHERE customer_id IS NULL 
   OR order_date IS NULL
   OR total_amount IS NULL

UNION ALL

SELECT 
    'Range check' as check_type,
    COUNT(*) as failed_records
FROM staging.orders
WHERE total_amount < 0 
   OR total_amount > 1000000

UNION ALL

SELECT 
    'Referential integrity' as check_type,
    COUNT(*) as failed_records
FROM staging.orders o
LEFT JOIN dim_customer c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

### 3. Data Enrichment

```sql
-- Add derived columns
SELECT 
    order_id,
    order_date,
    total_amount,
    -- Calculate age of order
    DATEDIFF(day, order_date, CURRENT_DATE) as days_since_order,
    -- Categorize order size
    CASE 
        WHEN total_amount < 100 THEN 'Small'
        WHEN total_amount < 1000 THEN 'Medium'
        ELSE 'Large'
    END as order_size_category,
    -- Add business day calculation
    CASE 
        WHEN DAYOFWEEK(order_date) IN (1,7) THEN FALSE
        ELSE TRUE
    END as is_business_day
FROM staging.orders;
```

### 4. Aggregation

```sql
-- Daily sales aggregation
SELECT 
    order_date,
    customer_id,
    COUNT(DISTINCT order_id) as order_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as avg_order_value,
    MIN(total_amount) as min_order_value,
    MAX(total_amount) as max_order_value
FROM staging.orders
GROUP BY order_date, customer_id;
```

## ETL Orchestration

### Workflow Example (Airflow DAG)

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.sql import SQLCheckOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data_engineering',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'sales_etl_pipeline',
    default_args=default_args,
    description='Daily sales data ETL pipeline',
    schedule_interval='0 2 * * *',  # 2 AM daily
    catchup=False,
    tags=['sales', 'etl', 'daily'],
)

# Task 1: Extract from source
extract_task = PythonOperator(
    task_id='extract_sales_data',
    python_callable=extract_sales_data,
    dag=dag,
)

# Task 2: Data quality checks
validate_task = SQLCheckOperator(
    task_id='validate_extracted_data',
    sql='SELECT COUNT(*) FROM staging.sales WHERE order_date = {{ ds }}',
    conn_id='warehouse_conn',
    dag=dag,
)

# Task 3: Transform and load
transform_task = PythonOperator(
    task_id='transform_sales_data',
    python_callable=transform_and_load,
    dag=dag,
)

# Task 4: Update dimensions
update_dims_task = PythonOperator(
    task_id='update_dimensions',
    python_callable=update_dimensions,
    dag=dag,
)

# Task 5: Load facts
load_facts_task = PythonOperator(
    task_id='load_fact_table',
    python_callable=load_fact_sales,
    dag=dag,
)

# Task 6: Data quality validation
final_validation = SQLCheckOperator(
    task_id='validate_final_data',
    sql='SELECT COUNT(*) FROM fact_sales WHERE date_key = {{ ds_nodash }}',
    conn_id='warehouse_conn',
    dag=dag,
)

# Define dependencies
extract_task >> validate_task >> transform_task >> update_dims_task >> load_facts_task >> final_validation
```

## Error Handling and Recovery

### Error Detection

```python
def process_batch_with_error_handling():
    try:
        # Extract
        data = extract_data()
        log_metric('extract_row_count', len(data))
        
        # Validate
        validation_errors = validate_data(data)
        if validation_errors:
            log_errors('validation', validation_errors)
            # Send to error table
            save_to_error_table(validation_errors)
            # Continue with valid records
            data = filter_valid_records(data)
        
        # Transform
        transformed = transform_data(data)
        
        # Load
        load_result = load_data(transformed)
        log_metric('load_row_count', load_result.rows_inserted)
        
        # Mark as success
        update_batch_status('SUCCESS')
        
    except Exception as e:
        log_error('pipeline_failure', str(e))
        update_batch_status('FAILED')
        send_alert('Pipeline failed', str(e))
        raise
```

### Retry Logic

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
def extract_with_retry():
    """Extract data with automatic retry on failure"""
    return extract_from_api()
```

### Data Reconciliation

```sql
-- Compare source vs target counts
WITH source_count AS (
    SELECT COUNT(*) as cnt FROM source_system.orders
    WHERE order_date = '2024-01-01'
),
target_count AS (
    SELECT COUNT(*) as cnt FROM staging.orders
    WHERE order_date = '2024-01-01'
)
SELECT 
    s.cnt as source_count,
    t.cnt as target_count,
    s.cnt - t.cnt as difference,
    CASE 
        WHEN s.cnt = t.cnt THEN 'PASS'
        ELSE 'FAIL'
    END as reconciliation_status
FROM source_count s, target_count t;
```

## Performance Optimization

### 1. Parallel Processing

```python
from concurrent.futures import ThreadPoolExecutor

def process_tables_in_parallel(table_list):
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = [
            executor.submit(process_table, table) 
            for table in table_list
        ]
        results = [f.result() for f in futures]
    return results
```

### 2. Bulk Loading

```sql
-- Use COPY command for bulk inserts (PostgreSQL/Redshift)
COPY staging.orders
FROM 's3://bucket/data/orders.csv'
CREDENTIALS 'aws_iam_role=arn:aws:iam::123456789:role/RedshiftRole'
CSV
DELIMITER ','
IGNOREHEADER 1
DATEFORMAT 'YYYY-MM-DD';
```

### 3. Incremental Processing

```sql
-- Process only changed records
MERGE INTO target_table t
USING (
    SELECT * FROM staging_table
    WHERE updated_timestamp > (
        SELECT MAX(updated_timestamp) FROM target_table
    )
) s
ON t.id = s.id
WHEN MATCHED THEN 
    UPDATE SET 
        t.column1 = s.column1,
        t.updated_timestamp = s.updated_timestamp
WHEN NOT MATCHED THEN
    INSERT VALUES (s.id, s.column1, s.updated_timestamp);
```

## AI-Assisted ETL

### 1. Automated Mapping Generation
- **Schema Matching**: AI identifies source-to-target column mappings
- **Transformation Suggestions**: ML recommends necessary transformations
- **Data Type Conversion**: Automatic type mapping and conversion logic

### 2. Intelligent Data Quality
- **Anomaly Detection**: ML identifies unusual patterns in data
- **Validation Rule Generation**: AI suggests validation rules
- **Error Classification**: Automatic categorization of data errors

### 3. Performance Optimization
- **Query Optimization**: AI rewrites queries for better performance
- **Resource Allocation**: ML predicts optimal resource allocation
- **Scheduling Optimization**: AI suggests best execution times

### 4. Self-Healing Pipelines
- **Automatic Retry**: AI determines when to retry vs. fail
- **Error Resolution**: ML suggests fixes for common errors
- **Adaptive Processing**: Pipelines adjust based on data patterns

## Monitoring and Logging

### Key Metrics to Track

```python
metrics = {
    'extract': {
        'row_count': 1000000,
        'duration_seconds': 120,
        'file_size_mb': 500
    },
    'transform': {
        'input_rows': 1000000,
        'output_rows': 998000,
        'rejected_rows': 2000,
        'duration_seconds': 300
    },
    'load': {
        'rows_inserted': 850000,
        'rows_updated': 148000,
        'rows_deleted': 0,
        'duration_seconds': 180
    },
    'quality': {
        'completeness_score': 99.5,
        'accuracy_score': 98.2,
        'validation_errors': 15
    }
}
```

### Logging Best Practices

```python
import logging

logger = logging.getLogger(__name__)

def etl_process():
    logger.info(f"Starting ETL process for batch {batch_id}")
    
    # Log start of each phase
    logger.info(f"Extract phase started")
    data = extract()
    logger.info(f"Extract complete: {len(data)} records")
    
    # Log transformations
    logger.debug(f"Applying transformation: remove_duplicates")
    data = remove_duplicates(data)
    logger.info(f"After deduplication: {len(data)} records")
    
    # Log warnings
    if validation_errors:
        logger.warning(f"Validation errors found: {len(validation_errors)}")
    
    # Log completion
    logger.info(f"ETL process completed successfully for batch {batch_id}")
```

## Best Practices

1. **Idempotency**: Ensure pipelines can be re-run safely
2. **Incremental Loading**: Process only changed data
3. **Data Validation**: Validate at every stage
4. **Error Handling**: Capture and log all errors
5. **Monitoring**: Track metrics and performance
6. **Documentation**: Document all transformations
7. **Version Control**: Track pipeline code changes
8. **Testing**: Test pipelines with sample data
9. **Rollback Capability**: Ability to revert changes
10. **Data Lineage**: Track data from source to target

## Next Steps
1. Review layer-specific transformations in `/docs/layers/`
2. Explore governance framework in `/docs/governance/`
3. Check metadata management in `/docs/metadata/`
4. Use templates from `/templates/` for new pipelines

# ETL - Bronze Layer Extraction

## Purpose

The `etl/` folder contains Python scripts for **Bronze layer extraction** - the first step in the Medallion Architecture data pipeline. These scripts extract raw data from the MSSQL operational database and load it into the PostgreSQL Bronze layer.

### Technology Separation

- **Python ETL (this folder)**: Bronze layer ingestion only (MSSQL → PostgreSQL)
- **dbt (dbt/models/)**: Silver and Gold layer transformations only (PostgreSQL → PostgreSQL)

This separation keeps concerns clear: Python handles external system integration, while dbt handles internal transformations.

## How It Works

### Extraction Process

1. **Connects to MSSQL** operational database (source system)
2. **Extracts data incrementally** using watermark-based loading (tracks `last_modified_ts`)
3. **Loads to PostgreSQL Bronze layer** (`bronze.*` schema)
4. **Adds ETL metadata** to every record:
   - `_bronze_load_ts`: Timestamp when record was loaded into Bronze
   - `_bronze_batch_id`: Unique identifier for the batch run
   - `_bronze_source_file`: Source script/file name

### Key Features

- **Incremental Loading**: Only extracts records modified since the last run (watermark pattern)
- **Batch Processing**: Processes data in chunks (1000 rows per batch) for memory efficiency
- **Append-Only Bronze**: Records are never updated, only appended (immutable audit trail)
- **Error Handling**: Failed batches are logged and can be retried

## Files in This Folder

| File | Description |
|------|-------------|
| `bronze_extract_customer_profile.py` | Extracts customer profile data from MSSQL to Bronze |
| `.env.example` | Configuration template (copy to `.env` and customize) |
| `requirements.txt` | Python dependencies (pyodbc, psycopg2-binary, python-dotenv) |

## Configuration

### Step 1: Copy Environment Template

```bash
cp .env.example .env
```

### Step 2: Configure Environment Variables

Edit `.env` with your connection details:

```bash
# MSSQL Source Database
MSSQL_SERVER=your-server.database.windows.net
MSSQL_PORT=1433
MSSQL_DATABASE=OperationalDB
MSSQL_USERNAME=your_username
MSSQL_PASSWORD=your_password

# PostgreSQL Target Database (Bronze Layer)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DATABASE=dw1
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=your_password
POSTGRES_SCHEMA=bronze

# Extraction Settings
BATCH_SIZE=1000
WATERMARK_TABLE=etl_watermarks
```

### Step 3: Install Dependencies

```bash
cd etl/
pip install -r requirements.txt
```

## Running Extraction

### Manual Execution

```bash
cd etl/
python bronze_extract_customer_profile.py
```

### Expected Output

```
[2025-12-12 10:30:00] Starting Bronze extraction for customer_profile
[2025-12-12 10:30:01] Last watermark: 2025-12-11 08:00:00
[2025-12-12 10:30:02] Extracted 2,345 new/modified records
[2025-12-12 10:30:03] Batch 1/3: Loaded 1000 records
[2025-12-12 10:30:04] Batch 2/3: Loaded 1000 records
[2025-12-12 10:30:05] Batch 3/3: Loaded 345 records
[2025-12-12 10:30:06] Updated watermark to: 2025-12-12 10:30:00
[2025-12-12 10:30:06] Extraction completed successfully
```

## Adding New Extraction Scripts

### Naming Convention

Follow this pattern for new scripts:

```
bronze_extract_{module}_profile.py
```

Examples:
- `bronze_extract_investment_profile.py`
- `bronze_extract_transaction_history.py`
- `bronze_extract_account_profile.py`

### Script Template Structure

```python
#!/usr/bin/env python3
"""
Bronze extraction script for {module} profile
Extracts from MSSQL operational DB to PostgreSQL Bronze layer
"""

import os
import pyodbc
import psycopg2
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
BATCH_SIZE = int(os.getenv('BATCH_SIZE', 1000))
SOURCE_TABLE = 'dbo.{source_table}'
TARGET_TABLE = 'bronze.{target_table}'
WATERMARK_KEY = '{module}_profile'

def get_last_watermark(pg_conn):
    """Retrieve last extraction timestamp"""
    # Implementation here
    pass

def extract_from_source(mssql_conn, watermark):
    """Extract new/modified records from MSSQL"""
    # Implementation here
    pass

def load_to_bronze(pg_conn, records, batch_id):
    """Load records to Bronze layer with metadata"""
    # Implementation here
    pass

def update_watermark(pg_conn, new_watermark):
    """Update watermark for next run"""
    # Implementation here
    pass

def main():
    print(f"Starting Bronze extraction for {WATERMARK_KEY}")
    
    # Connect to MSSQL
    mssql_conn = pyodbc.connect(...)
    
    # Connect to PostgreSQL
    pg_conn = psycopg2.connect(...)
    
    try:
        # Get watermark
        last_watermark = get_last_watermark(pg_conn)
        
        # Extract
        records = extract_from_source(mssql_conn, last_watermark)
        
        # Load in batches
        batch_id = datetime.utcnow().strftime('%Y%m%d%H%M%S')
        load_to_bronze(pg_conn, records, batch_id)
        
        # Update watermark
        update_watermark(pg_conn, datetime.utcnow())
        
        print("Extraction completed successfully")
        
    finally:
        mssql_conn.close()
        pg_conn.close()

if __name__ == "__main__":
    main()
```

## Integration with dbt

### Data Flow Pipeline

```
┌──────────────────────────────────────────────────────────────┐
│ Step 1: Bronze Extraction (Python ETL)                       │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
MSSQL (Operational)  →  PostgreSQL bronze.customer_profile_raw
                        • Exact copy from source
                        • + ETL metadata fields
                        • Append-only, immutable

┌──────────────────────────────────────────────────────────────┐
│ Step 2: Silver Transformation (dbt)                          │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
bronze.customer_profile_raw  →  silver.customer_profile_standardized
                                 • Data quality validation
                                 • Hash computation
                                 • Cleansing & normalization

┌──────────────────────────────────────────────────────────────┐
│ Step 3: Gold Transformation (dbt)                            │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
silver.customer_profile_standardized  →  gold.dim_customer_profile
                                          • SCD Type 2 dimensions
                                          • Bridge tables
                                          • Audit fact tables
```

### Example Workflow

```bash
# Step 1: Run Bronze extraction (Python)
cd etl/
python bronze_extract_customer_profile.py

# Step 2: Run Silver transformation (dbt)
cd ../dbt/
dbt run --models silver.customer_profile_standardized

# Step 3: Run Gold transformation (dbt)
dbt run --models gold.dim_customer_profile
dbt run --models gold.bridge_customer_*
dbt run --models gold.fact_customer_profile_audit
```

### Why This Separation?

**Bronze (Python ETL)**:
- Handles different protocols (ODBC, REST APIs, files)
- Manages external system credentials
- Deals with network issues and retries
- Performs incremental extraction logic

**Silver/Gold (dbt)**:
- Works entirely within PostgreSQL
- Version controlled SQL transformations
- Built-in testing and documentation
- Incremental materializations
- Data lineage tracking

## Future: Airflow Orchestration

These Python scripts will be orchestrated by Apache Airflow for automated scheduling and dependency management.

### Example Airflow DAG

```python
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'start_date': datetime(2025, 12, 1),
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'customer_profile_pipeline',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    catchup=False,
)

# Task 1: Bronze extraction
bronze_extract = BashOperator(
    task_id='bronze_extract_customer_profile',
    bash_command='cd /opt/dw1/etl && python bronze_extract_customer_profile.py',
    dag=dag,
)

# Task 2: Silver transformation
silver_transform = BashOperator(
    task_id='silver_transform_customer_profile',
    bash_command='cd /opt/dw1/dbt && dbt run --models silver.customer_profile_standardized',
    dag=dag,
)

# Task 3: Gold transformation
gold_transform = BashOperator(
    task_id='gold_transform_customer_profile',
    bash_command='cd /opt/dw1/dbt && dbt run --models gold.dim_customer_profile gold.bridge_customer_* gold.fact_customer_profile_audit',
    dag=dag,
)

# Define dependencies
bronze_extract >> silver_transform >> gold_transform
```

## Monitoring and Troubleshooting

### Check Watermark Status

```sql
-- View last extraction times
SELECT 
    watermark_key,
    last_watermark_ts,
    last_run_ts,
    records_extracted
FROM bronze.etl_watermarks
ORDER BY last_run_ts DESC;
```

### Check Bronze Record Counts

```sql
-- Count records by batch
SELECT 
    _bronze_batch_id,
    COUNT(*) as record_count,
    MIN(_bronze_load_ts) as batch_start,
    MAX(_bronze_load_ts) as batch_end
FROM bronze.customer_profile_raw
GROUP BY _bronze_batch_id
ORDER BY batch_start DESC
LIMIT 10;
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection timeout | MSSQL server unreachable | Check network, firewall, VPN |
| Authentication failed | Wrong credentials | Verify `.env` file settings |
| Duplicate key error | Primary key collision | Check watermark logic, may need full reload |
| Out of memory | Batch size too large | Reduce `BATCH_SIZE` in `.env` |
| No records extracted | Watermark ahead of data | Reset watermark or check source data |

## Best Practices

### DO ✅

- Always use `.env` file for credentials (never hardcode)
- Test with small `BATCH_SIZE` first (e.g., 100)
- Monitor disk space on PostgreSQL server
- Log all extraction runs with timestamps
- Keep Bronze schema immutable (append-only)
- Document any custom transformations applied during extraction

### DON'T ❌

- Don't apply business logic in Bronze scripts (keep in dbt)
- Don't update existing Bronze records (append only)
- Don't skip watermark updates (causes duplicate loads)
- Don't commit `.env` file to git (credentials exposure)
- Don't run multiple instances concurrently (race conditions)

## Related Documentation

- **dbt Setup**: See `/dbt/README.md` for Silver/Gold transformations
- **Data Quality**: See `/docs/data-quality/framework.md` for validation rules
- **Architecture**: See `/docs/architecture/README.md` for overall design
- **Layers**: See `/docs/layers/README.md` for Bronze/Silver/Gold layer specifications
- **Customer Module**: See `/docs/business/modules/customer_module.md` for business requirements

---

**Last Updated**: 2025-12-12  
**Maintained By**: Data Engineering Team

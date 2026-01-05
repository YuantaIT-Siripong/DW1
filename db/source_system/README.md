# Source System Views

**Purpose**: Sample DDL and documentation for IT operational database views  
**Layer**: Source System (External)  
**Schema**: Not applicable (external MSSQL database)  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains **sample DDL** and documentation for source system views created by the IT department. These views are the **starting point** for our Bronze layer extraction.

**Important**: This is NOT our database. These files are for **documentation purposes only**.

---

## Source System Architecture

### Operational Database
- **Platform**: Microsoft SQL Server (MSSQL)
- **Owner**: IT Department
- **Purpose**: Operational transaction processing (OLTP)
- **Access**: Read-only for data warehouse

### Standardized Views Pattern

IT creates **standardized views** for data warehouse consumption:

```
Source Tables (operational, complex)
    ↓ (IT creates standardized view)
vw_<entity>_standardized
    ↓ (We extract via Python ETL)
Bronze Layer (bronze.<entity>_standardized)
```

**Why standardized views?**
- ✅ IT handles source complexity
- ✅ Consistent column naming
- ✅ Type conversions
- ✅ Business logic encapsulation
- ✅ Stable interface (view can hide source changes)

---

## Files in This Directory

### create_it_view_sample.sql

**Type**: Sample DDL (for documentation)  
**Purpose**: Shows structure of IT standardized views  
**Status**: Example only, not executed in our database

**Contents**:
- Sample view definition
- Expected column names and types
- Comments on business logic
- Temporal column explanation

**Usage**:
- Reference when understanding source structure
- Template for requesting new IT views
- Documentation for Bronze layer design

---

## IT View Specifications

### Naming Convention

**Pattern**: `vw_<entity>_standardized`

**Examples**:
- `vw_customer_profile_standardized`
- `vw_investment_profile_standardized`
- `vw_company_profile_standardized`

### Standard Columns

**Required in ALL IT views**:

1. **Natural Key**: `<entity>_id BIGINT`
   - Unique identifier from source system
   - Immutable over time

2. **Temporal Column**: `last_modified_ts DATETIME`
   - When record was last modified in source
   - Used for incremental extraction
   - Precise to millisecond (if possible)

3. **Business Attributes**: All relevant entity attributes
   - Descriptive names (snake_case preferred)
   - Appropriate data types
   - NULL handling documented

### Sample IT View Structure

```sql
-- This is IT's responsibility (external to DW)
CREATE OR ALTER VIEW vw_customer_profile_standardized AS
SELECT 
    -- Natural key
    customer_id AS customer_id,
    
    -- Temporal column
    modified_date AS last_modified_ts,
    
    -- Demographics
    title AS person_title,
    first_name,
    last_name,
    birth_date,
    
    -- Economic attributes
    marital_status_code AS marital_status,
    nationality_code AS nationality,
    occupation_code AS occupation,
    occupation_freetext AS occupation_other,
    
    -- ... additional attributes ...
    
FROM customer_master cm
LEFT JOIN customer_details cd ON cm.customer_id = cd.customer_id
WHERE cm.is_deleted = 0  -- Exclude soft-deleted records
;
```

---

## IT View Requirements

When requesting new IT views, specify:

### 1. Entity Definition
- Entity name and description
- Business domain
- Primary use case

### 2. Required Columns
- Natural key column(s)
- Temporal column for incremental load
- All business attributes needed
- Data types and lengths

### 3. Data Quality Expectations
- NULL handling (which fields can be NULL?)
- Enumeration values (valid codes)
- Date ranges (min/max constraints)
- Referential integrity

### 4. Historical Requirements
- Need full history or current state only?
- Soft delete handling (include deleted records?)
- Temporal accuracy (hour? minute? second?)

### 5. Performance Considerations
- Expected row count
- Update frequency
- Indexes needed (on temporal column)

---

## Bronze Layer Extraction from IT Views

### Extraction Pattern

```python
# Python ETL script: etl/bronze_extract_<entity>.py
# Extracts from IT view to Bronze layer

import psycopg2
import pymssql

# 1. Connect to MSSQL (source)
mssql_conn = pymssql.connect(
    server='operational.mssql.server',
    database='operational_db'
)

# 2. Incremental query
query = """
    SELECT * 
    FROM vw_customer_profile_standardized
    WHERE last_modified_ts > ?
    ORDER BY last_modified_ts
"""
watermark = get_last_bronze_timestamp()  # From PostgreSQL Bronze

# 3. Extract in batches
cursor = mssql_conn.cursor()
cursor.execute(query, (watermark,))

# 4. Load to Bronze (PostgreSQL)
pg_conn = psycopg2.connect(...)
while True:
    rows = cursor.fetchmany(1000)  # Batch of 1000
    if not rows:
        break
    insert_to_bronze(pg_conn, rows)

# 5. Update watermark
update_watermark(pg_conn)
```

---

## IT View Change Management

### When IT View Changes

**Scenarios**:
1. **Column added**: Add to Bronze contract and DDL
2. **Column removed**: May need Bronze DDL change
3. **Column renamed**: Update Bronze mapping
4. **Type changed**: Update Bronze DDL
5. **View logic changed**: May affect data values

### Change Notification Process

**Process**:
1. IT notifies of planned view changes (advance notice)
2. Data team reviews impact
3. Update Bronze contracts and DDL
4. Update extraction scripts if needed
5. Test in development
6. Coordinate deployment with IT

### Version Tracking

Document IT view versions in Bronze contract:

```yaml
# contracts/bronze/customer_profile_standardized.yaml
upstream_source:
  type: "IT_view"
  location: "MSSQL.operational_db.vw_customer_profile_standardized"
  version: "2.0"
  last_modified: "2026-01-05"
  changes: "Added customer_segment column"
```

---

## Testing IT Views

### Validation Checklist

Before accepting new IT view:

1. **Structure Validation**
   - [ ] Natural key present and unique
   - [ ] Temporal column present and monotonic
   - [ ] All requested columns present
   - [ ] Data types appropriate

2. **Data Quality**
   - [ ] No unexpected NULLs
   - [ ] Enumeration codes valid
   - [ ] Date ranges reasonable
   - [ ] Row count matches expectations

3. **Performance**
   - [ ] Query execution time acceptable
   - [ ] Incremental query uses index
   - [ ] No full table scans

4. **Historical Accuracy**
   - [ ] Temporal column accurate
   - [ ] History preserved (if needed)
   - [ ] No gaps in temporal sequence

---

## Common Issues and Solutions

### Issue: Temporal Column Not Indexed
**Problem**: Incremental extraction slow  
**Solution**: Request IT to add index on `last_modified_ts`

### Issue: NULL Temporal Column
**Problem**: Cannot determine extraction watermark  
**Solution**: IT must ensure temporal column is NOT NULL

### Issue: Enumeration Codes Changed
**Problem**: Historic codes no longer valid  
**Solution**: Maintain enumeration version history

### Issue: View Performance Degradation
**Problem**: View query too complex  
**Solution**: Request materialized view or staging table

---

## Collaboration with IT

### Responsibilities

**IT Team**:
- ✅ Create and maintain standardized views
- ✅ Ensure view performance
- ✅ Notify of schema changes
- ✅ Handle source system complexity

**Data Warehouse Team** (Us):
- ✅ Extract data from IT views
- ✅ Apply data quality rules
- ✅ Build dimensional model
- ✅ Provide feedback on view structure

### Communication Channels

- **For new views**: Submit request with requirements
- **For changes**: Coordinated change management
- **For issues**: Direct communication with IT DBA team

---

## Related Documentation

- **Parent**: `/db/README.md`
- **Bronze Layer**: `/db/bronze/README.md`
- **ETL Scripts**: `/etl/README.md`
- **Bronze Contracts**: `/contracts/bronze/README.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Engineering Team (coordination with IT)  
**IT Contact**: IT Database Team

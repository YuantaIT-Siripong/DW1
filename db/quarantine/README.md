# Quarantine Layer DDL

**Purpose**: Data quality failures and rejected records  
**Layer**: Quarantine (Quality Control)  
**Schema**: `quarantine`  
**Last Updated**: 2026-01-05

---

## Overview

The Quarantine layer stores records that failed data quality validation. This enables:
- Root cause analysis of quality issues
- Reprocessing after fixes
- Audit trail of rejections
- Quality metrics calculation

---

## Quarantine Principles

### 1. Preserve Original Data
- ✅ ALL original columns from source
- ✅ NO transformations (preserve failing data)
- ✅ Maintain source references

### 2. Add Rejection Metadata
- ✅ **rejection_reason**: Why record was rejected
- ✅ **rejected_at**: When rejection occurred
- ✅ **rejected_by_rule**: Which validation rule failed
- ✅ **source_layer**: Where rejection occurred (bronze/silver)

### 3. Enable Reprocessing
- ✅ Records can be corrected and re-inserted to source
- ✅ Track reprocessing attempts
- ✅ Link to original source records

---

## DDL Files in This Directory

### customer_profile_rejected.sql
- **Entity**: Customer Profile
- **Source**: Records failing Silver validation
- **Rejection Types**: Enumeration validation failures, data type errors
- **Contract**: `contracts/quarantine/customer_profile_rejected.yaml`

---

## Quarantine Table Template

```sql
-- Create schema
CREATE SCHEMA IF NOT EXISTS quarantine;

-- Drop table (development only)
DROP TABLE IF EXISTS quarantine.<entity>_rejected CASCADE;

-- Create table
CREATE TABLE quarantine.<entity>_rejected (
    -- Quarantine metadata
    quarantine_id BIGSERIAL PRIMARY KEY,
    rejected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rejection_reason TEXT NOT NULL,
    rejected_by_rule VARCHAR(100),
    source_layer VARCHAR(20) NOT NULL,  -- 'bronze' or 'silver'
    reprocessing_status VARCHAR(20) DEFAULT 'PENDING',
    reprocessed_at TIMESTAMP,
    
    -- Original record (ALL source columns)
    <entity>_id BIGINT,
    last_modified_ts TIMESTAMP,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    -- ... all business attributes ...
    
    -- Original ETL metadata
    _bronze_load_ts TIMESTAMP,
    _bronze_source_file VARCHAR(255),
    _bronze_batch_id VARCHAR(100)
);

-- Indexes
CREATE INDEX idx_quarantine_<entity>_rejected_at 
    ON quarantine.<entity>_rejected(rejected_at);

CREATE INDEX idx_quarantine_<entity>_nk 
    ON quarantine.<entity>_rejected(<entity>_id);

CREATE INDEX idx_quarantine_<entity>_status 
    ON quarantine.<entity>_rejected(reprocessing_status);

-- Comments
COMMENT ON TABLE quarantine.<entity>_rejected IS 
    'Records from <entity> that failed data quality validation. Preserved for analysis and reprocessing.';

COMMENT ON COLUMN quarantine.<entity>_rejected.rejection_reason IS 
    'Detailed explanation of why record was rejected. May include multiple validation failures.';

COMMENT ON COLUMN quarantine.<entity>_rejected.rejected_by_rule IS 
    'Name of validation rule that triggered rejection (e.g., "dq_marital_status_enumeration").';

COMMENT ON COLUMN quarantine.<entity>_rejected.reprocessing_status IS 
    'Status: PENDING (awaiting review), CORRECTED (fixed and reprocessed), IGNORED (accepted as-is).';
```

---

## Rejection Metadata Columns

### quarantine_id
- **Type**: `BIGSERIAL PRIMARY KEY`
- **Purpose**: Unique identifier for quarantine record
- **Auto-generated**: Yes

### rejected_at
- **Type**: `TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP`
- **Purpose**: When record was quarantined
- **Usage**: Track rejection timeline

### rejection_reason
- **Type**: `TEXT NOT NULL`
- **Purpose**: Detailed explanation of failure(s)
- **Example**: `"marital_status 'XYZ' not in enumeration; nationality NULL but required"`

### rejected_by_rule
- **Type**: `VARCHAR(100)`
- **Purpose**: Name of validation rule that failed
- **Example**: `"dq_marital_status_enumeration"`

### source_layer
- **Type**: `VARCHAR(20) NOT NULL`
- **Purpose**: Which layer detected the failure
- **Values**: `'bronze'`, `'silver'`

### reprocessing_status
- **Type**: `VARCHAR(20) DEFAULT 'PENDING'`
- **Purpose**: Track reprocessing workflow
- **Values**:
  - `PENDING`: Awaiting review
  - `CORRECTED`: Fixed and reprocessed
  - `IGNORED`: Accepted as-is (false positive)
  - `REJECTED`: Permanently rejected

### reprocessed_at
- **Type**: `TIMESTAMP`
- **Purpose**: When record was reprocessed
- **NULL**: If not yet reprocessed

---

## Data Flow to Quarantine

### From Silver Validation

```sql
-- dbt model: quarantine_customer_profile_rejected
{{ config(
    materialized='incremental',
    schema='quarantine'
) }}

WITH failed_validations AS (
    SELECT 
        CURRENT_TIMESTAMP AS rejected_at,
        'Enumeration validation failed: ' || 
            CASE 
                WHEN NOT dq_marital_status_valid THEN 'marital_status; '
                WHEN NOT dq_nationality_valid THEN 'nationality; '
                ELSE ''
            END AS rejection_reason,
        'silver_enumeration_validation' AS rejected_by_rule,
        'silver' AS source_layer,
        'PENDING' AS reprocessing_status,
        
        -- All original columns
        *
    FROM {{ ref('silver_customer_profile_standardized') }}
    WHERE dq_status = 'FAIL'  -- Only FAIL records to quarantine
    
    {% if is_incremental() %}
        AND _silver_load_ts > (SELECT MAX(rejected_at) FROM {{ this }})
    {% endif %}
)

SELECT * FROM failed_validations
```

---

## Reprocessing Workflow

### 1. Identify Quarantined Records
```sql
SELECT 
    quarantine_id,
    rejection_reason,
    customer_id,
    first_name,
    last_name
FROM quarantine.customer_profile_rejected
WHERE reprocessing_status = 'PENDING'
ORDER BY rejected_at DESC;
```

### 2. Analyze Root Cause
- Check `rejection_reason` for details
- Review source data
- Identify if data issue or validation issue

### 3. Fix Options

**Option A: Fix Source Data**
- Correct data in source system
- Re-extract to Bronze
- Re-transform to Silver
- Mark quarantine record as `CORRECTED`

**Option B: Adjust Validation Rule**
- If rule is too strict (false positive)
- Update validation logic
- Reprocess quarantined records
- Mark as `CORRECTED`

**Option C: Accept As-Is**
- If data is valid despite failing validation
- Mark as `IGNORED`
- May require business approval

### 4. Update Reprocessing Status
```sql
UPDATE quarantine.customer_profile_rejected
SET 
    reprocessing_status = 'CORRECTED',
    reprocessed_at = CURRENT_TIMESTAMP
WHERE quarantine_id = <id>;
```

---

## Quality Metrics from Quarantine

### Rejection Rate
```sql
SELECT 
    DATE(rejected_at) AS rejection_date,
    COUNT(*) AS rejected_count,
    source_layer,
    rejected_by_rule
FROM quarantine.customer_profile_rejected
WHERE rejected_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(rejected_at), source_layer, rejected_by_rule
ORDER BY rejection_date DESC;
```

### Common Rejection Reasons
```sql
SELECT 
    rejection_reason,
    COUNT(*) AS occurrence_count,
    MIN(rejected_at) AS first_seen,
    MAX(rejected_at) AS last_seen
FROM quarantine.customer_profile_rejected
GROUP BY rejection_reason
ORDER BY occurrence_count DESC
LIMIT 10;
```

---

## Retention Policy

**Recommendation**: Retain quarantine records for:
- **Minimum**: 90 days (for analysis)
- **Optimal**: 1 year (for trend analysis)
- **Long-term**: Archive to cold storage after 1 year

**Purge Logic**:
```sql
-- Archive and delete records older than 1 year
DELETE FROM quarantine.customer_profile_rejected
WHERE 
    rejected_at < CURRENT_DATE - INTERVAL '1 year'
    AND reprocessing_status IN ('CORRECTED', 'IGNORED');
```

---

## Common Rejection Reasons

### Enumeration Validation Failures
- Invalid enumeration codes
- NULL where not allowed
- Typos in codes

### Data Type Mismatches
- String in numeric field
- Invalid date formats
- Exceeds field length

### Business Rule Violations
- Invalid date ranges
- Required field NULL
- Referential integrity failures

---

## Monitoring and Alerts

### Alert Thresholds

**High Priority**:
- Rejection rate > 5% of total records
- New rejection pattern not seen before
- Critical entity (e.g., customer) rejections

**Medium Priority**:
- Rejection rate 1-5%
- Known rejection patterns increasing

**Low Priority**:
- Rejection rate < 1%
- Isolated occurrences

---

## Related Documentation

- **Parent**: `/db/README.md`
- **Contracts**: `/contracts/quarantine/README.md`
- **Data Quality Framework**: `docs/data-quality/framework.md`
- **Silver Validation**: `/db/silver/README.md`

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Quality Team

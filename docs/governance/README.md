# Data Governance and Quality Framework

## Overview
This document establishes the framework for data governance, quality management, security, and compliance in the data warehouse.

## Data Governance

### Governance Organization

```
┌─────────────────────────────────────┐
│   Data Governance Council           │
│   (Executive Oversight)             │
└─────────────┬───────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼────────┐   ┌─────▼──────────┐
│  Data      │   │  Data          │
│  Owners    │   │  Stewards      │
└───┬────────┘   └─────┬──────────┘
    │                  │
    └─────────┬────────┘
              │
    ┌─────────▼──────────┐
    │  Data Consumers    │
    │  (Analysts, BI)    │
    └────────────────────┘
```

### Roles and Responsibilities

#### Data Governance Council
- Set governance policies and standards
- Approve major data initiatives
- Resolve cross-functional data issues
- Monitor governance metrics

#### Data Owners
- Business accountability for data domains
- Define business rules and definitions
- Approve access requests
- Review data quality reports

#### Data Stewards
- Implement governance policies
- Maintain data quality
- Document data lineage
- Coordinate with IT and business

#### Data Consumers
- Follow data usage policies
- Report data quality issues
- Provide feedback on data needs
- Adhere to security guidelines

## Data Quality Framework

### Six Dimensions of Data Quality

#### 1. Accuracy
**Definition**: Data correctly represents the real-world entity

**Metrics**:
```sql
-- Accuracy score example
SELECT 
    'customer_email' as field,
    COUNT(*) as total_records,
    SUM(CASE WHEN email_validated = TRUE THEN 1 ELSE 0 END) as accurate_records,
    ROUND(100.0 * SUM(CASE WHEN email_validated = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) as accuracy_percentage
FROM dim_customer;
```

**Validation Rules**:
- Format validation (email, phone, SSN)
- Range checks (dates, amounts)
- Reference data validation
- Cross-field validation

#### 2. Completeness
**Definition**: All required data is present

**Metrics**:
```sql
-- Completeness check
SELECT 
    table_name,
    column_name,
    COUNT(*) as total_rows,
    COUNT(column_name) as non_null_rows,
    COUNT(*) - COUNT(column_name) as null_rows,
    ROUND(100.0 * COUNT(column_name) / COUNT(*), 2) as completeness_pct
FROM information_schema.columns c
JOIN table_data t ON c.table_name = t.table_name
WHERE c.is_nullable = 'NO'
GROUP BY table_name, column_name;
```

**Rules**:
- Mandatory fields populated
- Required relationships exist
- No unexpected nulls
- Complete record sets

#### 3. Consistency
**Definition**: Data is consistent across systems and time

**Metrics**:
```sql
-- Consistency check across sources
SELECT 
    customer_id,
    COUNT(DISTINCT customer_name) as name_variations,
    COUNT(DISTINCT email) as email_variations
FROM (
    SELECT customer_id, customer_name, email FROM source_system_1
    UNION ALL
    SELECT customer_id, customer_name, email FROM source_system_2
) combined
GROUP BY customer_id
HAVING COUNT(DISTINCT customer_name) > 1
   OR COUNT(DISTINCT email) > 1;
```

**Rules**:
- Same values across systems
- Consistent naming conventions
- Uniform data formats
- Referential integrity maintained

#### 4. Timeliness
**Definition**: Data is current and available when needed

**Metrics**:
```sql
-- Timeliness monitoring
SELECT 
    table_name,
    MAX(updated_timestamp) as last_update,
    DATEDIFF(hour, MAX(updated_timestamp), CURRENT_TIMESTAMP) as hours_since_update,
    CASE 
        WHEN DATEDIFF(hour, MAX(updated_timestamp), CURRENT_TIMESTAMP) > 24 THEN 'STALE'
        WHEN DATEDIFF(hour, MAX(updated_timestamp), CURRENT_TIMESTAMP) > 12 THEN 'WARNING'
        ELSE 'CURRENT'
    END as freshness_status
FROM data_catalog
GROUP BY table_name;
```

**Rules**:
- Data loaded within SLA
- Refresh frequency met
- Historical data available
- Real-time data latency acceptable

#### 5. Validity
**Definition**: Data conforms to defined formats and rules

**Metrics**:
```sql
-- Validity checks
SELECT 
    'Invalid email format' as check_name,
    COUNT(*) as invalid_count
FROM dim_customer
WHERE email NOT LIKE '%@%.%'

UNION ALL

SELECT 
    'Invalid date range' as check_name,
    COUNT(*) as invalid_count
FROM fact_sales
WHERE order_date > CURRENT_DATE
   OR order_date < '2000-01-01';
```

**Rules**:
- Format compliance
- Domain value validation
- Data type conformance
- Business rule adherence

#### 6. Uniqueness
**Definition**: No unwanted duplicates exist

**Metrics**:
```sql
-- Duplicate detection
SELECT 
    customer_id,
    COUNT(*) as duplicate_count
FROM dim_customer
WHERE is_current = TRUE
GROUP BY customer_id
HAVING COUNT(*) > 1;
```

**Rules**:
- Primary keys unique
- No duplicate records
- Natural keys unique where required
- Proper deduplication logic

## Data Quality Monitoring

### Quality Scorecards

```sql
-- Overall data quality score
CREATE VIEW vw_data_quality_scorecard AS
SELECT 
    table_name,
    ROUND(AVG(accuracy_score), 2) as accuracy,
    ROUND(AVG(completeness_score), 2) as completeness,
    ROUND(AVG(consistency_score), 2) as consistency,
    ROUND(AVG(timeliness_score), 2) as timeliness,
    ROUND(AVG(validity_score), 2) as validity,
    ROUND(AVG(uniqueness_score), 2) as uniqueness,
    ROUND(AVG((accuracy_score + completeness_score + consistency_score + 
               timeliness_score + validity_score + uniqueness_score) / 6), 2) as overall_score
FROM data_quality_metrics
GROUP BY table_name;
```

### Automated Quality Checks

```python
# Data quality check framework
class DataQualityChecker:
    def __init__(self, table_name, rules):
        self.table_name = table_name
        self.rules = rules
        
    def run_checks(self):
        results = []
        for rule in self.rules:
            result = self.execute_rule(rule)
            results.append(result)
            
            if result['status'] == 'FAIL':
                self.log_failure(rule, result)
                self.send_alert(rule, result)
        
        return self.generate_report(results)
    
    def execute_rule(self, rule):
        # Execute SQL check
        count = execute_query(rule['sql'])
        
        return {
            'rule_name': rule['name'],
            'failed_records': count,
            'status': 'PASS' if count == 0 else 'FAIL',
            'severity': rule['severity'],
            'timestamp': datetime.now()
        }

# Example usage
rules = [
    {
        'name': 'null_check_customer_email',
        'sql': 'SELECT COUNT(*) FROM dim_customer WHERE email IS NULL',
        'severity': 'HIGH'
    },
    {
        'name': 'future_date_check',
        'sql': 'SELECT COUNT(*) FROM fact_sales WHERE order_date > CURRENT_DATE',
        'severity': 'CRITICAL'
    }
]

checker = DataQualityChecker('fact_sales', rules)
results = checker.run_checks()
```

## Data Lineage

### Lineage Tracking

```sql
-- Data lineage metadata table
CREATE TABLE metadata.data_lineage (
    lineage_id BIGINT PRIMARY KEY,
    source_table VARCHAR(255),
    source_column VARCHAR(255),
    target_table VARCHAR(255),
    target_column VARCHAR(255),
    transformation_logic TEXT,
    transformation_type VARCHAR(50), -- DIRECT, DERIVED, AGGREGATED
    created_date TIMESTAMP,
    created_by VARCHAR(100)
);

-- Example lineage records
INSERT INTO metadata.data_lineage VALUES
(1, 'source.orders', 'customer_id', 'dim_customer', 'customer_id', 'DIRECT MAPPING', 'DIRECT', CURRENT_TIMESTAMP, 'ETL_PROCESS'),
(2, 'source.orders', 'order_total', 'fact_sales', 'total_amount', 'SUM(order_total)', 'AGGREGATED', CURRENT_TIMESTAMP, 'ETL_PROCESS'),
(3, 'fact_sales', 'total_amount', 'summary.daily_sales', 'total_revenue', 'SUM(total_amount) GROUP BY date', 'AGGREGATED', CURRENT_TIMESTAMP, 'ETL_PROCESS');
```

### Impact Analysis

```sql
-- Find downstream dependencies
WITH RECURSIVE lineage_tree AS (
    -- Anchor: Start with specified table
    SELECT 
        source_table,
        target_table,
        1 as level
    FROM metadata.data_lineage
    WHERE source_table = 'dim_customer'
    
    UNION ALL
    
    -- Recursive: Find next level dependencies
    SELECT 
        dl.source_table,
        dl.target_table,
        lt.level + 1
    FROM metadata.data_lineage dl
    JOIN lineage_tree lt ON dl.source_table = lt.target_table
    WHERE lt.level < 10  -- Prevent infinite recursion
)
SELECT DISTINCT
    target_table,
    MAX(level) as dependency_level
FROM lineage_tree
GROUP BY target_table
ORDER BY dependency_level;
```

## Data Security

### Access Control

```sql
-- Role-based access control
CREATE TABLE metadata.data_access_control (
    access_id BIGINT PRIMARY KEY,
    role_name VARCHAR(100),
    object_type VARCHAR(50), -- TABLE, VIEW, SCHEMA
    object_name VARCHAR(255),
    access_level VARCHAR(50), -- READ, WRITE, ADMIN
    granted_date TIMESTAMP,
    granted_by VARCHAR(100),
    expiry_date TIMESTAMP
);

-- Row-level security example (PostgreSQL)
CREATE POLICY sales_region_policy ON fact_sales
    FOR SELECT
    USING (region_id IN (
        SELECT region_id 
        FROM user_regions 
        WHERE user_name = current_user
    ));
```

### Data Masking

```sql
-- Dynamic data masking
CREATE VIEW vw_customer_masked AS
SELECT 
    customer_id,
    customer_name,
    -- Mask email
    CONCAT(
        SUBSTRING(email, 1, 2),
        '***@',
        SUBSTRING(email, POSITION('@' IN email) + 1)
    ) as email_masked,
    -- Mask phone (show last 4 digits)
    CONCAT('***-***-', RIGHT(phone, 4)) as phone_masked,
    -- Mask SSN (show last 4 digits)
    CONCAT('***-**-', RIGHT(ssn, 4)) as ssn_masked,
    -- Full address for authorized users only
    CASE 
        WHEN current_user IN (SELECT user_name FROM authorized_users) 
        THEN address 
        ELSE 'REDACTED' 
    END as address
FROM dim_customer;
```

### Encryption

```sql
-- Column-level encryption (example)
CREATE TABLE sensitive_data (
    id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    ssn_encrypted VARBINARY(256),  -- Encrypted column
    credit_card_encrypted VARBINARY(256),
    created_timestamp TIMESTAMP
);

-- Encryption/Decryption functions (pseudocode)
-- INSERT: INSERT INTO sensitive_data VALUES (1, 100, ENCRYPT('123-45-6789'), ...)
-- SELECT: SELECT id, DECRYPT(ssn_encrypted) as ssn FROM sensitive_data WHERE id = 1
```

## Compliance and Auditing

### Audit Trail

```sql
-- Audit log table
CREATE TABLE metadata.audit_log (
    audit_id BIGINT PRIMARY KEY,
    user_name VARCHAR(100),
    action_type VARCHAR(50), -- SELECT, INSERT, UPDATE, DELETE
    object_type VARCHAR(50),
    object_name VARCHAR(255),
    action_timestamp TIMESTAMP,
    ip_address VARCHAR(50),
    query_text TEXT,
    rows_affected INTEGER,
    status VARCHAR(20) -- SUCCESS, FAILED
);

-- Trigger for audit logging (example)
CREATE TRIGGER audit_customer_changes
AFTER UPDATE ON dim_customer
FOR EACH ROW
INSERT INTO metadata.audit_log (
    user_name, action_type, object_type, object_name, 
    action_timestamp, rows_affected, status
) VALUES (
    CURRENT_USER, 'UPDATE', 'TABLE', 'dim_customer',
    CURRENT_TIMESTAMP, 1, 'SUCCESS'
);
```

### Compliance Monitoring

```sql
-- GDPR compliance - Data retention check
SELECT 
    customer_id,
    created_date,
    DATEDIFF(year, created_date, CURRENT_DATE) as years_retained,
    CASE 
        WHEN DATEDIFF(year, created_date, CURRENT_DATE) > 7 
        THEN 'REVIEW_FOR_DELETION'
        ELSE 'COMPLIANT'
    END as retention_status
FROM dim_customer
WHERE is_active = FALSE;

-- PCI compliance - Credit card data check
SELECT 
    table_name,
    column_name
FROM information_schema.columns
WHERE column_name LIKE '%credit_card%'
   OR column_name LIKE '%card_number%'
   OR column_name LIKE '%cvv%';
```

## AI-Assisted Governance

### Automated Classification
- **Sensitive Data Detection**: ML identifies PII, PHI, financial data
- **Data Cataloging**: AI auto-tags and categorizes data assets
- **Metadata Enrichment**: NLP generates business descriptions

### Intelligent Monitoring
- **Anomaly Detection**: ML identifies unusual access patterns
- **Quality Prediction**: AI predicts quality issues before they occur
- **Compliance Alerts**: Automated compliance violation detection

### Smart Recommendations
- **Access Control Optimization**: AI suggests optimal permissions
- **Retention Policy**: ML recommends data retention policies
- **Data Archival**: Intelligent data archiving recommendations

## Best Practices

1. **Establish Clear Ownership**: Every data asset has an owner
2. **Document Everything**: Maintain comprehensive metadata
3. **Automate Quality Checks**: Continuous monitoring and validation
4. **Implement Access Controls**: Principle of least privilege
5. **Track Data Lineage**: End-to-end visibility
6. **Regular Audits**: Periodic governance and compliance reviews
7. **Training and Awareness**: Educate users on policies
8. **Incident Response**: Clear procedures for data issues
9. **Version Control**: Track all policy and rule changes
10. **Continuous Improvement**: Regular review and updates

## Metrics and KPIs

### Governance Metrics
- Data quality score by domain
- Policy compliance rate
- Access request fulfillment time
- Number of data incidents
- Audit finding resolution time

### Quality Metrics
- Overall data quality score
- Error rate by source system
- Data freshness by table
- Duplicate record count
- Failed validation checks

### Security Metrics
- Unauthorized access attempts
- Data breach incidents
- Encryption coverage percentage
- Access review completion rate
- Privilege escalation requests

## Next Steps
1. Review metadata management in `/docs/metadata/`
2. Explore AI methodology in `/docs/ai-methodology/`
3. Check layer documentation in `/docs/layers/`
4. Use templates from `/templates/` for governance artifacts

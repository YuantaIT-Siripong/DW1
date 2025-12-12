# Raw Data Folder

**Purpose**: Sample raw data files for local testing and development

---

## Overview

This folder contains sample data files used during development and testing. It is **NOT part of the replication pattern** and is **optional** for new modules.

---

## Contents

### CustomerProfile.txt

- **Purpose**: Sample customer profile source data in delimited text format
- **Format**: Pipe-delimited (|) text file
- **Use Case**: Testing Bronze layer ETL extraction
- **Pattern Role**: OPTIONAL - for local testing only
- **Size**: Sample data (small subset)

**Usage**:
```bash
# Test Bronze extraction with sample data
python etl/bronze_extract_customer_profile.py --input raw/CustomerProfile.txt
```

---

### 4_Metadata.xlsx

- **Purpose**: Metadata documentation spreadsheet
- **Format**: Excel workbook
- **Contents**: 
  - Data dictionary
  - Source system mappings
  - Field definitions
  - Business rules
- **Use Case**: Reference during development, eventually should be migrated to formal documentation
- **Pattern Role**: OPTIONAL - supplementary documentation

---

## Pattern Role

**This folder is OPTIONAL and NOT required for module replication.**

### ✅ Use the raw/ folder for:

- Local testing of ETL scripts
- Sample data for demonstrations
- Data exploration during development
- Quick prototyping

### ❌ Do NOT use the raw/ folder for:

- Production data storage (use Bronze layer instead)
- Part of the replication pattern (not needed for new modules)
- Required module artifacts
- Documentation (use `/docs/` folder instead)

---

## For New Modules

**Question**: Should I create a `/raw/` folder for my new module?

**Answer**: **NO** - unless you need local sample data for testing.

The `/raw/` folder is not part of the standard module pattern. Your module should:

1. ✅ Define Bronze layer contract in `/contracts/bronze/`
2. ✅ Create Bronze DDL in `/db/bronze/`
3. ✅ Implement ETL to load Bronze from source system directly
4. ❌ Skip `/raw/` folder unless you need local test data

---

## Data Flow

```
Production Flow (Standard):
┌─────────────────┐
│ IT Operational  │
│ Database        │
└────────┬────────┘
         │
         ↓ ETL Script
┌─────────────────┐
│ Bronze Layer    │
│ (DW Database)   │
└─────────────────┘

Development/Testing Flow (Optional):
┌─────────────────┐
│ /raw/ folder    │  ← Sample data for local testing only
│ (Local Files)   │
└────────┬────────┘
         │
         ↓ Test ETL
┌─────────────────┐
│ Bronze Layer    │
│ (Test Database) │
└─────────────────┘
```

---

## Best Practices

### ✅ DO:

- Use raw/ for small sample datasets (< 10MB)
- Anonymize/mask any sensitive data
- Document file formats and structures
- Version control sample data files (if small)
- Clean up unused files regularly

### ❌ DON'T:

- Store production data in raw/ (security risk)
- Commit large files (use .gitignore)
- Rely on raw/ for automated processes
- Reference raw/ in production code
- Use as long-term data storage

---

## Alternative Approaches

Instead of using `/raw/` folder, consider:

1. **dbt Seeds** (`/seeds/`) - For static reference data that loads into database tables
2. **Test Fixtures** - In test frameworks for unit/integration testing  
3. **Sample Data Generation** - Generate synthetic data programmatically
4. **Database Snapshots** - Use database backup/restore for test environments

---

## Maintenance

- Review raw/ contents quarterly
- Remove obsolete files
- Update sample data to reflect current schema
- Ensure no sensitive data is present
- Keep file sizes small (< 1MB each)

---

## Pattern Decision

**Why is raw/ optional?**

The Bronze layer already serves as the raw data landing zone. The `/raw/` folder only exists for:
- Local development without database access
- Quick prototyping and exploration
- Sample data for demonstrations

In production and for module replication, **data flows directly from source systems to Bronze layer**, bypassing any local file storage.

---

## See Also

- **Bronze Layer**: `/db/bronze/` - Production raw data landing zone
- **Seeds**: `/seeds/` - Static reference data loaded via dbt
- **ETL Scripts**: `/etl/` - Extraction scripts from source systems
- **Test Data**: Consider test fixtures in test frameworks instead

---

**Last Updated**: 2025-12-12  
**Pattern Role**: OPTIONAL (not required for module replication)  
**Use Case**: Local testing and development only

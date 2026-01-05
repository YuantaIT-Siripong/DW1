# Raw Data Samples Directory

**Purpose**: Sample source data files for development, testing, and documentation  
**Owner**: Data Engineering Team  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains **sample data files** from source systems. These files are used for:
- Understanding source data structure
- Development and testing
- Documentation of source system formats
- Creating test fixtures

**⚠️ IMPORTANT**: Files in this directory are **SAMPLES ONLY** and may contain synthetic or anonymized data. They are NOT production data dumps.

---

## Files Inventory

### CustomerProfile.txt

**Type**: Text Data Sample  
**Source**: IT Operational Database (MSSQL)  
**Purpose**: Sample customer profile data showing source system structure  
**Format**: Text file (likely tab-delimited or pipe-delimited)

**Contains**:
- Sample customer profile records
- Demonstrates IT view structure as defined in `docs/business/modules/customer_module.md` Section 18
- Shows data types, formats, and encoding used by source system

**Used By**:
- Python ETL development (`etl/bronze_extract_customer_profile.py`)
- Testing Bronze extraction logic
- Validating data mappings in Bronze contract

**Data Classification**: 
- May contain PII (likely anonymized)
- DO NOT commit actual production data

### 4_Metadata.xlsx

**Type**: Excel Spreadsheet  
**Source**: Business Analysts / Data Governance  
**Purpose**: Metadata documentation, business glossary, or data dictionary

**Likely Contains**:
- Business definitions of fields
- Data lineage information
- Business rules and validation rules
- Mapping tables
- Enumeration definitions (pre-YAML migration)

**Used By**:
- Documentation creation
- Contract development
- Business requirement validation

**Data Classification**: Non-PII metadata

---

## Usage Guidelines

### For Developers

When using raw data samples:

1. **DO NOT assume samples are complete** - They are representative, not exhaustive
2. **Verify against source system documentation** - Samples may be outdated
3. **Test with edge cases** - Samples may not cover all scenarios
4. **DO NOT commit sensitive data** - Use anonymized or synthetic data only

### For Creating New Samples

When adding new data samples:

1. **Anonymize all PII** - Replace real names, IDs, addresses with fake data
2. **Keep samples small** - 10-100 rows maximum
3. **Document the format** - Add description in this README
4. **Add to .gitignore if large** - Keep repository lean
5. **Name descriptively** - `{entity}_{source}_{format}.{ext}`

### Example Naming:
```
customer_profile_mssql_sample.txt
product_catalog_api_sample.json
transaction_feed_csv_sample.csv
```

---

## File Format Documentation

### CustomerProfile.txt Format

**Encoding**: UTF-8  
**Delimiter**: [To be documented]  
**Header Row**: [Yes/No - to be documented]  
**Date Format**: [YYYY-MM-DD or other - to be documented]

**Sample Structure**:
```
[Document actual structure based on file inspection]
```

### 4_Metadata.xlsx Format

**Sheets**:
- [Document sheet names and purposes]

**Columns**:
- [Document key columns and their meanings]

---

## Relationship to Other Artifacts

### CustomerProfile.txt → Bronze Layer
```
raw/CustomerProfile.txt (sample)
  → etl/bronze_extract_customer_profile.py (extraction logic)
  → db/bronze/customer_profile_standardized.sql (landing table DDL)
  → contracts/bronze/customer_profile_standardized.yaml (specification)
```

### 4_Metadata.xlsx → Documentation
```
raw/4_Metadata.xlsx (source metadata)
  → docs/business/glossary.md (business terms)
  → contracts/*.yaml (attribute definitions)
  → docs/business/modules/*.md (module specifications)
```

---

## Data Privacy and Security

### PII Handling

**RULE**: This directory MUST NOT contain actual production PII.

**Allowed**:
- ✅ Synthetic data (faker-generated)
- ✅ Anonymized data (PII removed/masked)
- ✅ Public domain data
- ✅ Minimal examples (< 10 rows, clearly fake)

**PROHIBITED**:
- ❌ Production database dumps
- ❌ Real customer names, IDs, addresses
- ❌ Actual financial data
- ❌ Unmasked PII

### If Sensitive Data Needed

If you need real data structure but can't anonymize:
1. Use `db/source_system/create_it_view_sample.sql` to create synthetic IT view
2. Generate synthetic data with Python Faker library
3. Document structure in contracts without including actual data

---

## Maintenance

### Updating Samples

When source system format changes:
1. Update corresponding sample file
2. Document change in this README
3. Update related contracts and DDL
4. Notify team of format change

### Archive Policy

Samples older than 1 year should be:
1. Reviewed for relevance
2. Updated or archived
3. Documented if deprecated

---

## Adding New Sample Files

**Checklist** before adding new samples:

- [ ] File is anonymized (no real PII)
- [ ] File size < 1MB (use git LFS if larger)
- [ ] File name follows naming convention
- [ ] Purpose documented in this README
- [ ] Format documented
- [ ] Relationship to other artifacts documented
- [ ] Added to REPOSITORY_FILE_INDEX.md

---

## Related Documentation

- `etl/README.md` - ETL process documentation
- `docs/business/modules/customer_module.md` - Section 18 (IT View Specification)
- `contracts/bronze/` - Bronze layer contracts (mirror source structure)
- `REPOSITORY_FILE_INDEX.md` - Complete file inventory

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Engineering Team

**Questions?** Contact Data Engineering Team for:
- Source system access
- Data format clarifications
- Anonymization assistance
- Sample data generation

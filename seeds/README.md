# Seeds: Reference Data

**Purpose**: Seeds contain small, static lookup tables loaded via `dbt seed` command.

## Overview

Seeds provide reference data for foreign key relationships and enable human-readable descriptions in analytical queries. They are part of the replicable pattern for modules that require static lookup tables.

## Seeds vs Enumerations

| Aspect | Seeds (CSV) | Enumerations (YAML) |
|--------|-------------|---------------------|
| **Use Case** | Separate lookup tables with FK relationships | Inline codes stored directly in dimensions |
| **Storage** | Separate dimensional tables | VARCHAR columns in main dimensions |
| **Attributes** | Multiple columns (code, name, description, etc.) | Single code field |
| **Example** | dim_industry (code, name, sector, subsector) | marital_status = "MARRIED" |
| **Loading** | `dbt seed` command | Validated via macros in dbt models |
| **When to Use** | Need full dimensional table | Simple categorical attributes |

## Files

### dim_funding_source.csv

- **Purpose**: Company funding source classification
- **Used in**: Company Profile module
- **Columns**: 
  - `funding_source_code`: Unique identifier (VARCHAR)
  - `name_en`: English display name
  - `description`: Detailed explanation
- **Row Count**: ~5 rows
- **Examples**: EQUITY, DEBT, GRANT, INTERNAL, HYBRID

**Usage**:
```sql
SELECT
    c.company_id,
    f.name_en as funding_source_name
FROM gold.dim_company c
LEFT JOIN seeds.dim_funding_source f 
    ON c.funding_source_code = f.funding_source_code
```

---

### dim_industry.csv

- **Purpose**: Industry classification codes (based on GICS or custom taxonomy)
- **Used in**: Company Profile module
- **Columns**:
  - `industry_code`: Unique identifier (VARCHAR)
  - `name_en`: English industry name
  - `sector`: Sector grouping
  - `subsector`: Subsector classification (optional)
  - `description`: Industry description
- **Row Count**: ~10-50 rows
- **Examples**: FINANCE, TECHNOLOGY, MANUFACTURING, RETAIL, HEALTHCARE

**Usage**:
```sql
SELECT
    c.company_id,
    i.name_en as industry_name,
    i.sector as industry_sector
FROM gold.dim_company c
LEFT JOIN seeds.dim_industry i 
    ON c.industry_code = i.industry_code
```

---

### dim_investment_objective.csv

- **Purpose**: Investment objective types for company portfolios
- **Used in**: Investment Profile module, Company Profile module
- **Columns**:
  - `investment_objective_code`: Unique identifier (VARCHAR)
  - `name_en`: English display name
  - `strategic_flag`: Boolean indicating strategic vs tactical objective
  - `introduced_date`: Date objective was introduced
- **Row Count**: ~4-8 rows
- **Examples**: TREASURY_MANAGEMENT, STRATEGIC_ASSET_ALLOCATION, CASH_PRESERVATION, SPECULATIVE_GROWTH

**Usage**:
```sql
SELECT
    i.investment_profile_id,
    o.name_en as objective_name,
    o.strategic_flag
FROM gold.dim_investment_profile i
LEFT JOIN seeds.dim_investment_objective o 
    ON i.primary_objective_code = o.investment_objective_code
```

---

### dim_legal_form.csv

- **Purpose**: Legal entity form codes (company structure types)
- **Used in**: Company Profile module
- **Columns**:
  - `legal_form_code`: Unique identifier (VARCHAR)
  - `name_en`: English display name
  - `jurisdiction`: Typical jurisdiction where used
  - `description`: Legal form explanation
- **Row Count**: ~5-10 rows
- **Examples**: LLC, CORPORATION, PARTNERSHIP, SOLE_PROPRIETORSHIP, TRUST

**Usage**:
```sql
SELECT
    c.company_id,
    l.name_en as legal_form_name,
    l.jurisdiction
FROM gold.dim_company c
LEFT JOIN seeds.dim_legal_form l 
    ON c.legal_form_code = l.legal_form_code
```

---

## Loading Seeds

### Initial Load

```bash
# Load all seeds
dbt seed

# Load specific seed
dbt seed --select dim_industry
```

### Full Refresh (Truncate and Reload)

```bash
# Refresh all seeds
dbt seed --full-refresh

# Refresh specific seed
dbt seed --full-refresh --select dim_funding_source
```

### Update Seeds

1. Edit CSV file with changes
2. Run `dbt seed --full-refresh` to reload
3. Commit changes to version control

## dbt Project Configuration

Seeds are configured in `dbt_project.yml`:

```yaml
seed-paths: ["seeds"]

seeds:
  DW1:
    company:
      +schema: seeds
      +enabled: true
```

This creates seed tables in the `seeds` schema (e.g., `seeds.dim_industry`).

## Data Quality

Seeds should be validated using dbt tests in `dbt/seeds/schema.yml`:

```yaml
version: 2

seeds:
  - name: dim_industry
    description: Industry classification codes
    columns:
      - name: industry_code
        description: Unique industry code
        tests:
          - unique
          - not_null
```

## When to Create New Seeds

Create a new seed when:
- ✅ You need a lookup table with multiple descriptive attributes
- ✅ The data changes infrequently (quarterly or less)
- ✅ The table has < 1000 rows
- ✅ You need a dimensional table for foreign key relationships
- ✅ The data is shared across multiple modules

Use enumerations instead when:
- ❌ Simple codes stored inline in dimensions (e.g., marital_status)
- ❌ Only need code and description (no additional attributes)
- ❌ Validation happens in-flight (not via FK)

## Pattern Role for Module Replication

**Seeds are OPTIONAL** for new modules. Use seeds only if:
1. Your module requires FK lookup tables (like Company Profile)
2. The lookup table has multiple columns beyond code/name
3. The data is static/slow-changing reference data

**Customer Profile module does NOT use seeds** - it uses enumerations instead. This is the preferred pattern for simple categorical attributes.

**Company Profile module DOES use seeds** - it needs full dimensional lookup tables for industry, legal form, etc.

**Investment Profile module MAY use seeds** - for investment objectives if they have multiple attributes.

## Maintenance

- Review seeds quarterly for accuracy
- Version control all changes
- Document any additions in this README
- Add dbt tests for data quality
- Consider migrating to database tables if seeds grow > 1000 rows

---

**Last Updated**: 2025-12-12  
**Maintained By**: Data Architecture Team

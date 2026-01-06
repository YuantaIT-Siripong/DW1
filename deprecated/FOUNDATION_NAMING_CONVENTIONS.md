# Foundation: File and Folder Naming Conventions

**Version**: 1.0  
**Date**: 2025-12-12  
**Status**: Authoritative  
**Purpose**: Define comprehensive naming conventions for all files and folders in the DW1 repository

---

## Table of Contents
1. [Overview](#overview)
2. [Folder Structure Standards](#folder-structure-standards)
3. [File Naming Conventions](#file-naming-conventions)
4. [Layer-Specific Conventions](#layer-specific-conventions)
5. [Documentation Standards](#documentation-standards)
6. [Validation Rules](#validation-rules)

---

## Overview

This document establishes the authoritative naming standards for all files and folders in the DW1 Data Warehouse repository. These conventions ensure:

- **Consistency**: Predictable structure across the entire repository
- **Discoverability**: Easy location of files and resources
- **Maintainability**: Clear organization for long-term maintenance
- **AI-Assisted Development**: Structured patterns for automated tooling
- **Team Collaboration**: Shared understanding of repository organization

### Guiding Principles

1. **snake_case for files**: All code and data files use lowercase with underscores
2. **Hierarchical organization**: Group related files by layer, then by entity/module
3. **Descriptive names**: Names should clearly indicate purpose and content
4. **Consistent prefixes**: Use standard prefixes to indicate file types
5. **No spaces or special characters**: Use only alphanumeric characters, underscores, and hyphens

---

## Folder Structure Standards

### Top-Level Directories

```
DW1/
├── contracts/          # Data contracts (YAML specifications)
├── db/                 # DDL scripts (database table definitions)
├── dbt/                # dbt transformations (Silver → Gold)
├── docs/               # Documentation
├── enumerations/       # Enumeration value definitions (YAML)
├── etl/                # Python ETL scripts (Source → Bronze)
├── examples/           # Example implementations and patterns
├── raw/                # Raw data samples (for development/testing)
├── seeds/              # Static reference data (dbt seeds)
└── templates/          # Reusable templates for tables, models, etc.
```

#### Directory Naming Rules

- **Format**: `lowercase_with_underscores` or `single_word`
- **Plurality**: Use **singular** form (e.g., `template` not `templates`, exception: `docs`, `examples`)
- **Descriptive**: Name should indicate the category of contents
- **No abbreviations**: Avoid unclear abbreviations (e.g., use `enumeration` not `enum`)

### Layer Directories

Each data layer has three parallel structures:

```
db/
├── bronze/          # Bronze layer DDL
├── silver/          # Silver layer DDL
├── gold/            # Gold layer DDL
├── quarantine/      # Quarantine layer DDL
└── deprecated/      # Deprecated/legacy DDL

dbt/models/
├── bronze/          # Bronze dbt source definitions
├── silver/          # Silver dbt transformations
├── gold/            # Gold dbt transformations
└── quarantine/      # Quarantine dbt models

contracts/
├── bronze/          # Bronze layer contracts
├── silver/          # Silver layer contracts
├── gold/            # Gold layer contracts
└── deprecate/       # Deprecated contracts
```

#### Layer Directory Rules

- **Mandatory layers**: `bronze`, `silver`, `gold`, `quarantine`
- **Naming**: Must match **Medallion Architecture** terminology
- **No "curated"**: Use `gold` instead (see deprecation policy)
- **Deprecated files**: Move to `deprecated/` or `deprecate/` subdirectory

### Documentation Directories

```
docs/
├── adr/                     # Architectural Decision Records
├── ai-methodology/          # AI-assisted development guidelines
├── architecture/            # Architecture documentation
├── audit/                   # Audit trail documentation
├── business/                # Business domain documentation
│   ├── matrices/            # Decision matrices
│   └── modules/             # Module specifications
├── data-modeling/           # Data modeling standards
├── data-quality/            # Data quality framework
├── etl-elt/                 # ETL/ELT documentation
├── governance/              # Data governance policies
├── layers/                  # Layer-specific documentation
├── metadata/                # Metadata management
└── migrations/              # Migration guides
```

#### Documentation Directory Rules

- **Purpose-driven**: Each subdirectory represents a documentation category
- **Hierarchical depth**: Maximum 3 levels deep
- **README files**: Each directory should have a `README.md`
- **Related content**: Group related documents in subdirectories

---

## File Naming Conventions

### General Rules

| File Type | Pattern | Example |
|-----------|---------|---------|
| **Markdown Documentation** | `TOPIC_NAME.md` or `topic_name.md` | `README.md`, `naming_conventions.md` |
| **SQL DDL Scripts** | `<entity_name>.sql` | `dim_customer_profile.sql` |
| **SQL dbt Models** | `<entity_name>.sql` | `dim_customer_profile.sql` |
| **Python Scripts** | `<purpose>_<entity>.py` | `bronze_extract_customer_profile.py` |
| **YAML Contracts** | `<entity_name>.yaml` | `dim_customer_profile.yaml` |
| **YAML Enumerations** | `<domain>_<entity>.yaml` | `customer_marital_status.yaml` |
| **Templates** | `<type>_template.sql` | `dimension_table_template.sql` |

### Markdown Documentation Files

#### Policy/Standard Documents (UPPERCASE)

Use **UPPERCASE** for authoritative, repository-wide documents:

```
README.md
STANDARDS_INDEX.md
AI_CONTEXT.md
WORKFLOW.md
FOUNDATION_NAMING_CONVENTIONS.md
CHANGES_SUMMARY.md
```

**Rule**: Documents that are:
- Repository-level (apply to entire codebase)
- Authoritative policies or standards
- Frequently referenced anchor documents

#### Regular Documentation (snake_case)

Use **snake_case** for specific topic documentation:

```
naming_conventions.md
hashing_standards.md
fact_vs_dimension_decisions.md
enumeration_standards.md
```

**Rule**: Documents that are:
- Topic-specific or domain-specific
- Technical guides or specifications
- Sub-section documentation

#### Architectural Decision Records (ADR-NNN)

```
ADR-001-scd2-customer-profile.md
ADR-002-multi-valued-sets.md
ADR-INV-001-investment-profile.md
```

**Pattern**: `ADR-<number>-<kebab-case-title>.md`

### SQL Files

#### Database DDL Scripts (db/ folder)

```
# Dimension tables
dim_customer_profile.sql
dim_investment_profile_version.sql

# Fact tables
fact_customer_profile_audit.sql
fact_service_request.sql

# Bridge tables
bridge_customer_source_of_income.sql
bridge_customer_purpose_of_investment.sql

# Views
vw_customer_current_profile.sql
```

**Pattern**: `<table_name>.sql`  
**Rule**: Matches the exact database table name (snake_case)

#### dbt Model Files (dbt/models/ folder)

```
# Same pattern as DDL
customer_profile_standardized.sql
dim_customer_profile.sql
fact_customer_profile_audit.sql
```

**Pattern**: `<model_name>.sql`  
**Rule**: Matches the target table/model name

#### Migration Scripts (if numbered)

```
001_create_dim_customer_profile.sql
002_create_fact_customer_profile_audit.sql
010_alter_add_column_risk_score.sql
```

**Pattern**: `<sequence>_<action>_<subject>.sql`  
**Rule**: Three-digit sequence for ordering

### Python Files

```
# ETL scripts
bronze_extract_customer_profile.py
bronze_extract_investment_profile.py

# Utility scripts
generate_hash.py
validate_contracts.py
data_quality_checker.py
```

**Pattern**: `<purpose>_<entity_or_action>.py`  
**Rule**: Verb or purpose first, then noun/entity

### YAML Files

#### Contracts (contracts/ folder)

```
# Match table names exactly
dim_customer_profile.yaml
fact_customer_profile_audit.yaml
bridge_customer_source_of_income.yaml
customer_profile_standardized.yaml
```

**Pattern**: `<table_name>.yaml`

#### Enumerations (enumerations/ folder)

```
customer_marital_status.yaml
customer_education_level.yaml
customer_occupation.yaml
investment_risk_level.yaml
customer_profile_audit_change_reason.yaml
customer_profile_attribute_names.yaml
```

**Pattern**: `<domain>_<entity>_<attribute>.yaml`  
**Rule**: Use full descriptive names

#### dbt Configuration

```
dbt_project.yml
profiles.yml
packages.yml
```

**Pattern**: `<name>.yml` (note: `.yml` extension for dbt)

### Template Files

```
dimension_table_template.sql
fact_table_template.sql
bridge_table_template.sql
scd2_dbt_template.sql
```

**Pattern**: `<type>_template.sql`

---

## Layer-Specific Conventions

### Bronze Layer

**Purpose**: Raw data landing from source systems

#### File Organization

```
db/bronze/
├── customer_profile_standardized.sql
├── investment_profile_standardized.sql
└── insert_test_bad_data.sql

dbt/models/bronze/
└── sources.yml                    # Source definitions only

etl/
├── bronze_extract_customer_profile.py
├── bronze_extract_investment_profile.py
└── requirements.txt

contracts/bronze/
├── customer_profile_standardized.yaml
└── investment_profile_standardized.yaml
```

#### Naming Rules

- **DDL files**: Match source view name with `_standardized` suffix
- **ETL scripts**: Prefix with `bronze_extract_`
- **Contracts**: Match table name exactly

### Silver Layer

**Purpose**: Cleaned, validated, and hash-computed data

#### File Organization

```
db/silver/
├── customer_profile_standardized.sql
└── investment_profile_standardized.sql

dbt/models/silver/
├── customer_profile_standardized.sql
├── investment_profile_standardized.sql
└── schema.yml                      # Model tests and documentation

contracts/silver/
├── customer_profile_standardized.yaml
└── investment_profile_standardized.yaml
```

#### Naming Rules

- **Same name** across Bronze and Silver for clarity
- **Suffix**: Use `_standardized` to indicate cleaned state
- **Transformations**: No intermediate tables visible to consumers

### Gold Layer

**Purpose**: Dimensional model (SCD2 dimensions, facts, bridges)

#### File Organization

```
db/gold/
├── dim_customer_profile.sql
├── dim_investment_profile_version.sql
├── fact_customer_profile_audit.sql
├── bridge_customer_source_of_income.sql
└── bridge_customer_purpose_of_investment.sql

dbt/models/gold/
├── dim_customer_profile.sql
├── dim_investment_profile_version.sql
├── fact_customer_profile_audit.sql
├── bridge_customer_source_of_income.sql
├── bridge_customer_purpose_of_investment.sql
└── schema.yml

contracts/gold/
├── dim_customer_profile.yaml
├── dim_investment_profile_version.yaml
├── fact_customer_profile_audit.yaml
├── bridge_customer_source_of_income.yaml
└── bridge_customer_purpose_of_investment.yaml
```

#### Naming Rules

- **Dimensions**: Prefix `dim_`
- **Facts**: Prefix `fact_`
- **Bridges**: Prefix `bridge_`
- **SCD2 versioned dimensions**: Suffix `_version` after entity name
  - Example: `dim_investment_profile_version`
  - **Not**: `dim_investment_profile_version_scd2`

### Quarantine Layer

**Purpose**: Data quality failures and rejected records

#### File Organization

```
db/quarantine/
├── customer_profile_quarantine.sql
└── investment_profile_quarantine.sql

dbt/models/quarantine/
├── customer_profile_rejected.sql
└── investment_profile_rejected.sql
```

#### Naming Rules

- **DDL**: Suffix `_quarantine`
- **dbt models**: Suffix `_rejected` or `_quarantine`

### Deprecated/Legacy Files

#### File Organization

```
db/deprecated/
├── dim/                    # Old dimension definitions
├── fact/                   # Old fact definitions
├── audit/                  # Old audit tables
├── views/                  # Old views
└── seeds/                  # Old seed data

contracts/deprecate/
├── customer/
├── investment/
├── audit/
└── scd2/
```

#### Naming Rules

- **Never delete**: Move deprecated files to `deprecated/` folder
- **Add marker**: Include `DEPRECATED.md` in folder explaining why
- **Preserve structure**: Keep original subfolder organization
- **No new files**: Never add files to deprecated folders

---

## Documentation Standards

### Module Documentation

```
docs/business/modules/
├── customer_module.md
├── investment_profile_module.md
└── company_module.md
```

**Pattern**: `<entity>_module.md`

### Standards Documentation

```
docs/data-modeling/
├── README.md
├── naming_conventions.md
├── hashing_standards.md
├── enumeration_standards.md
└── fact_vs_dimension_decisions.md
```

**Pattern**: `<standard_topic>.md`

### Architectural Decision Records (ADRs)

```
docs/adr/
├── ADR-001-scd2-customer-profile.md
├── ADR-002-multi-valued-sets.md
└── ADR-INV-001-investment-profile.md
```

**Pattern**: `ADR-<sequence>-<kebab-case-title>.md`

### How-To Guides

```
docs/
├── HOW_TO_REPLICATE_MODULE.md
├── MODULE_DEVELOPMENT_CHECKLIST.md
└── DOCUMENTATION_ASSESSMENT.md
```

**Pattern**: `HOW_TO_<TOPIC>.md` or `<TOPIC>_<TYPE>.md` (UPPERCASE)

---

## Validation Rules

### File Naming Validation

✅ **Valid Examples**:
```
dim_customer_profile.sql
bronze_extract_customer_profile.py
customer_marital_status.yaml
naming_conventions.md
README.md
```

❌ **Invalid Examples**:
```
Dim_Customer_Profile.sql          # PascalCase not allowed
dim-customer-profile.sql          # Kebab-case not allowed (except ADRs)
dimCustomerProfile.sql            # camelCase not allowed
dim customer profile.sql          # Spaces not allowed
dim_customer_profile_v2.sql       # Version suffixes not recommended
```

### Folder Naming Validation

✅ **Valid Examples**:
```
data-modeling/                    # Kebab-case acceptable for docs
bronze/
silver/
gold/
```

❌ **Invalid Examples**:
```
DataModeling/                     # PascalCase not allowed
data_modeling/                    # Use kebab-case for doc folders
Bronze/                           # Uppercase not allowed
silverLayer/                      # camelCase not allowed
```

### Checklist

Use this checklist when creating new files or folders:

- [ ] File name uses snake_case (or UPPERCASE for policy docs)
- [ ] Folder name uses lowercase (kebab-case for docs acceptable)
- [ ] No spaces in file or folder names
- [ ] No version numbers in file names (use git for versioning)
- [ ] File extension is lowercase (`.sql`, `.md`, `.yaml`, not `.SQL`, `.MD`, `.YAML`)
- [ ] Name matches the entity/table name exactly (for DDL, dbt, contracts)
- [ ] Files in correct layer directory (bronze/silver/gold)
- [ ] Documentation files have descriptive names
- [ ] Deprecated files moved to `deprecated/` or `deprecate/` folder

---

## Migration from Legacy Naming

### "curated" → "gold" Migration

**Status**: ✅ COMPLETE (as of 2025-12-12)

All files previously in `db/curated/` have been:
1. Moved to `db/deprecated/` (for historical reference)
2. Recreated in `db/gold/` with updated schema names
3. Marked with `DEPRECATED.md` in the curated folder

**Rule**: Never use `curated` schema or folder in new code. Always use `gold`.

See: [db/curated/DEPRECATED.md](/db/curated/DEPRECATED.md)

### Version Suffix Standardization

**Old Pattern**: `dim_customer_profile_version_scd2.sql`  
**New Pattern**: `dim_investment_profile_version.sql`

**Rule**: Use `_version` suffix only, not `_version_scd2` or `_v1`, `_v2`

---

## Related Documents

- [Naming Conventions (Database Objects)](naming_conventions.md) - Physical layer naming (tables, columns)
- [STANDARDS_INDEX.md](/STANDARDS_INDEX.md) - Master index of all standards
- [AI_CONTEXT.md](/AI_CONTEXT.md) - AI agent context and guidelines
- [README.md](/README.md) - Repository overview and getting started

---

## Change Log

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-12-12 | Initial foundation document for file and folder naming conventions | Data Architecture Team |

---

**For AI Agents**: This document is the authoritative reference for file and folder naming in the DW1 repository. Always consult this when creating new files, folders, or organizing repository structure. Validate all names against the rules in this document before committing.

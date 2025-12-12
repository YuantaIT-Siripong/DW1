# DW1 Data Warehouse (Phase 1 Initialization)

## Phase 1 Scope
This phase establishes foundational SCD2 dimensions and supporting structures:
- **Customer Profile Dimension** (SCD2): Demographics, marital status, nationality, occupation, education, birthdate
- **Investment Profile Dimension** (SCD2): Suitability assessment, risk levels, KYC/AML status, entitlements, vulnerability classification
- **Service Taxonomy**: Service hierarchy, categories, subscription scopes
- **Multi-Valued Sets**: Income sources, investment purposes, contact channels (linked to profile versions via bridge tables)
- **Profile Change Audit**: Customer profile change tracking (investment profile audit in future phase)

## Layers
- dim: Conformed dimensions (including SCD2)
- fact: Events and requests
- audit: Change tracking (customer profile)
- contracts: Modeling contracts driving SCD2 logic
- docs: Modeling decisions & hierarchy descriptions

See docs/modeling_decisions.md and docs/service_hierarchy_and_subscription.md for details.

## Overview
This repository serves as a conceptual and experimental space for designing and documenting a Data Warehouse (DW) foundation using an **AI-first approach**. The goal is to create a structured, scalable architecture with repeatable patterns.

## Purpose
- Provide a comprehensive framework for modern data warehouse design
- Document best practices and patterns using AI-assisted methodology
- Create reusable templates and guidelines for enterprise data warehousing
- Establish a foundation for scalable data architecture

## Repository Structure
```
DW1/
├── contracts/              # YAML schema specifications (single source of truth)
│   ├── bronze/            # Bronze layer contracts
│   ├── silver/            # Silver layer contracts
│   └── customer/          # Gold/curated layer contracts
├── db/                    # Database DDL files
│   ├── bronze/           # Raw landing zone tables
│   ├── silver/           # Cleaned data tables
│   ├── gold/             # Dimensional model tables (deprecated - use dbt)
│   ├── curated/          # Production dimensional model
│   │   ├── dimensions/  # SCD2 dimensions
│   │   ├── bridges/     # Bridge tables for multi-valued sets
│   │   └── audit/       # Audit fact tables
│   └── quarantine/       # Data quality quarantine tables
├── dbt/                   # dbt transformations (Silver & Gold layers)
│   ├── models/
│   │   ├── bronze/      # Source definitions
│   │   ├── silver/      # Cleaned and validated models
│   │   └── gold/        # Dimensional models with SCD2
│   └── macros/          # Reusable macros (hashing, validation)
├── docs/                  # Comprehensive documentation
│   ├── architecture/     # Data warehouse architecture
│   ├── business/         # Business domain specifications
│   │   └── modules/     # Module specs (customer, investment, company)
│   ├── data-modeling/   # Standards (naming, hashing, enumerations)
│   ├── data-quality/    # Data quality framework
│   ├── layers/          # Bronze/Silver/Gold layer specifications
│   ├── adr/             # Architectural decision records
│   ├── HOW_TO_REPLICATE_MODULE.md        # 10-step replication guide
│   ├── MODULE_DEVELOPMENT_CHECKLIST.md   # Complete checklist
│   └── REPOSITORY_INVENTORY_AND_ASSESSMENT.md  # Full assessment
├── enumerations/         # Enumeration YAML files (valid codes)
├── templates/            # Annotated templates for common patterns
├── seeds/                # Static reference data (dbt seeds)
│   └── company/         # Company reference tables
├── etl/                  # ETL scripts (Bronze extraction)
└── deprecated/           # Old patterns and outdated examples
```

## Key Principles
### 1. AI-First Approach
- Leverage AI tools for documentation generation and validation
- Use AI-assisted design for data models and ETL processes
- Implement AI-driven data quality checks and monitoring
- Apply machine learning for metadata management and discovery

### 2. Scalability
- Design for horizontal and vertical scaling
- Support cloud-native architectures
- Enable distributed processing capabilities
- Plan for data volume growth

### 3. Consistency
- **Naming Conventions**: snake_case for physical layer, camelCase for API layer (see [Naming Conventions](docs/data-modeling/naming_conventions.md))
- **Hashing Standards**: SHA256-based deterministic hashing for change detection (see [Hashing Standards](docs/data-modeling/hashing_standards.md))
- **SCD2 Policy**: Microsecond precision, closure rules, surrogate key patterns (see [Standard SCD2 Policy](contracts/scd2/STANDARD_SCD2_POLICY.md))
- Follow established design patterns
- Use consistent documentation format
- Implement version control for all artifacts

### 4. Enterprise-Ready
- Support multiple data sources and formats
- Enable security and compliance requirements
- Provide monitoring and observability
- Include disaster recovery and backup strategies

## Getting Started

### For AI Agents Building New Modules
**⚡ Quick Start**: Follow this 10-step process to replicate the customer profile pattern for a new module (e.g., investment profile):

1. 📖 **Read the Replication Guide**: [HOW_TO_REPLICATE_MODULE.md](docs/HOW_TO_REPLICATE_MODULE.md)
2. ✅ **Use the Development Checklist**: [MODULE_DEVELOPMENT_CHECKLIST.md](docs/MODULE_DEVELOPMENT_CHECKLIST.md)
3. 🔍 **Review the Documentation Assessment**: [DOCUMENTATION_ASSESSMENT.md](docs/DOCUMENTATION_ASSESSMENT.md)
4. 🌉 **Use Templates**: 
   - Bridge Tables: [templates/bridge_table_template.sql](templates/bridge_table_template.sql)
   - Dimensions: [templates/dimension_table_template.sql](templates/dimension_table_template.sql)
   - Facts: [templates/fact_table_template.sql](templates/fact_table_template.sql)
5. 🔧 **dbt Macros Guide**: [dbt/macros/README.md](dbt/macros/README.md)

### For Human Developers
1. **Review Architecture Documentation**: Start with [/docs/architecture/](docs/architecture/)
2. **Explore Data Modeling**: Check [/docs/data-modeling/](docs/data-modeling/)
3. **Understand Data Flow**: Review [/docs/etl-elt/](docs/etl-elt/) and [/docs/layers/](docs/layers/)
4. **Implement Governance**: Follow [/docs/governance/](docs/governance/)
5. **See Working Example**: Review the complete customer profile module implementation

## Core Policies and Standards

This section provides quick access to authoritative policies governing data modeling, versioning, and naming:

| Policy | Purpose | Location |
|--------|---------|----------|
| **Standard SCD2 Policy** | Temporal precision, closure rules, surrogate key patterns, change detection | [contracts/scd2/STANDARD_SCD2_POLICY.md](contracts/scd2/STANDARD_SCD2_POLICY.md) |
| **Hashing Standards** | SHA256 algorithm, profile change hash, multi-valued set hash, normalization rules | [docs/data-modeling/hashing_standards.md](docs/data-modeling/hashing_standards.md) |
| **Naming Conventions** | snake_case physical, camelCase API, surrogate key suffixes, boolean patterns, enumeration casing | [docs/data-modeling/naming_conventions.md](docs/data-modeling/naming_conventions.md) |
| **Data Quality Framework** | Unified quality metrics taxonomy, component definitions, gold layer implementation plan | [docs/data-quality/framework.md](docs/data-quality/framework.md) |

**Note on Derived Metrics**: Derived scoring and quality metrics (e.g., data_quality_score, profile_reliability_score) are NOT stored in SCD2 dimensions. They are excluded from version storage and hash logic to prevent spurious versioning. These metrics will be computed in the gold layer as part of the unified Data Quality Framework.

**AI-Assisted Development**: These policies serve as authoritative anchors for AI tools. Always reference them when generating or reviewing code related to SCD2 dimensions, change detection, or naming.

## Key References

### 🚀 Quick Start Guides
- [**How to Replicate a Module**](docs/HOW_TO_REPLICATE_MODULE.md) - 10-step guide for building new modules
- [**Module Development Checklist**](docs/MODULE_DEVELOPMENT_CHECKLIST.md) - Complete checklist for module development
- [**Repository Assessment**](docs/REPOSITORY_INVENTORY_AND_ASSESSMENT.md) - Comprehensive inventory and replication readiness (99%)
- [**Assessment Summary**](docs/ASSESSMENT_EXECUTIVE_SUMMARY.md) - Quick reference: seeds (KEEP), examples (DEPRECATED)
- [**Documentation Assessment**](docs/DOCUMENTATION_ASSESSMENT.md) - Repository documentation maturity and readiness
- [**dbt Macros Guide**](dbt/macros/README.md) - Complete guide to all dbt macros with examples

### 📋 Module Specifications
- [AI Context](AI_CONTEXT.md)
- [Customer Module Spec](docs/business/modules/customer_module.md)
- [Investment Profile Module Spec](docs/business/modules/investment_profile_module.md)

### 📊 Data Quality & Governance
- [Data Quality Framework](docs/data-quality/framework.md)
- [Data Quality Rules](docs/business/data_quality_rules.md)

### 🏗️ Architecture & Modeling
- [Modeling Decisions](docs/modeling_decisions.md)
- [Contracts Index](contracts/INDEX.yaml)
- [Customer SCD2 Columns Contract](contracts/scd2/dim_customer_profile_columns.yaml)
- [Investment SCD2 Columns Contract](contracts/scd2/dim_investment_profile_version_columns.yaml)

### 📚 Standards & Enumerations
- [Unified Enumerations](docs/data-modeling/enumerations.md)
- [Investment Enumerations Detailed](docs/data-modeling/investment-profile/enumerations.md)

### 📖 Architectural Decision Records
- [ADR-001 SCD2 Customer Profile](docs/adr/ADR-001-scd2-customer-profile.md)
- [ADR-INV-001 Investment Profile](docs/adr/ADR-INV-001-investment-profile.md)
- [ADR-002 Multi-Valued Sets](docs/adr/ADR-002-multi-valued-sets.md)

## AI-First Methodology
Employed across design, development, operations, governance lifecycle.

## Internal Development Standards
This is an internal repository. For standards and guidelines:
- **Master Index**: [STANDARDS_INDEX.md](STANDARDS_INDEX.md)
- **AI Development**: [AI_CONTEXT.md](AI_CONTEXT.md)
- **Naming/Hashing**: [docs/data-modeling/](docs/data-modeling/)
- **SCD2 Policy**: [contracts/scd2/STANDARD_SCD2_POLICY.md](contracts/scd2/STANDARD_SCD2_POLICY.md)

## License
Conceptual educational repository.

## Version
Current Version: 1.0.0 - Foundation Release

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
├── contracts/
│   └── scd2/                # SCD2 modeling contracts
├── db/
│   ├── dim/                 # Dimension tables
│   ├── fact/                # Fact tables
│   ├── audit/               # Audit tables
│   └── views/               # View definitions
├── docs/
│   ├── architecture/        # Data warehouse architecture documentation
│   ├── business/            # Business domain specifications
│   │   └── modules/         # Business module specs (customer, investment)
│   ├── data-modeling/       # Data modeling standards and guidelines
│   ├── etl-elt/             # ETL/ELT process documentation
│   ├── governance/          # Data governance and quality framework
│   ├── layers/              # DW layer specifications (staging, integration, presentation)
│   ├── metadata/            # Metadata management documentation
│   └── ai-methodology/      # AI-first approach and tools
├── templates/               # Reusable templates for DW components
├── examples/                # Example implementations and use cases
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
1. **Review Architecture Documentation**: Start with /docs/architecture/
2. **Explore Data Modeling**: Check /docs/data-modeling/
3. **Understand Data Flow**: Review /docs/etl-elt/ and /docs/layers/
4. **Implement Governance**: Follow /docs/governance/

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
- [AI Context](AI_CONTEXT.md)
- [Customer Module Spec](docs/business/modules/customer_module.md)
- [Investment Profile Module Spec](docs/business/modules/investment_profile_module.md)
- [Data Quality Framework](docs/data-quality/framework.md)
- [Data Quality Rules](docs/business/data_quality_rules.md)
- [Modeling Decisions](docs/modeling_decisions.md)
- [Contracts Index](contracts/INDEX.yaml)
- [Customer SCD2 Columns Contract](contracts/scd2/dim_customer_profile_columns.yaml)
- [Investment SCD2 Columns Contract](contracts/scd2/dim_investment_profile_version_columns.yaml)
- [Unified Enumerations](docs/data-modeling/enumerations.md)
- [Investment Enumerations Detailed](docs/data-modeling/investment-profile/enumerations.md)
- [ADR-001 SCD2 Customer Profile](docs/adr/ADR-001-scd2-customer-profile.md)
- [ADR-INV-001 Investment Profile](docs/adr/ADR-INV-001-investment-profile.md)
- [ADR-002 Multi-Valued Sets](docs/adr/ADR-002-multi-valued-sets.md)
- [Contributing Guide](CONTRIBUTING.md)

## AI-First Methodology
Employed across design, development, operations, governance lifecycle.

## Contributing
Focus on improving clarity, adding patterns, enhancing templates, documenting lessons learned.

## License
Conceptual educational repository.

## Version
Current Version: 1.0.0 - Foundation Release

# Repository File Index

**Purpose**: Comprehensive inventory of every file and directory in the DW1 repository  
**Audience**: AI agents, new developers, architects  
**Last Updated**: 2026-01-05  
**Maintenance**: Update this file whenever files are added, moved, or removed

---

## Table of Contents

1. [Root Level Files](#root-level-files)
2. [Documentation (`/docs/`)](#documentation-docs)
3. [Contracts (`/contracts/`)](#contracts-contracts)
4. [Database DDL (`/db/`)](#database-ddl-db)
5. [dbt Transformations (`/dbt/`)](#dbt-transformations-dbt)
6. [Enumerations (`/enumerations/`)](#enumerations-enumerations)
7. [ETL Scripts (`/etl/`)](#etl-scripts-etl)
8. [Templates (`/templates/`)](#templates-templates)
9. [Examples (`/examples/`)](#examples-examples)
10. [Scripts (`/scripts/`)](#scripts-scripts)
11. [Raw Data Samples (`/raw/`)](#raw-data-samples-raw)
12. [Deprecated (`/deprecated/`)](#deprecated-deprecated)
13. [GitHub Configuration (`/.github/`)](#github-configuration-github)

---

## Root Level Files

### README.md
- **Type**: Documentation (Master)
- **Purpose**: Primary entry point for repository - project overview, architecture, getting started guide
- **Owner**: Data Architecture Team
- **Dependencies**: Links to all major documentation
- **When to Update**: Any major structural change to repository
- **AI Usage**: MUST be loaded first in any AI conversation

### AI_CONTEXT.md
- **Type**: Documentation (AI Reference)
- **Purpose**: Quick reference for AI assistants - standards, patterns, examples, prompts
- **Owner**: Data Architecture Team
- **Dependencies**: Consolidates references to all standards
- **When to Update**: When standards change or new patterns emerge
- **AI Usage**: MUST be loaded in AI conversation for module development

### STANDARDS_INDEX.md
- **Type**: Documentation (Index)
- **Purpose**: Master index of all standards (enumeration, hashing, naming, SCD2)
- **Owner**: Data Architecture Team
- **Dependencies**: Points to individual standard documents
- **When to Update**: When new standards added or modified
- **AI Usage**: Use as quick lookup for standard locations

### CONTEXT_MANIFEST.yaml
- **Type**: Configuration (Machine-Readable)
- **Purpose**: Authoritative manifest of modeling artifacts for AI thread rehydration
- **Owner**: Data Architecture Team
- **Dependencies**: All enumeration files, contracts, modules
- **When to Update**: When new modules, contracts, or enumerations added
- **AI Usage**: Optional - provides machine-readable artifact inventory

### CODEOWNERS
- **Type**: Configuration (GitHub)
- **Purpose**: Defines code ownership for automated review assignment
- **Owner**: Repository Administrators
- **Dependencies**: None
- **When to Update**: When team structure changes
- **AI Usage**: Not typically needed by AI

### .gitignore
- **Type**: Configuration (Git)
- **Purpose**: Specifies files/directories to exclude from version control
- **Owner**: Repository Administrators
- **Dependencies**: None
- **When to Update**: When new build artifacts or temp files need exclusion
- **AI Usage**: Not typically needed by AI

---

## Documentation (`/docs/`)

### Core Guides

#### docs/HOW_TO_REPLICATE_MODULE.md
- **Type**: Documentation (Guide)
- **Purpose**: 10-step guide for replicating Customer Profile pattern for new modules
- **Owner**: Data Architecture Team
- **Dependencies**: customer_module.md, all standards, templates
- **Relationship**: Used by AI boarding guide step 010
- **When to Update**: When module development process changes
- **AI Usage**: MUST load for module replication tasks

#### docs/MODULE_DEVELOPMENT_CHECKLIST.md
- **Type**: Documentation (Checklist)
- **Purpose**: Comprehensive checklist ensuring nothing is missed in module development
- **Owner**: Data Architecture Team
- **Dependencies**: All standards
- **Relationship**: Complements HOW_TO_REPLICATE_MODULE.md
- **When to Update**: When new requirements added to module development
- **AI Usage**: Use as validation checklist during module creation

#### docs/POLICY_ALIGNMENT_CHECKLIST.md
- **Type**: Documentation (Checklist)
- **Purpose**: Ensures policy compliance for modules
- **Owner**: Data Architecture Team
- **Dependencies**: SCD2 policy, naming conventions, hashing standards
- **When to Update**: When policies change
- **AI Usage**: Use for validation before finalizing module

#### docs/DOCUMENTATION_ASSESSMENT.md
- **Type**: Documentation (Assessment)
- **Purpose**: Self-assessment of repository documentation maturity
- **Owner**: Data Architecture Team
- **Dependencies**: All documentation
- **Relationship**: Historical - shows documentation evolution
- **When to Update**: Periodic reassessment
- **AI Usage**: Reference for understanding documentation quality

#### docs/AI_ONBOARDING_GAP_ANALYSIS.md
- **Type**: Documentation (Analysis)
- **Purpose**: Comprehensive gap analysis for AI-first onboarding readiness
- **Owner**: Data Architecture Team
- **Dependencies**: All repository files
- **Relationship**: Identifies gaps and enhancement recommendations
- **When to Update**: After addressing gaps or adding new content
- **AI Usage**: Reference for understanding repository completeness

#### docs/FOUNDATION_NAMING_CONVENTIONS.md
- **Type**: Documentation (Standard)
- **Purpose**: File and folder naming conventions for entire repository
- **Owner**: Data Architecture Team
- **Dependencies**: None (foundational)
- **Relationship**: Referenced by data-modeling/naming_conventions.md
- **When to Update**: When file structure patterns change
- **AI Usage**: MUST follow when creating new files/folders

### AI-First Employee Boarding Guide (`/docs/_ai-first-employee-boarding-guide/`)

#### Workflow Overview
This directory contains a 10-step workflow for AI agents to create new modules. Steps are numbered for sequential execution.

#### docs/_ai-first-employee-boarding-guide/010_load_repositories_context_into_ai.md
- **Type**: Documentation (Instruction)
- **Purpose**: Step 1 - List of foundation documents AI must load
- **Dependencies**: README.md, AI_CONTEXT.md, STANDARDS_INDEX.md, all standards
- **AI Usage**: Execute first in module creation workflow

#### docs/_ai-first-employee-boarding-guide/011_expected_result_from_ai.md
- **Type**: Documentation (Validation)
- **Purpose**: Expected confirmation from AI after loading context
- **Dependencies**: 010 step
- **AI Usage**: Self-validation checkpoint

#### docs/_ai-first-employee-boarding-guide/020_ai_converts_requirements.md
- **Type**: Documentation (Instruction)
- **Purpose**: Step 2 - Convert business requirements to structured specification
- **Dependencies**: customer_module.md template
- **AI Usage**: Execute to analyze requirements

#### docs/_ai-first-employee-boarding-guide/021_expected_result_from_ai.md
- **Type**: Documentation (Validation)
- **Purpose**: Expected analysis output format
- **Dependencies**: 020 step
- **AI Usage**: Self-validation checkpoint

#### docs/_ai-first-employee-boarding-guide/030_ai_generate_module_files.md
- **Type**: Documentation (Instruction)
- **Purpose**: Step 3 - Generate 9 module files (enumerations, contracts, DDL, dbt)
- **Dependencies**: All templates, customer examples
- **AI Usage**: Execute to generate module artifacts
- **Note**: Currently Customer-specific, needs parameterization (see gap analysis)

#### docs/_ai-first-employee-boarding-guide/031_ai_generate_module_files_test.md
- **Type**: Documentation (Instruction)
- **Purpose**: Generate test files for module
- **Dependencies**: 030 step
- **AI Usage**: Execute to create test artifacts

#### docs/_ai-first-employee-boarding-guide/040_ai_validates_against_standards.md
- **Type**: Documentation (Validation)
- **Purpose**: Step 4 - Comprehensive validation checklist
- **Dependencies**: All standards
- **AI Usage**: Execute to validate generated files

#### docs/_ai-first-employee-boarding-guide/041_fix_issue.md
- **Type**: Documentation (Instruction)
- **Purpose**: How to fix issues found in validation
- **Dependencies**: 040 step
- **AI Usage**: Execute when validation fails

#### docs/_ai-first-employee-boarding-guide/042_re_validate.md
- **Type**: Documentation (Instruction)
- **Purpose**: Re-run validation after fixes
- **Dependencies**: 041 step
- **AI Usage**: Execute after fixing issues

#### docs/_ai-first-employee-boarding-guide/100_sample.md
- **Type**: Documentation (Example)
- **Purpose**: Sample output showing expected results
- **Dependencies**: All steps
- **AI Usage**: Reference for understanding expected output

### Architecture Documentation (`/docs/architecture/`)

#### docs/architecture/README.md
- **Type**: Documentation (Overview)
- **Purpose**: High-level architecture principles and patterns
- **Owner**: Data Architecture Team
- **Dependencies**: None (foundational)
- **When to Update**: When architectural decisions change
- **AI Usage**: Load for understanding architecture context

### Business Documentation (`/docs/business/`)

#### docs/business/domain_overview.md
- **Type**: Documentation (Business Context)
- **Purpose**: Business domain overview and context
- **Owner**: Business Analysts + Data Architecture
- **Dependencies**: None
- **AI Usage**: Load for business context understanding

#### docs/business/glossary.md
- **Type**: Documentation (Reference)
- **Purpose**: Business terms and definitions
- **Owner**: Business Analysts
- **Dependencies**: None
- **When to Update**: When new business terms emerge
- **AI Usage**: Reference for term disambiguation

#### docs/business/data_quality_rules.md
- **Type**: Documentation (Business Rules)
- **Purpose**: Business-level data quality requirements
- **Owner**: Data Governance Team
- **Dependencies**: data-quality/framework.md
- **AI Usage**: Reference when implementing quality checks

#### docs/business/subscription_expansion_examples.md
- **Type**: Documentation (Example)
- **Purpose**: Business examples of subscription patterns
- **Owner**: Business Analysts
- **Dependencies**: service_hierarchy_and_subscription.md
- **AI Usage**: Reference for understanding subscription domain

#### docs/business/matrices/customer_profile_attribute_matrix.yaml
- **Type**: Configuration (Matrix)
- **Purpose**: Customer profile attribute metadata
- **Owner**: Data Architecture Team
- **Dependencies**: customer_module.md
- **AI Usage**: Optional reference for attribute details

### Module Specifications (`/docs/business/modules/`)

#### docs/business/modules/customer_module.md
- **Type**: Documentation (Specification) ⭐ **REFERENCE MODULE**
- **Purpose**: Complete Customer Profile module specification (31 attributes, 18 sections)
- **Owner**: Data Architecture Team
- **Dependencies**: All customer enumerations
- **Relationship**: **PRIMARY TEMPLATE** for new modules
- **When to Update**: When customer profile evolves
- **AI Usage**: MUST use as template for new module specifications
- **Key Sections**: 
  - Section 5: Attribute Inventory
  - Section 8: Hashing Standard
  - Section 18: IT View Specification

#### docs/business/modules/investment_profile_module.md
- **Type**: Documentation (Specification)
- **Purpose**: Investment Profile module specification
- **Owner**: Data Architecture Team
- **Dependencies**: Investment enumerations
- **Status**: Complete
- **AI Usage**: Reference for investment-specific patterns

#### docs/business/modules/company_module.md
- **Type**: Documentation (Specification)
- **Purpose**: Company Profile module specification
- **Owner**: Data Architecture Team
- **Dependencies**: Company enumerations
- **Status**: Complete
- **AI Usage**: Reference for company-specific patterns

### Data Modeling Documentation (`/docs/data-modeling/`)

#### docs/data-modeling/README.md
- **Type**: Documentation (Index)
- **Purpose**: Overview of data modeling standards
- **Owner**: Data Architecture Team
- **Dependencies**: All data-modeling docs
- **AI Usage**: Entry point for data modeling standards

#### docs/data-modeling/naming_conventions.md
- **Type**: Documentation (Standard) ⭐ **CRITICAL**
- **Purpose**: Database object naming standards (snake_case, camelCase, suffixes)
- **Owner**: Data Architecture Team
- **Dependencies**: FOUNDATION_NAMING_CONVENTIONS.md
- **When to Update**: When naming patterns change
- **AI Usage**: MUST follow for all database objects

#### docs/data-modeling/hashing_standards.md
- **Type**: Documentation (Standard) ⭐ **CRITICAL**
- **Purpose**: SHA256 hash algorithm, normalization rules, canonical ordering
- **Owner**: Data Architecture Team
- **Dependencies**: None (foundational)
- **When to Update**: Never (unless hash algorithm changes - requires ADR)
- **AI Usage**: MUST follow for profile_hash and set_hash computation

#### docs/data-modeling/enumeration_standards.md
- **Type**: Documentation (Standard)
- **Purpose**: Enumeration YAML file format and management
- **Owner**: Data Architecture Team
- **Dependencies**: None (foundational)
- **When to Update**: When enumeration patterns change
- **AI Usage**: MUST follow when creating enumeration files

#### docs/data-modeling/enumerations.md
- **Type**: Documentation (Reference)
- **Purpose**: Unified enumeration reference (all domains)
- **Owner**: Data Architecture Team
- **Dependencies**: All enumeration YAML files
- **When to Update**: When enumerations change
- **AI Usage**: Reference for seeing all enumerations in one place

#### docs/data-modeling/fact_vs_dimension_decisions.md
- **Type**: Documentation (Guide)
- **Purpose**: Decision matrix for fact vs dimension classification
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: When classification rules evolve
- **AI Usage**: Use when deciding entity type

#### docs/data-modeling/.keep
- **Type**: Placeholder
- **Purpose**: Ensures directory exists in git
- **AI Usage**: Ignore

### Data Quality Documentation (`/docs/data-quality/`)

#### docs/data-quality/framework.md
- **Type**: Documentation (Framework)
- **Purpose**: Unified quality metrics taxonomy and implementation plan
- **Owner**: Data Governance Team
- **Dependencies**: data_quality_rules.md
- **When to Update**: When quality framework evolves
- **AI Usage**: Reference for implementing quality checks

### Layer Documentation (`/docs/layers/`)

#### docs/layers/README.md
- **Type**: Documentation (Architecture)
- **Purpose**: Bronze/Silver/Gold layer specifications
- **Owner**: Data Architecture Team
- **Dependencies**: None (foundational)
- **When to Update**: When layer responsibilities change
- **AI Usage**: Load for understanding layer architecture

### ETL/ELT Documentation (`/docs/etl-elt/`)

#### docs/etl-elt/README.md
- **Type**: Documentation (Process)
- **Purpose**: ETL and ELT process documentation
- **Owner**: Data Engineering Team
- **Dependencies**: layers/README.md
- **When to Update**: When ETL processes change
- **AI Usage**: Reference for understanding data flow

### Audit Documentation (`/docs/audit/`)

#### docs/audit/audit_artifacts_standard.md
- **Type**: Documentation (Standard)
- **Purpose**: Standard for audit fact tables
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: When audit patterns change
- **AI Usage**: Use when creating audit fact tables

### Governance Documentation (`/docs/governance/`)

#### docs/governance/README.md
- **Type**: Documentation (Policy)
- **Purpose**: Data governance policies and procedures
- **Owner**: Data Governance Team
- **Dependencies**: None
- **When to Update**: When governance policies change
- **AI Usage**: Reference for compliance requirements

### Metadata Documentation (`/docs/metadata/`)

#### docs/metadata/README.md
- **Type**: Documentation (Technical)
- **Purpose**: Metadata management approach
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: When metadata strategy changes
- **AI Usage**: Reference for metadata handling

### AI Methodology Documentation (`/docs/ai-methodology/`)

#### docs/ai-methodology/README.md
- **Type**: Documentation (Process)
- **Purpose**: AI-first development methodology
- **Owner**: Data Architecture Team
- **Dependencies**: AI boarding guide
- **When to Update**: When AI methodology evolves
- **AI Usage**: Reference for understanding AI-first approach

### Migration Documentation (`/docs/migrations/`)

#### docs/migrations/CURATED_TO_GOLD_MIGRATION.md
- **Type**: Documentation (Historical)
- **Purpose**: Documents migration from 'curated' schema to 'gold' schema
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: Finalize when migration complete
- **AI Usage**: Historical reference - use 'gold' schema not 'curated'

### ADR Documentation (`/docs/adr/`)

Architectural Decision Records document significant architectural choices.

#### docs/adr/ADR-001-scd2-customer-profile.md
- **Type**: Documentation (ADR)
- **Purpose**: Decision record for Customer Profile SCD2 implementation
- **Owner**: Data Architecture Team
- **Dependencies**: STANDARD_SCD2_POLICY.md
- **When to Update**: Never (historical record)
- **AI Usage**: Reference for understanding SCD2 decisions

#### docs/adr/ADR-002-multi-valued-sets.md
- **Type**: Documentation (ADR)
- **Purpose**: Decision record for multi-valued set implementation via bridge tables
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: Never (historical record)
- **AI Usage**: Reference for bridge table pattern

#### docs/adr/ADR-INV-001-investment-profile.md
- **Type**: Documentation (ADR)
- **Purpose**: Decision record for Investment Profile module
- **Owner**: Data Architecture Team
- **Dependencies**: investment_profile_module.md
- **When to Update**: Never (historical record)
- **AI Usage**: Reference for investment-specific decisions

#### docs/adr/ADR-AUDIT-001-audit-artifacts-standard.md
- **Type**: Documentation (ADR)
- **Purpose**: Decision record for audit artifact standards
- **Owner**: Data Architecture Team
- **Dependencies**: audit_artifacts_standard.md
- **When to Update**: Never (historical record)
- **AI Usage**: Reference for audit pattern decisions

### Other Documentation Files

#### docs/modeling_decisions.md
- **Type**: Documentation (Decisions)
- **Purpose**: General modeling decisions and rationale
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: When modeling approach changes
- **AI Usage**: Reference for modeling context

#### docs/service_hierarchy_and_subscription.md
- **Type**: Documentation (Domain)
- **Purpose**: Service taxonomy and subscription scope
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: When service domain evolves
- **AI Usage**: Reference for service-related modules

---

## Contracts (`/contracts/`)

**Purpose**: YAML contracts define table schemas for all layers (Bronze, Silver, Gold)  
**Relationship**: Contracts are source of truth → DDL and dbt models implement contracts  
**Naming Convention**: `{layer}/{entity}_standardized.yaml` or `{layer}/{table_name}.yaml`

### Active Contracts

#### contracts/bronze/customer_profile_standardized.yaml
- **Type**: Contract (Bronze Layer)
- **Purpose**: Defines Bronze landing table for customer profile (raw + ETL metadata)
- **Owner**: Data Architecture Team
- **Dependencies**: customer_module.md Section 18 (IT View)
- **Implemented By**: db/bronze/customer_profile_standardized.sql
- **When to Update**: When IT view structure changes
- **AI Usage**: Reference for Bronze table structure

#### contracts/silver/customer_profile_standardized.yaml
- **Type**: Contract (Silver Layer)
- **Purpose**: Defines Silver table with computed hashes and quality flags
- **Owner**: Data Architecture Team
- **Dependencies**: Bronze contract, hashing_standards.md
- **Implemented By**: 
  - db/silver/customer_profile_standardized.sql (DDL)
  - dbt/models/silver/customer_profile_standardized.sql (transformation)
- **When to Update**: When computed columns change
- **AI Usage**: Reference for Silver table structure

#### contracts/gold/dim_customer_profile.yaml
- **Type**: Contract (Gold Dimension)
- **Purpose**: Defines Gold SCD2 dimension for customer profile
- **Owner**: Data Architecture Team
- **Dependencies**: STANDARD_SCD2_POLICY.md, customer_module.md
- **Implemented By**: 
  - db/gold/dim_customer_profile.sql (DDL)
  - dbt/models/gold/dim_customer_profile.sql (transformation)
- **When to Update**: When dimension structure changes
- **AI Usage**: MUST use as template for new SCD2 dimensions

#### contracts/gold/bridge_customer_income_source_version.yaml
- **Type**: Contract (Gold Bridge)
- **Purpose**: Defines bridge table for source_of_income multi-valued set
- **Owner**: Data Architecture Team
- **Dependencies**: dim_customer_profile contract
- **Implemented By**: 
  - db/gold/bridge_customer_source_of_income.sql (DDL)
  - dbt/models/gold/bridge_customer_source_of_income.sql (transformation)
- **When to Update**: When bridge structure changes
- **AI Usage**: Use as template for bridge tables

#### contracts/gold/bridge_customer_investment_purpose_version.yaml
- **Type**: Contract (Gold Bridge)
- **Purpose**: Defines bridge table for purpose_of_investment multi-valued set
- **Owner**: Data Architecture Team
- **Dependencies**: dim_customer_profile contract
- **Implemented By**: 
  - db/gold/bridge_customer_purpose_of_investment.sql (DDL)
  - dbt/models/gold/bridge_customer_purpose_of_investment.sql (transformation)
- **When to Update**: When bridge structure changes
- **AI Usage**: Use as template for bridge tables

#### contracts/gold/fact_customer_profile_audit.yaml
- **Type**: Contract (Gold Fact)
- **Purpose**: Defines audit fact table for customer profile changes
- **Owner**: Data Architecture Team
- **Dependencies**: dim_customer_profile contract, audit_artifacts_standard.md
- **Implemented By**: 
  - db/gold/fact_customer_profile_audit.sql (DDL)
  - dbt/models/gold/fact_customer_profile_audit.sql (transformation)
- **When to Update**: When audit tracking changes
- **AI Usage**: Use as template for audit fact tables

#### contracts/quarantine/customer_profile_rejected.yaml
- **Type**: Contract (Quarantine)
- **Purpose**: Defines quarantine table for rejected customer profiles
- **Owner**: Data Architecture Team
- **Dependencies**: Silver contract
- **Implemented By**: 
  - db/quarantine/customer_profile_quarantine.sql (DDL)
  - dbt/models/quarantine/customer_profile_rejected.sql (transformation)
- **When to Update**: When quarantine strategy changes
- **AI Usage**: Use as template for quarantine tables

### SCD2 Policy

#### contracts/scd2/STANDARD_SCD2_POLICY.md
- **Type**: Documentation (Standard) ⭐ **CRITICAL**
- **Purpose**: Authoritative SCD Type 2 policy (temporal precision, closure rules, patterns)
- **Owner**: Data Architecture Team
- **Dependencies**: None (foundational)
- **When to Update**: Never (requires ADR if changed)
- **AI Usage**: MUST follow for all SCD2 implementations

### Deprecated Contracts (`/contracts/deprecate/`)

**Purpose**: Historical contracts from old patterns (lookup dimensions, old schema names)  
**Status**: Keep for reference, do NOT use for new development

#### contracts/deprecate/INDEX.yaml
- **Type**: Index
- **Purpose**: Lists all deprecated contracts
- **AI Usage**: Reference only - do not use deprecated patterns

#### contracts/deprecate/customer/, company/, investment/, audit/
- **Type**: Deprecated Contracts
- **Purpose**: Old patterns (separate lookup dimensions, old naming)
- **Status**: Deprecated - replaced by enumeration pattern
- **AI Usage**: DO NOT USE - reference customer profile v2 instead

#### contracts/deprecate/scd2/
- **Type**: Deprecated Contracts
- **Purpose**: Old SCD2 contract versions
- **Status**: Superseded by contracts/scd2/STANDARD_SCD2_POLICY.md
- **AI Usage**: DO NOT USE - use active SCD2 policy

---

## Database DDL (`/db/`)

**Purpose**: CREATE TABLE scripts for all database layers  
**Relationship**: Implements contracts defined in `/contracts/`  
**Naming Convention**: Matches contract name (e.g., `customer_profile_standardized.sql`)

### Bronze DDL (`/db/bronze/`)

#### db/bronze/customer_profile_standardized.sql
- **Type**: DDL (Bronze)
- **Purpose**: Creates Bronze landing table for customer profile
- **Implements**: contracts/bronze/customer_profile_standardized.yaml
- **Owner**: Data Architecture Team
- **Dependencies**: PostgreSQL bronze schema
- **When to Run**: Initial setup or schema changes
- **AI Usage**: Use as template for Bronze DDL

#### db/bronze/insert_test_bad_data.sql
- **Type**: DDL (Test Fixture)
- **Purpose**: Inserts test data with quality issues for validation testing
- **Implements**: N/A (test fixture)
- **Owner**: Data Engineering Team
- **Dependencies**: customer_profile_standardized table
- **When to Run**: Test environment setup
- **AI Usage**: Reference for creating test fixtures

### Silver DDL (`/db/silver/`)

#### db/silver/customer_profile_standardized.sql
- **Type**: DDL (Silver)
- **Purpose**: Creates Silver table with computed columns
- **Implements**: contracts/silver/customer_profile_standardized.yaml
- **Owner**: Data Architecture Team
- **Dependencies**: PostgreSQL silver schema
- **When to Run**: Initial setup or schema changes
- **AI Usage**: Use as template for Silver DDL

### Gold DDL (`/db/gold/`)

#### db/gold/dim_customer_profile.sql
- **Type**: DDL (Gold Dimension)
- **Purpose**: Creates SCD2 customer profile dimension with 6 required indexes
- **Implements**: contracts/gold/dim_customer_profile.yaml
- **Owner**: Data Architecture Team
- **Dependencies**: PostgreSQL gold schema
- **When to Run**: Initial setup or schema changes
- **AI Usage**: MUST use as template for SCD2 dimension DDL

#### db/gold/bridge_customer_source_of_income.sql
- **Type**: DDL (Gold Bridge)
- **Purpose**: Creates bridge table for source_of_income
- **Implements**: contracts/gold/bridge_customer_income_source_version.yaml
- **Owner**: Data Architecture Team
- **Dependencies**: dim_customer_profile table
- **When to Run**: Initial setup or schema changes
- **AI Usage**: Use as template for bridge DDL

#### db/gold/bridge_customer_purpose_of_investment.sql
- **Type**: DDL (Gold Bridge)
- **Purpose**: Creates bridge table for purpose_of_investment
- **Implements**: contracts/gold/bridge_customer_investment_purpose_version.yaml
- **Owner**: Data Architecture Team
- **Dependencies**: dim_customer_profile table
- **When to Run**: Initial setup or schema changes
- **AI Usage**: Use as template for bridge DDL

#### db/gold/fact_customer_profile_audit.sql
- **Type**: DDL (Gold Fact)
- **Purpose**: Creates audit fact table for profile changes
- **Implements**: contracts/gold/fact_customer_profile_audit.yaml
- **Owner**: Data Architecture Team
- **Dependencies**: dim_customer_profile table
- **When to Run**: Initial setup or schema changes
- **AI Usage**: Use as template for audit fact DDL

### Quarantine DDL (`/db/quarantine/`)

#### db/quarantine/customer_profile_quarantine.sql
- **Type**: DDL (Quarantine)
- **Purpose**: Creates quarantine table for rejected profiles
- **Implements**: contracts/quarantine/customer_profile_rejected.yaml
- **Owner**: Data Architecture Team
- **Dependencies**: PostgreSQL quarantine schema
- **When to Run**: Initial setup or schema changes
- **AI Usage**: Use as template for quarantine DDL

### Source System DDL (`/db/source_system/`)

#### db/source_system/create_it_view_sample.sql
- **Type**: DDL (Test Fixture)
- **Purpose**: Creates sample IT view for testing Bronze extraction
- **Implements**: N/A (simulates source system)
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Run**: Development/test environment setup
- **AI Usage**: Reference for understanding IT view structure

### Deprecated DDL (`/db/deprecated/`)

**Purpose**: Historical DDL from old patterns  
**Status**: Keep for migration reference, do NOT use for new development

#### db/deprecated/curated/DEPRECATED.md
- **Type**: Documentation
- **Purpose**: Explains deprecation of 'curated' schema → 'gold' schema migration
- **AI Usage**: Historical context - always use 'gold' not 'curated'

#### db/deprecated/curated/, dim/, fact/, seeds/, views/
- **Type**: Deprecated DDL
- **Purpose**: Old schema patterns and lookup dimensions
- **Status**: Deprecated
- **AI Usage**: DO NOT USE - reference active DDL in /db/gold/

---

## dbt Transformations (`/dbt/`)

**Purpose**: dbt project for Silver and Gold layer transformations  
**Technology**: dbt (data build tool)  
**Relationship**: Transforms Bronze → Silver → Gold implementing contracts

### dbt Configuration

#### dbt/dbt_project.yml
- **Type**: Configuration (dbt)
- **Purpose**: Main dbt project configuration
- **Owner**: Data Engineering Team
- **Dependencies**: dbt profiles.yml
- **When to Update**: When project structure changes
- **AI Usage**: Reference for dbt configuration

#### dbt/profiles.yml.example
- **Type**: Configuration (Example)
- **Purpose**: Example dbt profiles for PostgreSQL connection
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Use**: Copy to ~/.dbt/profiles.yml and customize
- **AI Usage**: Reference for connection setup

#### dbt/.user.yml
- **Type**: Configuration (User)
- **Purpose**: User-specific dbt settings
- **Owner**: Individual developers
- **Dependencies**: None
- **AI Usage**: Not needed by AI

#### dbt/packages.yml
- **Type**: Configuration (dbt)
- **Purpose**: Declares dbt package dependencies
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Update**: When adding dbt packages
- **AI Usage**: Reference for available packages

#### dbt/package-lock.yml
- **Type**: Configuration (Generated)
- **Purpose**: Locks dbt package versions
- **Owner**: Auto-generated by dbt
- **Dependencies**: packages.yml
- **When to Update**: Auto-generated on dbt deps
- **AI Usage**: Not needed by AI

### dbt Macros (`/dbt/macros/`)

#### dbt/macros/README.md
- **Type**: Documentation (Macro Guide)
- **Purpose**: Complete guide to all dbt macros with usage examples
- **Owner**: Data Engineering Team
- **Dependencies**: All macro files
- **When to Update**: When macros added or changed
- **AI Usage**: MUST reference when using macros in dbt models

#### dbt/macros/compute_profile_hash.sql
- **Type**: dbt Macro
- **Purpose**: Computes SHA256 profile_hash from ordered attributes
- **Owner**: Data Engineering Team
- **Dependencies**: hashing_standards.md
- **Used By**: Silver models
- **When to Update**: Never (unless hash algorithm changes)
- **AI Usage**: Use in Silver dbt models for profile_hash computation

#### dbt/macros/compute_set_hash.sql
- **Type**: dbt Macro
- **Purpose**: Computes SHA256 hash for multi-valued sets
- **Owner**: Data Engineering Team
- **Dependencies**: hashing_standards.md
- **Used By**: Silver models
- **When to Update**: Never (unless hash algorithm changes)
- **AI Usage**: Use in Silver dbt models for set_hash computation

#### dbt/macros/validate_enumeration.sql
- **Type**: dbt Macro
- **Purpose**: Validates enumeration field against YAML definition
- **Owner**: Data Engineering Team
- **Dependencies**: enumeration YAML files
- **Used By**: Silver models
- **When to Update**: When validation logic changes
- **AI Usage**: Use in Silver dbt models for enumeration validation

#### dbt/macros/validate_set.sql
- **Type**: dbt Macro
- **Purpose**: Validates multi-valued set members
- **Owner**: Data Engineering Team
- **Dependencies**: enumeration YAML files
- **Used By**: Silver models
- **When to Update**: When validation logic changes
- **AI Usage**: Use in Silver dbt models for set validation

#### dbt/macros/get_custom_schema.sql
- **Type**: dbt Macro
- **Purpose**: Controls schema naming in different environments
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **Used By**: dbt core
- **When to Update**: When schema naming strategy changes
- **AI Usage**: Standard dbt macro, typically don't modify

### dbt Models - Bronze Source Definitions (`/dbt/models/bronze/`)

#### dbt/models/bronze/_sources.yml
- **Type**: dbt Source Definition
- **Purpose**: Defines Bronze schema tables as dbt sources
- **Owner**: Data Engineering Team
- **Dependencies**: Bronze DDL
- **Used By**: Silver models
- **When to Update**: When Bronze tables added/changed
- **AI Usage**: Update when adding Bronze tables

### dbt Models - Silver (`/dbt/models/silver/`)

#### dbt/models/silver/customer_profile_standardized.sql
- **Type**: dbt Model (Silver)
- **Purpose**: Transforms Bronze → Silver with hashes and quality checks
- **Implements**: contracts/silver/customer_profile_standardized.yaml
- **Owner**: Data Engineering Team
- **Dependencies**: 
  - Bronze source
  - compute_profile_hash macro
  - compute_set_hash macro
  - validate_enumeration macro
- **Materialization**: Incremental
- **When to Update**: When Silver logic changes
- **AI Usage**: MUST use as template for Silver transformation models

#### dbt/models/silver/schema.yml
- **Type**: dbt Schema
- **Purpose**: Documents Silver models and columns
- **Owner**: Data Engineering Team
- **Dependencies**: Silver models
- **When to Update**: When Silver models change
- **AI Usage**: Update when creating Silver models

#### dbt/models/silver/rejection_rules.yml
- **Type**: Configuration
- **Purpose**: Defines rejection rules for quarantine
- **Owner**: Data Governance Team
- **Dependencies**: Silver models
- **When to Update**: When quality rules change
- **AI Usage**: Reference for implementing rejection logic

### dbt Models - Silver Enums (`/dbt/models/silver/enums/`)

**Purpose**: dbt models that materialize enumeration lookup tables from YAML  
**Pattern**: Each enumeration YAML has corresponding dbt model  
**Usage**: Optional - for BI tools that prefer FK joins over direct codes

#### dbt/models/silver/enums/_customer_*.sql
- **Type**: dbt Model (Reference)
- **Purpose**: Materializes enumeration as lookup table
- **Owner**: Data Engineering Team
- **Dependencies**: Corresponding enumeration YAML in /enumerations/
- **Materialization**: Table (full rebuild)
- **When to Update**: Auto-syncs with enumeration YAML
- **AI Usage**: Create one for each enumeration if BI tools need lookup tables

#### dbt/models/silver/enums/schema.yml
- **Type**: dbt Schema
- **Purpose**: Documents enum models
- **Owner**: Data Engineering Team
- **Dependencies**: Enum models
- **When to Update**: When enum models change
- **AI Usage**: Update when creating enum models

### dbt Models - Gold (`/dbt/models/gold/`)

#### dbt/models/gold/dim_customer_profile.sql
- **Type**: dbt Model (Gold Dimension)
- **Purpose**: Transforms Silver → Gold SCD2 dimension with versioning
- **Implements**: contracts/gold/dim_customer_profile.yaml
- **Owner**: Data Engineering Team
- **Dependencies**: Silver customer_profile_standardized
- **Materialization**: Table (full rebuild)
- **Key Logic**: LEAD() for effective_end_ts, ROW_NUMBER() for version_num
- **When to Update**: When SCD2 logic changes
- **AI Usage**: MUST use as template for SCD2 dimension transformation

#### dbt/models/gold/bridge_customer_source_of_income.sql
- **Type**: dbt Model (Gold Bridge)
- **Purpose**: Explodes multi-valued set into bridge table
- **Implements**: contracts/gold/bridge_customer_income_source_version.yaml
- **Owner**: Data Engineering Team
- **Dependencies**: dim_customer_profile
- **Materialization**: Table (full rebuild)
- **When to Update**: When bridge logic changes
- **AI Usage**: Use as template for bridge transformation

#### dbt/models/gold/bridge_customer_purpose_of_investment.sql
- **Type**: dbt Model (Gold Bridge)
- **Purpose**: Explodes multi-valued set into bridge table
- **Implements**: contracts/gold/bridge_customer_investment_purpose_version.yaml
- **Owner**: Data Engineering Team
- **Dependencies**: dim_customer_profile
- **Materialization**: Table (full rebuild)
- **When to Update**: When bridge logic changes
- **AI Usage**: Use as template for bridge transformation

#### dbt/models/gold/fact_customer_profile_audit.sql
- **Type**: dbt Model (Gold Fact)
- **Purpose**: Tracks profile change events
- **Implements**: contracts/gold/fact_customer_profile_audit.yaml
- **Owner**: Data Engineering Team
- **Dependencies**: dim_customer_profile
- **Materialization**: Incremental
- **When to Update**: When audit tracking changes
- **AI Usage**: Use as template for audit fact transformation

#### dbt/models/gold/schema.yml
- **Type**: dbt Schema
- **Purpose**: Documents Gold models and columns
- **Owner**: Data Engineering Team
- **Dependencies**: Gold models
- **When to Update**: When Gold models change
- **AI Usage**: Update when creating Gold models

### dbt Models - Quarantine (`/dbt/models/quarantine/`)

#### dbt/models/quarantine/customer_profile_rejected.sql
- **Type**: dbt Model (Quarantine)
- **Purpose**: Routes rejected records to quarantine
- **Implements**: contracts/quarantine/customer_profile_rejected.yaml
- **Owner**: Data Engineering Team
- **Dependencies**: Silver customer_profile_standardized
- **Materialization**: Incremental
- **When to Update**: When rejection criteria change
- **AI Usage**: Use as template for quarantine models

### dbt Models - Reference (`/dbt/models/reference/`)

#### dbt/models/reference/sources.yml
- **Type**: dbt Source Definition
- **Purpose**: Additional source definitions
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Update**: When adding reference sources
- **AI Usage**: Reference for additional sources

### dbt Seeds (`/dbt/seeds/reference/`)

**Purpose**: CSV seed files for enumeration lookup tables  
**Status**: Alternative to YAML enumerations (being phased out in favor of YAML)  
**Usage**: Load with `dbt seed`

#### dbt/seeds/reference/*.csv
- **Type**: dbt Seed (CSV)
- **Purpose**: Enumeration lookup data
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **Status**: Legacy - prefer /enumerations/*.yaml
- **When to Update**: When enumerations change
- **AI Usage**: Use /enumerations/*.yaml instead for new enumerations

---

## Enumerations (`/enumerations/`)

**Purpose**: YAML definitions of all enumeration fields  
**Pattern**: One YAML file per enumeration  
**Naming**: `{domain}_{attribute}.yaml`  
**Standard**: docs/data-modeling/enumeration_standards.md

### Enumeration Index

#### enumerations/README.txt
- **Type**: Documentation
- **Purpose**: Overview of enumeration management
- **Owner**: Data Architecture Team
- **Dependencies**: enumeration_standards.md
- **When to Update**: When enumeration patterns change
- **AI Usage**: Reference for understanding enumerations

### Customer Domain Enumerations

#### enumerations/customer_person_title.yaml
- **Type**: Enumeration
- **Purpose**: Valid person titles (MR, MRS, MS, MISS, DR, PROF, REV, OTHER)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **When to Update**: When new titles needed
- **AI Usage**: Reference for person_title validation

#### enumerations/customer_marital_status.yaml
- **Type**: Enumeration
- **Purpose**: Valid marital statuses (SINGLE, MARRIED, DIVORCED, WIDOWED, SEPARATED, UNKNOWN)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **When to Update**: When new statuses needed
- **AI Usage**: Reference for marital_status validation

#### enumerations/customer_nationality.yaml
- **Type**: Enumeration
- **Purpose**: Valid nationalities (ISO 3166-1 alpha-2 + OTHER)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **Standard**: ISO 3166-1 alpha-2
- **When to Update**: When countries added (rare)
- **AI Usage**: Reference for nationality validation

#### enumerations/customer_occupation.yaml
- **Type**: Enumeration
- **Purpose**: Valid occupations (EMPLOYEE, SELF_EMPLOYED, BUSINESS_OWNER, etc.)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **When to Update**: When new occupation categories needed
- **AI Usage**: Reference for occupation validation

#### enumerations/customer_education_level.yaml
- **Type**: Enumeration
- **Purpose**: Valid education levels (PRIMARY, SECONDARY, BACHELOR, MASTER, DOCTORAL, etc.)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **When to Update**: When new education levels needed
- **AI Usage**: Reference for education_level validation

#### enumerations/customer_business_type.yaml
- **Type**: Enumeration
- **Purpose**: Valid business types (FINANCE, MANUFACTURING, RETAIL, etc.)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **When to Update**: When new business categories needed
- **AI Usage**: Reference for business_type validation

#### enumerations/customer_total_asset_bands.yaml
- **Type**: Enumeration
- **Purpose**: Asset range bands (ASSET_BAND_1 through ASSET_BAND_5, UNKNOWN)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **Note**: NO "OTHER" option - must select from bands
- **When to Update**: When band definitions change (rare, requires business approval)
- **AI Usage**: Reference for total_asset validation

#### enumerations/customer_monthly_income_bands.yaml
- **Type**: Enumeration
- **Purpose**: Income range bands (INCOME_BAND_1 through INCOME_BAND_5, UNKNOWN)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **Note**: NO "OTHER" option - must select from bands
- **When to Update**: When band definitions change (rare, requires business approval)
- **AI Usage**: Reference for monthly_income validation

#### enumerations/customer_income_country.yaml
- **Type**: Enumeration
- **Purpose**: Valid income origin countries (ISO 3166-1 alpha-2 + OTHER)
- **Owner**: Data Architecture Team
- **Used By**: customer_profile dimension
- **Standard**: ISO 3166-1 alpha-2
- **When to Update**: When countries added (rare)
- **AI Usage**: Reference for income_country validation

#### enumerations/customer_source_of_income.yaml
- **Type**: Enumeration
- **Purpose**: Valid income sources (SALARY, DIVIDEND, RENTAL, BUSINESS, etc.)
- **Owner**: Data Architecture Team
- **Used By**: bridge_customer_source_of_income
- **Note**: Multi-valued set
- **When to Update**: When new income sources needed
- **AI Usage**: Reference for source_of_income validation

#### enumerations/customer_purpose_of_investment.yaml
- **Type**: Enumeration
- **Purpose**: Valid investment purposes (RETIREMENT, EDUCATION, SPECULATION, etc.)
- **Owner**: Data Architecture Team
- **Used By**: bridge_customer_purpose_of_investment
- **Note**: Multi-valued set
- **When to Update**: When new purposes needed
- **AI Usage**: Reference for purpose_of_investment validation

#### enumerations/customer_profile_audit_change_reason.yaml
- **Type**: Enumeration
- **Purpose**: Valid change reason codes for audit (INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, etc.)
- **Owner**: Data Architecture Team
- **Used By**: fact_customer_profile_audit
- **When to Update**: When new change reasons needed
- **AI Usage**: Reference for change_reason validation

#### enumerations/customer_profile_attribute_names.yaml
- **Type**: Enumeration
- **Purpose**: Valid attribute names for audit change tracking JSON
- **Owner**: Data Architecture Team
- **Used By**: fact_customer_profile_audit (changed_scalar_attributes JSON)
- **When to Update**: When customer profile attributes change
- **AI Usage**: Reference for audit JSON validation

### Audit Domain Enumerations

#### enumerations/audit_event_types.yaml
- **Type**: Enumeration
- **Purpose**: Valid audit event types (cross-domain)
- **Owner**: Data Architecture Team
- **Used By**: Multiple audit fact tables
- **When to Update**: When new event types needed
- **AI Usage**: Reference for audit event classification

---

## ETL Scripts (`/etl/`)

**Purpose**: Python scripts for Bronze layer extraction from MSSQL to PostgreSQL  
**Technology**: Python (pyodbc + psycopg2)  
**Pattern**: Incremental watermark-based extraction

### ETL Configuration

#### etl/.env.example
- **Type**: Configuration (Example)
- **Purpose**: Example environment variables for ETL scripts
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Use**: Copy to .env and customize for your environment
- **AI Usage**: Reference for required configuration

#### etl/requirements.txt
- **Type**: Configuration (Python)
- **Purpose**: Python package dependencies for ETL scripts
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Update**: When adding Python packages
- **AI Usage**: Install with `pip install -r requirements.txt`

#### etl/README.md
- **Type**: Documentation
- **Purpose**: ETL process documentation and usage guide
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Update**: When ETL process changes
- **AI Usage**: Reference for running ETL scripts

### ETL Scripts

#### etl/bronze_extract_customer_profile.py
- **Type**: Python Script (ETL)
- **Purpose**: Extracts customer profile from MSSQL IT view to PostgreSQL Bronze
- **Owner**: Data Engineering Team
- **Dependencies**: 
  - MSSQL source database
  - PostgreSQL bronze.customer_profile_standardized table
  - .env configuration
- **Pattern**: Incremental (watermark on last_modified_ts)
- **When to Run**: Scheduled (e.g., daily)
- **AI Usage**: Use as template for Bronze extraction scripts

---

## Templates (`/templates/`)

**Purpose**: Reusable SQL templates for common table patterns  
**Usage**: Copy template and customize for specific entity

### Template Index

#### templates/README.md
- **Type**: Documentation
- **Purpose**: Explains template usage and customization
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: When templates change
- **AI Usage**: Reference before using templates

### SQL Templates

#### templates/dimension_table_template.sql
- **Type**: Template (DDL)
- **Purpose**: Generic SCD2 dimension table template
- **Owner**: Data Architecture Team
- **Usage**: Replace `<placeholders>` with actual entity names
- **When to Use**: Creating new SCD2 dimensions
- **AI Usage**: Use as starting point for dimension DDL

#### templates/bridge_table_template.sql
- **Type**: Template (DDL)
- **Purpose**: Generic bridge table template for multi-valued sets
- **Owner**: Data Architecture Team
- **Usage**: Replace `<placeholders>` with actual names
- **When to Use**: Creating new bridge tables
- **AI Usage**: Use as starting point for bridge DDL

#### templates/fact_table_template.sql
- **Type**: Template (DDL)
- **Purpose**: Generic fact table template
- **Owner**: Data Architecture Team
- **Usage**: Replace `<placeholders>` with actual names
- **When to Use**: Creating new fact tables
- **AI Usage**: Use as starting point for fact DDL

---

## Examples (`/examples/`)

**Purpose**: Example implementations and use cases

#### examples/README.md
- **Type**: Documentation
- **Purpose**: Overview of examples
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Update**: When examples added
- **AI Usage**: Reference for understanding examples

#### examples/retail_sales_example.md
- **Type**: Example
- **Purpose**: Example retail sales implementation
- **Owner**: Data Architecture Team
- **Dependencies**: None
- **When to Use**: Learning how patterns apply to retail domain
- **AI Usage**: Reference for domain-specific patterns

---

## Scripts (`/scripts/`)

**Purpose**: Utility scripts for repository maintenance

#### scripts/generate_seeds_from_yaml.py
- **Type**: Python Script (Utility)
- **Purpose**: Generates dbt seed CSV files from enumeration YAML files
- **Owner**: Data Engineering Team
- **Dependencies**: /enumerations/*.yaml
- **When to Run**: When synchronizing YAML enumerations to dbt seeds
- **Note**: Part of migration from seeds to YAML (legacy support)
- **AI Usage**: Run if maintaining backward compatibility with seed-based enumerations

---

## Raw Data Samples (`/raw/`)

**Purpose**: Sample source data files for development and testing

#### raw/CustomerProfile.txt
- **Type**: Data Sample
- **Purpose**: Sample customer profile data from source system
- **Owner**: Data Engineering Team
- **Dependencies**: None
- **When to Update**: When source format changes
- **AI Usage**: Reference for understanding source data structure

#### raw/4_Metadata.xlsx
- **Type**: Data Sample
- **Purpose**: Metadata sample (likely business glossary or data dictionary)
- **Owner**: Business Analysts
- **Dependencies**: None
- **When to Update**: When metadata structure changes
- **AI Usage**: Reference for business context

---

## Deprecated (`/deprecated/`)

**Purpose**: Deprecated documentation from previous development iterations  
**Status**: Historical - keep for reference, do not use for new development

#### deprecated/STATUS.md
- **Type**: Documentation (Historical)
- **Purpose**: Development status from earlier phase
- **AI Usage**: Historical reference only

#### deprecated/WORKFLOW.md
- **Type**: Documentation (Historical)
- **Purpose**: Old workflow documentation
- **AI Usage**: Historical reference only

#### deprecated/THREAD_HANDOVER.md
- **Type**: Documentation (Historical)
- **Purpose**: Old AI thread handover procedure
- **AI Usage**: Historical reference only

#### deprecated/CHANGES_SUMMARY.md
- **Type**: Documentation (Historical)
- **Purpose**: Summary of changes in earlier iterations
- **AI Usage**: Historical reference only

#### deprecated/GAP_ANALYSIS.md
- **Type**: Documentation (Historical)
- **Purpose**: Old gap analysis (superseded by docs/AI_ONBOARDING_GAP_ANALYSIS.md)
- **AI Usage**: Historical reference only

#### deprecated/seeds/
- **Type**: Data (Historical)
- **Purpose**: Old CSV seed files for company domain
- **Status**: Superseded by /enumerations/*.yaml
- **AI Usage**: DO NOT USE - use /enumerations/ instead

---

## GitHub Configuration (`/.github/`)

**Purpose**: GitHub-specific configuration (issue templates, PR templates, workflows)

#### .github/ISSUE_TEMPLATE/data_task.md
- **Type**: Template (GitHub)
- **Purpose**: Issue template for data tasks
- **Owner**: Repository Administrators
- **Dependencies**: None
- **When to Update**: When issue workflow changes
- **AI Usage**: Reference for creating issues

#### .github/PULL_REQUEST_TEMPLATE.md
- **Type**: Template (GitHub)
- **Purpose**: Pull request template
- **Owner**: Repository Administrators
- **Dependencies**: None
- **When to Update**: When PR requirements change
- **AI Usage**: Reference for creating PRs

---

## File Relationships and Dependencies

### Critical Dependency Chains

1. **Module Creation Chain**:
   ```
   docs/business/modules/customer_module.md (spec)
   → enumerations/*.yaml (domain values)
   → contracts/bronze/*.yaml (Bronze schema)
   → contracts/silver/*.yaml (Silver schema + hashes)
   → contracts/gold/*.yaml (Gold schema + SCD2)
   → db/*/*.sql (DDL implementation)
   → dbt/models/*/*.sql (transformation implementation)
   ```

2. **Standards Chain**:
   ```
   contracts/scd2/STANDARD_SCD2_POLICY.md (SCD2 rules)
   + docs/data-modeling/naming_conventions.md (naming)
   + docs/data-modeling/hashing_standards.md (hashing)
   + docs/FOUNDATION_NAMING_CONVENTIONS.md (files)
   → All implementations must follow
   ```

3. **AI Boarding Chain**:
   ```
   docs/_ai-first-employee-boarding-guide/010*.md (load context)
   → 020*.md (analyze requirements)
   → 030*.md (generate files)
   → 040*.md (validate)
   → 041*.md + 042*.md (fix and revalidate)
   ```

### Validation Points

- **Contract → DDL**: DDL must exactly match contract specifications
- **Contract → dbt**: dbt model output must match contract specifications
- **Enumeration YAML → Silver validation**: Silver uses validate_enumeration() macro
- **Hashing Standard → Silver**: Silver uses compute_profile_hash() and compute_set_hash() macros
- **SCD2 Policy → Gold**: Gold dimensions must follow SCD2 temporal patterns

---

## Maintenance Guidelines

### When Adding a New Module

1. Create module specification in `/docs/business/modules/`
2. Create enumeration YAML files in `/enumerations/`
3. Create contracts in `/contracts/bronze/`, `/contracts/silver/`, `/contracts/gold/`
4. Create DDL in `/db/bronze/`, `/db/silver/`, `/db/gold/`
5. Create dbt models in `/dbt/models/silver/`, `/dbt/models/gold/`
6. Update this file (REPOSITORY_FILE_INDEX.md)
7. Update CONTEXT_MANIFEST.yaml
8. Update AI_CONTEXT.md if needed

### When Deprecating Files

1. Move files to appropriate `/deprecated/` or `/contracts/deprecate/` or `/db/deprecated/`
2. Create or update DEPRECATED.md explaining deprecation
3. Update this file (REPOSITORY_FILE_INDEX.md) to mark as deprecated
4. Update references in other documents

### When Changing Standards

1. Create ADR in `/docs/adr/`
2. Update standard documents
3. Update AI_CONTEXT.md
4. Update this file if structure changes
5. Migrate existing implementations if needed

---

## Quick Reference for AI Agents

### Files AI MUST Load First

1. `README.md` - Project overview
2. `AI_CONTEXT.md` - Quick reference
3. `STANDARDS_INDEX.md` - Standards locations
4. `docs/HOW_TO_REPLICATE_MODULE.md` - Module replication guide
5. `contracts/scd2/STANDARD_SCD2_POLICY.md` - SCD2 rules
6. `docs/data-modeling/naming_conventions.md` - Naming standards
7. `docs/data-modeling/hashing_standards.md` - Hashing standards

### Template Files for Module Creation

- **Specification**: `docs/business/modules/customer_module.md`
- **Enumeration**: Any file in `/enumerations/customer_*.yaml`
- **Bronze Contract**: `contracts/bronze/customer_profile_standardized.yaml`
- **Silver Contract**: `contracts/silver/customer_profile_standardized.yaml`
- **Gold Dimension Contract**: `contracts/gold/dim_customer_profile.yaml`
- **Gold Bridge Contract**: `contracts/gold/bridge_customer_income_source_version.yaml`
- **Gold Fact Contract**: `contracts/gold/fact_customer_profile_audit.yaml`
- **Bronze DDL**: `db/bronze/customer_profile_standardized.sql`
- **Gold Dimension DDL**: `db/gold/dim_customer_profile.sql`
- **Gold Bridge DDL**: `db/gold/bridge_customer_source_of_income.sql`
- **Silver dbt Model**: `dbt/models/silver/customer_profile_standardized.sql`
- **Gold Dimension dbt Model**: `dbt/models/gold/dim_customer_profile.sql`
- **Gold Bridge dbt Model**: `dbt/models/gold/bridge_customer_source_of_income.sql`

### Files AI Should NOT Modify

- Anything in `/deprecated/`
- Anything in `/contracts/deprecate/`
- Anything in `/db/deprecated/`
- ADR files (they are historical records)
- Auto-generated files (`.gitignore`, `dbt/package-lock.yml`, etc.)

---

**Document End**

**Total Files Documented**: 205  
**Last Updated**: 2026-01-05  
**Maintained By**: Data Architecture Team

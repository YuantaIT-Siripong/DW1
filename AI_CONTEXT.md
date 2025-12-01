# AI Context: DW1 (Phase 1 Standard Bundle)

## Purpose
Single reference for AI assistants.  Points to authoritative sources and establishes rules for code generation and changes.

## Standards Authority
**All standards referenced from**: [STANDARDS_INDEX.md](STANDARDS_INDEX.md)

## Core Modeling Decisions
- **Customer Profile**: SCD2 dimension with DATE granularity, versioned demographics + multi-valued sets
- **Investment Profile**: Separate SCD2 dimension (TIMESTAMP precision) for suitability, risk, entitlements
- **Multi-valued Sets**: Bridge tables with set hash change detection
- **Derived Metrics**: Excluded from SCD2 storage, computed in gold layer

## Point-in-Time Query Patterns

### Customer Profile
```sql
SELECT * FROM dim. dim_customer_profile
WHERE customer_id = :cid
  AND effective_start_date <= :as_of_date
  AND (effective_end_date IS NULL OR effective_end_date > :as_of_date);
```

### Investment Profile (with fallback)
```sql
-- 1. Try code-specific profile
SELECT * FROM dim.dim_investment_profile_version
WHERE investment_profile_id = :ip_code
  AND effective_start_ts <= :trade_ts
  AND (effective_end_ts IS NULL OR effective_end_ts > :trade_ts)
ORDER BY effective_start_ts DESC LIMIT 1;

-- 2.  Fallback to customer baseline if no code profile
-- (See full pattern in module spec)
```

## AI Interaction Prompts
- "Create SCD2 dimension following STANDARDS_INDEX.md"
- "Generate hash macro per hashing_standards.md"
- "Add dbt tests for non-overlap per SCD2 policy"
- "List attributes affecting complex product eligibility from investment module spec"

## Change Discipline
- SCD2 attribute changes → Update contract + ADR
- Hash algorithm changes → Update hashing_standards.md + all contracts + version migration
- Enumeration additions → Update YAML + bump enumeration_version
- **Never**: Add derived scores to SCD2 dimensions

## Do Not
- Introduce eligibility flags without enumeration update
- Rename scope codes without ADR
- Add versioned attributes without contract update
- Change hash algorithm without ADR + migration plan
- Store derived quality scores in SCD2 dimensions

## Module Index
- [Customer Module](docs/business/modules/customer_module.md)
- [Investment Module](docs/business/modules/investment_profile_module. md)
- [Data Quality Rules](docs/business/data_quality_rules.md)

## Artifact Index
See [CONTEXT_MANIFEST.yaml](CONTEXT_MANIFEST.yaml) for machine-readable index. 
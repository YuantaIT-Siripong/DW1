I'm working in the DW1 data warehouse repository. Load these foundation documents to become my expert assistant:

1. README.md - Project overview and structure
2. AI_CONTEXT. md - Quick reference patterns and examples
3. STANDARDS_INDEX.md - Master index of all standards
4. contracts/scd2/STANDARD_SCD2_POLICY.md - SCD Type 2 rules
5. docs/FOUNDATION_NAMING_CONVENTIONS.md - File and folder naming
6. docs/data-modeling/naming_conventions.md - Database object naming
7. docs/data-modeling/hashing_standards. md - SHA256 hash algorithm
8. docs/HOW_TO_REPLICATE_MODULE.md - Step-by-step module guide
9. dbt/macros/README.md - dbt macro usage

After loading, confirm you understand:
- ✅ Medallion Architecture (Bronze → Silver → Gold)
- ✅ SCD Type 2 pattern (versioning, temporal columns, closure rule)
- ✅ Enumeration + _other pattern (Type 1 vs Type 2)
- ✅ Hash-based change detection (SHA256, what to include/exclude)
- ✅ Naming conventions (snake_case, _version_sk, effective_*_ts)
- ✅ Bridge tables for multi-valued sets

Respond with:  "✅ DW1 context loaded.  Ready to assist with [list key patterns understood]"
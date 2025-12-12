# Load Context
Load DW1 foundation:  README, AI_CONTEXT, STANDARDS_INDEX, 
STANDARD_SCD2_POLICY, FOUNDATION_NAMING_CONVENTIONS, naming_conventions, 
hashing_standards, HOW_TO_REPLICATE_MODULE, dbt macros README


# Convert Requirement
Requirement: <paste business requirement>

Using customer_module. md template, analyze and create: 
1. Entity classification
2. Attribute analysis (Type 1 vs Type 2)
3. Enumeration identification
4. Multi-valued sets
5. Surrogate key pattern
6. Hash computation (include/exclude)

# Generate Files
Generate complete <entity> module following DW1 standards. 
Reference: customer_profile examples. 
Create 9 files: enumeration, Bronze contract+DDL, Silver contract+dbt, 
Gold contract+DDL+dbt, (bridge if needed).
Generate one at a time, wait for confirmation.

# Validate
Gap analysis on <entity> module files.
Check:  MODULE_DEVELOPMENT_CHECKLIST, STANDARD_SCD2_POLICY, 
FOUNDATION_NAMING_CONVENTIONS, naming_conventions, hashing_standards. 
Verify: naming, SCD2 pattern, hash, indexes, enums, contracts, dbt.
Show ✅/❌ with issues list and line numbers.

# Fix Issues (if needed)
Fix issues found in validation: 
<paste issue list>

Show corrected code sections only.
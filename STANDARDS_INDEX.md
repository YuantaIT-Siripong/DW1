## Customer Profile Standards (Updated 2025-12-01)

### Foundation Documents
**Foundation: File & Folder Naming Conventions**: [docs/FOUNDATION_NAMING_CONVENTIONS.md](docs/FOUNDATION_NAMING_CONVENTIONS.md)
- Comprehensive file and folder naming standards for entire repository
- Top-level directory structure
- Layer-specific conventions (bronze/silver/gold)
- Documentation file naming
- Validation rules and checklists

### Enumeration + Freetext Pattern
**Decision**: Direct enumeration codes (VARCHAR) in dimension + `_other` Type 1 freetext fields

**Type 2 Fields** (versioned, in hash):
- Enumerations: person_title, marital_status, nationality, occupation, education_level, business_type, income_country
- Bands (no OTHER): total_asset, monthly_income
- All stored as VARCHAR codes (e.g., "MR", "MARRIED", "TH")

**Type 1 Fields** (NOT versioned, NOT in hash):
- Freetext: person_title_other, nationality_other, occupation_other, education_level_other, business_type_other, income_country_other
- Populated ONLY when enumeration = "OTHER"

**Removed**: Separate lookup dimensions (dim_marital_status, dim_nationality, etc.)  
**Replaced with**: Enumeration YAML files in `enumerations/` folder

### Hash Normalization (Customer Profile)
**Storage**: Preserve original case for names (firstname, lastname, firstname_local, lastname_local)

**Hash Computation**:
```
- English fields: UPPER(TRIM)
- Local fields: TRIM (preserve case)
- Enumerations: UPPER(TRIM)
- Dates: YYYY-MM-DD
- NULLs: "__NULL__"
- Delimiter: "|"
- Exclude: _other freetext fields
```

**Profile Hash**: SHA256 of 17 ordered fields (includes 2 set hashes)  
**Empty Set Hash**: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`

### Bridge Tables
- **Naming**: `bridge_customer_*` (not `dim_*_version`)
- **PK**: (customer_profile_version_sk, code)
- **Direct codes**: No FK to lookup dimensions
- **Tables**: bridge_customer_source_of_income, bridge_customer_purpose_of_investment

### Data Types
```
customer_id: BIGINT (not STRING)
evidence_unique_key: VARCHAR(100) (not national_id)
Enumeration codes: VARCHAR(length) (not INT FK)
Timestamps: TIMESTAMP (UTC, microsecond precision)
```

### References
- **Full Spec**: [docs/business/modules/customer_module.md](docs/business/modules/customer_module.md)
- **Contract**: [contracts/gold/dim_customer_profile.yaml](contracts/gold/dim_customer_profile.yaml)
- **Enumerations**: `enumerations/customer_*. yaml` (11 files)
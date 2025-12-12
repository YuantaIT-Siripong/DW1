New module requirement from business stakeholders:

"""
[PASTE BUSINESS REQUIREMENT HERE]

Example:
"We need to track Products in our warehouse.  Each product has:
- Unique product ID
- Product name
- Category (Electronics, Clothing, Food, or other custom category)
- Price
- Active/inactive status
- Creation date

We need full history when price or category changes."
"""

Using docs/business/modules/customer_module.md as a template, analyze and create:

### 1. Entity Classification
- Entity name: 
- Domain: 
- SCD Type needed: (Type 0 / Type 1 / Type 2 / Type 3)
- Rationale: 

### 2. Attribute Analysis

List all attributes and classify: 

| Attribute | Data Type | Type 1 or Type 2?  | Nullable? | Notes |
|-----------|-----------|-------------------|-----------|-------|
| ...  | ... | ... | ... | ...  |

### 3. Enumeration Identification

List enumerations with valid values:

| Enumeration Name | Valid Values | Has OTHER? | Needs _other field? |
|------------------|--------------|------------|---------------------|
| ... | ...  | ... | ... |

### 4. Multi-Valued Sets

Identify any multi-valued sets (1-to-many relationships):

| Set Name | Values | Bridge Table Needed? |
|----------|--------|---------------------|
| ... | ... | ... |

### 5. Surrogate Key Pattern

- Primary key name: `<entity>_version_sk` (for SCD2)
- Natural key: 
- Version tracking: Yes/No

### 6. Hash Computation

Fields to INCLUDE in profile_hash:
- [ ] ... 

Fields to EXCLUDE from profile_hash:
- [ ] Surrogate keys
- [ ] Temporal columns
- [ ] Type 1 attributes (*_other fields)
- [ ] ... 

Output as structured specification ready for Step 3.
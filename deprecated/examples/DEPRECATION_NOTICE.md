# DEPRECATED: Generic Data Warehouse Examples

**Status**: ❌ **DEPRECATED**  
**Deprecated Date**: 2025-12-12  
**Reason**: Patterns do not align with current repository standards  

---

## ⚠️ DO NOT USE THESE EXAMPLES

These examples were created during the initial exploration phase and demonstrate **outdated patterns** that do NOT reflect the current repository architecture.

---

## Why These Examples Are Deprecated

### ❌ Pattern Misalignment

| Aspect | Examples (Old) | Current Standard |
|--------|---------------|------------------|
| **Architecture** | Traditional star schema | **Bronze/Silver/Gold medallion** |
| **SCD Type 2** | Generic temporal tracking | **Profile hash-based change detection** |
| **Standards** | No standards | **Contracts, enumerations, hash standards** |
| **Tooling** | Raw SQL only | **dbt for Silver/Gold transformations** |
| **Documentation** | Generic examples | **Complete module specifications** |
| **Templates** | Not reusable | **Annotated templates for all patterns** |

### 🚫 Specific Issues

1. **No Medallion Architecture**
   - Examples use single-tier star schema
   - Missing Bronze (raw landing), Silver (cleaned), Gold (dimensional) layers
   
2. **Outdated SCD2 Approach**
   - Generic temporal tracking without profile_hash
   - No SHA256-based change detection
   - No version management pattern
   
3. **No Standards Compliance**
   - Naming conventions not followed (snake_case)
   - No enumeration pattern
   - No hashing standards
   - No data quality framework
   
4. **Missing Contracts**
   - No YAML contracts defining schemas
   - No single source of truth
   - Hard to maintain consistency
   
5. **Wrong Focus**
   - Retail, E-commerce, Healthcare examples
   - Not aligned with financial services domain
   - Customer profile pattern is THE example to follow

---

## 🎯 What to Use Instead

### For Module Replication

**Primary Reference**: Customer Profile Module (complete implementation)

| Component | Location | Purpose |
|-----------|----------|---------|
| **Bronze Layer** | `/db/bronze/customer_profile_standardized.sql` | Raw landing zone pattern |
| **Silver Layer** | `/dbt/models/silver/customer_profile_standardized.sql` | Cleaned data with validation |
| **Gold Layer** | `/dbt/models/gold/dim_customer_profile.sql` | SCD2 dimension pattern |
| **Bridge Tables** | `/db/curated/bridges/bridge_customer_*.sql` | Multi-valued set pattern |
| **Contracts** | `/contracts/{bronze,silver,customer}/` | Schema specifications |

### For Step-by-Step Guidance

1. **📖 Replication Guide**: `/docs/HOW_TO_REPLICATE_MODULE.md`
   - Complete 10-step process
   - Layer-by-layer implementation
   - Validation checkpoints
   
2. **✅ Development Checklist**: `/docs/MODULE_DEVELOPMENT_CHECKLIST.md`
   - Comprehensive checklist
   - All required artifacts
   - Testing requirements
   
3. **📊 Documentation Assessment**: `/docs/DOCUMENTATION_ASSESSMENT.md`
   - Repository maturity evaluation
   - Replication readiness assessment
   - Gap analysis

### For Templates

**Location**: `/templates/`

| Template | Purpose |
|----------|---------|
| `dimension_table_template.sql` | SCD2 dimension with version management |
| `bridge_table_template.sql` | Bridge table for multi-valued sets |
| `fact_table_template.sql` | Audit fact for change tracking |

### For Module Specifications

**Location**: `/docs/business/modules/`

| Module | Status | Use As |
|--------|--------|--------|
| `customer_module.md` | ✅ Complete | **PRIMARY TEMPLATE** |
| `investment_profile_module.md` | ⏳ In Progress | Next module to build |
| `company_module.md` | ⏳ Planned | Future module |

---

## 🔍 Historical Value

These examples are preserved to show:
- ✅ Initial exploration of data warehouse concepts
- ✅ Generic industry patterns (retail, e-commerce, financial, healthcare)
- ✅ Evolution of thinking toward current standards
- ✅ What NOT to do (patterns to avoid)

---

## 📚 Learning Path for New AI Agents

### If You're Building Investment Profile Module:

1. **Start Here**: `/docs/HOW_TO_REPLICATE_MODULE.md`
2. **Reference**: Customer Profile Module implementation
3. **Follow**: Module Development Checklist
4. **Use**: Templates for dimension, bridge, fact tables
5. **Apply**: Standards (naming, hashing, enumerations)

### If You're Learning Data Warehousing:

**Instead of these deprecated examples**, study:
1. **Architecture**: `/docs/architecture/README.md` + `/docs/layers/README.md`
2. **Real Implementation**: Customer Profile module (all layers)
3. **Standards**: `/docs/data-modeling/` (naming, hashing, enumerations)
4. **Patterns**: `/docs/adr/` (architectural decision records)
5. **Contracts**: `/contracts/` (YAML schema specifications)

---

## ❓ FAQ

### Q: Can I use the retail_sales_example.md for learning?

**A**: No. It demonstrates an outdated pattern. Instead:
- Study the **Customer Profile module** for a complete, production-ready example
- Follow **HOW_TO_REPLICATE_MODULE.md** for step-by-step guidance

### Q: Why were these examples moved to deprecated instead of deleted?

**A**: Historical reference. They show the evolution of thinking and what patterns were rejected in favor of the current approach.

### Q: Will new examples be created?

**A**: Maybe. If generic examples are needed in the future, they will:
- ✅ Follow Bronze/Silver/Gold medallion architecture
- ✅ Use dbt for transformations
- ✅ Demonstrate contracts and enumerations
- ✅ Follow current naming and hashing standards
- ✅ Be aligned with customer profile pattern

### Q: What if I already started following these examples?

**A**: Stop immediately. Refactor to follow the customer profile pattern:
1. Introduce Bronze/Silver/Gold layers
2. Add profile_hash for SCD2 change detection
3. Create contracts for all layers
4. Use enumerations for categorical attributes
5. Follow naming conventions and hashing standards

---

## 🔗 Quick Links

| Resource | Link | Purpose |
|----------|------|---------|
| **Replication Guide** | `/docs/HOW_TO_REPLICATE_MODULE.md` | Step-by-step process |
| **Development Checklist** | `/docs/MODULE_DEVELOPMENT_CHECKLIST.md` | Complete artifact list |
| **Customer Profile** | `/db/`, `/dbt/models/`, `/contracts/` | Reference implementation |
| **Templates** | `/templates/` | Annotated templates |
| **Standards** | `/docs/data-modeling/` | All standards |
| **AI Context** | `/AI_CONTEXT.md` | Quick reference for AI agents |

---

**Last Updated**: 2025-12-12  
**Reason for Deprecation**: Pattern misalignment with current medallion architecture and standards  
**Alternative**: Customer Profile Module + HOW_TO_REPLICATE_MODULE.md  
**Status**: Do not use for new development  

---

## 🎯 Remember

The **Customer Profile module** is THE authoritative example.  
All new modules should follow its pattern.  
Use `/docs/HOW_TO_REPLICATE_MODULE.md` as your guide.

**When in doubt, ask: "How does Customer Profile do this?"**

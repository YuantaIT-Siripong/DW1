# Investment Profile Module - Executive Summary

## 🎯 Purpose
Create a comprehensive data warehouse module to track customer investment profiles, enabling product eligibility determination and regulatory compliance.

## 📊 What This Module Does
Stores **calculated results** that answer: **"Can customer X buy product Y?"**

Tracks:
- Suitability scores (0-100)
- Risk tolerance levels
- Investor classification (RETAIL/HNW/UHNW/INSTITUTIONAL)
- Product-specific knowledge test results
- Risk acknowledgments and agreements
- Historical changes (SCD2 versioning)

## 🚫 What This Module Does NOT Do
- Store raw questionnaire responses
- Calculate suitability scores (done by source systems)
- Make eligibility decisions (done by OMS/application layer)
- Store trading limits or account balances

## 🏢 Business Context

### Products Covered
1. Equity, TFEX, DW, DRX
2. ETF/Inverse ETF
3. Funds (standard & complex)
4. Global Equity
5. Structured Notes (local & global)
6. Bonds (investment grade, unrated, perpetual)
7. Fixed Income, SBL, Block Trade, IPO/Tender Offer

### Omnibus Account Support
Financial advisors (like Company A) can have multiple customer codes with different profiles:
- Code 111111: Conservative profile (low-risk products)
- Code 222222: Aggressive profile (high-risk products)

## 🏗️ Architecture Overview

### Main Components
```
dim_investment_profile (SCD2)
├─ Suitability & Risk attributes
├─ Investor classification
└─ Profile validity dates

Bridge Tables (multi-valued sets):
├─ Knowledge test results (DW, DRX, etc.)
└─ Risk acknowledgments (derivative, FX, etc.)

Lookup Dimensions:
├─ Investor classifications
├─ Risk levels
└─ Suitability categories
```

### Example Profile
```json
Customer C123456, Code 111111:
  Suitability Score: 45 (Moderate)
  Risk Level: Moderate
  Classification: RETAIL
  Knowledge Tests: [DW passed, expires 2025-10-15]
  Acceptances: [DERIVATIVE_RISK_ACK, HIGH_RISK_ACK]
  Profile Valid Until: 2025-10-15
```

Can this customer buy DW (Derivative Warrants)?
- ✅ Suitability 45 ≥ 60 required? ❌ **NO**
- ✅ Risk Level: Moderate ≥ Moderate-High? ❌ **NO**
- ✅ Knowledge test passed? ✅ YES
- ✅ Acknowledgments present? ✅ YES

**Result**: NOT ELIGIBLE (suitability too low)

## 📋 Documentation Delivered

### 1. Business Specification (26KB)
**File**: `docs/business/investment_profile_module.md`

**Contains**:
- Complete entity and attribute inventory
- Thailand SEC compliance rules (HNW/UHNW thresholds)
- Product eligibility matrix for all products
- SCD2 versioning rules
- Data quality requirements
- 20+ open questions for discussion

### 2. Discussion Topics (12KB)
**File**: `docs/business/investment_profile_discussion_topics.md`

**Priority Structure**:
- 🔴 5 CRITICAL questions (block schema design)
- 🟡 5 HIGH priority questions (needed for complete design)
- 🟢 5 MEDIUM priority questions (defer to implementation)

**Top 3 Critical Questions**:
1. What is the suitability score calculation methodology?
2. How long is a profile valid (12/24/36 months)?
3. How do we handle investor classification downgrades?

### 3. Product Eligibility Rules (16KB)
**File**: `docs/business/product_eligibility_rules_reference.md`

**Contains**:
- Detailed rules for each product type
- Eligibility check pseudocode
- Implementation options (DB/service/rule engine)
- Testing strategy and edge cases
- Monitoring recommendations

### 4. Architecture Decision Record (8KB)
**File**: `docs/adr/ADR-020-investment-profile-scd2.md`

**Key Decisions**:
- Use SCD2 for historical tracking
- Bridge tables for knowledge tests and acceptances
- Hash-based change detection
- Omnibus account support via customer_id + customer_code

### 5. Contract Files (7 YAML files, 35KB total)
**Directory**: `contracts/investment_profile/`

**Main Contracts**:
- `dim_investment_profile.yaml` - Main SCD2 dimension
- `dim_knowledge_test_result_version.yaml` - Test results bridge
- `dim_product_acceptance_version.yaml` - Acknowledgments bridge
- `dim_investor_classification.yaml` - HNW/UHNW/RETAIL/INSTITUTIONAL
- `dim_risk_level.yaml` - Risk tolerance levels
- `dim_suitability_category.yaml` - Suitability categories

## 🎓 Key Concepts

### Thailand SEC Investor Classifications
| Classification | Net Worth (THB) | Income (THB) | Investment (THB) | Knowledge Required |
|----------------|----------------|--------------|------------------|-------------------|
| RETAIL | < 30M | < 3M | < 8M | No |
| HNW | ≥ 30M | ≥ 3M | ≥ 8M | Yes |
| UHNW | ≥ 60M | ≥ 6M | - | Yes |
| INSTITUTIONAL | Entity | Entity | Entity | Yes |

### Suitability Categories
| Score | Category | Typical Products |
|-------|----------|------------------|
| 0-20 | Very Conservative | Fixed Income, Money Market |
| 21-40 | Conservative | Gov't Bonds, Dividend Stocks |
| 41-60 | Moderate | Equity Funds, ETF, Blue Chips |
| 61-80 | Aggressive | Stocks, High Yield, DW |
| 81-100 | Very Aggressive | Derivatives, Leveraged Products |

### Product Knowledge Tests Required
- DW (Derivative Warrants)
- DRX (Derivatives)
- PERPETUAL_BOND
- STRUCTURED_NOTE
- COMPLEX_FUND
- INVERSE_ETF
- UNRATED_BOND
- LEVERAGED_PRODUCT

## ⚠️ Critical Decisions Needed

### Before Schema Finalization
1. **Suitability Score**: Who calculates it? What's the formula?
2. **Profile Validity**: 12 or 24 months? Classification-dependent?
3. **Classification Transitions**: Automatic downgrade or manual review?
4. **Omnibus Frequency**: How common? Optimize for it?
5. **Eligibility Rule Ownership**: Database tables or config files?

### Before Implementation
- Material change thresholds (when to create new version)
- Knowledge test expiry handling (grace periods?)
- Override mechanism design
- Real-time performance requirements
- Product-specific test variations

## 📈 Benefits

### Regulatory Compliance
- Complete audit trail of all profile changes
- Point-in-time eligibility verification
- Thailand SEC classification tracking
- Knowledge test and acknowledgment records

### Risk Management
- Enforce suitability requirements
- Prevent unsuitable product sales
- Track customer sophistication evolution
- Support compliance reviews

### Business Operations
- Customer segmentation (HNW/UHNW targeting)
- Product access governance
- Omnibus account flexibility
- Historical analysis capabilities

## 🛣️ Recommended Next Steps

### Week 1: Stakeholder Alignment
- [ ] Schedule 2-hour workshop with Compliance, Product, Risk, Data Arch teams
- [ ] Review and resolve 5 CRITICAL questions
- [ ] Validate product eligibility matrix
- [ ] Confirm Thailand SEC interpretation

### Week 2: Technical Specification
- [ ] Document suitability score calculation methodology
- [ ] Map source systems to attributes
- [ ] Define ETL data flows
- [ ] Finalize remaining contract files (net worth tier, income tier, etc.)

### Week 3: Prototype & Validate
- [ ] Build proof-of-concept eligibility check
- [ ] Test with sample data
- [ ] Performance benchmarking
- [ ] Stakeholder demo and feedback

### Week 4: Implementation Planning
- [ ] Finalize ADRs (omnibus, eligibility matrix, expiry handling)
- [ ] Create project plan with milestones
- [ ] Define success criteria
- [ ] Kickoff development (if approved)

## 💡 Design Highlights

### Follows Repository Patterns
- ✅ Same structure as customer and company modules
- ✅ YAML contracts with comprehensive metadata
- ✅ SCD2 versioning with hash-based change detection
- ✅ Bridge tables for multi-valued sets
- ✅ ADR documentation for key decisions

### Addresses All Requirements
- ✅ Customer ID and customer code binding
- ✅ Omnibus account scenarios (multiple codes, different profiles)
- ✅ Suitability score tracking
- ✅ Risk level/acceptance
- ✅ HNW/UHNW status
- ✅ Knowledge tests for specific products
- ✅ Investment experience years
- ✅ Product acceptances/acknowledgments
- ✅ **Excludes source data processing** (calculated values only)
- ✅ **Focus on product eligibility** (can customer buy product X?)

### Production-Ready Considerations
- Data quality rules (15+ validations)
- Performance optimization (is_current flag, indexes)
- PII handling (masking strategies)
- Monitoring metrics defined
- Testing strategy documented
- Edge cases identified

## 📞 Contact & Review

### Document Owner
Data Architecture Team

### Required Reviewers
- [ ] Compliance Team (regulatory requirements)
- [ ] Risk Management Team (risk assessment methodology)
- [ ] Product Team (product eligibility rules)
- [ ] Business Analysis Team (business requirements)
- [ ] IT Architecture Team (technical feasibility)
- [ ] Data Governance Team (data quality standards)

### Review Focus Areas
| Team | Key Review Items |
|------|------------------|
| Compliance | Thailand SEC rules, audit requirements, test/acknowledgment definitions |
| Risk | Suitability scoring, risk level definitions, classification rules |
| Product | Eligibility matrix accuracy, product coverage, special cases |
| Business Analysis | Use case coverage, omnibus scenarios, reporting needs |
| IT Architecture | Integration patterns, performance requirements, scalability |
| Data Governance | PII handling, data quality rules, retention policies |

## ✅ Success Criteria

This module is successful when:
1. ✅ 95%+ of active customers have complete, current profiles
2. ✅ Product eligibility determined in <100ms (95th percentile)
3. ✅ Zero regulatory violations from unsuitable product sales
4. ✅ Point-in-time profile reconstruction works for all dates
5. ✅ Omnibus accounts fully supported
6. ✅ 100% accurate knowledge test and acceptance tracking
7. ✅ Clear audit trail for all changes
8. ✅ Business users can self-serve analytics and reports

## 📚 Related Documentation

- `/docs/business/customer_module.md` - Customer demographics (complementary module)
- `/docs/business/company_module.md` - Corporate customers (similar SCD2 pattern)
- `/docs/business/glossary.md` - Updated with investment profile terms
- `/docs/modeling_decisions.md` - Overall DW modeling approach

---

**Document Status**: 🟢 Ready for Stakeholder Review  
**Last Updated**: 2024-11-18  
**Version**: 1.0 - Initial Draft for Discussion  

**Next Action**: Schedule stakeholder workshop to review and resolve critical questions

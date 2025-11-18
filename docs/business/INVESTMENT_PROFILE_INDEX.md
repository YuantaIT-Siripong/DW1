# Investment Profile Module - Documentation Index

## 📋 Complete Document Inventory

This index provides a roadmap to all investment profile module documentation.

---

## 🎯 Getting Started (Choose Your Path)

### Path 1: Executive/Manager (15 minutes)
1. **START**: investment_profile_QUICK_START.md *(this document)*
2. **OVERVIEW**: investment_profile_EXECUTIVE_SUMMARY.md
3. **DECISIONS**: investment_profile_discussion_topics.md (Critical section only)

### Path 2: Business Analyst/Product Owner (1 hour)
1. **QUICK START**: investment_profile_QUICK_START.md
2. **FULL SPEC**: investment_profile_module.md
3. **RULES**: product_eligibility_rules_reference.md
4. **QUESTIONS**: investment_profile_discussion_topics.md

### Path 3: Compliance/Risk Officer (45 minutes)
1. **EXECUTIVE SUMMARY**: investment_profile_EXECUTIVE_SUMMARY.md (Regulations section)
2. **BUSINESS SPEC**: investment_profile_module.md (Sections 6, 11, 19-21)
3. **ELIGIBILITY RULES**: product_eligibility_rules_reference.md
4. **QUESTIONS**: investment_profile_discussion_topics.md (Critical + Compliance sections)

### Path 4: Technical Architect/Developer (2 hours)
1. **QUICK START**: investment_profile_QUICK_START.md
2. **ADR**: ADR-020-investment-profile-scd2.md
3. **CONTRACTS**: All YAML files in contracts/investment_profile/
4. **BUSINESS SPEC**: investment_profile_module.md (Sections 5, 8-12)

---

## 📚 All Documents

### Core Business Documentation

#### 1. investment_profile_QUICK_START.md (10KB)
**Purpose**: Fast orientation for first-time readers  
**Reading Time**: 10-15 minutes  
**Content**:
- What is an investment profile?
- Key concepts explained simply
- Real-world examples
- FAQ
- Document navigation guide

#### 2. investment_profile_EXECUTIVE_SUMMARY.md (10KB)
**Purpose**: Executive overview and decision framework  
**Reading Time**: 15-20 minutes  
**Content**:
- Module purpose and scope
- Business context
- Architecture overview
- Documentation delivered
- Thailand SEC compliance
- Critical decisions needed
- Recommended next steps

#### 3. investment_profile_module.md (26KB)
**Purpose**: Complete business specification  
**Reading Time**: 1-2 hours  
**Content**:
- 23 comprehensive sections
- Entity and attribute inventory
- Investor classification rules
- Suitability score framework
- Product eligibility matrix
- Omnibus account scenarios
- Versioning rules
- Data quality requirements
- 20+ open questions
- Success criteria

#### 4. investment_profile_discussion_topics.md (12KB)
**Purpose**: Prioritized questions and decision tracking  
**Reading Time**: 30-45 minutes  
**Content**:
- 40+ discussion questions
- Critical/High/Medium prioritization
- 5 blocking questions
- Decision log template
- Next steps checklist
- Stakeholder assignments

#### 5. product_eligibility_rules_reference.md (16KB)
**Purpose**: Detailed product eligibility matrix  
**Reading Time**: 45 minutes  
**Content**:
- Rules for 13+ product types
- Required tests and acknowledgments
- Eligibility check pseudocode
- Implementation options
- Testing strategy
- Edge cases
- Monitoring recommendations

---

### Technical Documentation

#### 6. ADR-020-investment-profile-scd2.md (8KB)
**Purpose**: Architecture decision record  
**Reading Time**: 30 minutes  
**Content**:
- Rationale for SCD2 approach
- Versioning rules
- Hash specifications
- Alternatives considered
- Consequences (pros/cons)
- Implementation notes
- Query patterns

---

### Contract Files (YAML)

Location: `contracts/investment_profile/`

#### 7. dim_investment_profile.yaml (10KB)
- Main SCD2 dimension
- 25+ attributes
- Foreign keys
- Data quality rules
- Sample rows

#### 8. dim_knowledge_test_result_version.yaml (4KB)
- Bridge table for knowledge tests
- Test expiry tracking
- Set hash logic

#### 9. dim_product_acceptance_version.yaml (5KB)
- Bridge table for acceptances
- 10+ acceptance types
- Expiry tracking

#### 10. dim_investor_classification.yaml (5KB)
- Thailand SEC classifications
- HNW/UHNW criteria
- Knowledge requirements

#### 11. dim_risk_level.yaml (4KB)
- 5 risk levels
- Score ranges (1-10)
- Descriptions

#### 12. dim_suitability_category.yaml (4KB)
- 5 suitability categories
- Score ranges (0-100)
- Typical products

#### 13. README.md (3KB)
- Contract overview
- Dependencies
- Status
- Next steps

---

### Supporting Documentation

#### 14. glossary.md (Updated)
Location: `docs/business/glossary.md`
- Investment Profile entity added
- 10+ new terms
- Phase 2 constants
- Updated exclusions

---

## 📊 Documentation Statistics

| Category | Files | Total Size | Reading Time |
|----------|-------|-----------|--------------|
| Business Docs | 5 | ~74KB | 3-4 hours |
| Technical Docs | 1 ADR | ~8KB | 30 minutes |
| Contracts | 7 YAMLs | ~35KB | 1-2 hours |
| Supporting | 1 glossary | Updated | 10 minutes |
| **TOTAL** | **14 files** | **~117KB** | **5-7 hours** |

*Note: Reading times are for detailed review. Quick scan takes 1-2 hours total.*

---

## 🎯 By Role

### Product Manager
**Must Read**:
1. investment_profile_EXECUTIVE_SUMMARY.md
2. investment_profile_module.md (Sections 1-9)
3. product_eligibility_rules_reference.md

**Should Review**:
- investment_profile_discussion_topics.md

**Time Needed**: 2-3 hours

---

### Compliance Officer
**Must Read**:
1. investment_profile_EXECUTIVE_SUMMARY.md (Regulations section)
2. investment_profile_module.md (Sections 6, 11, 19-21)
3. product_eligibility_rules_reference.md

**Should Review**:
- investment_profile_discussion_topics.md (Critical + Regulatory sections)

**Time Needed**: 2 hours

---

### Technical Lead
**Must Read**:
1. ADR-020-investment-profile-scd2.md
2. All contracts/*.yaml files
3. investment_profile_module.md (Sections 5, 8-12)

**Should Review**:
- investment_profile_QUICK_START.md (for context)
- investment_profile_discussion_topics.md (Technical section)

**Time Needed**: 3-4 hours

---

### Business Analyst
**Must Read**:
1. investment_profile_QUICK_START.md
2. investment_profile_module.md (full)
3. investment_profile_discussion_topics.md
4. product_eligibility_rules_reference.md

**Time Needed**: 4-5 hours

---

### Executive Sponsor
**Must Read**:
1. investment_profile_EXECUTIVE_SUMMARY.md

**Optional**:
- investment_profile_discussion_topics.md (Critical section)

**Time Needed**: 20-30 minutes

---

## 🔍 By Topic

### Understanding the Basics
1. investment_profile_QUICK_START.md
2. investment_profile_EXECUTIVE_SUMMARY.md

### Business Requirements
1. investment_profile_module.md
2. investment_profile_discussion_topics.md

### Product Eligibility
1. product_eligibility_rules_reference.md
2. investment_profile_module.md (Section 8)

### Technical Architecture
1. ADR-020-investment-profile-scd2.md
2. contracts/investment_profile/*.yaml

### Thailand SEC Compliance
1. investment_profile_module.md (Section 6)
2. investment_profile_EXECUTIVE_SUMMARY.md (Key Concepts)
3. dim_investor_classification.yaml

### Omnibus Accounts
1. investment_profile_module.md (Section 9)
2. ADR-020-investment-profile-scd2.md (Omnibus section)
3. investment_profile_QUICK_START.md (Omnibus FAQ)

---

## ✅ Review Checklist

### Before Stakeholder Workshop
- [ ] All stakeholders have read Executive Summary
- [ ] Product team has reviewed eligibility matrix
- [ ] Compliance has validated Thailand SEC interpretation
- [ ] Technical team has reviewed contracts and ADR
- [ ] Critical questions (C1-C5) have been distributed

### Workshop Preparation
- [ ] Printed/shared discussion_topics.md
- [ ] Decision log template ready
- [ ] Sample customer scenarios prepared
- [ ] Product eligibility examples ready

### Post-Workshop
- [ ] All critical questions resolved and documented
- [ ] Decision log updated
- [ ] Contracts updated based on decisions
- [ ] Next steps assigned with owners

---

## 🚀 Quick Access

### Most Important 3 Documents
1. **investment_profile_EXECUTIVE_SUMMARY.md** - Start here
2. **investment_profile_module.md** - Complete specification
3. **investment_profile_discussion_topics.md** - Questions to resolve

### For Quick Reference
- **Product rules**: product_eligibility_rules_reference.md
- **Data model**: contracts/investment_profile/README.md + YAMLs
- **Architecture**: ADR-020-investment-profile-scd2.md

---

## 📞 Document Owners

| Document Type | Owner Team | Reviewers |
|--------------|------------|-----------|
| Business Specs | Business Analysis | Product, Compliance, Risk |
| Product Rules | Product Team | Compliance, Risk |
| Technical Specs | Data Architecture | Development, DBA |
| Contracts | Data Architecture | All teams |
| ADRs | Data Architecture | Technical teams |

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-11-18 | Initial documentation package |

---

## 📝 Status

**Overall Status**: 🟢 Ready for Stakeholder Review  
**Next Milestone**: Stakeholder workshop to resolve critical questions  
**Estimated Timeline**: 4 weeks to implementation start (after approval)

---

**Last Updated**: 2024-11-18  
**Maintained By**: Data Architecture Team  
**Contact**: [Your contact info]

# Investment Profile Module - Quick Start Guide

## 📖 For New Readers

If you're reviewing the Investment Profile Module documentation for the first time, start here.

---

## 🎯 What Is This Module?

An investment profile is a **snapshot of a customer's investment capability**. It answers:

> **"Can this customer buy this product?"**

Think of it as a **financial passport** that:
- Shows customer's risk tolerance (Conservative → Aggressive)
- Proves they understand complex products (knowledge tests passed)
- Records their acknowledgment of specific risks
- Tracks their investor classification (Retail, HNW, UHNW)

**Example**: Customer wants to buy Derivative Warrants (DW)
- Need: Suitability score ≥60, Moderate-High risk tolerance, DW knowledge test passed, risk acknowledgments signed
- Profile shows: Score=45, Risk=Moderate, No DW test
- Result: ❌ NOT ELIGIBLE (score too low, test missing)

---

## 📂 Documentation Structure

### Start Here (5 minutes)
📄 **investment_profile_EXECUTIVE_SUMMARY.md** (this document's companion)
- Overview of what the module does
- Key concepts explained simply
- What's included in the documentation
- Next steps

### For Business Stakeholders (30 minutes)
📄 **investment_profile_module.md**
- Complete business specification (26KB, 23 sections)
- All attributes explained with examples
- Product eligibility requirements
- Omnibus account scenarios
- Open questions for discussion

📄 **investment_profile_discussion_topics.md**
- 40+ questions organized by priority
- What needs to be decided before implementation
- Decision tracking template

### For Product/Compliance Teams (20 minutes)
📄 **product_eligibility_rules_reference.md**
- Detailed eligibility rules for each product
- What tests and acknowledgments are required
- Implementation options
- Testing scenarios

### For Technical Teams (1 hour)
📁 **contracts/investment_profile/** (7 YAML files)
- Database schema definitions
- Attribute specifications
- Data quality rules
- Foreign key relationships

📄 **ADR-020-investment-profile-scd2.md**
- Why we chose SCD Type 2
- Technical design decisions
- Implementation notes

---

## 🔑 Key Concepts (60-Second Version)

### Suitability Score (0-100)
How suitable is the customer for risky investments?
- 0-20: Very Conservative (only safe products)
- 41-60: Moderate (balanced portfolio)
- 81-100: Very Aggressive (derivatives, complex products)

### Risk Level
Customer's tolerance for volatility:
- Very Conservative → Conservative → Moderate → Aggressive → Very Aggressive

### Investor Classification (Thailand SEC)
- **RETAIL**: Standard investors
- **HNW** (High Net Worth): ≥30M THB net worth OR ≥3M income
- **UHNW** (Ultra HNW): ≥60M THB net worth OR ≥6M income
- **INSTITUTIONAL**: Corporate/fund investors

### Knowledge Tests
Product-specific tests to prove understanding:
- DW (Derivative Warrants)
- DRX (Derivatives)
- Structured Notes, Perpetual Bonds, etc.
- Tests expire (typically 12 months)

### Acceptances/Acknowledgments
Customer agrees they understand specific risks:
- Derivative risk
- Foreign exchange (FX) risk
- High-risk product risk
- Complex product risk
- Etc.

### Omnibus Accounts
Financial advisor Company A manages funds for different client groups:
- Customer Code 111111: Conservative clients → Low-risk profile
- Customer Code 222222: Aggressive clients → High-risk profile

Each code gets its own investment profile!

---

## 📊 Real-World Example

### Customer Profile
```
Customer: John Smith (C123456)
Customer Code: 111111 (Conservative Fund)

Investment Profile:
├─ Suitability Score: 45 (Moderate)
├─ Risk Level: Moderate
├─ Classification: RETAIL
├─ Net Worth Tier: 2 (10-30M THB)
├─ Investment Experience: 5 years
├─ Knowledge Tests Passed:
│  └─ DW (expires 2025-10-15)
└─ Acceptances:
   ├─ DERIVATIVE_RISK_ACK ✓
   └─ HIGH_RISK_ACK ✓
```

### Eligibility Checks

**Q: Can John buy regular Equity stocks?**
- Min suitability: 30 ✅ (John has 45)
- Min risk: Conservative ✅ (John is Moderate)
- Tests needed: None ✅
- **Answer: YES ✅**

**Q: Can John buy Derivative Warrants (DW)?**
- Min suitability: 60 ❌ (John only has 45)
- Min risk: Moderate-High ❌ (John is Moderate)
- DW test passed: ✅ (expires 2025-10-15)
- Acknowledgments: ✅ (has both)
- **Answer: NO ❌** (suitability too low, risk level insufficient)

**Q: Can John buy Government Bonds?**
- Min suitability: 25 ✅
- Min risk: Very Conservative ✅
- **Answer: YES ✅**

---

## 🎬 Current Status

### ✅ What's Complete
- [x] Business requirements documented
- [x] Thailand SEC regulations researched
- [x] Product eligibility matrix drafted
- [x] Database schema designed (7 YAML contracts)
- [x] 40+ discussion questions identified
- [x] Architecture decisions documented
- [x] Sample data and examples provided

### 🟡 What's Needed
- [ ] Stakeholder workshop to resolve critical questions
- [ ] Validate suitability score calculation methodology
- [ ] Confirm product eligibility rules with Compliance
- [ ] Map source systems to attributes
- [ ] Define ETL processes

### 🔴 What's Blocked
- Code generation (waiting for business decisions)
- ETL implementation (waiting for source system mapping)
- Testing (waiting for sample data from source systems)

---

## ❓ FAQ

### Q: Why no code yet?
**A**: Per the requirement: *"I want to discuss & solve everything first, until business term is crystal clear before proceeding generate code"*

We've documented everything needed for informed discussion. Code comes after business sign-off.

### Q: Where's the suitability score calculation?
**A**: That's **not** in this module! We only store the **final calculated score**. The calculation happens in the source assessment system.

This module is **output only** - we get calculated values from upstream systems and store them for product eligibility checks.

### Q: How is this different from Customer Profile?
**A**: Customer Profile = **who they are** (demographics, occupation, income sources)
Investment Profile = **what they can invest in** (risk tolerance, product knowledge, eligibility)

They complement each other!

### Q: What's an omnibus account?
**A**: A financial advisor managing money for multiple client groups. Each group needs different investment restrictions.

Example: Pension fund (conservative) vs. Venture fund (aggressive) - same advisor company, different customer codes, different investment profiles.

### Q: Do we track every product a customer can buy?
**A**: No! We track **profile attributes**. The eligibility check logic (in the application or database) **derives** which products are eligible.

We store: suitability=60, risk=Moderate, tests=[DW], etc.
Application decides: "With these attributes, customer can buy X, Y, Z products"

### Q: How long does a profile last?
**A**: **CRITICAL QUESTION** that needs business decision! Could be:
- 12 months (annual reassessment)
- 24 months for UHNW
- Until customer situation changes significantly

See discussion_topics.md for full question list.

---

## 🚀 Next Actions

### For Business Stakeholders
1. Read **investment_profile_EXECUTIVE_SUMMARY.md** (10 min)
2. Review **investment_profile_module.md** Section 1-5 (20 min)
3. Review **product_eligibility_rules_reference.md** for your products (15 min)
4. Prepare feedback on critical questions in **discussion_topics.md**

### For Compliance Team
1. Validate Thailand SEC classification rules (Section 6 of main doc)
2. Review product eligibility matrix (product_eligibility_rules_reference.md)
3. Confirm knowledge test and acceptance requirements
4. Review audit and retention requirements

### For Product Team
1. Validate product list and categorization
2. Confirm eligibility requirements per product
3. Review knowledge test types needed
4. Identify missing products or special cases

### For Technical Team
1. Review contracts (YAML files) for data model understanding
2. Review ADR-020 for architectural decisions
3. Identify source systems for each attribute
4. Estimate ETL complexity and timeline

### For Everyone
**Schedule Workshop**: 2-hour session to resolve critical questions and align on next steps

---

## 📞 Questions?

- **Business Requirements**: See discussion_topics.md for organized Q&A
- **Product Eligibility**: See product_eligibility_rules_reference.md
- **Technical Design**: See ADR-020-investment-profile-scd2.md
- **Data Model**: See contracts/investment_profile/ directory

---

## 💡 Tips for Effective Review

1. **Don't read everything at once** - Start with Executive Summary, then dive into areas relevant to your role
2. **Focus on your domain** - Product team: eligibility matrix, Compliance: regulations, Tech: contracts
3. **Mark up the docs** - Add comments, questions, suggestions directly
4. **Bring examples** - Real customer scenarios help clarify requirements
5. **Think edge cases** - What happens when X? What if Y?

---

**Document Purpose**: Fast orientation for new readers  
**Reading Time**: 10-15 minutes  
**Target Audience**: Anyone reviewing investment profile documentation for first time  
**Next Step**: Read the Executive Summary, then dive into role-specific documents

---

## 📚 Document Map

```
investment_profile_EXECUTIVE_SUMMARY.md (you are here)
├─ START HERE: Overview & next steps
│
├─ BUSINESS DETAILS
│  ├─ investment_profile_module.md (26KB, comprehensive spec)
│  ├─ investment_profile_discussion_topics.md (questions & decisions)
│  └─ product_eligibility_rules_reference.md (eligibility matrix)
│
├─ TECHNICAL DETAILS
│  ├─ contracts/investment_profile/*.yaml (7 files, schema)
│  └─ ADR-020-investment-profile-scd2.md (architecture decisions)
│
└─ SUPPORTING
   └─ glossary.md (updated with investment profile terms)
```

**Total Documentation**: ~107KB across 13 files  
**Status**: Ready for stakeholder review and discussion

# Investment Profile Module - Discussion Topics & Clarification Checklist

## Purpose
This document tracks all open questions, discussion points, and items requiring clarification before proceeding with implementation of the Investment Profile Module. It is organized by priority and stakeholder group.

---

## 🔴 CRITICAL - Must Resolve Before Schema Design

### C1. Suitability Score Methodology
**Question**: What is the official algorithm/methodology for calculating the suitability score (0-100)?

**Details Needed**:
- Input factors and their weights
- Score calculation formula or lookup table
- Who owns the scoring algorithm (Compliance, Risk, Product team)?
- Is scoring done by external system or calculated in-house?
- How often can scores change (real-time, batch daily, manual only)?

**Stakeholders**: Compliance Team, Risk Management, Business Analysis

**Dependencies**: Attribute definition, versioning triggers, ETL design

**Current Status**: 🟡 Open

---

### C2. Profile Validity Period
**Question**: How long is an investment profile valid before requiring renewal/reassessment?

**Details Needed**:
- Standard validity period: 12 months? 24 months? 36 months?
- Does validity vary by investor classification (e.g., UHNW = longer)?
- Grace period after expiry before restricting trading?
- Automatic profile expiry process or manual notification?
- Can expired profiles be renewed without full reassessment?

**Stakeholders**: Compliance Team, Regulatory Affairs

**Dependencies**: expiry_date attribute definition, ETL scheduling, monitoring

**Current Status**: 🟡 Open

---

### C3. Investor Classification Transition Rules
**Question**: How are transitions between investor classifications handled?

**Details Needed**:
- If customer's net worth drops below HNW threshold, automatic downgrade to RETAIL?
- Does downgrade happen immediately or at next reassessment?
- Manual override allowed? Who can approve?
- Notification process to customer when downgraded?
- Product access impact - immediate restriction or grandfathered positions?

**Stakeholders**: Compliance Team, Product Team, Customer Service

**Dependencies**: Versioning logic, audit requirements, customer communication

**Current Status**: 🟡 Open

---

### C4. Omnibus Account Frequency & Design
**Question**: How common are omnibus account scenarios? Should we optimize for this?

**Details Needed**:
- Current number of omnibus accounts in production
- Expected growth rate
- Typical structure: how many customer codes per parent entity?
- Do all codes need different profiles or can some share?
- Master profile with code-level overrides vs. fully independent profiles?

**Stakeholders**: Product Team, Business Analysis, Key Account Managers

**Dependencies**: Schema design (customer_id vs customer_code), indexing strategy

**Current Status**: 🟡 Open

---

### C5. Product Eligibility Matrix Authority
**Question**: Who owns and maintains the product eligibility rules?

**Details Needed**:
- Product Team, Compliance, or joint ownership?
- How often do eligibility rules change?
- Approval process for rule changes
- Should rules be in database tables or configuration files?
- Versioning of eligibility rules for historical accuracy

**Stakeholders**: Product Team, Compliance Team, IT Architecture

**Dependencies**: Database schema vs. application config, rule engine design

**Current Status**: 🟡 Open

---

## 🟡 HIGH PRIORITY - Needed for Complete Design

### H1. Knowledge Test Expiry Handling
**Question**: What happens when a knowledge test expires?

**Details Needed**:
- Immediate product access restriction or grace period?
- Can customer keep existing positions but not open new?
- Notification timeline (30 days before expiry)?
- Automatic test retake scheduling or customer-initiated?
- Different expiry rules per product category?

**Stakeholders**: Compliance Team, Product Team, Customer Service

**Current Status**: 🟡 Open

---

### H2. Material Change Thresholds
**Question**: What constitutes a "material" change requiring new profile version?

**Details Needed**:
- Suitability score: ±5 points? ±10 points? Category change only?
- Risk score: ±1 point? ±2 points?
- Investment experience: ±1 year? ±2 years?
- Should we version on every change or apply thresholds to reduce churn?

**Stakeholders**: Data Architecture, Compliance Team

**Current Status**: 🟡 Open

---

### H3. Total Portfolio Value Source
**Question**: What does total_portfolio_value include?

**Details Needed**:
- Internal holdings only or includes external declared assets?
- Market value or book value?
- Includes cash/deposits or securities only?
- Update frequency: daily, weekly, real-time?
- Source system: calculated in DW or provided by upstream?

**Stakeholders**: Product Team, Data Engineering

**Current Status**: 🟡 Open

---

### H4. Risk Level Granularity
**Question**: Is 1-10 risk score sufficient or do we need finer granularity?

**Details Needed**:
- Current assessment generates 1-10 scale or different?
- Do we need separate dimensions (risk capacity vs. risk tolerance)?
- Alignment with product risk ratings (same scale)?
- International standard we should follow (MiFID, FINRA)?

**Stakeholders**: Risk Management, Compliance Team

**Current Status**: 🟡 Open

---

### H5. Override Mechanism
**Question**: Can relationship managers override product restrictions?

**Details Needed**:
- Override allowed for which scenarios?
- Authorization levels required
- Time-limited override or permanent exception?
- How to track overrides (attribute, audit fact, separate table)?
- Compliance review required for overrides?

**Stakeholders**: Compliance Team, Sales/RM Leadership, Risk Management

**Current Status**: 🟡 Open

---

## 🟢 MEDIUM PRIORITY - Can Defer to Implementation Phase

### M1. Real-time vs Batch Requirements
**Question**: Performance requirements for profile updates and eligibility checks?

**Details Needed**:
- Eligibility check latency SLA: <100ms? <500ms? <1s?
- Profile update: real-time or batch acceptable?
- Peak load: queries per second?
- Caching strategy acceptable?

**Stakeholders**: IT Architecture, Product Team

**Current Status**: 🟢 Defer to Implementation

---

### M2. Product-Specific Test Rules
**Question**: Detailed knowledge test requirements per product?

**Details Needed**:
- DW: call vs put separate tests or combined?
- Structured notes: local vs global separate?
- ETF vs Inverse ETF: same test or different?
- Bond: unrated vs perpetual separate tests?

**Stakeholders**: Product Team, Compliance Team

**Current Status**: 🟢 Defer to Implementation

---

### M3. Cross-Border Profile Requirements
**Question**: Do global trading customers need different profiles per market?

**Details Needed**:
- Single global profile or per-jurisdiction?
- Thailand SEC rules vs. US/EU/other regulations
- How to handle conflicting requirements?

**Stakeholders**: Compliance Team, Global Trading Product Team

**Current Status**: 🟢 Defer to Implementation

---

### M4. Audit Retention Period
**Question**: How long to retain old profile versions?

**Details Needed**:
- Regulatory requirement: 5 years? 7 years? Indefinitely?
- Online vs. archived storage strategy
- Purge process or keep forever?

**Stakeholders**: Compliance Team, Data Governance, IT Operations

**Current Status**: 🟢 Defer to Implementation

---

### M5. PII Classification
**Question**: Are suitability score, risk level, or classification PII?

**Details Needed**:
- Masking requirements for non-privileged access?
- GDPR/PDPA considerations?
- Which teams have access to unmasked data?

**Stakeholders**: Legal/Privacy Team, Data Governance, Compliance

**Current Status**: 🟢 Defer to Implementation

---

## 📋 DATA QUALITY & MONITORING

### DQ1. Profile Completeness Targets
**Question**: What is acceptable completeness score threshold?

**Suggestion**: 95% for active trading customers, 80% for dormant

**Stakeholders**: Data Governance, Business Analysis

---

### DQ2. Stale Profile Alerts
**Question**: When to alert on approaching expiry?

**Suggestion**: 30 days, 14 days, 7 days before expiry

**Stakeholders**: Customer Service, Compliance Team

---

### DQ3. Missing Knowledge Test Monitoring
**Question**: How to detect customers trading products without valid tests?

**Suggestion**: Daily batch job comparing trades vs. profile eligibility

**Stakeholders**: Compliance Team, Risk Management

---

### DQ4. Classification Inconsistency Detection
**Question**: How to identify HNW status without supporting financial data?

**Suggestion**: Weekly validation report flagging mismatches

**Stakeholders**: Data Quality Team, Compliance Team

---

## 🔄 INTEGRATION & TECHNICAL

### I1. Source System Mapping
**Question**: Which systems provide which profile attributes?

**Action Required**: Create detailed source-to-target mapping matrix

**Stakeholders**: Data Engineering, Business Analysis

---

### I2. OMS Integration Pattern
**Question**: How does Order Management System query investment profiles?

**Options**:
1. Direct database read (materialized view)
2. RESTful API
3. Message queue publication
4. Shared cache layer

**Stakeholders**: IT Architecture, OMS Team, Data Engineering

---

### I3. Error Handling Strategy
**Question**: What happens when profile unavailable or expired during order entry?

**Options**:
1. Hard reject
2. Warning with manual override
3. Queue for manual review

**Stakeholders**: Product Team, OMS Team, Customer Service

---

## 📊 ANALYTICS & REPORTING

### A1. Standard Reports Needed
**Question**: What are the top 10 reports using investment profile data?

**Action Required**: Gather requirements from business users

**Stakeholders**: Business Analysis, BI Team, Sales/RM Teams

---

### A2. Segmentation Dimensions
**Question**: Primary dimensions for customer segmentation?

**Examples**: Risk level, classification, product access tier, knowledge breadth

**Stakeholders**: Marketing, Product Team, Business Analysis

---

## ✅ DECISION LOG

| # | Question | Decision | Date | Owner | Status |
|---|----------|----------|------|-------|--------|
| - | (Example) Profile validity period | 12 months standard, 24 for UHNW | TBD | Compliance | ⏳ Pending |
| - | | | | | |

---

## 📝 NEXT STEPS

1. **Schedule Workshop**: Gather key stakeholders for 2-hour discussion session
   - Attendees: Compliance, Risk, Product, Data Arch, Business Analysis
   - Agenda: Address all CRITICAL (C1-C5) questions
   - Output: Documented decisions for each item

2. **Create Source System Inventory**: Document all upstream systems providing profile data
   - Assessment platform
   - Knowledge test system
   - Wealth management platform
   - Manual entry tools

3. **Prototype Eligibility Check**: Build proof-of-concept for product eligibility logic
   - Test with real product requirements
   - Measure query performance
   - Validate accuracy

4. **Regulatory Review**: Confirm Thailand SEC compliance requirements with legal team
   - Investor classification criteria
   - Knowledge test requirements
   - Suitability documentation
   - Audit trail standards

5. **Finalize Contracts**: Update YAML contracts based on decisions from workshops
   - Complete attribute definitions
   - Add derived field formulas
   - Document all validation rules

---

**Document Owner**: Data Architecture Team  
**Last Updated**: 2024-11-18  
**Next Review**: After stakeholder workshop

**Status Legend**:
- 🔴 CRITICAL: Blocks schema design
- 🟡 HIGH: Needed for complete design
- 🟢 MEDIUM: Can defer to implementation
- ⏳ Pending: Awaiting input
- ✅ Resolved: Decision made

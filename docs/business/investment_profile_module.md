# Investment Profile Module Domain Specification (Phase 2 - Planning)

## 1. Module Overview
The Investment Profile Module establishes the canonical representation of a customer's investment suitability, risk tolerance, product knowledge, and regulatory compliance attributes. This module is designed to work alongside the Customer Profile Module and enables precise product eligibility determination and regulatory compliance tracking. It supports both individual customer codes and omnibus account scenarios where different customer codes under the same parent entity may have different investment profiles.

**Key Design Principle**: This module stores only **calculated/derived values** and final assessment results. It explicitly excludes the source data processing logic, questionnaire responses, or calculation methodologies.

## 2. Business Goals / KPIs
- Investment profile completeness rate (percentage of active customers with current valid profiles)
- Product eligibility coverage (customers who can access each product category)
- Suitability assessment recency (average days since last update)
- Knowledge test validity rate (percentage of tests still within validity period)
- Risk-product mismatch detection rate (transactions requiring override/approval)
- High net worth classification accuracy
- Regulatory compliance coverage (customers with all required acknowledgments)

## 3. Core Use Cases
- **Product Eligibility Check**: Can customer X buy product Y based on their current investment profile?
- **Suitability Validation**: Does a proposed transaction align with customer's risk tolerance and investment objectives?
- **Regulatory Compliance**: Has customer acknowledged all required risks for complex/derivative products?
- **Point-in-Time Audit**: What was the customer's investment profile on a specific trade date?
- **Segmentation & Analytics**: Analyze customer distribution across risk levels, HNW status, product knowledge
- **Omnibus Account Management**: Different investment profiles for different customer codes under same parent entity

## 4. Entity Inventory
| Entity | Type | Description |
|--------|------|-------------|
| Investment Profile | Dimension (SCD2) | Versioned investment suitability & risk attributes per customer_id or customer_code |
| Investor Classification | Lookup | Retail, HNW, UHNW, Institutional classifications |
| Suitability Score | Lookup | Standardized suitability score ranges and meanings |
| Risk Level | Lookup | Risk tolerance levels (Conservative, Moderate, Aggressive, etc.) |
| Product Knowledge Test | Bridge | Product-specific knowledge test results per profile version |
| Product Acceptance | Bridge | Product category acceptances and risk acknowledgments per profile version |
| Investment Profile Audit Event | Fact (Audit) | Profile change events with reasons and timestamps |
| Product Eligibility Matrix | Reference | Mapping of profile attributes to product access permissions |

## 5. Investment Profile Attributes (Proposed)
| Attribute | Description | Example | Versioning | Business Rule |
|-----------|-------------|---------|-----------|---------------|
| investment_profile_id | Globally unique profile version ID | IP-100001 | Yes | Primary key |
| customer_id | Link to customer identity | C123456 | No | FK to dim_customer |
| customer_code | Specific customer code (for omnibus scenarios) | 111111 | No | Optional; enables code-level profiles |
| profile_version_num | Sequential version number per customer | 3 | Yes | Auto-increment |
| suitability_score | Numeric suitability assessment score | 75 | Yes | 0-100 scale, derived from assessment |
| suitability_category_id | Categorical suitability level | MODERATE | Yes | FK to dim_suitability_category |
| risk_level_id | Risk tolerance/acceptance level | MODERATE_RISK | Yes | FK to dim_risk_level |
| risk_score | Numeric risk tolerance score | 6 | Yes | 1-10 scale, higher = more risk tolerant |
| investor_classification_id | HNW/UHNW/Retail/Institutional | HNW | Yes | FK to dim_investor_classification |
| hnw_status | High net worth flag | Y | Yes | Derived from classification |
| uhnw_status | Ultra high net worth flag | N | Yes | Derived from classification |
| net_worth_tier_id | Net worth categorization | TIER_3 | Yes | FK to dim_net_worth_tier |
| annual_income_tier_id | Income categorization | TIER_2 | Yes | FK to dim_income_tier |
| investment_experience_years | Years of investment experience | 8 | Yes | Non-negative integer |
| total_portfolio_value | Total investment portfolio value (if available) | 15000000 | Yes | Optional, masked in non-privileged views |
| knowledge_test_set_hash | Hash of product knowledge test results | sha256(...) | Yes | Derived from bridge |
| acceptance_set_hash | Hash of product acceptances/acknowledgments | sha256(...) | Yes | Derived from bridge |
| profile_hash | Composite hash of all versioning attributes | sha256(...) | Derived | Change detection |
| effective_start_ts | Profile version start timestamp (UTC) | 2024-11-01T08:00:00Z | Yes | Microsecond precision |
| effective_end_ts | Profile version end (null=current) | null | Yes | SCD2 closure |
| assessment_date | Date of assessment/questionnaire completion | 2024-11-01 | Yes | When profile was established |
| expiry_date | Profile validity expiration date | 2025-11-01 | Yes | Regulatory validity period |
| is_current | Current version flag | Y | Derived | For query optimization |
| load_ts | ETL ingestion timestamp | 2024-11-01T08:05:00Z | No | ETL metadata |

### 5.1 Product Knowledge Test Attributes (Bridge Table)
| Attribute | Description | Example | Business Rule |
|-----------|-------------|---------|---------------|
| investment_profile_id | Profile version reference | IP-100001 | FK |
| product_category_code | Product requiring knowledge test | DW | FK to dim_product_category |
| test_pass_flag | Passed test indicator | Y | Y/N |
| test_score | Test score if applicable | 85 | 0-100 or null |
| test_date | Date test was completed | 2024-10-15 | Not null |
| test_expiry_date | Test validity expiration | 2025-10-15 | May be null for permanent |
| test_version | Test version/iteration | V2.3 | For audit trail |

Product categories requiring knowledge tests:
- DW (Derivative Warrants)
- DRX (Derivatives)
- PERPETUAL_BOND
- STRUCTURED_NOTE
- COMPLEX_FUND
- INVERSE_ETF
- UNRATED_BOND
- LEVERAGED_PRODUCT

### 5.2 Product Acceptance Attributes (Bridge Table)
| Attribute | Description | Example | Business Rule |
|-----------|-------------|---------|---------------|
| investment_profile_id | Profile version reference | IP-100001 | FK |
| acceptance_type_code | Type of acceptance/acknowledgment | HIGH_RISK_ACK | FK to dim_acceptance_type |
| acceptance_flag | Accepted indicator | Y | Y/N |
| acceptance_date | Date of acceptance | 2024-10-20 | Not null if accepted |
| expiry_date | Acceptance validity expiration | 2025-10-20 | May be null for permanent |

Acceptance types:
- HIGH_RISK_PRODUCT_ACK: Acknowledgment of high-risk product risks
- COMPLEX_PRODUCT_ACK: Complex product understanding
- DERIVATIVE_RISK_ACK: Derivative trading risk acknowledgment
- FX_RISK_ACK: Foreign exchange risk acknowledgment
- LEVERAGED_RISK_ACK: Leveraged product risk
- LIQUIDITY_RISK_ACK: Illiquid product risk
- GLOBAL_TRADING_AGREEMENT: Agreement for global market access
- W8BEN_STATUS: U.S. tax status declaration
- UNRATED_BOND_ACK: Unrated bond risk acknowledgment
- PERPETUAL_BOND_ACK: Perpetual bond risk acknowledgment

## 6. Investor Classification Rules (Thailand SEC Context)
Based on Thailand SEC regulations:

### 6.1 Ultra High Net Worth (UHNW)
- Net worth ≥ THB 60 million OR
- Annual income ≥ THB 6 million
- AND proven investment experience/knowledge

### 6.2 High Net Worth (HNW)
- Net worth ≥ THB 30 million OR
- Annual income ≥ THB 3 million OR
- Direct investment in securities/derivatives ≥ THB 8 million (or ≥ THB 15 million including deposits)

### 6.3 Retail
- Does not meet HNW criteria
- Standard suitability assessment required for all products

### 6.4 Institutional
- Legal entities meeting institutional criteria
- Corporate/fund investors with professional management

**Note**: Classification requires both financial thresholds AND demonstrated knowledge/experience. Exemptions from certain suitability tests may apply for UHNW/Institutional.

## 7. Suitability Score Framework (Proposed)
Suitability score is a calculated value (0-100) derived from comprehensive assessment:

| Score Range | Category | Description | Typical Products |
|-------------|----------|-------------|------------------|
| 0-20 | Very Conservative | Capital preservation priority | Savings, Fixed Income, Money Market |
| 21-40 | Conservative | Low risk tolerance | Government Bonds, Investment Grade Bonds |
| 41-60 | Moderate | Balanced risk/return | Equity Funds, Balanced Funds, ETF |
| 61-80 | Aggressive | High risk tolerance | Individual Stocks, High Yield Bonds, DW |
| 81-100 | Very Aggressive | Maximum risk acceptance | Derivatives, Leveraged Products, Complex Structures |

**Calculation inputs** (stored elsewhere, not in this module):
- Risk tolerance questionnaire responses
- Investment objectives
- Time horizon
- Financial capacity
- Investment knowledge level

## 8. Product Eligibility Matrix (Conceptual)
This matrix defines which profile attributes enable access to each product category:

| Product | Min Suitability | Risk Level | HNW Required | Knowledge Test | Specific Acknowledgments |
|---------|----------------|------------|--------------|----------------|-------------------------|
| Equity | 30 | Low-Moderate | N | N | - |
| TFEX | 50 | Moderate-High | N | Y (DRX) | DERIVATIVE_RISK_ACK |
| DW | 60 | Moderate-High | N | Y (DW) | DERIVATIVE_RISK_ACK, HIGH_RISK_ACK |
| DRX | 65 | High | N | Y (DRX) | DERIVATIVE_RISK_ACK |
| ETF (Regular) | 35 | Low-Moderate | N | N | - |
| Inverse ETF | 60 | High | N | Y (INVERSE_ETF) | COMPLEX_PRODUCT_ACK |
| Fund (Standard) | 30 | Low-Moderate | N | N | - |
| Fund (Complex) | 55 | Moderate-High | N | Y (COMPLEX_FUND) | COMPLEX_PRODUCT_ACK |
| Global Equity | 45 | Moderate | N | N | FX_RISK_ACK, GLOBAL_TRADING_AGREEMENT |
| Structured Note (Local) | 65 | High | Preferred | Y (STRUCTURED_NOTE) | COMPLEX_PRODUCT_ACK |
| Structured Note (Global) | 70 | High | Preferred | Y (STRUCTURED_NOTE) | COMPLEX_PRODUCT_ACK, FX_RISK_ACK |
| Bond (Investment Grade) | 25 | Low | N | N | - |
| Bond (Unrated) | 60 | High | Recommended | Y (UNRATED_BOND) | UNRATED_BOND_ACK, HIGH_RISK_ACK |
| Perpetual Bond | 70 | High | Recommended | Y (PERPETUAL_BOND) | PERPETUAL_BOND_ACK, LIQUIDITY_RISK_ACK |
| Fixed Income (Standard) | 20 | Very Low-Low | N | N | - |
| SBL (Securities Lending) | 50 | Moderate | N | N | - |
| Block Trade | 45 | Moderate | N | N | - |
| IPO | 40 | Moderate | N | N | - |
| Tender Offer | 40 | Moderate | N | N | - |

**Note**: This is a conceptual matrix for discussion. Actual rules may be more complex and should be defined with business stakeholders.

## 9. Omnibus Account Scenario
Example: Company A is a financial advisor with multiple customer codes:
- Customer Code 111111: Low-risk profile (Conservative clients)
- Customer Code 222222: High-risk profile (Aggressive clients)

Both codes link to the same company (company_id = CO_A), but each has:
- Separate investment_profile records
- Different suitability scores
- Different risk levels
- Different product knowledge tests
- Different acceptances

**Design Decision**: Investment profiles can be created at either:
- `customer_id` level (applies to all codes under that customer)
- `customer_code` level (specific to one code, for omnibus scenarios)

When `customer_code` IS NOT NULL, the profile is code-specific.
When `customer_code` IS NULL, the profile applies to the entire customer_id.

## 10. Versioning Rules (SCD2)
Triggers new version when any of these change:
1. Suitability score or category
2. Risk level or risk score
3. Investor classification (HNW/UHNW status change)
4. Net worth or income tier
5. Investment experience years (material change, e.g., ±1 year)
6. Knowledge test set membership (new test passed, test expired)
7. Acceptance set membership (new acceptance, expiry)
8. Assessment/expiry dates

**Non-versioning attributes** (Type 1):
- Total portfolio value (frequently changing, tracked separately if needed)

**Hash Specification**:
- Algorithm: SHA256
- Ordered attributes for profile_hash:
  suitability_score | risk_score | investor_classification_id | net_worth_tier_id | annual_income_tier_id | investment_experience_years | knowledge_test_set_hash | acceptance_set_hash
- Delimiter: "|"
- Null token: "__NULL__"
- Empty set hash: SHA256("")

**Set Hashing** (for knowledge tests and acceptances):
1. Sort codes ascending
2. For knowledge tests: concatenate product_category_code|test_pass_flag|test_expiry_date (or "PERMANENT")
3. For acceptances: concatenate acceptance_type_code|acceptance_flag|expiry_date (or "PERMANENT")
4. Join all items with "|", hash with SHA256

## 11. Data Quality Rules
- No overlapping (effective_start_ts, effective_end_ts) intervals per customer_id + customer_code combination
- suitability_score between 0-100
- risk_score between 1-10
- investment_experience_years >= 0
- If HNW=Y, investor_classification_id must be HNW, UHNW, or INSTITUTIONAL
- If UHNW=Y, investor_classification_id must be UHNW
- assessment_date <= effective_start_ts <= load_ts
- expiry_date > assessment_date (if not null)
- All FK codes exist in lookup dimensions
- investment_profile_id globally unique
- profile_hash length = 64 hex, deterministic recomputation matches stored value
- Knowledge test: test_date <= profile effective_start_ts
- Knowledge test: if test_expiry_date NOT NULL, must be > test_date
- Acceptance: if acceptance_flag = Y, acceptance_date must NOT be NULL
- At least one customer_id OR customer_code must be populated (not both null)

## 12. Relationship to Customer Profile Module
| Customer Profile | Investment Profile |
|-----------------|-------------------|
| Demographics (age, occupation, income source) | Risk tolerance, suitability score |
| Investment purpose (Retirement, Education) | Specific product knowledge & acceptances |
| Basic KYC attributes | Advanced investment capability assessment |
| Updated on life events | Updated on assessment/knowledge test |

**Synergy**: Customer Profile provides context (who they are, what they want), Investment Profile provides capability (what they can invest in).

## 13. Audit & Change Tracking
`fact_investment_profile_audit` captures:
- change_reason (INITIAL_ASSESSMENT, REASSESSMENT, TEST_PASSED, TEST_EXPIRED, CLASSIFICATION_UPGRADE, RISK_TOLERANCE_CHANGE, ACCEPTANCE_ADDED, CORRECTION, REGULATORY_UPDATE)
- changed_attributes (comma-separated list)
- changed_by_user_id
- change_timestamp
- old_profile_hash
- new_profile_hash
- notes (optional explanation)

## 14. Source Systems & Update Cadence (Conceptual)
| Source | Feed Type | Cadence | Coverage |
|--------|-----------|---------|----------|
| Suitability Assessment System | Batch/Event | On-demand + Annual | Suitability scores, risk levels |
| Knowledge Test Platform | Event | Real-time | Test results and expiry |
| Client Onboarding System | Batch | Daily | Initial investor classification |
| Wealth Management Platform | Batch | Weekly | Net worth, portfolio value updates |
| Compliance System | Event | Real-time | Acknowledgments and acceptances |
| Customer Service Manual Entry | Event | Ad-hoc | Corrections and overrides |

**Important**: This module does NOT store the raw assessment questionnaire data or calculation logic. It only stores final calculated results.

## 15. Profile Completeness KPI
Required attributes for a "complete" investment profile:
- suitability_score NOT NULL
- risk_level_id NOT NULL
- investor_classification_id NOT NULL
- assessment_date NOT NULL AND assessment_date within last 12 months
- expiry_date IS NULL OR expiry_date > current_date
- For HNW/UHNW: net_worth_tier_id and/or annual_income_tier_id must justify classification
- For complex products: corresponding knowledge tests passed and not expired

Completeness Score Calculation:
```
completeness_score = 
  (suitability_score_present * 20) +
  (risk_level_present * 20) +
  (classification_valid * 20) +
  (assessment_current * 20) +
  (knowledge_tests_adequate * 20)
/ 100
```

## 16. Product Access Decision Logic (Conceptual)
To determine if customer can buy product X:
```
1. Retrieve current investment profile (effective_end_ts IS NULL)
2. If profile expired (expiry_date < current_date): REJECT (profile needs renewal)
3. Check product eligibility matrix:
   a. suitability_score >= min_required_score for product
   b. risk_level matches or exceeds product risk requirement
   c. If HNW required: hnw_status = Y OR uhnw_status = Y
   d. If knowledge test required: test exists, passed, not expired
   e. If specific acknowledgments required: all present and not expired
4. If all conditions met: ELIGIBLE
5. If some conditions not met: return specific failure reasons for remediation
```

## 17. Schema Artifact Mapping
- `dim_investment_profile` (SCD2 main table)
- `dim_investor_classification` (lookup)
- `dim_suitability_category` (lookup)
- `dim_risk_level` (lookup)
- `dim_net_worth_tier` (lookup)
- `dim_income_tier` (lookup)
- `dim_product_category` (lookup, reused from product module)
- `dim_acceptance_type` (lookup)
- `dim_knowledge_test_result_version` (bridge)
- `dim_product_acceptance_version` (bridge)
- `fact_investment_profile_audit` (fact)
- `fact_product_eligibility_check` (optional: log of eligibility checks)
- staging: `stg_investment_profile_raw`, `stg_knowledge_test_raw`, `stg_acceptance_raw`

## 18. ADR Links (To Be Created)
- ADR-020-investment-profile-scd2.md
- ADR-021-product-eligibility-matrix.md
- ADR-022-omnibus-account-profiles.md
- ADR-023-knowledge-test-expiry-handling.md
- ADR-024-investor-classification-rules.md

## 19. Sample Record
```json
{
  "investment_profile_id": "IP-100001",
  "customer_id": "C123456",
  "customer_code": "111111",
  "profile_version_num": 1,
  "suitability_score": 45,
  "suitability_category_id": "MODERATE",
  "risk_level_id": "MODERATE_RISK",
  "risk_score": 5,
  "investor_classification_id": "RETAIL",
  "hnw_status": "N",
  "uhnw_status": "N",
  "net_worth_tier_id": "TIER_2",
  "annual_income_tier_id": "TIER_2",
  "investment_experience_years": 5,
  "knowledge_tests": [
    {
      "product_category_code": "DW",
      "test_pass_flag": "Y",
      "test_score": 85,
      "test_date": "2024-10-15",
      "test_expiry_date": "2025-10-15"
    }
  ],
  "acceptances": [
    {
      "acceptance_type_code": "DERIVATIVE_RISK_ACK",
      "acceptance_flag": "Y",
      "acceptance_date": "2024-10-15",
      "expiry_date": null
    },
    {
      "acceptance_type_code": "HIGH_RISK_ACK",
      "acceptance_flag": "Y",
      "acceptance_date": "2024-10-15",
      "expiry_date": "2025-10-15"
    }
  ],
  "assessment_date": "2024-10-15",
  "expiry_date": "2025-10-15",
  "effective_start_ts": "2024-11-01T08:00:00Z",
  "effective_end_ts": null,
  "is_current": "Y",
  "profile_hash": "a7f3d2c1b8e9f4a5..."
}
```

## 20. Open Questions & Discussion Points

### 20.1 Business Clarifications Needed
1. **Suitability Score Calculation**: What is the official algorithm/methodology? Who provides this score?
2. **Profile Validity Period**: How long is an investment profile valid? 12 months? 24 months? Does it vary by classification?
3. **Automatic Downgrade**: If HNW customer's net worth drops below threshold, automatic classification change or requires reassessment?
4. **Test Retake Rules**: If a knowledge test expires, is there a grace period? Can customer continue trading existing positions?
5. **Override Mechanism**: Can relationship managers override product restrictions? How is this tracked?
6. **Portfolio Value Source**: Is total_portfolio_value calculated from internal holdings only, or includes external declared assets?
7. **Omnibus Frequency**: How common are omnibus accounts? Should we optimize for this scenario?
8. **Risk Level Granularity**: Is a 1-10 risk score sufficient, or do we need more detailed risk profiling dimensions?

### 20.2 Technical Decisions Needed
1. **Customer vs Code Level**: Default to customer_id or customer_code level profiles? Validation rules for mixing?
2. **Expiry Handling**: Should expired profiles automatically create new versions or require manual intervention?
3. **Knowledge Test Storage**: Store individual test questions/responses or just final pass/fail with score?
4. **Eligibility Matrix Location**: Should product eligibility rules be in database tables or application configuration?
5. **Real-time Requirements**: Does product eligibility need sub-second lookup, or is batch processing acceptable?
6. **Historical Reconstruction**: Need to replay all historical trades against past profiles, or just current/recent?
7. **Integration with Order Management**: How does OMS query this module? API, direct DB, materialized view?

### 20.3 Regulatory & Compliance
1. **Audit Retention**: How long to retain old profile versions? Indefinitely or X years?
2. **PII Considerations**: Is suitability score or risk level considered PII? Masking requirements?
3. **Cross-Border**: Do global trading customers need different profiles per market/jurisdiction?
4. **MiFID II / Other Regulations**: Any international regulatory requirements beyond Thailand SEC?
5. **Suitability Override Documentation**: What level of documentation required when customer trades outside profile?

### 20.4 Data Quality & Monitoring
1. **Stale Profile Alerts**: Alert when profiles are X days from expiry?
2. **Missing Knowledge Tests**: Monitor customers trading products without current knowledge tests?
3. **Classification Inconsistencies**: Detect customers with HNW status but insufficient net worth/income data?
4. **Profile Completeness Targets**: What is acceptable completeness score threshold (e.g., 80%)?

### 20.5 Product-Specific Questions
1. **DW (Derivative Warrants)**: Separate knowledge test for call vs put warrants, or combined?
2. **Structured Notes**: Different knowledge tests for local vs global? Different suitability thresholds?
3. **Perpetual Bonds**: Additional liquidity risk assessment beyond standard bond knowledge?
4. **ETF vs Inverse ETF**: Can standard ETF knowledge enable inverse ETF, or separate test required?
5. **Block Trade vs Regular**: Same profile requirements or special handling for block trades?
6. **IPO/Tender Offer**: Special suitability requirements or same as regular equity?

### 20.6 Future Enhancements
1. **AI-Driven Suitability**: Use ML to suggest suitability updates based on trading behavior?
2. **Dynamic Risk Scoring**: Real-time risk score adjustment based on portfolio volatility?
3. **Product Recommendation Engine**: Suggest products that match customer's current profile?
4. **Profile Comparison**: Compare customer's profile against peer segment benchmarks?
5. **Automated Renewal**: System-triggered profile renewal reminders and workflows?

## 21. Next Steps (Before Code Generation)

### 21.1 Immediate Discussion & Documentation
- [ ] Validate product eligibility matrix with business stakeholders
- [ ] Confirm suitability score scale and categorization
- [ ] Define investor classification transition rules
- [ ] Clarify omnibus account profile management approach
- [ ] Document knowledge test expiry handling procedures
- [ ] Define profile renewal/reassessment triggers

### 21.2 Reference Data Collection
- [ ] Obtain official Thailand SEC investor classification criteria
- [ ] Collect complete list of products and their risk ratings
- [ ] Document all required acknowledgment types
- [ ] Map source systems and data feeds
- [ ] Define calculation methodology for derived fields

### 21.3 Contract Finalization
- [ ] Create YAML contracts for all tables and bridges
- [ ] Define complete attribute lists with data types
- [ ] Document all FK relationships
- [ ] Specify PII and masking requirements
- [ ] Create sample data sets for testing

### 21.4 Integration Planning
- [ ] Define API contracts for eligibility checks
- [ ] Plan integration with order management system
- [ ] Design batch ETL processes for profile updates
- [ ] Plan real-time event processing for tests/acceptances
- [ ] Define monitoring and alerting requirements

## 22. Success Criteria
Investment profile module is considered successful when:
1. ✅ Product eligibility can be determined in <100ms for 95% of queries
2. ✅ Profile completeness rate >95% for active customers
3. ✅ Zero regulatory compliance violations related to unsuitable product sales
4. ✅ Point-in-time profile reconstruction works for all historical dates
5. ✅ Omnibus account scenarios fully supported
6. ✅ Knowledge test and acceptance tracking 100% accurate
7. ✅ SCD2 versioning captures all material profile changes
8. ✅ Integration with OMS is seamless and reliable
9. ✅ Business users can generate analytics and reports independently
10. ✅ Clear audit trail for all profile changes and access decisions

## 23. Risk & Mitigation
| Risk | Impact | Mitigation |
|------|--------|------------|
| Unclear eligibility rules | High | Extensive stakeholder workshops, document all edge cases |
| Frequent profile updates causing version explosion | Medium | Careful selection of versioning attributes, aggregation strategies |
| Knowledge test expiry not monitored | High | Automated alerts, expiry date validation in eligibility checks |
| Omnibus account complexity underestimated | Medium | Prototype with real omnibus scenarios early |
| Integration with external systems unreliable | High | Robust error handling, retry logic, fallback mechanisms |
| Regulatory requirements change | Medium | Design for flexibility, modular eligibility rule engine |
| Performance issues with complex eligibility queries | Medium | Materialized views, denormalization where needed, caching |

---

**Document Status**: 🟡 Draft for Discussion  
**Last Updated**: 2024-11-18  
**Owner**: Data Architecture Team  
**Reviewers**: Business Analysis Team, Compliance Team, Product Team

**Next Review Date**: TBD - After initial stakeholder feedback

# Product Eligibility Rules Reference

## Purpose
This document defines the conceptual mapping between investment profile attributes and product access eligibility. This is a **reference for discussion** and should be validated with Compliance, Product, and Risk teams before implementation.

**IMPORTANT**: This module stores only the **profile attributes**. The eligibility decision logic may reside in:
- Application layer (Order Management System)
- Database stored procedures/functions
- Configuration tables (rule engine)
- Hybrid approach

---

## Products in Scope

Based on problem statement, the company offers:
1. Equity (local stocks)
2. TFEX (Thailand Futures Exchange derivatives)
3. DW (Derivative Warrants)
4. DRX (Derivatives)
5. ETF / Inverse ETF
6. Fund (Mutual Funds)
7. Global Equity (international stocks)
8. Structured Note (Local and Global)
9. Bond / Perpetual Bond
10. Fixed Income
11. SBL (Securities Borrowing and Lending)
12. Block Trade
13. IPO / Tender Offer

---

## Eligibility Framework

Each product eligibility check evaluates:
1. **Minimum Suitability Score** (0-100)
2. **Risk Level** (Conservative, Moderate, Aggressive, etc.)
3. **Investor Classification** (RETAIL, HNW, UHNW, INSTITUTIONAL)
4. **Knowledge Tests** (product-specific tests passed and not expired)
5. **Acceptances** (risk acknowledgments signed and not expired)
6. **Profile Validity** (profile not expired)

Logic: Customer is eligible IF (profile valid AND score ≥ min AND risk level ≥ min AND classification check AND tests passed AND acceptances present)

---

## Product Eligibility Matrix (DRAFT - For Discussion)

### 1. Equity (Local Stocks)
- **Min Suitability Score**: 30
- **Min Risk Level**: Conservative
- **HNW Required**: No
- **Knowledge Tests**: None
- **Acceptances**: None
- **Notes**: Basic product, accessible to most retail investors

### 2. TFEX (Thailand Futures Exchange)
- **Min Suitability Score**: 50
- **Min Risk Level**: Moderate
- **HNW Required**: No
- **Knowledge Tests**: DRX (Derivatives general knowledge)
- **Acceptances**: DERIVATIVE_RISK_ACK
- **Notes**: Regulated derivative exchange, requires understanding of leverage

### 3. DW (Derivative Warrants)
- **Min Suitability Score**: 60
- **Min Risk Level**: Moderate-High
- **HNW Required**: No (but recommended)
- **Knowledge Tests**: DW (specific DW test)
- **Acceptances**: 
  - DERIVATIVE_RISK_ACK
  - HIGH_RISK_ACK
- **Notes**: Complex derivative product, time decay, leverage

### 4. DRX (Derivatives - general)
- **Min Suitability Score**: 65
- **Min Risk Level**: Aggressive
- **HNW Required**: No
- **Knowledge Tests**: DRX (Derivatives knowledge)
- **Acceptances**: DERIVATIVE_RISK_ACK
- **Notes**: Includes futures, options, swaps, etc.

### 5. ETF (Standard Exchange-Traded Funds)
- **Min Suitability Score**: 35
- **Min Risk Level**: Conservative-Moderate
- **HNW Required**: No
- **Knowledge Tests**: None
- **Acceptances**: None (for standard ETF)
- **Notes**: Passive investment vehicle, low cost

### 6. Inverse ETF / Leveraged ETF
- **Min Suitability Score**: 60
- **Min Risk Level**: Aggressive
- **HNW Required**: No
- **Knowledge Tests**: INVERSE_ETF or LEVERAGED_PRODUCT
- **Acceptances**: 
  - COMPLEX_PRODUCT_ACK
  - LEVERAGED_RISK_ACK (if leveraged)
- **Notes**: Sophisticated instruments, daily rebalancing, compounding effects

### 7. Fund (Mutual Funds - Standard)
- **Min Suitability Score**: 30
- **Min Risk Level**: Conservative-Moderate
- **HNW Required**: No
- **Knowledge Tests**: None
- **Acceptances**: None
- **Notes**: Professionally managed, varies by fund type

### 8. Fund (Complex/Alternative)
- **Min Suitability Score**: 55
- **Min Risk Level**: Moderate-Aggressive
- **HNW Required**: No
- **Knowledge Tests**: COMPLEX_FUND
- **Acceptances**: COMPLEX_PRODUCT_ACK
- **Notes**: Hedge funds, alternative strategies, limited liquidity

### 9. Global Equity (International Stocks)
- **Min Suitability Score**: 45
- **Min Risk Level**: Moderate
- **HNW Required**: No
- **Knowledge Tests**: None (or GLOBAL_TRADING if required)
- **Acceptances**: 
  - FX_RISK_ACK
  - GLOBAL_TRADING_AGREEMENT
- **Notes**: Currency risk, different market hours, settlement

### 10. Structured Note (Local)
- **Min Suitability Score**: 65
- **Min Risk Level**: Aggressive
- **HNW Required**: Recommended (not hard requirement)
- **Knowledge Tests**: STRUCTURED_NOTE
- **Acceptances**: 
  - COMPLEX_PRODUCT_ACK
  - HIGH_RISK_ACK
- **Notes**: Complex payoff structures, issuer risk, limited liquidity

### 11. Structured Note (Global)
- **Min Suitability Score**: 70
- **Min Risk Level**: Aggressive
- **HNW Required**: Recommended
- **Knowledge Tests**: STRUCTURED_NOTE
- **Acceptances**: 
  - COMPLEX_PRODUCT_ACK
  - FX_RISK_ACK
  - HIGH_RISK_ACK
- **Notes**: Adds currency and cross-border risks to local structured notes

### 12. Bond (Investment Grade)
- **Min Suitability Score**: 25
- **Min Risk Level**: Very Conservative - Conservative
- **HNW Required**: No
- **Knowledge Tests**: None
- **Acceptances**: None
- **Notes**: Lower risk, rated BBB- or above

### 13. Bond (Unrated / Non-Investment Grade)
- **Min Suitability Score**: 60
- **Min Risk Level**: Aggressive
- **HNW Required**: Recommended
- **Knowledge Tests**: UNRATED_BOND
- **Acceptances**: 
  - UNRATED_BOND_ACK
  - HIGH_RISK_ACK
- **Notes**: Higher default risk, requires credit analysis capability

### 14. Perpetual Bond
- **Min Suitability Score**: 70
- **Min Risk Level**: Aggressive
- **HNW Required**: Recommended
- **Knowledge Tests**: PERPETUAL_BOND
- **Acceptances**: 
  - PERPETUAL_BOND_ACK
  - LIQUIDITY_RISK_ACK
  - HIGH_RISK_ACK
- **Notes**: No maturity, callable, interest deferral risk

### 15. Fixed Income (General)
- **Min Suitability Score**: 20
- **Min Risk Level**: Very Conservative
- **HNW Required**: No
- **Knowledge Tests**: None
- **Acceptances**: None
- **Notes**: Includes deposits, CDs, low-risk instruments

### 16. SBL (Securities Borrowing and Lending)
- **Min Suitability Score**: 50
- **Min Risk Level**: Moderate
- **HNW Required**: No
- **Knowledge Tests**: SBL (if required)
- **Acceptances**: 
  - SBL_AGREEMENT (if separate from general terms)
- **Notes**: Collateral management, counterparty risk

### 17. Block Trade
- **Min Suitability Score**: 45
- **Min Risk Level**: Moderate
- **HNW Required**: No (but often HNW by nature)
- **Knowledge Tests**: None
- **Acceptances**: None
- **Notes**: Large volume trades, pricing considerations

### 18. IPO (Initial Public Offering)
- **Min Suitability Score**: 40
- **Min Risk Level**: Moderate
- **HNW Required**: No
- **Knowledge Tests**: None
- **Acceptances**: IPO_RISK_ACK (if required)
- **Notes**: Allocation rules may apply, lock-up periods

### 19. Tender Offer
- **Min Suitability Score**: 40
- **Min Risk Level**: Moderate
- **HNW Required**: No
- **Knowledge Tests**: None
- **Acceptances**: None
- **Notes**: Corporate action participation

---

## Special Cases & Considerations

### HNW/UHNW Benefits
While not strictly "required" for many products, HNW/UHNW status may provide:
- Exemption from certain periodic suitability reassessments (Thailand SEC)
- Access to private placements not in above list
- Reduced knowledge test frequency (quarterly → less frequent)
- Higher leverage/concentration limits (not covered by this profile module)

### Grandfathered Positions
**Question for Discussion**: When a customer's profile changes (e.g., downgrade from HNW to Retail), can they:
1. Hold existing positions indefinitely?
2. Close positions but not open new ones?
3. Must liquidate incompatible positions?

**Suggestion**: Flag as "grandfathered_position" in separate table, not in investment profile.

### Manual Overrides
**Question for Discussion**: When RM/supervisor overrides eligibility:
1. Where to store override (profile attribute, separate fact table, OMS only)?
2. Time-limited or permanent?
3. Approval workflow requirements?

**Suggestion**: Separate fact table `fact_eligibility_override` with approval chain.

### Product-Specific Sub-Rules
Some products may have additional criteria not in investment profile:
- Account type restrictions (cash vs. margin)
- Trading limit thresholds
- Previous trading experience in similar product
- Minimum account balance

**Design Decision**: These are **not** investment profile concerns. Handle in OMS/product-specific validation.

---

## Eligibility Check Pseudocode

```python
def check_product_eligibility(customer_id, product_code, trade_date=today):
    """
    Determine if customer can trade a product based on investment profile.
    
    Returns: {
        "eligible": True/False,
        "reasons": ["list", "of", "blockers"],
        "profile_id": "IP-xxxxx",
        "checked_at": timestamp
    }
    """
    
    # Step 1: Get current (or point-in-time) investment profile
    profile = get_investment_profile(customer_id, as_of_date=trade_date)
    
    if not profile:
        return {"eligible": False, "reasons": ["NO_PROFILE_FOUND"]}
    
    # Step 2: Check profile validity
    if profile.expiry_date and profile.expiry_date < trade_date:
        return {"eligible": False, "reasons": ["PROFILE_EXPIRED"]}
    
    # Step 3: Get product requirements
    requirements = get_product_requirements(product_code)
    
    blockers = []
    
    # Step 4: Check suitability score
    if profile.suitability_score < requirements.min_suitability_score:
        blockers.append(f"SUITABILITY_SCORE_TOO_LOW ({profile.suitability_score} < {requirements.min_suitability_score})")
    
    # Step 5: Check risk level
    if not risk_level_sufficient(profile.risk_level_id, requirements.min_risk_level):
        blockers.append(f"RISK_LEVEL_INSUFFICIENT ({profile.risk_level_id})")
    
    # Step 6: Check HNW requirement (if hard requirement)
    if requirements.hnw_required and profile.hnw_status != 'Y':
        blockers.append("HNW_STATUS_REQUIRED")
    
    # Step 7: Check knowledge tests
    for test in requirements.knowledge_tests:
        test_result = get_knowledge_test(profile.investment_profile_id, test)
        if not test_result or test_result.test_pass_flag != 'Y':
            blockers.append(f"KNOWLEDGE_TEST_MISSING ({test})")
        elif test_result.test_expiry_date and test_result.test_expiry_date < trade_date:
            blockers.append(f"KNOWLEDGE_TEST_EXPIRED ({test})")
    
    # Step 8: Check acceptances
    for acceptance in requirements.acceptances:
        acceptance_record = get_acceptance(profile.investment_profile_id, acceptance)
        if not acceptance_record or acceptance_record.acceptance_flag != 'Y':
            blockers.append(f"ACCEPTANCE_MISSING ({acceptance})")
        elif acceptance_record.expiry_date and acceptance_record.expiry_date < trade_date:
            blockers.append(f"ACCEPTANCE_EXPIRED ({acceptance})")
    
    # Step 9: Return result
    if blockers:
        return {
            "eligible": False,
            "reasons": blockers,
            "profile_id": profile.investment_profile_id,
            "checked_at": current_timestamp()
        }
    else:
        return {
            "eligible": True,
            "reasons": [],
            "profile_id": profile.investment_profile_id,
            "checked_at": current_timestamp()
        }
```

---

## Implementation Options

### Option 1: Database Function
Create stored procedure/function that performs eligibility check:
- **Pros**: Centralized logic, consistent results, database-level enforcement
- **Cons**: Less flexible, harder to unit test, potential performance bottleneck

### Option 2: Application Service
Microservice or library that queries profile and applies rules:
- **Pros**: Easier to test, can cache, more flexible
- **Cons**: Requires network call, logic distributed

### Option 3: Rule Engine
Use rule engine (Drools, Easy Rules, etc.) with externalized rules:
- **Pros**: Business users can modify rules, version-controlled, very flexible
- **Cons**: Additional complexity, learning curve, dependency

### Option 4: Hybrid
Database stores profile, application enforces eligibility with cached rule set:
- **Pros**: Best performance, centralized data, flexible rules
- **Cons**: Cache invalidation complexity, rule versioning

**Recommendation for Discussion**: Start with Option 2 (Application Service), consider Option 4 (Hybrid) for scale.

---

## Product Eligibility Matrix Table (Optional Database Implementation)

If storing rules in database:

```yaml
entity_name: ref_product_eligibility_rules
columns:
  - product_code (PK)
  - min_suitability_score
  - min_risk_level_id (FK)
  - hnw_required_flag
  - knowledge_test_codes (array or JSON)
  - acceptance_codes (array or JSON)
  - rule_effective_date
  - rule_expiry_date
  - is_active
  - notes
```

Bridge for knowledge tests required:
```yaml
entity_name: ref_product_knowledge_test_requirement
columns:
  - product_code (PK, FK)
  - product_category_code (PK, FK)
  - is_required
  - effective_date
```

Bridge for acceptances required:
```yaml
entity_name: ref_product_acceptance_requirement
columns:
  - product_code (PK, FK)
  - acceptance_type_code (PK, FK)
  - is_required
  - effective_date
```

---

## Testing Strategy

### Test Scenarios
1. **Happy Path**: Customer with complete profile, all requirements met → ELIGIBLE
2. **Expired Profile**: Profile expiry_date < today → NOT ELIGIBLE
3. **Low Suitability**: Score 40, product requires 60 → NOT ELIGIBLE
4. **Missing Knowledge Test**: DW trade, no DW test → NOT ELIGIBLE
5. **Expired Knowledge Test**: Test taken 13 months ago, expires at 12 months → NOT ELIGIBLE
6. **Missing Acceptance**: Derivative trade, no DERIVATIVE_RISK_ACK → NOT ELIGIBLE
7. **HNW Required**: Perpetual bond (recommended), RETAIL customer → ELIGIBLE (warning) or NOT ELIGIBLE?
8. **Omnibus Code**: Customer has multiple codes, each with different profiles → Check code-specific profile

### Edge Cases
- Customer has no investment profile yet → Assume most restrictive or reject?
- Multiple active profiles (data quality issue) → Error or take latest?
- Knowledge test passed but score below passing threshold → Should not happen (data quality)
- Test expiry date null (permanent) → Always valid

---

## Monitoring & Alerting

### Metrics to Track
1. **Eligibility Check Volume**: Requests per second, per product
2. **Rejection Rate**: % of checks returning NOT ELIGIBLE
3. **Rejection Reasons Distribution**: Which reasons are most common?
4. **Profile Completeness**: % of customers with all required tests/acceptances
5. **Approaching Expiry**: Customers with profiles/tests expiring in next 30 days

### Alerts
- Spike in rejections for specific product → Rule change or data issue?
- High % of customers lacking required tests → Onboarding gap?
- Profile expiry rate increasing → Renewal process not working?

---

## Open Questions for Stakeholders

1. **Hard vs Soft Requirements**: Are HNW "Recommended" products hard rejections for RETAIL, or warnings?
2. **Grace Periods**: 7-day grace period after test expiry before blocking trades?
3. **Risk Acknowledgment Expiry**: Which acceptances are permanent vs. time-limited?
4. **Product Hierarchy**: Can ETF knowledge enable Inverse ETF, or must be separate?
5. **Override Authority**: Which roles can override eligibility checks?
6. **Audit Requirements**: Must we log every eligibility check or only rejections/overrides?
7. **Customer Communication**: How/when do we notify customers of upcoming profile/test expiry?
8. **Multiple Profiles**: Can one customer have multiple active profiles (e.g., personal + trust)? How to handle?

---

**Document Owner**: Data Architecture Team, Product Team  
**Last Updated**: 2024-11-18  
**Status**: 🟡 DRAFT - Requires Stakeholder Validation  
**Next Steps**: Workshop with Compliance, Product, Risk teams to validate/refine matrix

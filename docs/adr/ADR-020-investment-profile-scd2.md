# ADR-020: Adopt SCD2 for Investment Profile

## Status
Proposed (Draft for Discussion)

## Context
Need to track historical changes to customer investment profiles including suitability scores, risk tolerance, investor classification (HNW/UHNW), product knowledge tests, and risk acknowledgments. This enables:
- Point-in-time eligibility checks for regulatory audits
- Historical analysis of customer investment capability evolution
- Compliance verification for past transactions
- Support for omnibus account scenarios with code-level profiles

Investment profiles are distinct from customer profiles (demographics) and update on different triggers (assessments, tests, classifications vs. life events).

## Decision
Use SCD Type 2 dimension `dim_investment_profile` with:
- `effective_start_ts` / `effective_end_ts` for version validity windows
- `profile_version_num` sequential versioning per customer_id+customer_code
- `profile_hash` for change detection across all versioning attributes
- Multi-valued sets (knowledge tests, acceptances) hashed and versioned via bridge tables

### Versioned Attributes
- suitability_score, risk_score
- investor_classification_id, net_worth_tier_id, annual_income_tier_id
- investment_experience_years
- knowledge_test_set_hash (derived from bridge)
- acceptance_set_hash (derived from bridge)

### Type 1 (Non-Versioned)
- total_portfolio_value (frequently changing, less relevant historically)

### Bridge Dimensions
- `dim_knowledge_test_result_version`: Product-specific test results
- `dim_product_acceptance_version`: Risk acknowledgments and agreements

## Rationale
1. **Regulatory Compliance**: Auditors need to verify that customers were eligible for products at trade time
2. **Profile Evolution**: Track how customer sophistication and risk tolerance change over time
3. **Omnibus Support**: Enable different profiles for different customer codes under same parent
4. **Expiry Handling**: Profiles and tests have validity periods requiring historical tracking
5. **Multi-valued Sets**: Knowledge tests and acceptances are naturally multi-valued; bridge tables provide clean implementation

## Hash Specification
- Algorithm: SHA256 (hex string output)
- Profile hash input (ordered, pipe-delimited):
  ```
  suitability_score | risk_score | investor_classification_id | 
  net_worth_tier_id | annual_income_tier_id | investment_experience_years | 
  knowledge_test_set_hash | acceptance_set_hash
  ```
- Null token: `__NULL__`
- Empty set hash: `SHA256("")` = `e3b0c44298fc1c149afbf4c8996fb924...`

### Set Hash Construction
For knowledge tests:
1. Sort by (product_category_code, test_expiry_date)
2. Concatenate: `product_code|pass_flag|expiry_or_PERMANENT`
3. Join all with `|`, hash result

For acceptances:
1. Sort by (acceptance_type_code, expiry_date)
2. Concatenate: `acceptance_code|flag|expiry_or_PERMANENT`
3. Join all with `|`, hash result

## Versioning Triggers
New profile version created when:
1. Suitability score changes materially (defined threshold, e.g., category change)
2. Risk level/score changes
3. Investor classification changes (e.g., RETAIL → HNW upgrade)
4. Net worth or income tier changes
5. Investment experience years changes materially (±1 year)
6. Knowledge test set membership changes (new test, test expiry)
7. Acceptance set membership changes (new acceptance, expiry)
8. Profile expiry date reached (requires reassessment)

## Omnibus Account Handling
- `customer_id` alone: Profile applies to all codes under customer
- `customer_id` + `customer_code`: Code-specific profile for omnibus scenarios
- Example: Financial advisor Company A with codes 111111 (conservative) and 222222 (aggressive) can have distinct profiles

## Alternatives Considered

### 1. Type 1 Only (Current State)
- **Rejected**: Cannot audit historical eligibility; regulatory risk

### 2. Daily Snapshots
- **Rejected**: Excessive storage for infrequent changes; complicates querying

### 3. Separate Tables per Component
- **Rejected**: Tests and acceptances as separate fact tables
- **Issue**: Harder to atomically determine "complete profile at point in time"

### 4. JSON Arrays for Multi-valued Sets
- **Rejected**: Harder to query, index, and diff; less database-native

## Consequences

### Positive
- ✅ Accurate point-in-time eligibility determination
- ✅ Complete audit trail for compliance
- ✅ Supports complex omnibus scenarios
- ✅ Clean handling of test/acceptance expiry
- ✅ Reuses proven SCD2 patterns from customer profile module

### Negative
- ⚠️ Row growth on frequent profile updates (mitigated: updates less frequent than demographics)
- ⚠️ Requires hash diff pipeline for change detection
- ⚠️ Complex queries for "current + all knowledge tests + all acceptances"
- ⚠️ Bridge tables add join complexity

### Mitigation Strategies
- Materialized view for "current profile with all tests/acceptances" (query optimization)
- Batch profile update process to minimize version churn
- Define material change thresholds (e.g., suitability score ±5, not ±1)
- Index on (customer_id, customer_code, effective_end_ts) for current profile lookups

## Implementation Notes

### ETL Process
1. Source systems provide assessment results, test outcomes, acceptances
2. Compute suitability_score, risk_score, classifications (outside DW module)
3. Calculate set hashes from bridge table inputs
4. Compute profile_hash from ordered attributes
5. Compare with previous profile version hash
6. If different: close previous version, insert new version + bridge rows
7. If same: no action (idempotent)

### Query Patterns
```sql
-- Current profile with all tests and acceptances
SELECT p.*, 
       array_agg(DISTINCT k.product_category_code) as knowledge_tests,
       array_agg(DISTINCT a.acceptance_type_code) as acceptances
FROM dim_investment_profile p
LEFT JOIN dim_knowledge_test_result_version k ON p.investment_profile_id = k.investment_profile_id
LEFT JOIN dim_product_acceptance_version a ON p.investment_profile_id = a.investment_profile_id
WHERE p.customer_id = :cid
  AND p.is_current = 'Y'
GROUP BY p.investment_profile_id;

-- Point-in-time profile for specific date
SELECT p.*, k.*, a.*
FROM dim_investment_profile p
LEFT JOIN dim_knowledge_test_result_version k ON p.investment_profile_id = k.investment_profile_id
LEFT JOIN dim_product_acceptance_version a ON p.investment_profile_id = a.investment_profile_id
WHERE p.customer_id = :cid
  AND p.effective_start_ts <= :target_date
  AND (p.effective_end_ts IS NULL OR p.effective_end_ts > :target_date);
```

## Future Enhancements
1. **Profile Snapshots**: Monthly snapshot table for performance (ADR-TBD)
2. **Automated Renewal**: System-triggered profile renewal workflows when approaching expiry
3. **Dynamic Eligibility Rules**: Configurable product eligibility matrix in database
4. **ML-Driven Updates**: Use trading behavior to suggest profile updates (Phase 3)

## Related ADRs
- ADR-001: SCD2 Customer Profile (baseline pattern)
- ADR-002: Multi-Valued Sets (bridge table approach)
- ADR-021: Product Eligibility Matrix (to be created)
- ADR-022: Omnibus Account Profiles (to be created)
- ADR-023: Knowledge Test Expiry Handling (to be created)

## References
- Thailand SEC investor classification regulations
- FINRA Rule 2111 (Suitability - for international context)
- Customer Profile Module documentation

## Open Questions
1. What is the standard profile validity period (12/24/36 months)?
2. Should test expiry automatically downgrade eligibility or require manual intervention?
3. How to handle classification downgrade when financial thresholds no longer met?
4. What is the threshold for "material" suitability score change (±5 pts, ±10 pts)?
5. Should we track profile update reasons in audit fact or as attribute?

## Decision Date
TBD - Pending business stakeholder review

## Reviewers
- [ ] Data Architecture Team
- [ ] Compliance Team
- [ ] Business Analysis Team
- [ ] Product Team
- [ ] Risk Management Team

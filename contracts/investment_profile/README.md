# Investment Profile Module - Contract Files

## Overview
This directory contains data modeling contracts (YAML) for the Investment Profile Module, following the same pattern as customer and company modules.

## Contract Files

### Main Dimension
- **dim_investment_profile.yaml**: SCD2 dimension tracking investment suitability, risk tolerance, investor classification, and profile attributes

### Bridge Dimensions (Multi-valued Sets)
- **dim_knowledge_test_result_version.yaml**: Product-specific knowledge test results per profile version
- **dim_product_acceptance_version.yaml**: Risk acknowledgments and trading agreements per profile version

### Lookup Dimensions
- **dim_investor_classification.yaml**: Investor types (RETAIL, HNW, UHNW, INSTITUTIONAL) with Thailand SEC criteria
- **dim_risk_level.yaml**: Risk tolerance levels (Very Conservative to Very Aggressive)
- **dim_suitability_category.yaml**: Suitability score categories mapping to score ranges

### Supporting Lookups (To Be Created)
- **dim_net_worth_tier.yaml**: Net worth categorization tiers
- **dim_income_tier.yaml**: Annual income categorization tiers
- **dim_product_category.yaml**: Product categories requiring knowledge tests
- **dim_acceptance_type.yaml**: Types of risk acknowledgments and agreements

### Fact Tables (To Be Created)
- **fact_investment_profile_audit.yaml**: Profile change events with reasons and audit trail
- **fact_product_eligibility_check.yaml** (Optional): Log of eligibility check requests and results

## Versioning Strategy
Investment profiles use SCD Type 2 with:
- Profile hash for change detection
- Multi-valued set hashing for knowledge tests and acceptances
- Microsecond precision timestamps
- Sequential version numbering per customer_id+customer_code

## Key Design Decisions
1. **Omnibus Support**: Profiles can be at customer_id OR customer_code level
2. **Calculated Values Only**: Module stores only final assessment results, not source questionnaire data
3. **Bridge Tables**: Knowledge tests and acceptances stored as multi-valued sets via bridge dimensions
4. **Expiry Tracking**: Both profiles and individual tests/acceptances have expiry dates
5. **Hash-based Change Detection**: Composite hash of all versioning attributes triggers new versions

## Dependencies
- **dim_customer** from customer module (for customer_id FK)
- Product catalog (for product_category_code references)
- Source systems: Suitability assessment platform, knowledge test system, compliance systems

## Status
🟡 **Draft for Discussion** - Contracts are conceptual and require stakeholder validation before implementation

## Related Documentation
- `/docs/business/investment_profile_module.md` - Complete business specification
- `/docs/business/investment_profile_discussion_topics.md` - Open questions and clarifications needed
- `/docs/business/product_eligibility_rules_reference.md` - Product eligibility matrix and logic
- `/docs/adr/ADR-020-investment-profile-scd2.md` - Architecture decision record for SCD2 approach
- `/docs/business/glossary.md` - Updated with investment profile terms

## Next Steps
1. Validate contracts with business stakeholders
2. Complete remaining lookup dimension contracts
3. Create fact table contracts
4. Finalize attribute definitions based on source system analysis
5. Add sample data sets for testing

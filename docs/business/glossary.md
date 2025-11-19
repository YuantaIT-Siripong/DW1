# Business Glossary (Phase 1)

## Entities
- Person: A natural individual; may own multiple Customer Codes.
- Customer Code: 6-digit identifier representing a trading relationship.
- Account Code: 8-character code extending Customer Code.
- Service Category: High-level grouping of services.
- Service: Specific business offering.
- Subscribe Scope: Level at which a service entitlement applies (PERSON, CUSTOMER_CODE, ACCOUNT_CODE).
- Service Request: Formal request to activate a service at a scope.
- Service Subscription Event: Lifecycle event (SUBMITTED, APPROVED, REJECTED, DEACTIVATED).
- Customer Profile: Demographic & suitability attributes tied to a customer_id.
- Investment Profile: Suitability, risk, eligibility, vulnerability, and acknowledgements by scope.
- SCD2 Version: Historical slice of profile validity interval.
- Bridge Dimension: Table modeling multi-valued set membership for a given version.
- Audit Fact: Fact table capturing discrete change or lifecycle events.

## Terms
- Entitlement: Active permission for a service.
- Churn: Deactivation of a previously approved service.
- Multi-Valued Set: Collection of categorical selections (income sources, investment purposes, contact channels).
- Set Hash: SHA256 of sorted codes joined by '|'.
- Profile Hash: SHA256 of ordered versioning attributes + set hashes (SCD2 change detection).
- Effective Start/End Timestamp: Boundaries for version validity (UTC).
- Backdated Correction: Profile change applied with historical effective_start_ts.

## Constants (Phase 1)
MaritalStatus, Nationality, Occupation, EducationLevel, SourceOfIncome, PurposeOfInvestment, ContactChannel, RiskLevel, AbilityToBearLoss, InvestmentObjective, InvestmentTimeHorizon, LiquidityNeed, HNWStatus, KYCStatus, KYCRiskRating, AMLRiskRating, SanctionScreeningStatus, FATCAStatus, InvestorCategory, SourceOfWealth, VulnerabilityReason, MarginAgreementStatus, LeverageTolerance, ESGPreference, TaxResidencyStatus, ReviewCycle.

## Hashing Conventions
- Algorithm: SHA256
- Ordering: Ascending code order for sets
- Delimiter: '|'
- Null Token: '__NULL__'

## Exclusions (Phase 1)
- Detailed reliability formula final weights
- Transactional usage measures
- Corporate customer modeling (Phase 2)
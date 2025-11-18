# Business Glossary (Phase 1)

## Entities
- Person: A natural individual; may own multiple Customer Codes.
- Customer Code: 6-digit identifier representing a trading relationship.
- Account Code: 8-character code extending Customer Code (e.g., settlement suffix).
- Service Category: High-level grouping of services.
- Service: Specific business offering.
- Subscribe Scope: Level at which a service entitlement applies (PERSON, CUSTOMER_CODE, ACCOUNT_CODE).
- Service Request: Formal request to activate a service at a scope.
- Service Subscription Event: Lifecycle event (SUBMITTED, APPROVED, REJECTED, DEACTIVATED).
- Customer Profile: Demographic & suitability attributes tied to a customer_id.
- Investment Profile: Investment suitability, risk tolerance, product knowledge, and compliance attributes per customer or customer code.
- SCD2 Version: Historical slice of profile valid for a time interval.
- Bridge Dimension: Table modeling multi-valued set membership for a given version.
- Audit Fact: Fact table capturing discrete change or lifecycle events (e.g., profile change).

## Terms
- Entitlement: Active permission for a service.
- Churn: Deactivation of a previously approved service.
- Multi-Valued Set: A collection of related categorical selections (income sources, investment purposes, contact channels, knowledge tests, acceptances).
- Set Hash: SHA256 of a deterministic, sorted, delimiter-joined list of codes representing one multi-valued set.
- Attribute Hash / Profile Hash: SHA256 of ordered versioning attributes + set hashes used for SCD2 change detection.
- Effective Start Date / End Date (effective_start_ts / effective_end_ts): Timestamp boundaries for version validity (UTC).
- Backdated Correction: A profile change applied with a historical effective_start_ts differing from ingestion time.
- Suitability Score: Calculated assessment score (0-100) indicating investment product suitability level.
- Risk Level: Categorical risk tolerance classification (Very Conservative to Very Aggressive).
- Investor Classification: Regulatory category (Retail, HNW, UHNW, Institutional) based on financial thresholds and knowledge.
- Knowledge Test: Product-specific test assessing customer understanding of complex/risky products.
- Acceptance/Acknowledgment: Customer's formal acceptance of specific product risks or trading terms.
- Product Eligibility: Determination of whether customer can purchase a product based on investment profile.
- Omnibus Account: Account structure where different customer codes under same parent have distinct investment profiles.
- HNW (High Net Worth): Investor meeting Thailand SEC financial thresholds (≥30M THB net worth or ≥3M THB income).
- UHNW (Ultra High Net Worth): Investor meeting higher thresholds (≥60M THB net worth or ≥6M THB income) with proven knowledge.

## Constants (Phase 1)
MaritalStatus, Nationality, Occupation, EducationLevel, SourceOfIncome, PurposeOfInvestment, ContactChannel.

## Constants (Phase 2 - Investment Profile)
InvestorClassification (RETAIL, HNW, UHNW, INSTITUTIONAL), RiskLevel, SuitabilityCategory, NetWorthTier, IncomeTier, ProductCategory (DW, DRX, ETF, TFEX, etc.), AcceptanceType (HIGH_RISK_ACK, DERIVATIVE_RISK_ACK, FX_RISK_ACK, etc.).

## Hashing Conventions
- Algorithm: SHA256 (hex string).
- Ordering: Ascending code order for set membership.
- Delimiter: "|" between codes and attributes.
- Null Token: "__NULL__".
- Collision Handling: SHA256 chosen to reduce collision probability; collision detection not expected Phase 1.

## Exclusions (Phase 1)
- Transactional usage measures.
- Corporate customer modeling (completed in separate phase).

## Exclusions (Phase 2 - Investment Profile Module)
- Raw assessment questionnaire responses (stored in source systems only).
- Suitability score calculation algorithms (documented separately, not in DW).
- Product recommendation logic (application layer, not DW).
- Real-time eligibility check API implementation (application layer).
- Trading transaction validation logic (OMS responsibility).
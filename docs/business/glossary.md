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
- SCD2 Version: Historical slice of profile valid for a time interval.
- Bridge Dimension: Table modeling multi-valued set membership for a given version.
- Audit Fact: Fact table capturing discrete change or lifecycle events (e.g., profile change).

## Terms
- Entitlement: Active permission for a service.
- Churn: Deactivation of a previously approved service.
- Multi-Valued Set: A collection of related categorical selections (income sources, investment purposes, contact channels).
- Set Hash: SHA256 of a deterministic, sorted, delimiter-joined list of codes representing one multi-valued set.
- Attribute Hash / Profile Hash: SHA256 of ordered versioning attributes + set hashes used for SCD2 change detection.
- Effective Start Date / End Date (effective_start_ts / effective_end_ts): Timestamp boundaries for version validity (UTC).
- Backdated Correction: A profile change applied with a historical effective_start_ts differing from ingestion time.

## Constants (Phase 1)
MaritalStatus, Nationality, Occupation, EducationLevel, SourceOfIncome, PurposeOfInvestment, ContactChannel.

## Hashing Conventions
- Algorithm: SHA256 (hex string).
- Ordering: Ascending code order for set membership.
- Delimiter: "|" between codes and attributes.
- Null Token: "__NULL__".
- Collision Handling: SHA256 chosen to reduce collision probability; collision detection not expected Phase 1.

## Exclusions (Phase 1)
- Detailed investment/risk profile scoring model.
- Transactional usage measures.
- Corporate customer modeling (Phase 2).
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
- Customer Profile: Demographic & suitability attributes for a customer_id.
- SCD2 Version: Historical slice of profile valid for a time interval.

## Terms
- Entitlement: Active permission for a service.
- Churn: Deactivation of a previously approved service.
- Multi-Valued Set: A collection of related categorical selections (income sources, investment purposes).
- Attribute Hash: MD5 (or similar) of normalized SCD2 attribute values for change detection.
- Effective Start Date / End Date: Interval boundaries for version validity.

## Constants (Phase 1)
MaritalStatus, Nationality, Occupation, EducationLevel, SourceOfIncome, PurposeOfInvestment.

## Exclusions (Phase 1)
- Investment/risk profile details.
- Transactional usage measures.

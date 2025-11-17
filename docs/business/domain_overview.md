# Domain Overview (Phase 1)

## 1. Person / Customer / Account Hierarchy
- Person: Natural individual identified by evidence (national ID / passport). One Person may own multiple Customer Codes.
- Customer Code (6 digits): Trading relationship identifier. A Person may hold multiple Customer Codes.
- Account Code (8 chars): Derived from Customer Code plus suffix (e.g., 123666-H). Multiple Accounts per Customer Code represent product/settlement variations.

**Relationships**:
Person (1) → Customer Codes (N) → Account Codes (N per Customer Code)

## 2. Service Taxonomy
- ServiceCategory: High-level grouping (e.g., Premium service, Equity).
- Service: Specific offering (e.g., Advance research, SBL).
- Subscribe Scope Levels:
  - PERSON: Entitlement applies across all current and future Customer Codes and Accounts of the Person.
  - CUSTOMER_CODE: Entitlement applies only to the specified Customer Code and its Accounts.
  - ACCOUNT_CODE: Entitlement applies only to the specific Account.

## 3. Subscription Lifecycle
Statuses: SUBMITTED → APPROVED → (REJECTED or DEACTIVATED)
- SUBMITTED: Initial request captured.
- APPROVED: Entitlement becomes active.
- REJECTED: Request denied (no entitlement).
- DEACTIVATED: Previously approved entitlement revoked.
No REACTIVATED status; a new APPROVED event is required to resume entitlement.

## 4. Customer Profile Structure
SCD2 Versioned Demographic Attributes:
- marital_status_id, nationality_id, occupation_id, education_level_id, birthdate
- income_source_set (multi-valued)
- investment_purpose_set (multi-valued)

Type 1 Attributes:
- Names (TH/EN), email, phones, evidence_unique_key

## 5. Multi-Valued Sets
- Income Sources: ConstantType = SourceOfIncome
- Investment Purposes: ConstantType = PurposeOfInvestment
Version anchored via profile version (only rewritten if set hash changes).

## 6. Rationale for SCD2 Choices
Demographics & investment purpose/income sets affect risk, suitability, segmentation analytics. Contact details change more frequently and rarely needed historically → Type 1. Birthdate tracked historically for correction auditing.

## 7. Future Domains (Not in Phase 1)
- Investment / Risk Profile (separate SCD2 dimension)
- KYC / AML risk rating history
- Service usage metrics (fact tables)
- Masked PII layer

## 8. Point-in-Time Logic (Example)
Retrieve profile version as of 2025-03-31:
```sql
select *
from dim.dim_customer_profile
where customer_id = :cid
  and effective_start_date <= date '2025-03-31'
  and (effective_end_date is null or effective_end_date > date '2025-03-31');
```

## 9. Entitlement Expansion (Simplified Steps)
1. Latest APPROVED event without later DEACTIVATED for (service_id, scope reference).
2. If PERSON scope: enumerate all customer_codes + accounts for that person.
3. If CUSTOMER_CODE scope: enumerate all accounts for that code.
4. If ACCOUNT_CODE scope: use only that account.
5. Deduplicate combined entitlement rows.

## 10. Initial Business KPIs
- Active services per person
- Approval turnaround (days submit → approve)
- Service churn rate (DEACTIVATED / active services)
- Demographic change frequency (versions per customer per year)

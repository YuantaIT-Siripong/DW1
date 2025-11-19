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
  - PERSON
  - CUSTOMER_CODE
  - ACCOUNT_CODE

## 3. Subscription Lifecycle
Statuses: SUBMITTED → APPROVED → (REJECTED or DEACTIVATED)
No REACTIVATED status; a new APPROVED event is required.

## 4. Customer Profile Structure
SCD2 Versioned Demographic Attributes:
- marital_status_id, nationality_id, occupation_id, education_level_id, birthdate
- income_source_set (multi-valued)
- investment_purpose_set (multi-valued)

Type 1 Attributes:
- Names (TH/EN), email, phones, evidence_unique_key

## 5. Investment Profile Structure (NEW)
Root + SCD2 Version separation:
- Root: dim_investment_profile (scope_type CUSTOMER / CUSTOMERCODE)
- Version: dim_investment_profile_version (risk, suitability, acknowledgements, eligibility, vulnerability, scoring)

## 6. Multi-Valued Sets
- Income Sources
- Investment Purposes
- Contact Channels
Version anchored via profile version (only rewritten if set hash changes).

## 7. Rationale for SCD2 Choices
Demographics & multi-valued sets affect segmentation and suitability logic. Investment suitability attributes change independently and merit separate SCD2.

## 8. Future Domains
- Investment profile audit fact
- KYC / AML risk rating historical fact separation
- Service usage metrics
- Masked PII layer

## 9. Point-in-Time Logic (Examples)
Customer Profile:
```sql
select *
from dim.dim_customer_profile
where customer_id = :cid
  and effective_start_ts <= :as_of_ts
  and (effective_end_ts is null or effective_end_ts > :as_of_ts);
```
Investment Profile (code scope preferred):
```sql
select *
from dim.dim_investment_profile_version
where customer_code = :code
  and effective_start_ts <= :trade_ts
  and (effective_end_ts is null or effective_end_ts > :trade_ts)
order by effective_start_ts desc
limit 1;
```
Fallback to CUSTOMER scope if no code profile exists.

## 10. Entitlement Expansion (Simplified Steps)
1. Latest APPROVED event without later DEACTIVATED for (service_id, scope reference).
2. If PERSON scope: enumerate all customer_codes + accounts for that person.
3. If CUSTOMER_CODE scope: enumerate all accounts for that code.
4. If ACCOUNT_CODE scope: use only that account.
5. Deduplicate combined entitlement rows.

## 11. Initial Business KPIs
- Active services per person
- Approval turnaround
- Service churn rate
- Demographic change frequency
- Suitability coverage (investment profile)
- Vulnerability prevalence

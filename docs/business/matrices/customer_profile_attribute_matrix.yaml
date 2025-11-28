# Subscription Expansion Examples

## Example 1: Person-Level
Service: Advance research (scope PERSON)
Person P with customer codes: 123666, 123777
Accounts: 123666-H, 123666-M, 123777-H
Expansion:
| person_id | customer_code | account_code | service_id | source_scope |
|-----------|---------------|--------------|------------|--------------|
| P         | 123666        | 123666-H     | AdvResearch| PERSON       |
| P         | 123666        | 123666-M     | AdvResearch| PERSON       |
| P         | 123777        | 123777-H     | AdvResearch| PERSON       |

## Example 2: Customer-Code-Level
Service: SBL (scope CUSTOMER_CODE)
Customer Code: 555111 (accounts 555111-H, 555111-M)
| customer_code | account_code | service_id | source_scope |
|---------------|--------------|------------|--------------|
| 555111        | 555111-H     | SBL        | CUSTOMER_CODE|
| 555111        | 555111-M     | SBL        | CUSTOMER_CODE|

## Example 3: Account-Level
Service: Margin (scope ACCOUNT_CODE)
Account: 888222-M
| customer_code | account_code | service_id | source_scope |
|---------------|--------------|------------|--------------|
| 888222        | 888222-M     | Margin     | ACCOUNT_CODE |

## Expansion Algorithm (Pseudo-SQL)
```sql
-- Latest active (approved without later deactivation)
with latest_events as (
  select e.*
  from fact.fact_service_subscription_event e
  where e.status_code = 'APPROVED'
    and not exists (
      select 1
      from fact.fact_service_subscription_event d
      where d.service_request_id = e.service_request_id
        and d.status_code = 'DEACTIVATED'
        and d.event_timestamp > e.event_timestamp
    )
)
select * from latest_events; -- Expansion logic implemented later using mapping tables
```

## Notes
- PERSON scope expands across all current and future customer codes/accounts.
- CUSTOMER_CODE scope expands to its accounts only.
- ACCOUNT_CODE scope no expansion.

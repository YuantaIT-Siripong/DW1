# Service Hierarchy & Subscription Scope

Hierarchy:
Person → Customer Code (6 digits) → Account Code (8 chars: CustomerCode + suffix)

Examples:
- Premium service / Advance research / PERSON scope
- Equity / SBL / CUSTOMER_CODE scope

Dimensions:
- dim_service_category(category_id, category_name)
- dim_subscribe_scope(scope_id, scope_code: PERSON|CUSTOMER_CODE|ACCOUNT_CODE, hierarchy_order)
- dim_service(service_id, service_name, service_category_id, subscribe_scope_id, is_active)

Facts:
- fact_service_request (one row per request)
- fact_service_subscription_event (one row per status event)

Entitlement View Logic (v_current_service_entitlement):
1. Determine active APPROVED events without later DEACTIVATED.
2. For PERSON scope: expand to all customer codes + accounts.
3. For CUSTOMER_CODE scope: expand to accounts under that code.
4. For ACCOUNT_CODE scope: keep exact account.
5. Union expansions, remove duplicates.

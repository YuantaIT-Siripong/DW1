# Data Quality Rules (Phase 1)

## 1. Customer Profile
- Uniqueness: One current version per customer (is_current = true).
- Non-Overlap: No overlapping effective intervals for same customer_id.
- Hash Integrity: attribute_hash changes when any SCD2 attribute changes.
- Birthdate Validity: birthdate <= current_date AND birthdate > '1900-01-01'.

## 2. Multi-Valued Sets
- No duplicates: (customer_profile_version_sk, constant_id) unique.
- Referential integrity: constant IDs exist in constant_list for required constant_type.

## 3. Service Subscription Events
- Sequence:
  - SUBMITTED precedes APPROVED/REJECTED.
  - APPROVED precedes DEACTIVATED.
- No duplicate identical status entries with same timestamp for a service_request_id.

## 4. Service Requests
- Active Flag: is_active_flag = true only if latest status APPROVED and no later DEACTIVATED.
- Approval Timeliness: approve_date >= submit_date.

## 5. General Integrity
- Scope Code in {PERSON, CUSTOMER_CODE, ACCOUNT_CODE}.
- effective_end_date is NULL or >= effective_start_date.

## 6. Alert Thresholds (Initial)
- Version Surge: >2% of customers versioned same day.
- High Rejection Rate: REJECTED / SUBMITTED > 15% daily.
- Hash Collision: 0 tolerated.

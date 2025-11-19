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

## 5. Investment Profile (NEW)
- Exactly one current_flag = true per investment_profile_id.
- No overlapping (effective_start_ts, effective_end_ts) intervals per investment_profile_id.
- complex_product_allowed = true => complex_product_ack_flag = true.
- margin_agreement_status = 'ACTIVE' => leverage_tolerance <> 'NONE' AND ability_to_bear_loss_tier <> 'LOW' AND vulnerable_investor_flag = false.
- next_review_due_ts > last_risk_review_ts.
- vulnerability_assessment_ts not null when vulnerable_investor_flag = true.
- DataQualityScore mandatory attributes present (risk_level_code, suitability_score, ability_to_bear_loss_tier, investment_objective_category, investor_category, kyc_status).

## 6. General Integrity
- Scope Code in {PERSON, CUSTOMER_CODE, ACCOUNT_CODE}.
- effective_end_ts is NULL or > effective_start_ts.

## 7. Alert Thresholds (Initial)
- Version Surge: >2% of customers versioned same day.
- High Rejection Rate: REJECTED / SUBMITTED > 15% daily.
- Hash Collision: 0 tolerated.
- Investment Profile Unknown Horizon Rate > 25% triggers remediation.

-- ====================================================================
-- Test Data: Bad Records for Quarantine Testing
-- ====================================================================

INSERT INTO bronze.customer_profile_standardized (
    customer_id, evidence_unique_key, firstname, lastname,
    person_title, person_title_other, marital_status,
    birthdate, total_asset, monthly_income,
    last_modified_ts, _bronze_load_ts, _bronze_source_file, _bronze_batch_id
) VALUES 

-- Test Case 1: NULL customer_id (CRITICAL - must quarantine)
(NULL, 'EV-BAD-001', 'John', 'Doe', 
 'MR', NULL, 'SINGLE',
 '1980-01-01', 'ASSET_1M_5M', 'INCOME_50K_100K',
 '2025-12-11', CURRENT_TIMESTAMP, 'test_bad_data', 99999999999901),

-- Test Case 2: Invalid person_title (ERROR - should quarantine)
('CUST-BAD-002', 'EV-BAD-002', 'Jane', 'Smith',
 'INVALID_TITLE', NULL, 'MARRIED',
 '1985-05-15', 'ASSET_500K_1M', 'INCOME_30K_50K',
 '2025-12-11', CURRENT_TIMESTAMP, 'test_bad_data', 99999999999902),

-- Test Case 3: person_title='OTHER' but person_title_other is NULL (ERROR)
('CUST-BAD-003', 'EV-BAD-003', 'Bob', 'Johnson',
 'OTHER', NULL, 'SINGLE',
 '1990-03-20', 'ASSET_UNDER_500K', 'INCOME_UNDER_30K',
 '2025-12-11', CURRENT_TIMESTAMP, 'test_bad_data', 99999999999903),

-- Test Case 4: Invalid birthdate (future date - CRITICAL)
('CUST-BAD-004', 'EV-BAD-004', 'Alice', 'Williams',
 'MS', NULL, 'SINGLE',
 '2099-12-31', 'ASSET_1M_5M', 'INCOME_100K_200K',
 '2025-12-11', CURRENT_TIMESTAMP, 'test_bad_data', 99999999999904),

-- Test Case 5: Invalid marital_status (ERROR)
('CUST-BAD-005', 'EV-BAD-005', 'Charlie', 'Brown',
 'MR', NULL, 'INVALID_STATUS',
 '1975-06-10', 'ASSET_5M_10M', 'INCOME_200K_PLUS',
 '2025-12-11', CURRENT_TIMESTAMP, 'test_bad_data', 99999999999905);
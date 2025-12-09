-- =====================================================================
-- MSSQL IT Operational View:  vw_customer_profile_standardized
-- Sample data for testing Bronze extract
-- =====================================================================
-- Database:  MSSQL (operational_db)
-- Schema: TempPOC
-- Purpose: Mock IT-provided standardized customer profile view
-- =====================================================================

USE TempPOC;
GO

-- Create underlying table for sample data
CREATE TABLE customer_profile_raw (
    customer_id VARCHAR(50) NOT NULL,
    evidence_unique_key VARCHAR(100),
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local NVARCHAR(200),
    lastname_local NVARCHAR(200),
    person_title VARCHAR(50),
    person_title_other VARCHAR(200),
    marital_status VARCHAR(50),
    nationality VARCHAR(2),
    nationality_other VARCHAR(200),
    occupation VARCHAR(100),
    occupation_other VARCHAR(200),
    education_level VARCHAR(100),
    education_level_other VARCHAR(200),
    business_type VARCHAR(100),
    business_type_other VARCHAR(200),
    birthdate DATE,
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(2),
    income_country_other VARCHAR(200),
    source_of_income_list VARCHAR(MAX),
    purpose_of_investment_list VARCHAR(MAX),
    last_modified_ts DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT PK_customer_profile_raw PRIMARY KEY (customer_id)
);
GO

-- Insert 20 sample records
INSERT INTO customer_profile_raw 
(customer_id, evidence_unique_key, firstname, lastname, firstname_local, lastname_local,
 person_title, person_title_other, marital_status, nationality, nationality_other,
 occupation, occupation_other, education_level, education_level_other,
 business_type, business_type_other, birthdate, total_asset, monthly_income,
 income_country, income_country_other, source_of_income_list, purpose_of_investment_list,
 last_modified_ts)
VALUES
-- Record 1: Complete profile, married software engineer
('100001', '1234567890123', 'Somchai', 'Suksamran', N' ¡™“¬', N' ÿ¢ ”√“≠', 
 'MR', NULL, 'MARRIED', 'TH', NULL, 'SOFTWARE_ENGINEER', NULL, 
 'BACHELORS', NULL, 'TECHNOLOGY', NULL, '1985-03-15', 
 'ASSET_1M_5M', 'INCOME_50K_100K', 'TH', NULL, 
 'DIVIDEND|SALARY', 'RETIREMENT|SAVINGS', '2025-01-15 08:30:00'),

-- Record 2: Single investor, high net worth
('100002', '9876543210987', 'Apinya', 'Wongsakul', N'Õ¿‘≠≠“', N'«ß»Ï °ÿ≈', 
 'MS', NULL, 'SINGLE', 'TH', NULL, 'BUSINESS_OWNER', NULL, 
 'MASTERS', NULL, 'REAL_ESTATE', NULL, '1990-07-22', 
 'ASSET_10M_PLUS', 'INCOME_200K_PLUS', 'TH', NULL, 
 'BUSINESS_INCOME|RENTAL', 'CAPITAL_GROWTH|INCOME_GENERATION', '2025-01-15 09:15:00'),

-- Record 3: Doctor with multiple income sources
('100003', '5551234567890', 'Narong', 'Pattanapong', N'≥√ß§Ï', N'æ—≤πæß»Ï', 
 'DR', NULL, 'MARRIED', 'TH', NULL, 'MEDICAL_PROFESSIONAL', NULL, 
 'DOCTORATE', NULL, 'HEALTHCARE', NULL, '1978-11-30', 
 'ASSET_5M_10M', 'INCOME_100K_200K', 'TH', NULL, 
 'DIVIDEND|RENTAL|SALARY', 'EDUCATION|RETIREMENT', '2025-01-15 10:00:00'),

-- Record 4: Young professional, entry level
('100004', '3334445556666', 'Preeyaporn', 'Chaiyasit', N'ª√’¬“æ√', N'™—¬ ‘∑∏‘Ï', 
 'MS', NULL, 'SINGLE', 'TH', NULL, 'ACCOUNTANT', NULL, 
 'BACHELORS', NULL, 'FINANCE', NULL, '1995-05-18', 
 'ASSET_500K_1M', 'INCOME_30K_50K', 'TH', NULL, 
 'SALARY', 'SAVINGS', '2025-01-15 11:20:00'),

-- Record 5: Retired investor
('100005', '7778889990000', 'Wichai', 'Tanawat', N'«‘™—¬', N'∏π“«—≤πÏ', 
 'MR', NULL, 'WIDOWED', 'TH', NULL, 'RETIRED', NULL, 
 'HIGH_SCHOOL', NULL, 'OTHER', 'Former Government Officer', '1955-02-10', 
 'ASSET_5M_10M', 'INCOME_50K_100K', 'TH', NULL, 
 'DIVIDEND|PENSION|RENTAL', 'INCOME_GENERATION', '2025-01-15 12:45:00'),

-- Record 6: Expat worker from Singapore
('100006', 'S1234567A', 'Michael', 'Tan', N'Michael', N'Tan', 
 'MR', NULL, 'MARRIED', 'SG', NULL, 'FINANCIAL_ANALYST', NULL, 
 'MASTERS', NULL, 'FINANCE', NULL, '1988-09-05', 
 'ASSET_5M_10M', 'INCOME_100K_200K', 'SG', NULL, 
 'SALARY', 'CAPITAL_GROWTH|RETIREMENT', '2025-01-15 13:10:00'),

-- Record 7: OTHER title example
('100007', '1112223334444', 'Chitpong', 'Rattanakorn', N'®‘µæß…Ï', N'√—µπ°√', 
 'OTHER', 'Lieutenant Colonel', 'MARRIED', 'TH', NULL, 'MILITARY', NULL, 
 'BACHELORS', NULL, 'GOVERNMENT', NULL, '1982-12-25', 
 'ASSET_1M_5M', 'INCOME_50K_100K', 'TH', NULL, 
 'SALARY', 'EDUCATION|RETIREMENT|SAVINGS', '2025-01-15 14:00:00'),

-- Record 8: Divorced entrepreneur
('100008', '5556667778888', 'Kannika', 'Srisawat', N'°√√≥‘°“√Ï', N'»√’ «— ¥‘Ï', 
 'MRS', NULL, 'DIVORCED', 'TH', NULL, 'BUSINESS_OWNER', NULL, 
 'BACHELORS', NULL, 'RETAIL', NULL, '1987-04-12', 
 'ASSET_1M_5M', 'INCOME_100K_200K', 'TH', NULL, 
 'BUSINESS_INCOME', 'CAPITAL_GROWTH', '2025-01-16 08:00:00'),

-- Record 9: Entry level with OTHER occupation
('100009', '9998887776665', 'Siriporn', 'Jaidee', N'»‘√‘æ√', N'„®¥’', 
 'MISS', NULL, 'SINGLE', 'TH', NULL, 'OTHER', 'Social Media Influencer', 
 'BACHELORS', NULL, 'OTHER', 'Content Creation', '1998-08-20', 
 'ASSET_UNDER_500K', 'INCOME_UNDER_30K', 'TH', NULL, 
 'OTHER', 'SAVINGS|SPECULATION', '2025-01-16 09:30:00'),

-- Record 10: Professor with international income
('100010', '2223334445555', 'Surasak', 'Wongchai', N' ÿ√»—°¥‘Ï', N'«ß»Ï™—¬', 
 'PROF', NULL, 'MARRIED', 'TH', NULL, 'EDUCATION', NULL, 
 'DOCTORATE', NULL, 'EDUCATION', NULL, '1970-06-18', 
 'ASSET_5M_10M', 'INCOME_100K_200K', 'US', NULL, 
 'SALARY', 'EDUCATION|RETIREMENT', '2025-01-16 10:15:00'),

-- Record 11: Young investor, separated
('100011', '4445556667777', 'Nattapong', 'Sukhothai', N'≥—∞æß»Ï', N' ÿ‚¢∑—¬', 
 'MR', NULL, 'SEPARATED', 'TH', NULL, 'SOFTWARE_ENGINEER', NULL, 
 'MASTERS', NULL, 'TECHNOLOGY', NULL, '1992-03-08', 
 'ASSET_500K_1M', 'INCOME_50K_100K', 'TH', NULL, 
 'SALARY', 'CAPITAL_GROWTH', '2025-01-16 11:00:00'),

-- Record 12: Senior business owner
('100012', '6667778889999', 'Pensri', 'Kraisorn', N'‡æÁ≠»√’', N'‰°√ √', 
 'MRS', NULL, 'MARRIED', 'TH', NULL, 'BUSINESS_OWNER', NULL, 
 'HIGH_SCHOOL', NULL, 'MANUFACTURING', NULL, '1965-01-30', 
 'ASSET_10M_PLUS', 'INCOME_200K_PLUS', 'TH', NULL, 
 'BUSINESS_INCOME|DIVIDEND|RENTAL', 'INCOME_GENERATION|WEALTH_PRESERVATION', '2025-01-16 12:30:00'),

-- Record 13: Expat from Japan
('100013', 'JP9876543', 'Takeshi', 'Yamamoto', N'Takeshi', N'Yamamoto', 
 'MR', NULL, 'MARRIED', 'JP', NULL, 'ENGINEER', NULL, 
 'BACHELORS', NULL, 'AUTOMOTIVE', NULL, '1983-11-11', 
 'ASSET_1M_5M', 'INCOME_100K_200K', 'JP', NULL, 
 'SALARY', 'RETIREMENT', '2025-01-16 13:45:00'),

-- Record 14: Newly graduated
('100014', '8889990001111', 'Patcharee', 'Moonmuang', N'æ—™√’', N'¡Ÿ≈‡¡◊Õß', 
 'MISS', NULL, 'SINGLE', 'TH', NULL, 'MARKETING', NULL, 
 'BACHELORS', NULL, 'ADVERTISING', NULL, '1999-12-05', 
 'ASSET_UNDER_500K', 'INCOME_30K_50K', 'TH', NULL, 
 'SALARY', 'SAVINGS', '2025-01-17 08:15:00'),

-- Record 15: Mid-career banker
('100015', '1231231231234', 'Thanawat', 'Siriwan', N'∏π“«—≤πÏ', N'»‘√‘«√√≥', 
 'MR', NULL, 'MARRIED', 'TH', NULL, 'FINANCIAL_ANALYST', NULL, 
 'MASTERS', NULL, 'FINANCE', NULL, '1986-07-14', 
 'ASSET_5M_10M', 'INCOME_100K_200K', 'TH', NULL, 
 'DIVIDEND|SALARY', 'CAPITAL_GROWTH|RETIREMENT', '2025-01-17 09:00:00'),

-- Record 16: Lawyer with high income
('100016', '4564564564567', 'Anchalee', 'Phuangmalai', N'Õ—≠™≈’', N'æ«ß¡“≈—¬', 
 'MS', NULL, 'SINGLE', 'TH', NULL, 'LAWYER', NULL, 
 'MASTERS', NULL, 'LEGAL', NULL, '1989-02-28', 
 'ASSET_5M_10M', 'INCOME_200K_PLUS', 'TH', NULL, 
 'SALARY', 'CAPITAL_GROWTH|WEALTH_PRESERVATION', '2025-01-17 10:30:00'),

-- Record 17: OTHER nationality example
('100017', 'XX1234567', 'Ahmed', 'Al-Rashid', N'Ahmed', N'Al-Rashid', 
 'MR', NULL, 'MARRIED', 'OTHER', 'United Arab Emirates', 'BUSINESS_OWNER', NULL, 
 'MASTERS', NULL, 'REAL_ESTATE', NULL, '1980-05-20', 
 'ASSET_10M_PLUS', 'INCOME_200K_PLUS', 'OTHER', 'UAE', 
 'BUSINESS_INCOME|RENTAL', 'CAPITAL_GROWTH|INCOME_GENERATION', '2025-01-17 11:15:00'),

-- Record 18: Government officer
('100018', '7897897897890', 'Chalermchai', 'Boonmee', N'‡©≈‘¡™—¬', N'∫ÿ≠¡’', 
 'MR', NULL, 'MARRIED', 'TH', NULL, 'GOVERNMENT', NULL, 
 'BACHELORS', NULL, 'GOVERNMENT', NULL, '1975-10-03', 
 'ASSET_1M_5M', 'INCOME_50K_100K', 'TH', NULL, 
 'SALARY', 'EDUCATION|RETIREMENT', '2025-01-17 12:00:00'),

-- Record 19: Freelance consultant
('100019', '3213213213210', 'Wilaiporn', 'Kaewkanya', N'«‘‰≈æ√', N'·°È«°—≠≠“', 
 'MRS', NULL, 'MARRIED', 'TH', NULL, 'CONSULTANT', NULL, 
 'MASTERS', NULL, 'CONSULTING', NULL, '1991-09-16', 
 'ASSET_1M_5M', 'INCOME_50K_100K', 'TH', NULL, 
 'BUSINESS_INCOME', 'RETIREMENT|SAVINGS', '2025-01-17 13:30:00'),

-- Record 20: Artist with irregular income
('100020', '6546546546543', 'Natthawut', 'Artchai', N'≥—∞«ÿ≤‘', N'Õ“®™—¬', 
 'MR', NULL, 'SINGLE', 'TH', NULL, 'OTHER', 'Professional Artist', 
 'BACHELORS', NULL, 'OTHER', 'Creative Arts', '1993-04-25', 
 'ASSET_500K_1M', 'INCOME_30K_50K', 'TH', NULL, 
 'OTHER', 'SAVINGS|SPECULATION', '2025-01-17 14:45:00');
GO

-- Create IT view (standardized interface)
CREATE VIEW vw_customer_profile_standardized AS
SELECT 
    customer_id,
    evidence_unique_key,
    firstname,
    lastname,
    firstname_local,
    lastname_local,
    person_title,
    person_title_other,
    marital_status,
    nationality,
    nationality_other,
    occupation,
    occupation_other,
    education_level,
    education_level_other,
    business_type,
    business_type_other,
    birthdate,
    total_asset,
    monthly_income,
    income_country,
    income_country_other,
    source_of_income_list,
    purpose_of_investment_list,
    last_modified_ts
FROM customer_profile_raw;
GO

-- Verify data
SELECT 
    COUNT(*) AS total_records,
    MIN(last_modified_ts) AS earliest_modified,
    MAX(last_modified_ts) AS latest_modified
FROM vw_customer_profile_standardized;
GO

-- Show sample records
SELECT TOP 5 
    customer_id,
    firstname,
    lastname,
    occupation,
    total_asset,
    monthly_income,
    last_modified_ts
FROM vw_customer_profile_standardized
ORDER BY customer_id;
GO
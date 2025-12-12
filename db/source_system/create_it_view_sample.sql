-- =====================================================================
-- MSSQL IT Operational View:  vw_customer_profile_standardized
-- Sample data for testing Bronze extract
-- =====================================================================
-- Database:  MSSQL (TempPOC)
-- Schema: dbo
-- Purpose: Mock IT-provided standardized customer profile view
-- =====================================================================

USE TempPOC;
GO

-- Drop existing objects if they exist
IF OBJECT_ID('dbo.vw_customer_profile_standardized', 'V') IS NOT NULL
    DROP VIEW dbo.vw_customer_profile_standardized;
GO

IF OBJECT_ID('dbo.customer_profile_raw', 'U') IS NOT NULL
    DROP TABLE dbo.customer_profile_raw;
GO

-- Create underlying table for sample data (with larger column sizes)
CREATE TABLE dbo.customer_profile_raw (
    customer_id VARCHAR(50) NOT NULL,
    evidence_unique_key VARCHAR(100),
    firstname VARCHAR(200),
    lastname VARCHAR(200),
    firstname_local NVARCHAR(200),
    lastname_local NVARCHAR(200),
    person_title VARCHAR(50),
    person_title_other VARCHAR(500),           -- Increased size
    marital_status VARCHAR(50),
    nationality VARCHAR(50),                   -- Increased from VARCHAR(2)
    nationality_other VARCHAR(500),            -- Increased size
    occupation VARCHAR(100),
    occupation_other VARCHAR(500),             -- Increased size
    education_level VARCHAR(100),
    education_level_other VARCHAR(500),        -- Increased size
    business_type VARCHAR(100),
    business_type_other VARCHAR(500),          -- Increased size
    birthdate DATE,
    total_asset VARCHAR(50),
    monthly_income VARCHAR(50),
    income_country VARCHAR(50),                -- Increased from VARCHAR(2)
    income_country_other VARCHAR(500),         -- Increased size
    source_of_income_list VARCHAR(MAX),
    purpose_of_investment_list VARCHAR(MAX),
    last_modified_ts DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT PK_customer_profile_raw PRIMARY KEY (customer_id)
);
GO

-- Insert 20 sample records with CORRECT enumeration codes
INSERT INTO dbo. customer_profile_raw 
(customer_id, evidence_unique_key, firstname, lastname, firstname_local, lastname_local,
 person_title, person_title_other, marital_status, nationality, nationality_other,
 occupation, occupation_other, education_level, education_level_other,
 business_type, business_type_other, birthdate, total_asset, monthly_income,
 income_country, income_country_other, source_of_income_list, purpose_of_investment_list,
 last_modified_ts)
VALUES
-- Record 1: Software engineer
('100001', '1234567890123', 'Somchai', 'Suksamran', N' ¡™“¬', N' ÿ¢ ”√“≠', 
 'MR', NULL, 'MARRIED', 'TH', NULL, 'PROFESSIONAL', NULL, 
 'BACHELOR', NULL, 'TECHNOLOGY', NULL, '1985-03-15', 
 'ASSET_BAND_3', 'INCOME_BAND_3', 'TH', NULL, 
 'DIVIDEND|SALARY', 'RETIREMENT|SAVINGS', '2025-01-15 08:30:00'),

-- Record 2: Business owner
('100002', '9876543210987', 'Apinya', 'Wongsakul', N'Õ¿‘≠≠“', N'«ß»Ï °ÿ≈', 
 'MS', NULL, 'SINGLE', 'TH', NULL, 'BUSINESS_OWNER', NULL, 
 'MASTER', NULL, 'REAL_ESTATE', NULL, '1990-07-22', 
 'ASSET_BAND_5', 'INCOME_BAND_5', 'TH', NULL, 
 'BUSINESS_INCOME|RENTAL', 'CAPITAL_GROWTH|INCOME_GENERATION', '2025-01-15 09:15:00'),

-- Record 3: Doctor
('100003', '5551234567890', 'Narong', 'Pattanapong', N'≥√ß§Ï', N'ª—∞πæß»Ï', 
 'DR', NULL, 'MARRIED', 'TH', NULL, 'PROFESSIONAL', NULL, 
 'DOCTORATE', NULL, 'HEALTHCARE', NULL, '1978-11-30', 
 'ASSET_BAND_4', 'INCOME_BAND_4', 'TH', NULL, 
 'DIVIDEND|RENTAL|SALARY', 'EDUCATION|RETIREMENT', '2025-01-15 10:00:00'),

-- Record 4: Accountant
('100004', '3334445556666', 'Preeyaporn', 'Chaiyasit', N'ª√’¬“æ√', N'™—¬ ‘∑∏‘Ï', 
 'MS', NULL, 'SINGLE', 'TH', NULL, 'PROFESSIONAL', NULL, 
 'BACHELOR', NULL, 'FINANCE', NULL, '1995-05-18', 
 'ASSET_BAND_2', 'INCOME_BAND_2', 'TH', NULL, 
 'SALARY', 'SAVINGS', '2025-01-15 11:20:00'),

-- Record 5:  Retired
('100005', '7778889990000', 'Wichai', 'Tanawat', N'«‘™—¬', N'∏π“«—≤πÏ', 
 'MR', NULL, 'WIDOWED', 'TH', NULL, 'RETIRED', NULL, 
 'SECONDARY', NULL, 'OTHER', 'Former Officer', '1955-02-10', 
 'ASSET_BAND_4', 'INCOME_BAND_3', 'TH', NULL, 
 'DIVIDEND|PENSION|RENTAL', 'INCOME_GENERATION', '2025-01-15 12:45:00'),

-- Record 6: Expat employee
('100006', 'S1234567A', 'Michael', 'Tan', N'Michael', N'Tan', 
 'MR', NULL, 'MARRIED', 'SG', NULL, 'EMPLOYEE', NULL, 
 'MASTER', NULL, 'FINANCE', NULL, '1988-09-05', 
 'ASSET_BAND_4', 'INCOME_BAND_4', 'SG', NULL, 
 'SALARY', 'CAPITAL_GROWTH|RETIREMENT', '2025-01-15 13:10:00'),

-- Record 7: Government officer with OTHER title
('100007', '1112223334444', 'Chitpong', 'Rattanakorn', N'™‘µæß…Ï', N'√—µπ“°√', 
 'OTHER', 'Lt Col', 'MARRIED', 'TH', NULL, 'GOVERNMENT_OFFICER', NULL, 
 'BACHELOR', NULL, 'GOVERNMENT', NULL, '1982-12-25', 
 'ASSET_BAND_3', 'INCOME_BAND_3', 'TH', NULL, 
 'SALARY', 'EDUCATION|RETIREMENT|SAVINGS', '2025-01-15 14:00:00'),

-- Record 8: Business owner
('100008', '5556667778888', 'Kannika', 'Srisawat', N'°“πµ‘°“', N'»√’ «— ¥‘Ï', 
 'MRS', NULL, 'DIVORCED', 'TH', NULL, 'BUSINESS_OWNER', NULL, 
 'BACHELOR', NULL, 'RETAIL', NULL, '1987-04-12', 
 'ASSET_BAND_3', 'INCOME_BAND_4', 'TH', NULL, 
 'BUSINESS_INCOME', 'CAPITAL_GROWTH', '2025-01-16 08:00:00'),

-- Record 9: OTHER occupation
('100009', '9998887776665', 'Siriporn', 'Jaidee', N'»‘√‘æ√', N'„®¥’', 
 'MISS', NULL, 'SINGLE', 'TH', NULL, 'OTHER', 'Influencer', 
 'BACHELOR', NULL, 'OTHER', 'Content', '1998-08-20', 
 'ASSET_BAND_1', 'INCOME_BAND_1', 'TH', NULL, 
 'OTHER', 'SAVINGS|SPECULATION', '2025-01-16 09:30:00'),

-- Record 10: Professor
('100010', '2223334445555', 'Surasak', 'Wongchai', N' ÿ√»—°¥‘Ï', N'«ß»Ï™—¬', 
 'PROF', NULL, 'MARRIED', 'TH', NULL, 'EMPLOYEE', NULL, 
 'DOCTORATE', NULL, 'EDUCATION', NULL, '1970-06-18', 
 'ASSET_BAND_4', 'INCOME_BAND_4', 'US', NULL, 
 'SALARY', 'EDUCATION|RETIREMENT', '2025-01-16 10:15:00'),

-- Record 11: Employee
('100011', '4445556667777', 'Nattapong', 'Sukhothai', N'≥—∞æß…Ï', N' ÿ‚¢∑—¬', 
 'MR', NULL, 'SEPARATED', 'TH', NULL, 'EMPLOYEE', NULL, 
 'MASTER', NULL, 'TECHNOLOGY', NULL, '1992-03-08', 
 'ASSET_BAND_2', 'INCOME_BAND_3', 'TH', NULL, 
 'SALARY', 'CAPITAL_GROWTH', '2025-01-16 11:00:00'),

-- Record 12: Senior business owner
('100012', '6667778889999', 'Pensri', 'Kraisorn', N'‡æÁ≠»√’', N'‰°√ √', 
 'MRS', NULL, 'MARRIED', 'TH', NULL, 'BUSINESS_OWNER', NULL, 
 'SECONDARY', NULL, 'MANUFACTURING', NULL, '1965-01-30', 
 'ASSET_BAND_5', 'INCOME_BAND_5', 'TH', NULL, 
 'BUSINESS_INCOME|DIVIDEND|RENTAL', 'INCOME_GENERATION|WEALTH_PRESERVATION', '2025-01-16 12:30:00'),

-- Record 13: Japanese expat
('100013', 'JP9876543', 'Takeshi', 'Yamamoto', N'Takeshi', N'Yamamoto', 
 'MR', NULL, 'MARRIED', 'JP', NULL, 'EMPLOYEE', NULL, 
 'BACHELOR', NULL, 'AUTOMOTIVE', NULL, '1983-11-11', 
 'ASSET_BAND_3', 'INCOME_BAND_4', 'JP', NULL, 
 'SALARY', 'RETIREMENT', '2025-01-16 13:45:00'),

-- Record 14: Young graduate
('100014', '8889990001111', 'Patcharee', 'Moonmuang', N'æ—™√’', N'¡Ÿ≈‡¡◊Õß', 
 'MISS', NULL, 'SINGLE', 'TH', NULL, 'EMPLOYEE', NULL, 
 'BACHELOR', NULL, 'ADVERTISING', NULL, '1999-12-05', 
 'ASSET_BAND_1', 'INCOME_BAND_2', 'TH', NULL, 
 'SALARY', 'SAVINGS', '2025-01-17 08:15:00'),

-- Record 15: Banker
('100015', '1231231231234', 'Thanawat', 'Siriwan', N'∏π“«—≤πÏ', N' ‘√‘«√√≥', 
 'MR', NULL, 'MARRIED', 'TH', NULL, 'EMPLOYEE', NULL, 
 'MASTER', NULL, 'FINANCE', NULL, '1986-07-14', 
 'ASSET_BAND_4', 'INCOME_BAND_4', 'TH', NULL, 
 'DIVIDEND|SALARY', 'CAPITAL_GROWTH|RETIREMENT', '2025-01-17 09:00:00'),

-- Record 16: Lawyer
('100016', '4564564564567', 'Anchalee', 'Phuangmalai', N'Õ—≠™≈’', N'æ«ß¡“≈—¬', 
 'MS', NULL, 'SINGLE', 'TH', NULL, 'PROFESSIONAL', NULL, 
 'MASTER', NULL, 'LEGAL', NULL, '1989-02-28', 
 'ASSET_BAND_4', 'INCOME_BAND_5', 'TH', NULL, 
 'SALARY', 'CAPITAL_GROWTH|WEALTH_PRESERVATION', '2025-01-17 10:30:00'),

-- Record 17: OTHER nationality
('100017', 'XX1234567', 'Ahmed', 'AlRashid', N'Ahmed', N'AlRashid', 
 'MR', NULL, 'MARRIED', 'OTHER', 'UAE', 'BUSINESS_OWNER', NULL, 
 'MASTER', NULL, 'REAL_ESTATE', NULL, '1980-05-20', 
 'ASSET_BAND_5', 'INCOME_BAND_5', 'OTHER', 'UAE', 
 'BUSINESS_INCOME|RENTAL', 'CAPITAL_GROWTH|INCOME_GENERATION', '2025-01-17 11:15:00'),

-- Record 18: Government officer
('100018', '7897897897890', 'Chalermchai', 'Boonmee', N'‡©≈‘¡™—¬', N'∫ÿ≠¡’', 
 'MR', NULL, 'MARRIED', 'TH', NULL, 'GOVERNMENT_OFFICER', NULL, 
 'BACHELOR', NULL, 'GOVERNMENT', NULL, '1975-10-03', 
 'ASSET_BAND_3', 'INCOME_BAND_3', 'TH', NULL, 
 'SALARY', 'EDUCATION|RETIREMENT', '2025-01-17 12:00:00'),

-- Record 19: Self-employed consultant
('100019', '3213213213210', 'Wilaiporn', 'Kaewkanya', N'«‘‰≈æ√', N'·°È«°—≠≠“', 
 'MRS', NULL, 'MARRIED', 'TH', NULL, 'SELF_EMPLOYED', NULL, 
 'MASTER', NULL, 'CONSULTING', NULL, '1991-09-16', 
 'ASSET_BAND_3', 'INCOME_BAND_3', 'TH', NULL, 
 'BUSINESS_INCOME', 'RETIREMENT|SAVINGS', '2025-01-17 13:30:00'),

-- Record 20: Artist
('100020', '6546546546543', 'Natthawut', 'Artchai', N'≥—∞«ÿ≤‘', N'Õ“®™—¬', 
 'MR', NULL, 'SINGLE', 'TH', NULL, 'OTHER', 'Artist', 
 'BACHELOR', NULL, 'OTHER', 'Arts', '1993-04-25', 
 'ASSET_BAND_2', 'INCOME_BAND_2', 'TH', NULL, 
 'OTHER', 'SAVINGS|SPECULATION', '2025-01-17 14:45:00');
GO

-- Create IT view
CREATE VIEW dbo.vw_customer_profile_standardized AS
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
FROM dbo.customer_profile_raw;
GO

-- Verify
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT occupation) AS distinct_occupations,
    COUNT(DISTINCT total_asset) AS distinct_assets
FROM dbo.vw_customer_profile_standardized;
GO

-- Show sample
SELECT TOP 5 
    customer_id,
    firstname,
    occupation,
    total_asset,
    monthly_income
FROM dbo.vw_customer_profile_standardized
ORDER BY customer_id;
GO

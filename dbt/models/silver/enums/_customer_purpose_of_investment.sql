{{ config(materialized='table', schema='silver') }}

SELECT * FROM (VALUES
    ('RETIREMENT'),
    ('SAVINGS'),
    ('EDUCATION'),
    ('CAPITAL_GROWTH'),
    ('INCOME_GENERATION'),
    ('WEALTH_PRESERVATION'),
    ('TAX_PLANNING'),
    ('ESTATE_PLANNING'),
    ('SPECULATION'),
    ('DIVERSIFICATION'),
    ('HEDGING'),
    ('LIQUIDITY'),
    ('EMERGENCY_FUND'),
    ('MAJOR_PURCHASE'),  -- house, car, etc. 
    ('BUSINESS_INVESTMENT'),
    ('CHARITABLE_GIVING'),
    ('OTHER')
) AS t(code)
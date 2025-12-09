{{ config(materialized='table', schema='silver') }}

SELECT * FROM (VALUES
    ('SALARY'),
    ('BUSINESS_INCOME'),
    ('DIVIDEND'),
    ('RENTAL'),
    ('PENSION'),
    ('INVESTMENT'),
    ('INHERITANCE'),
    ('GIFT'),
    ('LOTTERY'),
    ('CAPITAL_GAINS'),
    ('ROYALTY'),
    ('COMMISSION'),
    ('BONUS'),
    ('ALLOWANCE'),
    ('SOCIAL_SECURITY'),
    ('ALIMONY'),
    ('SCHOLARSHIP'),
    ('GRANT'),
    ('LOAN'),
    ('OTHER')
) AS t(code)
{{ config(materialized='table', schema='silver') }}

SELECT * FROM (VALUES
    ('INCOME_UNDER_30K'),
    ('INCOME_30K_50K'),
    ('INCOME_50K_100K'),
    ('INCOME_100K_200K'),
    ('INCOME_200K_PLUS')
) AS t(code)
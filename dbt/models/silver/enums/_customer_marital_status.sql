{{ config(materialized='table', schema='silver') }}

SELECT * FROM (VALUES
    ('SINGLE'),
    ('MARRIED'),
    ('DIVORCED'),
    ('WIDOWED'),
    ('SEPARATED'),
    ('UNKNOWN')
) AS t(code)
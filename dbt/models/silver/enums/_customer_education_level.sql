{{ config(materialized='table', schema='silver') }}

SELECT * FROM (VALUES
    ('PRIMARY_SCHOOL'),
    ('JUNIOR_HIGH'),
    ('HIGH_SCHOOL'),
    ('VOCATIONAL'),
    ('DIPLOMA'),
    ('BACHELORS'),
    ('MASTERS'),
    ('DOCTORATE'),
    ('PROFESSIONAL'),  -- CPA, CFA, etc.
    ('OTHER'),
    ('UNKNOWN')
) AS t(code)
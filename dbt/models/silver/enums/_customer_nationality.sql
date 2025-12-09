{{ config(materialized='table', schema='silver') }}

-- ISO 3166-1 alpha-2 country codes (common ones + OTHER)
SELECT * FROM (VALUES
    ('TH'),  -- Thailand
    ('US'),  -- United States
    ('GB'),  -- United Kingdom
    ('SG'),  -- Singapore
    ('JP'),  -- Japan
    ('CN'),  -- China
    ('HK'),  -- Hong Kong
    ('MY'),  -- Malaysia
    ('ID'),  -- Indonesia
    ('VN'),  -- Vietnam
    ('PH'),  -- Philippines
    ('KR'),  -- South Korea
    ('TW'),  -- Taiwan
    ('IN'),  -- India
    ('AU'),  -- Australia
    ('NZ'),  -- New Zealand
    ('CA'),  -- Canada
    ('DE'),  -- Germany
    ('FR'),  -- France
    ('CH'),  -- Switzerland
    ('AE'),  -- United Arab Emirates
    ('OTHER')
) AS t(code)
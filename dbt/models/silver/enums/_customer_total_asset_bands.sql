{{ config(materialized='table', schema='silver') }}

SELECT * FROM (VALUES
    ('ASSET_UNDER_500K'),
    ('ASSET_500K_1M'),
    ('ASSET_1M_5M'),
    ('ASSET_5M_10M'),
    ('ASSET_10M_PLUS')
) AS t(code)
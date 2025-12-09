{{ config(materialized='table', schema='silver') }}

SELECT * FROM (VALUES
    ('MR'),
    ('MRS'),
    ('MS'),
    ('MISS'),
    ('DR'),
    ('PROF'),
    ('REV'),
    ('OTHER')
) AS t(code)
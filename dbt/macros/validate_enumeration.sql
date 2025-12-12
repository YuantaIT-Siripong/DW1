{% macro validate_enumeration(column_name, enum_ref_name) %}
    CASE 
        WHEN {{ column_name }} IS NULL THEN TRUE
        WHEN {{ column_name }} IN (
            SELECT code 
            FROM {{ ref(enum_ref_name) }}
            WHERE is_active = TRUE
        ) THEN TRUE
        ELSE FALSE
    END
{% endmacro %}
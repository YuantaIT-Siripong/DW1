{% macro validate_enumeration(column_name, enum_table_name) %}
    (
        {{ column_name }} IS NULL 
        OR {{ column_name }} IN (
            SELECT code FROM {{ ref(enum_table_name) }}
        )
    )
{% endmacro %}
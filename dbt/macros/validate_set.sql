{% macro validate_set(column_name, enum_table_name) %}
    (
        {{ column_name }} IS NULL
        OR NOT EXISTS (
            SELECT 1 
            FROM unnest(string_to_array({{ column_name }}, '|')) AS item
            WHERE item NOT IN (SELECT code FROM {{ ref(enum_table_name) }})
        )
    )
{% endmacro %}
{% macro compute_set_hash(set_column) %}
    CASE 
        WHEN {{ set_column }} IS NULL THEN NULL
        ELSE encode(
            sha256(
                array_to_string(
                    (
                        SELECT array_agg(item ORDER BY item)
                        FROM unnest(string_to_array({{ set_column }}, '|')) AS item
                    ),
                    '|'
                )::bytea
            ),
            'hex'
        )
    END
{% endmacro %}
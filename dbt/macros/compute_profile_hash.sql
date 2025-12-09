{% macro compute_profile_hash() %}
    encode(
        sha256(
            concat_ws('|',
                {% for arg in varargs %}
                    COALESCE({{ arg }}::TEXT, '')
                    {%- if not loop.last %},{% endif %}
                {% endfor %}
            ):: bytea
        ),
        'hex'
    )
{% endmacro %}
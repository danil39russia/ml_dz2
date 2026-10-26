{% macro amount_bucket(column_name) -%}
    {#- Сегментация суммы транзакции: micro / small / medium / large / huge -#}
    multiIf(
        {{ column_name }} < 10, 'micro',
        {{ column_name }} < 50, 'small',
        {{ column_name }} < 200, 'medium',
        {{ column_name }} < {{ var('large_amount_threshold', 500) }}, 'large',
        'huge'
    )
{%- endmacro %}

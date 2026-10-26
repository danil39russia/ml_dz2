{% macro fraud_rate(fraud_col='is_fraud', precision=4) -%}
    {#- Доля мошеннических транзакций в процентах (0–100) -#}
    round(100.0 * sum({{ fraud_col }}) / nullIf(count(), 0), {{ precision }})
{%- endmacro %}

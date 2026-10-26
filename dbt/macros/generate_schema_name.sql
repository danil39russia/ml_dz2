{% macro generate_schema_name(custom_schema_name, node) -%}
    {#- Слои живут в отдельных базах ClickHouse: staging, marts (без префикса target-схемы) -#}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}

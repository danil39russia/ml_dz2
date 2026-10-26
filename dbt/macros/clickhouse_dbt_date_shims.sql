{#-
    Реализация dbt_date.date_part для ClickHouse: в пакете нет диспатча под этот адаптер.
    Подключается через dispatch в dbt_project.yml (поиск сначала в этом проекте).
    Семантика как в Postgres: dayofweek 0 = воскресенье ... 6 = суббота.
-#}
{% macro clickhouse__date_part(datepart, date) -%}
    {%- set part = datepart | lower -%}
    {%- if part in ('dayofweek', 'dow') -%}
        (toDayOfWeek({{ date }}) % 7)
    {%- elif part in ('isodow', 'dayofweekiso') -%}
        toDayOfWeek({{ date }})
    {%- elif part in ('dayofyear', 'doy') -%}
        toDayOfYear({{ date }})
    {%- elif part == 'hour' -%}
        toHour({{ date }})
    {%- elif part == 'day' -%}
        toDayOfMonth({{ date }})
    {%- elif part == 'month' -%}
        toMonth({{ date }})
    {%- elif part == 'year' -%}
        toYear({{ date }})
    {%- elif part == 'week' -%}
        toISOWeek({{ date }})
    {%- else -%}
        {{ exceptions.raise_compiler_error("clickhouse__date_part: unsupported datepart " ~ datepart) }}
    {%- endif -%}
{%- endmacro %}

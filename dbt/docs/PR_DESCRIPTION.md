## dbt-проект: аналитика фрода на ClickHouse

Каталог `dbt/` — слоистая модель `raw (transactions_db.transactions) → staging → marts` поверх данных из ДЗ по ClickHouse.

### Версии
- dbt-core **1.9.11**
- dbt-clickhouse **1.10.3**
- ClickHouse 24.8, sqlfluff 3.2.5

### Витрины (6)
- `mart_daily_state_metrics` — дневные метрики по штатам (количество, сумма, средний чек, P95, доля крупных)
- `mart_fraud_by_category` — фрод по категориям (fraud_rate %, суммы, ранг)
- `mart_fraud_by_state` — фрод по штатам (fraud_rate, уникальные клиенты и мерчанты, суммы)
- `mart_customer_risk_profile` — профиль риска клиента HIGH/MEDIUM/LOW
- `mart_hourly_fraud_pattern` — день недели × час, окна повышенного риска
- `mart_merchant_analytics` — оборот, fraud_rate, флаг подозрительности мерчанта

### Макросы и пакеты
- Свои макросы: `amount_bucket`, `fraud_rate`, `clickhouse__date_part` (адаптация `dbt_date` под ClickHouse), `generate_schema_name`
- Пакеты: `dbt_utils` (surrogate keys, unique_combination_of_columns, accepted_range), `dbt_date` (day_of_week), `dbt_expectations`

### Тесты — `dbt test`: PASS=57, ERROR=0
- generic: not_null, unique, accepted_values, relationships
- dbt_utils / dbt_expectations: уникальность комбинаций ключей витрин, диапазоны, количество строк и категорий
- singular: `assert_no_negative_amounts`, `assert_fraud_rate_bounds`, `assert_marts_reconcile_with_staging`, `assert_amount_bucket_matches_amount`
- unit tests: `test_fraud_by_category_rate`, `test_customer_risk_segments`

Лог: [`dbt/docs/dbt_test.log`](dbt/docs/dbt_test.log)

```
Done. PASS=57 WARN=0 ERROR=0 SKIP=0 TOTAL=57
```

### DAG (dbt Docs)
![DAG](dbt/docs/dbt_dag.jpg)

### sqlfluff и pre-commit
- `dbt/.sqlfluff`: dialect clickhouse, templater dbt; `sqlfluff lint models tests` проходит без замечаний
- `.pre-commit-config.yaml`: sqlfluff-lint (+ sqlfluff-fix вручную), базовые хуки
- `dbt/Makefile`: install / up / load / all / build / docs / lint

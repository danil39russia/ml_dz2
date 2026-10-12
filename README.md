# Kafka → ClickHouse: загрузка транзакций

Пайплайн: CSV с транзакциями → Python-продюсер → топик Kafka `transactions` → таблица ClickHouse с движком `Kafka` → materialized view → таблица хранения `MergeTree`.

## Структура

```
.
├── docker-compose.yml          # Kafka (KRaft), ClickHouse, продюсер
├── producer/
│   ├── producer.py             # п.1: загрузка CSV в топик Kafka
│   ├── requirements.txt
│   └── Dockerfile
├── sql/
│   ├── 01_ddl.sql              # п.2: Kafka-таблица, базовая таблица transactions_raw + MV
│   ├── 02_ddl_optimized.sql    # п.4: оптимизированная таблица transactions + MV
│   └── query.sql               # п.3: категория наибольшей транзакции по каждому штату
├── result/
│   └── result.csv              # п.3: результат запроса
└── data/
    └── train.csv               # датасет (не хранится в репозитории)
```

## Запуск

Требуется Docker с Docker Compose v2.

1. Скачать датасет с [Kaggle](https://www.kaggle.com/t/1918f3f6435300327d38d6c596f97394) и положить `train.csv` в папку `data/`:

   ```
   data/train.csv
   ```

2. Поднять Kafka и ClickHouse (DDL из `sql/` применяется автоматически при первом старте ClickHouse):

   ```bash
   docker compose up -d
   ```

3. Загрузить CSV в Kafka (собирается образ продюсера, контейнер отправляет все строки и завершается):

   ```bash
   docker compose --profile producer run --rm producer
   ```

   ClickHouse читает топик в фоне. Проверить, что все 786 431 строк дошли до обеих таблиц:

   ```bash
   docker compose exec clickhouse clickhouse-client -q "SELECT (SELECT count() FROM transactions_raw), (SELECT count() FROM transactions)"
   ```

4. Выполнить запрос и сохранить результат в CSV:

   ```bash
   docker compose exec -T clickhouse clickhouse-client --format CSVWithNames < sql/query.sql > result/result.csv
   ```

5. Остановить и удалить контейнеры:

   ```bash
   docker compose down
   ```

Продюсер можно запустить и локально (без Docker): `pip install -r producer/requirements.txt`, затем `python producer/producer.py` — по умолчанию он подключается к `localhost:9092` и читает `data/train.csv` (настраивается переменными `KAFKA_BOOTSTRAP_SERVERS`, `KAFKA_TOPIC`, `CSV_PATH`).

## Как устроено

**Продюсер** (`producer/producer.py`) читает CSV построчно, приводит числовые поля к числам, дополняет время до формата `YYYY-MM-DD hh:mm:ss` и отправляет каждую строку в топик как JSON. Топик создаётся автоматически, если его нет.

**ClickHouse** (`sql/01_ddl.sql`):

- `transactions_kafka` — таблица на движке `Kafka` (формат `JSONEachRow`), которая подписана на топик;
- `transactions_raw` — базовая таблица хранения: «прямые» типы (`String`, `Float64`, `Int64`), `ORDER BY tuple()`;
- `transactions_raw_mv` — materialized view, перекладывающий сообщения из Kafka в `transactions_raw`.

**Запрос** (`sql/query.sql`) — для каждого штата берётся категория транзакции с максимальной суммой через `argMax(cat_id, amount)`.

## Оптимизация хранения (п.4)

Оптимизированная версия DDL — `sql/02_ddl_optimized.sql`, таблица `transactions` наполняется из того же Kafka-топика своим materialized view. Обе таблицы оставлены рядом, чтобы их можно было сравнить на одних данных.

Что изменено относительно `transactions_raw`:

| Изменение | Зачем |
|---|---|
| `LowCardinality(String)` для `cat_id`, `us_state`, `merch`, `one_city`, `jobs`, `gender`, `name_1`, `name_2` | словарное кодирование: в колонках сотни уникальных значений на 786 тыс. строк, хранятся и сравниваются короткие числовые индексы |
| `Decimal(12, 2)` для `amount`, `Float32` для координат, `UInt32`/`UInt8` вместо `Int64` | типы минимально достаточного размера |
| `CODEC(Delta, ZSTD)` для времени, `ZSTD` для остальных «тяжёлых» колонок | лучшее сжатие |
| `PARTITION BY toYYYYMM(transaction_time)` | отсечение партиций при фильтрах по дате |
| `ORDER BY (us_state, cat_id, transaction_time)` | данные упорядочены по полям группировки: лучше сжатие, быстрые выборки по штату |
| `PROJECTION max_amount_by_state` | заранее посчитанный агрегат `argMax(cat_id, amount)`, `max(amount)` по штатам; ClickHouse автоматически использует его для целевого запроса |

Результаты на полном датасете (786 431 строка, после `OPTIMIZE TABLE ... FINAL`):

| | `transactions_raw` | `transactions` |
|---|---|---|
| Размер на диске (сжато) | ~56 MiB | ~20 MiB |
| Строк прочитано целевым запросом | 786 431 | 751 (из проекции) |

Как проверить:

```bash
# размер таблиц
docker compose exec clickhouse clickhouse-client -q "SELECT table, formatReadableSize(sum(data_compressed_bytes)) AS size FROM system.parts WHERE active AND table IN ('transactions_raw', 'transactions') GROUP BY table"
```

```bash
# сколько строк читает запрос и используется ли проекция
docker compose exec clickhouse clickhouse-client -q "EXPLAIN indexes = 1 SELECT us_state, argMax(cat_id, amount), max(amount) FROM transactions GROUP BY us_state"
```

Результат запроса на обеих таблицах совпадает.

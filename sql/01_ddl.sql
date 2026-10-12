-- Таблица-консьюмер: читает JSON-сообщения из топика Kafka
CREATE TABLE IF NOT EXISTS transactions_kafka
(
    transaction_time DateTime,
    merch            String,
    cat_id           String,
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           String,
    street           String,
    one_city         String,
    us_state         String,
    post_code        Int64,
    lat              Float64,
    lon              Float64,
    population_city  Int64,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           Int64
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:29092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'clickhouse_transactions',
    kafka_format = 'JSONEachRow',
    kafka_max_block_size = 65536;

-- Базовая (неоптимизированная) таблица хранения
CREATE TABLE IF NOT EXISTS transactions_raw
(
    transaction_time DateTime,
    merch            String,
    cat_id           String,
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           String,
    street           String,
    one_city         String,
    us_state         String,
    post_code        Int64,
    lat              Float64,
    lon              Float64,
    population_city  Int64,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           Int64
)
ENGINE = MergeTree
ORDER BY tuple();

-- Перекладывание данных из Kafka в таблицу хранения
CREATE MATERIALIZED VIEW IF NOT EXISTS transactions_raw_mv TO transactions_raw AS
SELECT * FROM transactions_kafka;

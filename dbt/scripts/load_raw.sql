-- Загрузка сырых транзакций в transactions_db.transactions из data/train.csv
-- (файл смонтирован в user_files ClickHouse, см. docker-compose.yml)
CREATE DATABASE IF NOT EXISTS transactions_db;

DROP TABLE IF EXISTS transactions_db.transactions;

CREATE TABLE transactions_db.transactions
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
    post_code        String,
    lat              Float64,
    lon              Float64,
    population_city  UInt32,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           UInt8
)
ENGINE = MergeTree
ORDER BY (us_state, transaction_time);

INSERT INTO transactions_db.transactions
SELECT *
FROM file('data/train.csv', 'CSVWithNames')
SETTINGS date_time_input_format = 'best_effort';

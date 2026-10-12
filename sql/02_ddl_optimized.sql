-- Оптимизированная таблица хранения.
--  * LowCardinality(String) для колонок с малым числом уникальных значений (словарное кодирование)
--  * компактные типы: Decimal для суммы, Float32 для координат, UInt вместо Int64
--  * ZSTD-сжатие для «тяжёлых» текстовых колонок, Delta+ZSTD для времени
--  * PARTITION BY по месяцу и ORDER BY (us_state, cat_id, transaction_time):
--    данные отсортированы по полям группировки -> лучше сжатие и чтение по первичному ключу
--  * проекция с готовым агрегатом по штатам: целевой запрос читает ~сотни строк вместо всей таблицы
CREATE TABLE IF NOT EXISTS transactions
(
    transaction_time DateTime CODEC(Delta, ZSTD(3)),
    merch            LowCardinality(String),
    cat_id           LowCardinality(String),
    amount           Decimal(12, 2) CODEC(ZSTD(3)),
    name_1           LowCardinality(String),
    name_2           LowCardinality(String),
    gender           LowCardinality(String),
    street           String CODEC(ZSTD(3)),
    one_city         LowCardinality(String),
    us_state         LowCardinality(String),
    post_code        UInt32 CODEC(ZSTD(3)),
    lat              Float32 CODEC(ZSTD(3)),
    lon              Float32 CODEC(ZSTD(3)),
    population_city  UInt32 CODEC(ZSTD(3)),
    jobs             LowCardinality(String),
    merchant_lat     Float32 CODEC(ZSTD(3)),
    merchant_lon     Float32 CODEC(ZSTD(3)),
    target           UInt8,

    PROJECTION max_amount_by_state
    (
        SELECT
            us_state,
            argMax(cat_id, amount),
            max(amount)
        GROUP BY us_state
    )
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(transaction_time)
ORDER BY (us_state, cat_id, transaction_time);

CREATE MATERIALIZED VIEW IF NOT EXISTS transactions_mv TO transactions AS
SELECT
    transaction_time,
    merch,
    cat_id,
    toDecimal64(toString(amount), 2) AS amount,
    name_1,
    name_2,
    gender,
    street,
    one_city,
    us_state,
    toUInt32(post_code) AS post_code,
    toFloat32(lat) AS lat,
    toFloat32(lon) AS lon,
    toUInt32(population_city) AS population_city,
    jobs,
    toFloat32(merchant_lat) AS merchant_lat,
    toFloat32(merchant_lon) AS merchant_lon,
    toUInt8(target) AS target
FROM transactions_kafka;

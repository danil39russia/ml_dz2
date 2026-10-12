"""Загрузка транзакций из CSV в топик Kafka (одно сообщение = одна строка в JSON)."""
import csv
import json
import logging
import os
import sys

from confluent_kafka import Producer
from confluent_kafka.admin import AdminClient, NewTopic

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("producer")

BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "transactions")
CSV_PATH = os.getenv("CSV_PATH", "data/train.csv")
PARTITIONS = int(os.getenv("KAFKA_PARTITIONS", "1"))

FLOAT_COLS = {"amount", "lat", "lon", "merchant_lat", "merchant_lon"}
INT_COLS = {"post_code", "population_city", "target"}


def ensure_topic(admin: AdminClient) -> None:
    if TOPIC in admin.list_topics(timeout=10).topics:
        return
    future = admin.create_topics([NewTopic(TOPIC, num_partitions=PARTITIONS, replication_factor=1)])[TOPIC]
    future.result()
    log.info("Топик %s создан", TOPIC)


def convert(row: dict) -> dict:
    for col in FLOAT_COLS:
        row[col] = float(row[col]) if row[col] else None
    for col in INT_COLS:
        row[col] = int(row[col]) if row[col] else None
    # "2019-12-27 15:21" -> "2019-12-27 15:21:00", чтобы ClickHouse разбирал DateTime без доп. настроек
    if len(row["transaction_time"]) == 16:
        row["transaction_time"] += ":00"
    return row


def on_delivery(err, msg):
    if err is not None:
        log.error("Ошибка доставки: %s", err)


def main() -> None:
    if not os.path.exists(CSV_PATH):
        log.error("Файл %s не найден", CSV_PATH)
        sys.exit(1)

    ensure_topic(AdminClient({"bootstrap.servers": BOOTSTRAP}))
    producer = Producer({
        "bootstrap.servers": BOOTSTRAP,
        "linger.ms": 50,
        "batch.size": 1_000_000,
        "compression.type": "lz4",
    })

    sent = 0
    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            payload = json.dumps(convert(row), ensure_ascii=False)
            while True:
                try:
                    producer.produce(TOPIC, value=payload.encode("utf-8"), on_delivery=on_delivery)
                    break
                except BufferError:
                    producer.poll(0.5)
            producer.poll(0)
            sent += 1
            if sent % 100_000 == 0:
                log.info("Отправлено %d сообщений", sent)

    producer.flush()
    log.info("Готово: %d сообщений отправлено в топик %s", sent, TOPIC)


if __name__ == "__main__":
    main()

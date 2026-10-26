# Запуск из каталога dbt/. ClickHouse поднимается из корня репозитория (docker compose).
export DBT_PROFILES_DIR := .
COMPOSE := docker compose -f ../docker-compose.yml

.PHONY: help install up load deps seed run test unit build docs docs-serve lint fix all clean

help:
	@echo "make install  - зависимости Python (dbt, sqlfluff, pre-commit)"
	@echo "make up       - поднять ClickHouse"
	@echo "make load     - загрузить data/train.csv в transactions_db.transactions"
	@echo "make all      - deps + seed + run + test"
	@echo "make build    - dbt build (модели + все тесты)"
	@echo "make docs     - сгенерировать и открыть dbt Docs (http://localhost:8080)"
	@echo "make lint     - sqlfluff lint"

install:
	pip install -r requirements.txt

up:
	$(COMPOSE) up -d clickhouse

load:
	$(COMPOSE) exec -T clickhouse clickhouse-client --multiquery < scripts/load_raw.sql
	$(COMPOSE) exec -T clickhouse clickhouse-client -q "SELECT count() FROM transactions_db.transactions"

deps:
	dbt deps

seed:
	dbt seed

run:
	dbt run

test:
	dbt test

unit:
	dbt test --select "test_type:unit"

build: deps
	dbt build

all: deps seed run test

docs:
	dbt docs generate
	dbt docs serve --port 8080

lint:
	sqlfluff lint models tests

fix:
	sqlfluff fix models tests

clean:
	dbt clean

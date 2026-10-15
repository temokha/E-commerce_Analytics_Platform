-- Промежуточная схема для загрузки и проверки исходных данных.
CREATE SCHEMA IF NOT EXISTS staging;

-- Общие поля таблиц:
-- payload    — одна исходная запись в формате JSONB.
-- source_key — путь к исходному файлу в Silo.
-- loaded_at  — время загрузки в PostgreSQL, заполняется автоматически.
-- IF NOT EXISTS пропускает создание существующего объекта,
-- но не обновляет его структуру.


-- Позиции заказов: одна строка — одна позиция заказа.
CREATE TABLE IF NOT EXISTS staging.order_items (
    payload jsonb NOT NULL,
    source_key text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Заказы: одна строка — один заказ.
CREATE TABLE IF NOT EXISTS staging.orders (
    payload jsonb NOT NULL,
    source_key text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Товары: одна строка — один товар каталога.
CREATE TABLE IF NOT EXISTS staging.products (
    payload jsonb NOT NULL,
    source_key text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Категории: одна строка — одна категория товаров.
CREATE TABLE IF NOT EXISTS staging.categories (
    payload jsonb NOT NULL,
    source_key text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Клиенты: одна строка — один клиент.
CREATE TABLE IF NOT EXISTS staging.customers (
    payload jsonb NOT NULL,
    source_key text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

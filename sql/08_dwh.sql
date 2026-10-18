-- Аналитическая схема.
CREATE SCHEMA IF NOT EXISTS dwh;

-- Справочник категорий: одна строка - одна категория.
CREATE TABLE IF NOT EXISTS dwh.dim_category (
    id integer PRIMARY KEY,
    name text NOT NULL,
    created_at timestamptz,
    updated_at timestamptz);

-- Справочник клиентов: одна строка - один клиент.
CREATE TABLE IF NOT EXISTS dwh.dim_customer (
    id integer PRIMARY KEY,
    name text NOT NULL,
    city text,
    region text,
    country text,
    tier text,
    created_at timestamptz,
    updated_at timestamptz);

-- Справочник товаров: одна строка - один товар.
CREATE TABLE IF NOT EXISTS dwh.dim_product (
    id integer PRIMARY KEY,
    sku text NOT NULL,
    name text NOT NULL,
    category_id integer NOT NULL REFERENCES dwh.dim_category(id),
    brand text,
    price numeric(14,2) NOT NULL CHECK (price >= 0),
    currency text NOT NULL,
    color text,
    in_stock boolean,
    rating numeric(3,2) CHECK (rating BETWEEN 0 AND 5),
    status text,
    created_at timestamptz,
    updated_at timestamptz);

-- Факты заказов: одна строка — один заказ.
CREATE TABLE IF NOT EXISTS dwh.fct_order (
    id integer PRIMARY KEY,
    number text,
    customer_id integer NOT NULL REFERENCES dwh.dim_customer(id),
    status text,
    subtotal numeric(14, 2) NOT NULL,
    shipping numeric(14, 2) NOT NULL,
    tax numeric(14, 2) NOT NULL,
    discount numeric(14, 2) NOT NULL,
    total numeric(14, 2) NOT NULL,
    currency text NOT NULL,
    payment_method text,
    shipping_method text,
    shipping_city text,
    shipping_region text,
    shipping_country text,
    placed_at timestamptz NOT NULL,
    paid_at timestamptz,
    shipped_at timestamptz,
    delivered_at timestamptz,
    created_at timestamptz,
    updated_at timestamptz);

-- Факты позиций заказов: одна строка — одна позиция заказа.
CREATE TABLE IF NOT EXISTS dwh.fct_order_item (
    id integer PRIMARY KEY,
    order_id integer NOT NULL REFERENCES dwh.fct_order(id),
    product_id integer NOT NULL REFERENCES dwh.dim_product(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(14, 2) NOT NULL CHECK (unit_price >= 0),
    line_total numeric(14, 2) NOT NULL CHECK (line_total >= 0),
    created_at timestamptz,
    updated_at timestamptz);
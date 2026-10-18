-- Загрузка категорий из staging в DWH.
INSERT INTO dwh.dim_category (
    id,
    name,
    created_at,
    updated_at)
SELECT
    (payload ->> 'id')::integer,
    payload ->> 'name',
    (payload ->> 'created_at')::timestamptz,
    (payload ->> 'updated_at')::timestamptz
FROM staging.categories
WHERE TRUE
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;

-- Загрузка клиентов из staging в DWH.
INSERT INTO dwh.dim_customer (
    id,
    name,
    city,
    region,
    country,
    tier,
    created_at,
    updated_at
)
SELECT
    (payload ->> 'id')::integer,
    payload ->> 'name',
    payload -> 'address' ->> 'city',
    payload -> 'address' ->> 'region',
    payload -> 'address' ->> 'country',
    payload ->> 'tier',
    (payload ->> 'created_at')::timestamptz,
    (payload ->> 'updated_at')::timestamptz
FROM staging.customers
WHERE TRUE
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    city = EXCLUDED.city,
    region = EXCLUDED.region,
    country = EXCLUDED.country,
    tier = EXCLUDED.tier,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;

-- Загрузка товаров из staging в DWH.
INSERT INTO dwh.dim_product (
    id,
    sku,
    name,
    category_id,
    brand,
    price,
    currency,
    color,
    in_stock,
    rating,
    status,
    created_at,
    updated_at
)
SELECT
    (payload ->> 'id')::integer,
    payload ->> 'sku',
    payload ->> 'name',
    (payload ->> 'category_id')::integer,
    payload ->> 'brand',
    (payload ->> 'price')::numeric(14, 2),
    payload ->> 'currency',
    payload ->> 'color',
    (payload ->> 'in_stock')::boolean,
    (payload ->> 'rating')::numeric(3, 2),
    payload ->> 'status',
    (payload ->> 'created_at')::timestamptz,
    (payload ->> 'updated_at')::timestamptz
FROM staging.products
WHERE TRUE
ON CONFLICT (id) DO UPDATE SET
    sku = EXCLUDED.sku,
    name = EXCLUDED.name,
    category_id = EXCLUDED.category_id,
    brand = EXCLUDED.brand,
    price = EXCLUDED.price,
    currency = EXCLUDED.currency,
    color = EXCLUDED.color,
    in_stock = EXCLUDED.in_stock,
    rating = EXCLUDED.rating,
    status = EXCLUDED.status,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;

-- Загрузка заказов из staging в DWH.
INSERT INTO dwh.fct_order (
    id,
    number,
    customer_id,
    status,
    subtotal,
    shipping,
    tax,
    discount,
    total,
    currency,
    payment_method,
    shipping_method,
    shipping_city,
    shipping_region,
    shipping_country,
    placed_at,
    paid_at,
    shipped_at,
    delivered_at,
    created_at,
    updated_at
)
SELECT
    (payload ->> 'id')::integer,
    payload ->> 'number',
    (payload ->> 'customer_id')::integer,
    payload ->> 'status',
    (payload ->> 'subtotal')::numeric(14, 2),
    (payload ->> 'shipping')::numeric(14, 2),
    (payload ->> 'tax')::numeric(14, 2),
    (payload ->> 'discount')::numeric(14, 2),
    (payload ->> 'total')::numeric(14, 2),
    payload ->> 'currency',
    payload ->> 'payment_method',
    payload ->> 'shipping_method',
    payload -> 'shipping_address' ->> 'city',
    payload -> 'shipping_address' ->> 'region',
    payload -> 'shipping_address' ->> 'country',
    (payload ->> 'placed_at')::timestamptz,
    (payload ->> 'paid_at')::timestamptz,
    (payload ->> 'shipped_at')::timestamptz,
    (payload ->> 'delivered_at')::timestamptz,
    (payload ->> 'created_at')::timestamptz,
    (payload ->> 'updated_at')::timestamptz
FROM staging.orders
WHERE TRUE
ON CONFLICT (id) DO UPDATE SET
    number = EXCLUDED.number,
    customer_id = EXCLUDED.customer_id,
    status = EXCLUDED.status,
    subtotal = EXCLUDED.subtotal,
    shipping = EXCLUDED.shipping,
    tax = EXCLUDED.tax,
    discount = EXCLUDED.discount,
    total = EXCLUDED.total,
    currency = EXCLUDED.currency,
    payment_method = EXCLUDED.payment_method,
    shipping_method = EXCLUDED.shipping_method,
    shipping_city = EXCLUDED.shipping_city,
    shipping_region = EXCLUDED.shipping_region,
    shipping_country = EXCLUDED.shipping_country,
    placed_at = EXCLUDED.placed_at,
    paid_at = EXCLUDED.paid_at,
    shipped_at = EXCLUDED.shipped_at,
    delivered_at = EXCLUDED.delivered_at,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;

-- Загрузка позиций заказов из staging в DWH.
INSERT INTO dwh.fct_order_item (
    id,
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total,
    created_at,
    updated_at
)
SELECT
    (payload ->> 'id')::integer,
    (payload ->> 'order_id')::integer,
    (payload ->> 'product_id')::integer,
    (payload ->> 'quantity')::integer,
    (payload ->> 'unit_price')::numeric(14, 2),
    (payload ->> 'line_total')::numeric(14, 2),
    (payload ->> 'created_at')::timestamptz,
    (payload ->> 'updated_at')::timestamptz
FROM staging.order_items
WHERE TRUE
ON CONFLICT (id) DO UPDATE SET
    order_id = EXCLUDED.order_id,
    product_id = EXCLUDED.product_id,
    quantity = EXCLUDED.quantity,
    unit_price = EXCLUDED.unit_price,
    line_total = EXCLUDED.line_total,
    created_at = EXCLUDED.created_at,
    updated_at = EXCLUDED.updated_at;
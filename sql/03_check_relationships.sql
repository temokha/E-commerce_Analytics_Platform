-- 1. Позиции, для которых не найден заказ.
SELECT COUNT(*) AS items_without_order
FROM staging.order_items AS i
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.orders AS o
    WHERE o.payload ->> 'id' = i.payload ->> 'order_id'
);


-- 2. Позиции, для которых не найден товар.
SELECT COUNT(*) AS items_without_product
FROM staging.order_items AS i
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.products AS p
    WHERE p.payload ->> 'id' = i.payload ->> 'product_id'
);


-- 3. Заказы, для которых не найден клиент.
SELECT COUNT(*) AS orders_without_customer
FROM staging.orders AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.customers AS c
    WHERE c.payload ->> 'id' = o.payload ->> 'customer_id'
);


-- 4. Товары, для которых не найдена категория.
SELECT COUNT(*) AS products_without_category
FROM staging.products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.categories AS c
    WHERE c.payload ->> 'id' = p.payload ->> 'category_id'
);
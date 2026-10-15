-- 1. Проверяем, что ID и ссылки являются целыми числами
-- и помещаются в PostgreSQL integer.
WITH identifiers AS (
    SELECT 'orders.id' AS field, payload ->> 'id' AS value
    FROM staging.orders

    UNION ALL
    SELECT 'orders.customer_id', payload ->> 'customer_id'
    FROM staging.orders

    UNION ALL
    SELECT 'order_items.id', payload ->> 'id'
    FROM staging.order_items

    UNION ALL
    SELECT 'order_items.order_id', payload ->> 'order_id'
    FROM staging.order_items

    UNION ALL
    SELECT 'order_items.product_id', payload ->> 'product_id'
    FROM staging.order_items

    UNION ALL
    SELECT 'products.id', payload ->> 'id'
    FROM staging.products

    UNION ALL
    SELECT 'products.category_id', payload ->> 'category_id'
    FROM staging.products

    UNION ALL
    SELECT 'categories.id', payload ->> 'id'
    FROM staging.categories

    UNION ALL
    SELECT 'customers.id', payload ->> 'id'
    FROM staging.customers
)
SELECT
    field,
    COUNT(*) AS invalid_values
FROM identifiers
WHERE CASE
    WHEN value IS NULL THEN TRUE
    WHEN value !~ '^-?[0-9]+$' THEN TRUE
    ELSE value::numeric NOT BETWEEN -2147483648 AND 2147483647
END
GROUP BY field
ORDER BY field;


-- 2. Проверяем имена клиентов и названия категорий.
SELECT
    'customers' AS entity,
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payload ->> 'name'), '') IS NULL
    ) AS missing_name
FROM staging.customers

UNION ALL

SELECT
    'categories',
    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payload ->> 'name'), '') IS NULL
    )
FROM staging.categories;
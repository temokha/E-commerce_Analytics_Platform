-- 1. Сравниваем количество строк в staging и DWH.
WITH row_counts AS (
    SELECT
        'categories' AS entity,
        (SELECT COUNT(*) FROM staging.categories) AS staging_rows,
        (SELECT COUNT(*) FROM dwh.dim_category) AS dwh_rows

    UNION ALL

    SELECT
        'customers',
        (SELECT COUNT(*) FROM staging.customers),
        (SELECT COUNT(*) FROM dwh.dim_customer)

    UNION ALL

    SELECT
        'products',
        (SELECT COUNT(*) FROM staging.products),
        (SELECT COUNT(*) FROM dwh.dim_product)

    UNION ALL

    SELECT
        'orders',
        (SELECT COUNT(*) FROM staging.orders),
        (SELECT COUNT(*) FROM dwh.fct_order)

    UNION ALL

    SELECT
        'order_items',
        (SELECT COUNT(*) FROM staging.order_items),
        (SELECT COUNT(*) FROM dwh.fct_order_item)
)
SELECT
    entity,
    staging_rows,
    dwh_rows,
    staging_rows = dwh_rows AS counts_match
FROM row_counts
ORDER BY entity;


-- 2. Проверяем суммы позиций после загрузки в DWH.
WITH item_totals AS (
    SELECT
        order_id,
        SUM(line_total) AS items_total
    FROM dwh.fct_order_item
    GROUP BY order_id
)
SELECT
    o.id AS order_id,
    o.subtotal,
    i.items_total
FROM dwh.fct_order AS o
LEFT JOIN item_totals AS i
    ON i.order_id = o.id
WHERE i.order_id IS NULL
   OR o.subtotal <> i.items_total;
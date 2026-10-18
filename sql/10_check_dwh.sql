-- Проверка количества строк во всех пяти таблицах.
WITH row_counts AS (
    SELECT
        'categories' AS entity,
        (SELECT COUNT(*) FROM staging.categories) AS source_count,
        (SELECT COUNT(*) FROM dwh.dim_category) AS target_count

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
),
item_totals AS (
    SELECT
        order_id,
        SUM(line_total) AS items_total
    FROM dwh.fct_order_item
    GROUP BY order_id
)
SELECT
    'row_count_' || entity AS check_name,
    ABS(source_count - target_count) AS error_count
FROM row_counts

UNION ALL

-- Проверка соответствия subtotal сумме позиций заказа.
SELECT
    'order_subtotal_matches_items',
    COUNT(*)
FROM dwh.fct_order AS o
LEFT JOIN item_totals AS i
    ON i.order_id = o.id
WHERE i.order_id IS NULL
   OR o.subtotal <> i.items_total;
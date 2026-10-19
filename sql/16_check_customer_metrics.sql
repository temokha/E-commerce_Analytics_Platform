-- 1. Проверяем, что каждый клиент представлен одной строкой.
SELECT
    (SELECT COUNT(*) FROM dwh.dim_customer) AS dwh_customers,
    COUNT(*) AS mart_rows,
    COUNT(DISTINCT customer_id) AS mart_unique_customers
FROM dm.customer_metrics;


-- 2. Сверяем количество заказов и сумму товаров для USD.
SELECT
    (
        SELECT COUNT(*)
        FROM dwh.fct_order
        WHERE currency = 'USD'
    ) AS dwh_orders,

    SUM(orders_count) AS mart_orders,

    (
        SELECT SUM(subtotal - discount)
        FROM dwh.fct_order
        WHERE currency = 'USD'
          AND status IN ('paid', 'shipped', 'delivered')
    ) AS dwh_merchandise_amount,

    SUM(merchandise_amount) AS mart_merchandise_amount

FROM dm.customer_metrics;
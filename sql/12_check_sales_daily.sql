-- 1. Сверяем общее количество заказов.
SELECT
    (SELECT COUNT(*) FROM dwh.fct_order) AS dwh_orders,
    (SELECT SUM(orders_count) FROM dm.sales_daily) AS mart_orders;


-- 2. Сверяем сумму товаров после скидки.
SELECT
    (
        SELECT SUM(subtotal - discount)
        FROM dwh.fct_order
        WHERE status IN ('paid', 'shipped', 'delivered')
    ) AS dwh_merchandise_amount,

    (
        SELECT SUM(merchandise_amount)
        FROM dm.sales_daily
    ) AS mart_merchandise_amount;
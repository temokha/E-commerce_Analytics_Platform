-- Клиентские показатели за весь доступный период.
CREATE OR REPLACE VIEW dm.customer_metrics AS
WITH customer_orders AS (
    SELECT
        customer_id,
        currency,

        COUNT(*) AS orders_count,

        COUNT(*) FILTER (
            WHERE status IN ('paid', 'shipped', 'delivered')
        ) AS active_paid_orders_count,

        SUM(subtotal - discount) FILTER (
            WHERE status IN ('paid', 'shipped', 'delivered')
        ) AS merchandise_amount,

        MIN(placed_at) FILTER (
            WHERE status IN ('paid', 'shipped', 'delivered')
        ) AS first_active_order_at,

        MAX(placed_at) FILTER (
            WHERE status IN ('paid', 'shipped', 'delivered')
        ) AS last_active_order_at

    FROM dwh.fct_order
    GROUP BY customer_id, currency
),
currencies AS (
    SELECT DISTINCT currency
    FROM dwh.fct_order
)
SELECT
    c.id AS customer_id,
    c.name AS customer_name,
    c.tier,
    c.city,
    c.region,
    c.country,
    cur.currency,

    COALESCE(co.orders_count, 0) AS orders_count,
    COALESCE(co.active_paid_orders_count, 0) AS active_paid_orders_count,
    COALESCE(co.merchandise_amount, 0) AS merchandise_amount,

    ROUND(
        co.merchandise_amount
        / NULLIF(co.active_paid_orders_count, 0),
        2
    ) AS avg_merchandise_amount,

    co.first_active_order_at,
    co.last_active_order_at,

    COALESCE(co.active_paid_orders_count, 0) >= 2 AS is_repeat_customer

FROM dwh.dim_customer AS c
CROSS JOIN currencies AS cur
LEFT JOIN customer_orders AS co
    ON co.customer_id = c.id
   AND co.currency = cur.currency;

SELECT *
FROM dm.customer_metrics
ORDER BY merchandise_amount DESC
LIMIT 10;

SELECT COUNT(*) AS rows_count
FROM dm.customer_metrics;
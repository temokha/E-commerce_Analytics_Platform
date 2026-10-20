CREATE SCHEMA IF NOT EXISTS dm;

-- Одна строка — день оформления в UTC.
-- Показатели рассчитываются по текущим статусам заказов.

CREATE OR REPLACE VIEW dm.sales_daily AS
WITH daily as (
	SELECT (placed_at AT TIME ZONE 'UTC')::date AS order_date,
	currency,
	COUNT(*) AS orders_count,
	COUNT(*) FILTER (
		WHERE status IN ('paid','shipped', 'delivered')
	) AS active_paid_orders_count,
	
	COALESCE(
		SUM(subtotal-discount) FILTER (
			WHERE status IN ('paid','shipped', 'delivered')
		),0
	) AS merchandise_amount,
	COUNT(*) FILTER (
            WHERE status = 'cancelled'
        ) AS cancelled_orders_count,
    COUNT(*) FILTER (
            WHERE status = 'refunded'
        ) AS refunded_orders_count
    FROM dwh.fct_order
    GROUP BY (placed_at AT TIME ZONE 'UTC')::date,
    currency
)
SELECT
    order_date,
    currency,
    orders_count,
    active_paid_orders_count,
    merchandise_amount,
    ROUND(merchandise_amount
        / NULLIF(active_paid_orders_count, 0),
        2
    ) AS avg_merchandise_amount,
    cancelled_orders_count,
    refunded_orders_count,
    cancelled_orders_count::numeric
        / NULLIF(orders_count, 0) AS cancellation_rate,
    refunded_orders_count::numeric
        / NULLIF(orders_count, 0) AS refund_rate
    FROM daily;
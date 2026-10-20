-- Продажи товаров по дням.
-- Сумма позиций не учитывает скидку, заданную на уровне заказа.
CREATE OR REPLACE VIEW dm.product_performance AS
WITH product_daily AS (
    SELECT
        (o.placed_at AT TIME ZONE 'UTC')::date AS order_date,
        o.currency,
        i.product_id,

        COUNT(DISTINCT i.order_id) AS orders_count,
        SUM(i.quantity) AS units_sold,
        SUM(i.line_total) AS gross_merchandise_amount

    FROM dwh.fct_order_item AS i
    JOIN dwh.fct_order AS o
        ON i.order_id = o.id

    WHERE o.status IN ('paid', 'shipped', 'delivered')

    GROUP BY
        (o.placed_at AT TIME ZONE 'UTC')::date,
        o.currency,
        i.product_id
)
SELECT
    pd.order_date,
    pd.currency,
    pd.product_id,
    p.sku,
    p.name AS product_name,
    p.brand,
    p.category_id,
    c.name AS category_name,
    pd.orders_count,
    pd.units_sold,
    pd.gross_merchandise_amount

FROM product_daily AS pd
JOIN dwh.dim_product AS p
    ON pd.product_id = p.id
JOIN dwh.dim_category AS c
    ON p.category_id = c.id;
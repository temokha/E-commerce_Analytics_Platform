-- Сравниваем количество единиц и сумму позиций в DWH и витрине.
WITH source_totals AS (
    SELECT
        o.currency,
        SUM(i.quantity) AS units_sold,
        SUM(i.line_total) AS gross_amount
    FROM dwh.fct_order_item AS i
    JOIN dwh.fct_order AS o
        ON i.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.currency
),
mart_totals AS (
    SELECT
        currency,
        SUM(units_sold) AS units_sold,
        SUM(gross_merchandise_amount) AS gross_amount
    FROM dm.product_performance
    GROUP BY currency
)
SELECT
    COALESCE(s.currency, m.currency) AS currency,
    s.units_sold AS dwh_units,
    m.units_sold AS mart_units,
    s.gross_amount AS dwh_amount,
    m.gross_amount AS mart_amount
FROM source_totals AS s
FULL JOIN mart_totals AS m
    ON s.currency = m.currency;
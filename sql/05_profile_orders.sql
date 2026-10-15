-- 1. Проверяем заполненность обязательной даты оформления.
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE payload ->> 'placed_at' IS NULL
    ) AS missing_placed_at
FROM staging.orders;


-- 2. Проверяем пропуски в денежных полях.
SELECT
    COUNT(*) FILTER (
        WHERE payload ->> 'subtotal' IS NULL
    ) AS missing_subtotal,

    COUNT(*) FILTER (
        WHERE payload ->> 'shipping' IS NULL
    ) AS missing_shipping,

    COUNT(*) FILTER (
        WHERE payload ->> 'tax' IS NULL
    ) AS missing_tax,

    COUNT(*) FILTER (
        WHERE payload ->> 'discount' IS NULL
    ) AS missing_discount,

    COUNT(*) FILTER (
        WHERE payload ->> 'total' IS NULL
    ) AS missing_total
FROM staging.orders;


-- 3. Проверяем формулу итоговой суммы.
-- Округляем расчёт до двух знаков для сравнения денежных сумм.
SELECT COUNT(*) AS total_mismatch
FROM staging.orders
WHERE (payload ->> 'total')::numeric
      <> ROUND(
          (payload ->> 'subtotal')::numeric
          + (payload ->> 'shipping')::numeric
          + (payload ->> 'tax')::numeric
          - (payload ->> 'discount')::numeric,
          2
      );


-- 4. Смотрим, какие валюты присутствуют, включая пропуски.
SELECT
    payload ->> 'currency' AS currency,
    COUNT(*) AS orders_count
FROM staging.orders
GROUP BY payload ->> 'currency'
ORDER BY currency;

-- 5. Сверяем subtotal заказа с суммой его товарных позиций.
WITH item_totals AS (
    SELECT
        payload ->> 'order_id' AS order_id,
        SUM((payload ->> 'line_total')::numeric) AS items_total
    FROM staging.order_items
    GROUP BY payload ->> 'order_id'
)
SELECT
    o.payload ->> 'id' AS order_id,
    (o.payload ->> 'subtotal')::numeric AS subtotal,
    i.items_total
FROM staging.orders AS o
LEFT JOIN item_totals AS i
    ON i.order_id = o.payload ->> 'id'
WHERE i.order_id IS NULL
   OR (o.payload ->> 'subtotal')::numeric <> i.items_total;

-- 6. Смотрим заполненность дат событий по статусам заказов.
SELECT
    payload ->> 'status' AS status,
    COUNT(*) AS orders_count,

    COUNT(*) FILTER (
        WHERE payload ->> 'paid_at' IS NOT NULL
    ) AS with_payment_date,

    COUNT(*) FILTER (
        WHERE payload ->> 'shipped_at' IS NOT NULL
    ) AS with_shipping_date,

    COUNT(*) FILTER (
        WHERE payload ->> 'delivered_at' IS NOT NULL
    ) AS with_delivery_date

FROM staging.orders
GROUP BY payload ->> 'status'
ORDER BY status;

-- 7. Проверяем хронологию событий.
-- NULL-даты не считаются нарушением: событие могло ещё не произойти.
SELECT
    COUNT(*) FILTER (
        WHERE (payload ->> 'paid_at')::timestamptz
              < (payload ->> 'placed_at')::timestamptz
    ) AS payment_before_order,

    COUNT(*) FILTER (
        WHERE (payload ->> 'shipped_at')::timestamptz
              < (payload ->> 'paid_at')::timestamptz
    ) AS shipping_before_payment,

    COUNT(*) FILTER (
        WHERE (payload ->> 'delivered_at')::timestamptz
              < (payload ->> 'shipped_at')::timestamptz
    ) AS delivery_before_shipping

FROM staging.orders;
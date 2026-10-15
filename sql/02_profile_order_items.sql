-- 1. Количество: проверяем пропуски, нули, отрицательные и дробные значения.
SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE payload ->> 'quantity' IS NULL
    ) AS missing_quantity,

    COUNT(*) FILTER (
        WHERE (payload ->> 'quantity')::numeric = 0
    ) AS zero_quantity,

    COUNT(*) FILTER (
        WHERE (payload ->> 'quantity')::numeric < 0
    ) AS negative_quantity,

    COUNT(*) FILTER (
        WHERE (payload ->> 'quantity')::numeric
              <> TRUNC((payload ->> 'quantity')::numeric)
    ) AS fractional_quantity

FROM staging.order_items;


-- 2. ID позиций: проверяем заполненность и уникальность.
-- duplicate_id_rows — количество повторных строк сверх первого вхождения ID.
SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE payload ->> 'id' IS NULL
    ) AS missing_id,

    COUNT(DISTINCT payload ->> 'id') AS unique_ids,

    COUNT(payload ->> 'id')
        - COUNT(DISTINCT payload ->> 'id') AS duplicate_id_rows

FROM staging.order_items;


-- 3. Ссылки: проверяем заполненность order_id и product_id.
-- Существование соответствующих заказов и товаров здесь не проверяется.
SELECT
    COUNT(*) FILTER (
        WHERE payload ->> 'order_id' IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE payload ->> 'product_id' IS NULL
    ) AS missing_product_id

FROM staging.order_items;


-- 4. Деньги: проверяем пропуски, отрицательные значения
-- и соответствие формуле line_total = quantity * unit_price.
SELECT
    COUNT(*) FILTER (
        WHERE payload ->> 'unit_price' IS NULL
    ) AS missing_unit_price,

    COUNT(*) FILTER (
        WHERE payload ->> 'line_total' IS NULL
    ) AS missing_line_total,

    COUNT(*) FILTER (
        WHERE (payload ->> 'unit_price')::numeric < 0
    ) AS negative_unit_price,

    COUNT(*) FILTER (
        WHERE (payload ->> 'line_total')::numeric < 0
    ) AS negative_line_total,

    COUNT(*) FILTER (
        WHERE (payload ->> 'line_total')::numeric
              <> (payload ->> 'quantity')::numeric
                 * (payload ->> 'unit_price')::numeric
    ) AS amount_mismatch

FROM staging.order_items;


-- 5. Точность: проверяем, изменятся ли денежные значения
-- при округлении до двух знаков после запятой.
SELECT
    COUNT(*) FILTER (
        WHERE (payload ->> 'unit_price')::numeric
              <> ROUND((payload ->> 'unit_price')::numeric, 2)
    ) AS unit_price_over_two_decimals,

    COUNT(*) FILTER (
        WHERE (payload ->> 'line_total')::numeric
              <> ROUND((payload ->> 'line_total')::numeric, 2)
    ) AS line_total_over_two_decimals

FROM staging.order_items;
-- 1. Проверяем заполненность основных полей товара.
SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payload ->> 'sku'), '') IS NULL
    ) AS missing_sku,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payload ->> 'name'), '') IS NULL
    ) AS missing_name,

    COUNT(*) FILTER (
        WHERE payload ->> 'price' IS NULL
    ) AS missing_price,

    COUNT(*) FILTER (
        WHERE NULLIF(BTRIM(payload ->> 'currency'), '') IS NULL
    ) AS missing_currency

FROM staging.products;


-- 2. Проверяем цену и диапазон рейтинга.
SELECT
    COUNT(*) FILTER (
        WHERE (payload ->> 'price')::numeric < 0
    ) AS negative_price,

    COUNT(*) FILTER (
        WHERE (payload ->> 'price')::numeric
              <> ROUND((payload ->> 'price')::numeric, 2)
    ) AS price_over_two_decimals,

    COUNT(*) FILTER (
        WHERE (payload ->> 'rating')::numeric < 0
           OR (payload ->> 'rating')::numeric > 5
    ) AS rating_outside_range

FROM staging.products;


-- 3. Смотрим валюты цен в каталоге.
SELECT
    payload ->> 'currency' AS currency,
    COUNT(*) AS products_count
FROM staging.products
GROUP BY payload ->> 'currency'
ORDER BY currency;
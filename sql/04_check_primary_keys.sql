-- Собираем ID четырёх сущностей для общей проверки.
WITH source_ids AS (
    SELECT 'orders' AS entity, payload ->> 'id' AS id
    FROM staging.orders

    UNION ALL

    SELECT 'products', payload ->> 'id'
    FROM staging.products

    UNION ALL

    SELECT 'categories', payload ->> 'id'
    FROM staging.categories

    UNION ALL

    SELECT 'customers', payload ->> 'id'
    FROM staging.customers
)

-- Проверяем ID отдельно для каждой сущности.
SELECT
    entity,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE id IS NULL) AS missing_id,
    COUNT(DISTINCT id) AS unique_ids,
    COUNT(id) - COUNT(DISTINCT id) AS duplicate_id_rows
FROM source_ids
GROUP BY entity
ORDER BY entity;
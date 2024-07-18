WITH products_series AS (
    SELECT
        DISTINCT ON (store_id, product_id)
        store_id,
        product_id,
        product_name,
        product_properties,
        status
    FROM {{ ref('int_store_current_status') }}
)
SELECT *
FROM products_series
ORDER BY 1 ASC
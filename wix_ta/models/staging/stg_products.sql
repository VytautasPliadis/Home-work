WITH raw_data AS (
SELECT
    store_id,
    (product::json)->>'Id' AS product_id,
    (product::json)->>'name' AS product_name,
    (product::json)->'properties'->>'size' AS size,
    (product::json)->'properties'->>'color' AS color,
    change_type,
    event_date
FROM
    {{ ref('stg_store_events') }}
)
SELECT *
FROM raw_data
WHERE product_name IS NOT NULL
AND product_id IS NOT NULL

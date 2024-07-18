-- Extract and normalize raw events data
WITH raw_events AS (
    SELECT
        timestamp,
        user_id,
        store_id,
        (digest::json)->>'Date' AS event_date,
        (digest::json)->'payload'->>'change' AS change_type,
        (digest::json)->'payload'->'products' AS products
    FROM
        {{ source('raw_data_source', 'raw_data') }}
)

-- Normalize products into individual rows
SELECT
    timestamp,
    user_id,
    store_id,
    event_date,
    change_type,
    jsonb_array_elements_text(
        CASE
            WHEN json_typeof(products::json) = 'array' THEN products::jsonb
            ELSE jsonb_build_array(products::jsonb)
        END
    ) AS product
FROM
    raw_events



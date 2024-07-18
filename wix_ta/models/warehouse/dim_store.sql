WITH raw_data AS (
    SELECT
        DISTINCT store_id
    FROM {{ ref('stg_store_events') }}
)
SELECT *
FROM raw_data
ORDER BY 1
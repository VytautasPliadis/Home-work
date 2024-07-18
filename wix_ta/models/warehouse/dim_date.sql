WITH date_series AS (
    SELECT
        DISTINCT
        event_date AS date_id,
        EXTRACT(YEAR FROM CAST(event_date AS DATE)) AS year,
        EXTRACT(MONTH FROM CAST(event_date AS DATE)) AS month,
        EXTRACT(DAY FROM CAST(event_date AS DATE)) AS day,
        EXTRACT(QUARTER FROM CAST(event_date AS DATE)) AS quarter
    FROM {{ ref('stg_store_events') }}
)
SELECT *
FROM date_series
ORDER BY 1 ASC
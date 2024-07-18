WITH ranked_changes AS (
    SELECT
        store_id,
        product_id,
        product_name,
        size,
        color,
        change_type,
        event_date,
        LAG(size) OVER (PARTITION BY store_id, product_id ORDER BY event_date) AS previous_size,
        LAG(color) OVER (PARTITION BY store_id, product_id ORDER BY event_date) AS previous_color
    FROM
        {{ ref('stg_products') }}
),
parameter_changes AS (
    SELECT
        store_id,
        product_id,
        product_name,
        event_date,
        size,
        previous_size,
        CASE
            WHEN size != previous_size THEN size
            ELSE NULL
        END AS size_change,
        color,
        previous_color,
        CASE
            WHEN color != previous_color THEN color
            ELSE NULL
        END AS color_change
    FROM
        ranked_changes
)

SELECT *
FROM parameter_changes
WHERE size_change IS NOT NULL OR color_change IS NOT NULL
SELECT
    product_id,
    product_name,
    DATE_TRUNC('month', event_date::timestamp) AS month,
    COUNT(DISTINCT size_change) AS size_changes_count,
    COUNT(DISTINCT color_change) AS color_changes_count
FROM
    {{ ref('int_product_parameter_changes') }}
GROUP BY
    product_id,
    product_name,
    month
ORDER BY
    product_id,
    month

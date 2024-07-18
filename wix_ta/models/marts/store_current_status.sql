SELECT
    store_id,
    product_name,
    COUNT(product_id) AS quantity
FROM
    {{ ref('int_store_current_status') }}
WHERE
    status = 'active'
GROUP BY
    store_id, product_name
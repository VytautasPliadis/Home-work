{% macro generate_store_status(execution_date_condition) %}
    -- CTE to define the changes
    WITH changes AS (
        SELECT
            store_id,
            (product::json)->>'Id' AS product_id,
            (product::json)->>'name' AS product_name,
            (product::json)->'properties' AS product_properties,
            change_type,
            event_date
        FROM
            {{ ref('stg_store_events') }}
        WHERE
            {{ execution_date_condition }}
    ),

    -- Capture added, updated, and removed products
    product_changes AS (
        SELECT
            store_id,
            product_id,
            product_name,
            product_properties,
            event_date,
            change_type,
            ROW_NUMBER() OVER (PARTITION BY store_id, product_id ORDER BY event_date DESC) AS update_rank
        FROM
            changes
        WHERE
            change_type IN ('add', 'update', 'remove')
    ),

    -- Capture latest updates and additions
    latest_product_changes AS (
        SELECT
            store_id,
            product_id,
            MAX(CASE WHEN change_type = 'add' THEN event_date ELSE NULL END) AS added_at,
            MAX(CASE WHEN change_type = 'update' AND update_rank = 1 THEN event_date ELSE NULL END) AS latest_update_at,
            MAX(CASE WHEN change_type = 'remove' THEN event_date ELSE NULL END) AS removed_at
        FROM
            product_changes
        GROUP BY
            store_id,
            product_id
    )

    -- Final query to compile the product status and properties
    SELECT
        lpc.store_id,
        lpc.product_id,
        lpc.added_at,
        lpc.latest_update_at,
        lpc.removed_at,
        pc.product_name,
        COALESCE(
            (SELECT product_properties FROM product_changes WHERE store_id = lpc.store_id AND product_id = lpc.product_id AND change_type = 'update' AND update_rank = 1),
            pc.product_properties
        ) AS product_properties,
        CASE
            WHEN lpc.removed_at IS NULL THEN 'active'
            WHEN lpc.added_at > lpc.removed_at THEN 'active'
            ELSE 'removed'
        END AS status
    FROM
        latest_product_changes AS lpc
    JOIN
        product_changes AS pc
    ON
        lpc.store_id = pc.store_id
        AND lpc.product_id = pc.product_id
        AND pc.change_type = 'add'
    ORDER BY
        lpc.store_id, status ASC
{% endmacro %}
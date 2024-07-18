WITH raw_data AS (
    SELECT
        timestamp,
        user_id,
        store_id,
        event_date AS date_id,
        change_type AS store_action,
        (product::json)->>'Id' AS product_id,
        {{ dbt_utils.generate_surrogate_key(['timestamp']) }} as pk_fct_user_store_actions
    FROM {{ ref('stg_store_events') }}
)
SELECT
    pk_fct_user_store_actions,
    timestamp,
    date_id,
    user_id,
    store_id,
    store_action,
    product_id
FROM raw_data
ORDER BY 2 ASC

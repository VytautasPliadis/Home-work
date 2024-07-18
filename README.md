![lineage_graph.png](img%2Flineage_graph.png)

## Project Structure  

```
├── img
│   ├── erd.png
│   └── lineage_graph.png
├── sql
│   ├── relationships.sql
│   └── seed_db.sql
├── wix_ta
│   ├── macros
│   │   └── store_status.sql
│   ├── models
│   │   ├── intermediate
│   │   │   ├── int_product_parameter_changes.sql
│   │   │   ├── int_store_current_status.sql
│   │   │   └── int_store_point_in_time_status.sql
│   │   ├── marts
│   │   │   ├── product_parameter_trends.sql
│   │   │   ├── store_current_status.sql
│   │   │   └── store_status_at_point_in_time.sql
│   │   ├── staging
│   │   │   ├── sources.yml
│   │   │   ├── stg_products.sql
│   │   │   └── stg_store_events.sql
│   │   └── warehouse
│   │       ├── dim_date.sql
│   │       ├── dim_product.sql
│   │       ├── dim_store.sql
│   │       ├── dim_user.sql
│   │       ├── fct_user_store_actions.sql
│   │       └── schema.yml
│   ├── dbt_project.yml
│   └── packages.yml
├── .gitignore
├── pyproject.toml
└── README.md
```

## Data Assumptions  

- The data is **extracted** and **loaded** into the database table (this part is outside the scope of this project).
- Each change to a store's state is stored in the database as a JSON object in the `digest` column of the `raw_data` table.
- The `product_id` may not be unique (multiple stores could use same product id), so a composite primary key must be used in the product dimension table.
- The `timestamp` in the data model may not be unique due to multiple products being added in one JSON file, so a surrogate key must be implemented in the fact table.
- There are only `add`, `remove`, and `create` actions in the sample data. `update` action is added to increase project complexity.

## Processes and Tables for Flexible Reporting Infrastructure  

To create a flexible infrastructure for generating fast reports, we need to define several processes and tables. 
  
### 1. Transform  
  
- **Staging Tables**: Intermediate tables that hold raw but normalized data.  
    - **`stg_store_events`**: Normalize raw events data.  
      - Parse fields from JSON, splitting a single JSON object into multiple rows based on individual product information.  
    - **`stg_products`**: Filter events from `stg_store_events` witch are related only to products.  
  
- **Intermediate Tables**: Aggregated and calculated data.  
    - **`int_store_current_status`**: Current status of stores.  
      - Aggregate active product quantities per store.  
    - **`int_store_point_in_time_status`**: Status of stores at specific points in time.  
      - Aggregate product quantities at specific timestamps.  
    - **`int_product_parameter_changes`**: Track parameter changes over time.  
      - Identify and log changes in product attributes.
      
- **Warehouse Tables**: Fact and dimension tables for analytics.  
    - **`dim_date`**: Date dimension table.  
      - Store calendar dates with attributes (year, month, day, quarter).  
    - **`dim_product`**: Product dimension table.  
      - Store product details and attributes.  
    - **`dim_store`**: Store dimension table.  
      - Store details.  
    - **`dim_user`**: User dimension table.  
      - User details.  
    - **`fct_user_store_actions`**: Fact table for user actions.  
      - Log user actions in stores with associated timestamps.  

### 2. Reporting and Analysis  
  
- **Mart Tables**: Aggregated data for specific reporting needs.  
    - **`store_current_status`**: Generate current status reports.  
    - **`store_status_at_point_in_time`**: Generate historical status reports.  
    - **`product_parameter_trends`**: Analyze parameter changes over time.  
  
## Processes Sensitive to Scale and Production Changes  
  
- **Data Volume**: As data grows, indexing and partitioning strategies should be implemented to optimize query performance.  
- **Schema Changes**: Maintain version control for schema changes.  
- **Data Quality**: Implement data validation and testing to ensure data integrity.  

### Organizational Advancement

- **Collaboration**: Foster collaboration between data engineers, analysts, and PMs.
    - Regular meetings to discuss data needs and issues.
    - Shared documentation and knowledge base.
- **Documentation**: Maintain comprehensive documentation for the project.
    - Detailed descriptions of processes and tables.

## Stakeholders and Process  

- **Product Managers (PMs)**: Require reports for decision-making.  
    - **Involvement**: Define report requirements and priorities.  
    - **Process**: Collaborate with data analysts to specify report details.  
- **Data Engineers**: Maintain the dbt project and ensure data integrity.  
    - **Involvement**: Develop and maintain ETL processes.  
    - **Process**: Implement changes based on feedback and performance metrics.  
- **Data Analysts**: Generate insights and reports from the data.  
    - **Involvement**: Analyze data and create reports.  
    - **Process**: Collaborate with PMs to understand report requirements.  
- **Business Stakeholders**: Utilize the reports for strategic decisions.  
    - **Involvement**: Provide feedback on report usefulness.  
    - **Process**: Communicate data needs and impact of reports.

## Apendix

### Wahrehouse Star Schema

![erd.png](img%2Ferd.png)

### Macro
The `generate_store_status` macro processes events to determine the current status of products in stores. It goes through the following steps:

1. Extracts relevant product change events from the `stg_store_events` table.
2. Ranks changes to identify the most recent updates.
3. Determines the latest add, update, and remove timestamps for each product.
4. Compiles the final product status, resolving properties based on the latest changes.
5. Outputs a report showing each product's current status and details.

```sql
-- macro/store_status.sql

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
```
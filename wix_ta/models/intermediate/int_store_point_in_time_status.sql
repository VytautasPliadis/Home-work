{% set execution_date_string = "'" ~ execution_date ~ "'" %}
{% set execution_date_condition = "event_date <= " ~ execution_date_string %}

{{ generate_store_status(execution_date_condition) }}
-- dim_date table
ALTER TABLE dim_date
ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_id);

-- dim_product table
ALTER TABLE dim_product
ADD CONSTRAINT pk_dim_product PRIMARY KEY (store_id, product_id);

-- dim_store table
ALTER TABLE dim_store
ADD CONSTRAINT pk_dim_store PRIMARY KEY (store_id);

-- dim_user table
ALTER TABLE dim_user
ADD CONSTRAINT pk_dim_user PRIMARY KEY (user_id);

-- fct_user_store_actions table
ALTER TABLE fct_user_store_actions
ADD CONSTRAINT pk_fct_user_store_actions PRIMARY KEY (pk_fct_user_store_actions),
ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES dim_user (user_id),
ADD CONSTRAINT fk_store_id FOREIGN KEY (store_id) REFERENCES dim_store (store_id),
ADD CONSTRAINT fk_product_id FOREIGN KEY (store_id, product_id) REFERENCES dim_product (store_id, product_id),
ADD CONSTRAINT fk_date_id FOREIGN KEY (date_id) REFERENCES dim_date (date_id);
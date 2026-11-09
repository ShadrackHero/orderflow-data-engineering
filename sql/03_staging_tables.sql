
-- OrderFlow | Day 3
-- Staging Layer: Table Definitions

CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5),
    customer_city TEXT,
    customer_state CHAR(2)
);


-- ==========================================
-- STAGING: ORDERS
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    CONSTRAINT fk_staging_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES staging.customers(customer_id)
);


-- ==========================================
-- STAGING: ORDER ITEMS
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),

    CONSTRAINT pk_staging_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_staging_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES staging.orders(order_id),

    CONSTRAINT chk_staging_order_items_price
        CHECK (price >= 0),

    CONSTRAINT chk_staging_order_items_freight
        CHECK (freight_value >= 0)
);


-- ==========================================
-- STAGING: PRODUCTS
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(12,2),
    product_length_cm NUMERIC(12,2),
    product_height_cm NUMERIC(12,2),
    product_width_cm NUMERIC(12,2)
);

-- ==========================================
-- STAGING: SELLERS
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city TEXT,
    seller_state CHAR(2)
);


-- ==========================================
-- STAGING: ORDER PAYMENTS
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),

    CONSTRAINT pk_staging_order_payments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_staging_payments_order
        FOREIGN KEY (order_id)
        REFERENCES staging.orders(order_id),

    CONSTRAINT chk_payment_value
        CHECK (payment_value >= 0),

    CONSTRAINT chk_payment_installments
        CHECK (payment_installments >= 0)
);

-- ==========================================
-- STAGING: ORDER REVIEWS
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.order_reviews (
    review_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    review_id VARCHAR(32),
    order_id VARCHAR(32) NOT NULL,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    CONSTRAINT fk_staging_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES staging.orders(order_id),

    CONSTRAINT chk_review_score
        CHECK (review_score BETWEEN 1 AND 5)
);


-- ==========================================
-- STAGING: GEOLOCATION
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.geolocation (
    geolocation_row_id BIGINT
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat NUMERIC(10,7),
    geolocation_lng NUMERIC(10,7),
    geolocation_city TEXT,
    geolocation_state CHAR(2)
);

-- ==========================================
-- STAGING: PRODUCT CATEGORY TRANSLATION
-- ==========================================

CREATE TABLE IF NOT EXISTS staging.product_category_name_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

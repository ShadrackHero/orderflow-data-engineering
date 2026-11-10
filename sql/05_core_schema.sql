
-- ==========================================
-- ORDERFLOW | DAY 4
-- 05_core_schema.sql
-- CORE DATA WAREHOUSE
-- ==========================================

CREATE SCHEMA IF NOT EXISTS core;

-- ==========================================
-- DIMENSION: CUSTOMERS
-- ==========================================

CREATE TABLE IF NOT EXISTS core.dim_customers (
    customer_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL UNIQUE,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- ==========================================
-- DIMENSION: PRODUCTS
-- ==========================================

CREATE TABLE IF NOT EXISTS core.dim_products (
    product_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL UNIQUE,
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- ==========================================
-- DIMENSION: SELLERS
-- ==========================================

CREATE TABLE IF NOT EXISTS core.dim_sellers (
    seller_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id VARCHAR(50) NOT NULL UNIQUE,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- ==========================================
-- DIMENSION: DATE
-- ==========================================

CREATE TABLE IF NOT EXISTS core.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20),
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20),
    is_weekend BOOLEAN NOT NULL
);

-- ==========================================
-- FACT: ORDERS
-- ==========================================

CREATE TABLE IF NOT EXISTS core.fact_orders (
    order_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL UNIQUE,
    customer_key BIGINT REFERENCES core.dim_customers(customer_key),
    purchase_date_key INTEGER REFERENCES core.dim_date(date_key),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    delivery_days INTEGER,
    delivery_delay_days INTEGER
);

-- ==========================================
-- FACT: ORDER ITEMS
-- ==========================================

CREATE TABLE IF NOT EXISTS core.fact_order_items (
    order_item_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_key BIGINT NOT NULL REFERENCES core.fact_orders(order_key),
    order_item_id INTEGER NOT NULL,
    product_key BIGINT REFERENCES core.dim_products(product_key),
    seller_key BIGINT REFERENCES core.dim_sellers(seller_key),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2),
    freight_value NUMERIC(12,2),
    CONSTRAINT uq_fact_order_items
        UNIQUE (order_key, order_item_id)
);

-- ==========================================
-- FACT: ORDER PAYMENTS
-- ==========================================

CREATE TABLE IF NOT EXISTS core.fact_order_payments (
    payment_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_key BIGINT NOT NULL REFERENCES core.fact_orders(order_key),
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(12,2),
    CONSTRAINT uq_fact_order_payments
        UNIQUE (order_key, payment_sequential)
);

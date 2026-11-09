
-- =====================================================
-- ORDERFLOW DATA ENGINEERING
-- DAY 3: RAW TO STAGING TRANSFORMATIONS
-- =====================================================
-- Strategy: Full refresh
-- All tables are truncated together to respect FKs.
-- Execute within one transaction from run_staging.py.
-- =====================================================


-- =====================================================
-- 1. TRUNCATE ALL STAGING TABLES
-- =====================================================

TRUNCATE TABLE
    staging.order_items,
    staging.order_payments,
    staging.order_reviews,
    staging.orders,
    staging.customers,
    staging.products,
    staging.sellers,
    staging.geolocation,
    staging.product_category_name_translation
RESTART IDENTITY;


-- =====================================================
-- 2. CUSTOMERS
-- =====================================================

INSERT INTO staging.customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    NULLIF(TRIM(customer_id), ''),
    NULLIF(TRIM(customer_unique_id), ''),
    LPAD(
        NULLIF(TRIM(customer_zip_code_prefix), ''),
        5, '0'
    ),
    LOWER(NULLIF(TRIM(customer_city), '')),
    UPPER(NULLIF(TRIM(customer_state), ''))
FROM raw.customers;


-- =====================================================
-- 3. ORDERS
-- =====================================================

INSERT INTO staging.orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(customer_id), ''),
    LOWER(NULLIF(TRIM(order_status), '')),
    NULLIF(TRIM(order_purchase_timestamp), '')::TIMESTAMP,
    NULLIF(TRIM(order_approved_at), '')::TIMESTAMP,
    NULLIF(TRIM(order_delivered_carrier_date), '')::TIMESTAMP,
    NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP,
    NULLIF(TRIM(order_estimated_delivery_date), '')::TIMESTAMP
FROM raw.orders;


-- =====================================================
-- 4. PRODUCTS
-- =====================================================

INSERT INTO staging.products (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    NULLIF(TRIM(product_id), ''),
    LOWER(NULLIF(TRIM(product_category_name), '')),
    NULLIF(TRIM(product_name_lenght), '')::INTEGER,
    NULLIF(TRIM(product_description_lenght), '')::INTEGER,
    NULLIF(TRIM(product_photos_qty), '')::INTEGER,
    NULLIF(TRIM(product_weight_g), '')::NUMERIC(12,2),
    NULLIF(TRIM(product_length_cm), '')::NUMERIC(12,2),
    NULLIF(TRIM(product_height_cm), '')::NUMERIC(12,2),
    NULLIF(TRIM(product_width_cm), '')::NUMERIC(12,2)
FROM raw.products;


-- =====================================================
-- 5. SELLERS
-- =====================================================

INSERT INTO staging.sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    NULLIF(TRIM(seller_id), ''),
    LPAD(
        NULLIF(TRIM(seller_zip_code_prefix), ''),
        5, '0'
    ),
    LOWER(NULLIF(TRIM(seller_city), '')),
    UPPER(NULLIF(TRIM(seller_state), ''))
FROM raw.sellers;


-- =====================================================
-- 6. ORDER ITEMS
-- =====================================================

INSERT INTO staging.order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(order_item_id), '')::INTEGER,
    NULLIF(TRIM(product_id), ''),
    NULLIF(TRIM(seller_id), ''),
    NULLIF(TRIM(shipping_limit_date), '')::TIMESTAMP,
    NULLIF(TRIM(price), '')::NUMERIC(12,2),
    NULLIF(TRIM(freight_value), '')::NUMERIC(12,2)
FROM raw.order_items;


-- =====================================================
-- 7. ORDER PAYMENTS
-- =====================================================

INSERT INTO staging.order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(payment_sequential), '')::INTEGER,
    LOWER(NULLIF(TRIM(payment_type), '')),
    NULLIF(TRIM(payment_installments), '')::INTEGER,
    NULLIF(TRIM(payment_value), '')::NUMERIC(12,2)
FROM raw.order_payments;


-- =====================================================
-- 8. ORDER REVIEWS
-- =====================================================

INSERT INTO staging.order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    NULLIF(TRIM(review_id), ''),
    NULLIF(TRIM(order_id), ''),
    NULLIF(TRIM(review_score), '')::INTEGER,
    NULLIF(TRIM(review_comment_title), ''),
    NULLIF(TRIM(review_comment_message), ''),
    NULLIF(TRIM(review_creation_date), '')::TIMESTAMP,
    NULLIF(TRIM(review_answer_timestamp), '')::TIMESTAMP
FROM raw.order_reviews;


-- =====================================================
-- 9. GEOLOCATION
-- =====================================================

INSERT INTO staging.geolocation (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT
    LPAD(
        NULLIF(TRIM(geolocation_zip_code_prefix), ''),
        5, '0'
    ),
    NULLIF(TRIM(geolocation_lat), '')::NUMERIC(10,7),
    NULLIF(TRIM(geolocation_lng), '')::NUMERIC(10,7),
    LOWER(NULLIF(TRIM(geolocation_city), '')),
    UPPER(NULLIF(TRIM(geolocation_state), ''))
FROM raw.geolocation;


-- =====================================================
-- 10. PRODUCT CATEGORY TRANSLATION
-- =====================================================

INSERT INTO staging.product_category_name_translation (
    product_category_name,
    product_category_name_english
)
SELECT
    LOWER(NULLIF(TRIM(product_category_name), '')),
    LOWER(NULLIF(TRIM(product_category_name_english), ''))
FROM raw.product_category_name_translation;

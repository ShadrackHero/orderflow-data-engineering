
-- ==========================================
-- ORDERFLOW | DAY 4
-- 06_core_load.sql
-- STAGING TO CORE
-- ==========================================

BEGIN;

-- ==========================================
-- 1. DIMENSION: CUSTOMERS
-- ==========================================

INSERT INTO core.dim_customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers
ON CONFLICT (customer_id)
DO UPDATE SET
    customer_unique_id = EXCLUDED.customer_unique_id,
    customer_zip_code_prefix = EXCLUDED.customer_zip_code_prefix,
    customer_city = EXCLUDED.customer_city,
    customer_state = EXCLUDED.customer_state;


-- ==========================================
-- 2. DIMENSION: PRODUCTS
-- ==========================================

INSERT INTO core.dim_products (
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM staging.products p
LEFT JOIN staging.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
ON CONFLICT (product_id)
DO UPDATE SET
    product_category_name = EXCLUDED.product_category_name,
    product_category_name_english = EXCLUDED.product_category_name_english,
    product_name_length = EXCLUDED.product_name_length,
    product_description_length = EXCLUDED.product_description_length,
    product_photos_qty = EXCLUDED.product_photos_qty,
    product_weight_g = EXCLUDED.product_weight_g,
    product_length_cm = EXCLUDED.product_length_cm,
    product_height_cm = EXCLUDED.product_height_cm,
    product_width_cm = EXCLUDED.product_width_cm;


-- ==========================================
-- 3. DIMENSION: SELLERS
-- ==========================================

INSERT INTO core.dim_sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers
ON CONFLICT (seller_id)
DO UPDATE SET
    seller_zip_code_prefix = EXCLUDED.seller_zip_code_prefix,
    seller_city = EXCLUDED.seller_city,
    seller_state = EXCLUDED.seller_state;


-- ==========================================
-- 4. DIMENSION: DATE
-- ==========================================

INSERT INTO core.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    day_name,
    is_weekend
)
SELECT
    TO_CHAR(d::date, 'YYYYMMDD')::INTEGER,
    d::date,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    TRIM(TO_CHAR(d, 'Month')),
    EXTRACT(DAY FROM d)::INTEGER,
    EXTRACT(ISODOW FROM d)::INTEGER,
    TRIM(TO_CHAR(d, 'Day')),
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series(
    DATE '2016-01-01',
    DATE '2020-12-31',
    INTERVAL '1 day'
) AS g(d)
ON CONFLICT (date_key) DO NOTHING;


-- ==========================================
-- 5. FACT: ORDERS
-- ==========================================

INSERT INTO core.fact_orders (
    order_id,
    customer_key,
    purchase_date_key,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    delivery_days,
    delivery_delay_days
)
SELECT
    o.order_id,
    c.customer_key,
    TO_CHAR(o.order_purchase_timestamp::date, 'YYYYMMDD')::INTEGER,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN
            o.order_delivered_customer_date::date
            - o.order_purchase_timestamp::date
    END,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN
            o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date
    END
FROM staging.orders o
LEFT JOIN core.dim_customers c
    ON o.customer_id = c.customer_id
ON CONFLICT (order_id)
DO UPDATE SET
    customer_key = EXCLUDED.customer_key,
    purchase_date_key = EXCLUDED.purchase_date_key,
    order_status = EXCLUDED.order_status,
    order_purchase_timestamp = EXCLUDED.order_purchase_timestamp,
    order_approved_at = EXCLUDED.order_approved_at,
    order_delivered_carrier_date = EXCLUDED.order_delivered_carrier_date,
    order_delivered_customer_date = EXCLUDED.order_delivered_customer_date,
    order_estimated_delivery_date = EXCLUDED.order_estimated_delivery_date,
    delivery_days = EXCLUDED.delivery_days,
    delivery_delay_days = EXCLUDED.delivery_delay_days;


-- ==========================================
-- 6. FACT: ORDER ITEMS
-- ==========================================

DELETE FROM core.fact_order_items;

INSERT INTO core.fact_order_items (
    order_key,
    order_item_id,
    product_key,
    seller_key,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    o.order_key,
    oi.order_item_id,
    p.product_key,
    s.seller_key,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value
FROM staging.order_items oi
INNER JOIN core.fact_orders o
    ON oi.order_id = o.order_id
LEFT JOIN core.dim_products p
    ON oi.product_id = p.product_id
LEFT JOIN core.dim_sellers s
    ON oi.seller_id = s.seller_id;


-- ==========================================
-- 7. FACT: ORDER PAYMENTS
-- ==========================================

DELETE FROM core.fact_order_payments;

INSERT INTO core.fact_order_payments (
    order_key,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    o.order_key,
    op.payment_sequential,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM staging.order_payments op
INNER JOIN core.fact_orders o
    ON op.order_id = o.order_id;

COMMIT;


-- OrderFlow | Day 3
-- Customer Staging Validation

-- 1. Compare source and staging counts
SELECT
    (SELECT COUNT(*) FROM raw.customers)
        AS raw_rows,
    (SELECT COUNT(*) FROM staging.customers)
        AS staging_rows;

-- 2. Check duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM staging.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 3. Check required fields
SELECT
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS null_customer_ids,
    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
    ) AS null_unique_ids
FROM staging.customers;

-- 4. Check state abbreviations
SELECT
    customer_state,
    COUNT(*) AS customer_count
FROM staging.customers
GROUP BY customer_state
ORDER BY customer_count DESC;

-- 5. Inspect transformed records
SELECT *
FROM staging.customers
LIMIT 10;


-- ==========================================
-- VALIDATION: ORDERS
-- ==========================================

-- Compare row counts
SELECT
    (SELECT COUNT(*) FROM raw.orders) AS raw_rows,
    (SELECT COUNT(*) FROM staging.orders) AS staging_rows;

-- Check order statuses
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM staging.orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Check missing timestamps
SELECT
    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_dates,

    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_customer_delivery_dates,

    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery_dates
FROM staging.orders;

-- Check referential integrity
SELECT COUNT(*) AS orphan_orders
FROM staging.orders o
LEFT JOIN staging.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ==========================================
-- VALIDATION: ORDER ITEMS
-- ==========================================

-- 1. Compare raw and staging counts
SELECT
    (SELECT COUNT(*) FROM raw.order_items) AS raw_rows,
    (SELECT COUNT(*) FROM staging.order_items) AS staging_rows;

-- 2. Check duplicate composite keys
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS occurrences
FROM staging.order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- 3. Check missing values
SELECT
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_ids,

    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS missing_seller_ids,

    COUNT(*) FILTER (
        WHERE price IS NULL
    ) AS missing_prices,

    COUNT(*) FILTER (
        WHERE freight_value IS NULL
    ) AS missing_freight_values
FROM staging.order_items;

-- 4. Check orphan order items
SELECT COUNT(*) AS orphan_items
FROM staging.order_items oi
LEFT JOIN staging.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5. Check negative financial values
SELECT COUNT(*) AS invalid_amounts
FROM staging.order_items
WHERE price < 0
   OR freight_value < 0;

-- 6. Summarise financial amounts
SELECT
    COUNT(*) AS total_items,
    ROUND(SUM(price), 2) AS total_product_value,
    ROUND(SUM(freight_value), 2) AS total_freight_value,
    ROUND(SUM(price + freight_value), 2)
        AS total_item_value
FROM staging.order_items;


-- ==========================================
-- VALIDATION: PRODUCTS AND SELLERS
-- ==========================================

-- 1. Compare raw and staging row counts
SELECT
    'products' AS dataset,
    (SELECT COUNT(*) FROM raw.products) AS raw_rows,
    (SELECT COUNT(*) FROM staging.products) AS staging_rows

UNION ALL

SELECT
    'sellers',
    (SELECT COUNT(*) FROM raw.sellers),
    (SELECT COUNT(*) FROM staging.sellers);


-- 2. Product missing-value assessment
SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_categories,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weights,
    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
    ) AS missing_lengths,
    COUNT(*) FILTER (
        WHERE product_height_cm IS NULL
    ) AS missing_heights,
    COUNT(*) FILTER (
        WHERE product_width_cm IS NULL
    ) AS missing_widths
FROM staging.products;


-- 3. Check invalid measurements
SELECT
    COUNT(*) FILTER (
        WHERE product_weight_g < 0
           OR product_length_cm < 0
           OR product_height_cm < 0
           OR product_width_cm < 0
    ) AS negative_measurements
FROM staging.products;


-- 4. Seller geographical distribution
SELECT
    seller_state,
    COUNT(*) AS total_sellers
FROM staging.sellers
GROUP BY seller_state
ORDER BY total_sellers DESC;


-- 5. Check missing seller attributes
SELECT
    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix IS NULL
    ) AS missing_zip_codes,
    COUNT(*) FILTER (
        WHERE seller_city IS NULL
    ) AS missing_cities,
    COUNT(*) FILTER (
        WHERE seller_state IS NULL
    ) AS missing_states
FROM staging.sellers;

SELECT
    'order_payments' AS dataset,
    (SELECT COUNT(*) FROM raw.order_payments) AS raw_rows,
    (SELECT COUNT(*) FROM staging.order_payments) AS staging_rows

UNION ALL

SELECT
    'order_reviews',
    (SELECT COUNT(*) FROM raw.order_reviews),
    (SELECT COUNT(*) FROM staging.order_reviews);

SELECT
    'geolocation' AS dataset,
    (SELECT COUNT(*) FROM raw.geolocation) AS raw_rows,
    (SELECT COUNT(*) FROM staging.geolocation) AS staging_rows

UNION ALL

SELECT
    'product_category_name_translation',
    (SELECT COUNT(*) FROM raw.product_category_name_translation),
    (SELECT COUNT(*) FROM staging.product_category_name_translation);

    
SELECT
    'geolocation' AS dataset,
    (SELECT COUNT(*) FROM raw.geolocation) AS raw_rows,
    (SELECT COUNT(*) FROM staging.geolocation) AS staging_rows

UNION ALL

SELECT
    'product_category_name_translation',
    (SELECT COUNT(*) FROM raw.product_category_name_translation),
    (SELECT COUNT(*) FROM staging.product_category_name_translation);

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )) AS distinct_rows
FROM staging.geolocation;

WITH duplicates AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS occurrences
    FROM staging.geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
)
SELECT
    SUM(occurrences - 1) AS duplicate_rows
FROM duplicates;

SELECT
    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
    ) AS missing_zip_codes,

    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
    ) AS missing_latitudes,

    COUNT(*) FILTER (
        WHERE geolocation_lng IS NULL
    ) AS missing_longitudes,

    COUNT(*) FILTER (
        WHERE geolocation_city IS NULL
    ) AS missing_cities,

    COUNT(*) FILTER (
        WHERE geolocation_state IS NULL
    ) AS missing_states
FROM staging.geolocation;

SELECT
    COUNT(*) FILTER (
        WHERE geolocation_lat NOT BETWEEN -34 AND 6
           OR geolocation_lng NOT BETWEEN -74 AND -28
    ) AS outside_brazil_approx_bounds,

    COUNT(*) FILTER (
        WHERE geolocation_lat NOT BETWEEN -90 AND 90
           OR geolocation_lng NOT BETWEEN -180 AND 180
    ) AS invalid_global_coordinates
FROM staging.geolocation;

SELECT
    COUNT(*) AS total_categories,
    COUNT(*) FILTER (
        WHERE product_category_name_english IS NULL
    ) AS missing_translations
FROM staging.product_category_name_translation;

SELECT
    p.product_category_name,
    COUNT(*) AS products_without_translation
FROM staging.products p
LEFT JOIN staging.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY products_without_translation DESC;

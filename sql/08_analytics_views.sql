
-- ==========================================
-- ORDERFLOW | DAY 5
-- 08_analytics_views.sql
-- ANALYTICS & REPORTING LAYER
-- ==========================================

CREATE SCHEMA IF NOT EXISTS analytics;

-- ==========================================
-- VIEW 1: SALES DETAIL
-- Grain: One row per order item
-- ==========================================

CREATE OR REPLACE VIEW analytics.vw_sales_detail AS
SELECT
    oi.order_item_key,
    o.order_id,
    oi.order_item_id,

    -- Dates
    d.full_date AS order_date,
    d.year AS order_year,
    d.quarter AS order_quarter,
    d.month AS order_month,
    d.month_name AS order_month_name,

    -- Customer
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    -- Product
    p.product_id,
    p.product_category_name,
    COALESCE(
        p.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    -- Seller
    s.seller_id,
    s.seller_city,
    s.seller_state,

    -- Order
    o.order_status,

    -- Financial metrics
    oi.price AS item_revenue,
    oi.freight_value AS freight_revenue,
    COALESCE(oi.price, 0)
      + COALESCE(oi.freight_value, 0)
        AS total_item_value,

    -- Quantity
    1 AS item_quantity

FROM core.fact_order_items oi

INNER JOIN core.fact_orders o
    ON oi.order_key = o.order_key

LEFT JOIN core.dim_date d
    ON o.purchase_date_key = d.date_key

LEFT JOIN core.dim_customers c
    ON o.customer_key = c.customer_key

LEFT JOIN core.dim_products p
    ON oi.product_key = p.product_key

LEFT JOIN core.dim_sellers s
    ON oi.seller_key = s.seller_key;


-- ==========================================
-- ORDERFLOW | DAY 5
-- VIEW 2: MONTHLY SALES PERFORMANCE
-- ==========================================

CREATE OR REPLACE VIEW analytics.vw_monthly_sales AS

WITH monthly_aggregation AS (

    SELECT
        DATE_TRUNC('month', order_date)::DATE
            AS sales_month,

        COUNT(DISTINCT order_id)
            AS total_orders,

        COUNT(*)
            AS items_sold,

        SUM(item_revenue)
            AS merchandise_sales,

        SUM(freight_revenue)
            AS freight_charges,

        SUM(total_item_value)
            AS total_sales_value

    FROM analytics.vw_sales_detail

    WHERE order_date IS NOT NULL

    GROUP BY
        DATE_TRUNC('month', order_date)::DATE

),

monthly_metrics AS (

    SELECT
        sales_month,
        total_orders,
        items_sold,
        merchandise_sales,
        freight_charges,
        total_sales_value,

        ROUND(
            total_sales_value
            / NULLIF(total_orders, 0),
            2
        ) AS average_order_value,

        LAG(total_sales_value) OVER (
            ORDER BY sales_month
        ) AS previous_month_sales

    FROM monthly_aggregation

)

SELECT
    sales_month,

    EXTRACT(YEAR FROM sales_month)::INTEGER
        AS sales_year,

    EXTRACT(MONTH FROM sales_month)::INTEGER
        AS sales_month_number,

    total_orders,
    items_sold,

    merchandise_sales,
    freight_charges,
    total_sales_value,

    average_order_value,
    previous_month_sales,

    ROUND(
        (
            total_sales_value - previous_month_sales
        ) * 100.0
        / NULLIF(previous_month_sales, 0),
        2
    ) AS mom_growth_pct

FROM monthly_metrics;

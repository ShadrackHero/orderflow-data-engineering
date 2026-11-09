# OrderFlow — Initial Data Quality Report

## 1. Dataset Overview

Source: Olist Brazilian E-Commerce Public Dataset

Number of source tables: 9

The dataset contains customer, order, product, seller, payment, review and geolocation information.

## 2. Primary Key Validation

Six tables were tested for primary-key candidate uniqueness and null values.

All six passed the validation checks.

Composite keys identified:
- order_items: (order_id, order_item_id)
- order_payments: (order_id, payment_sequential)

## 3. Referential Integrity

Six foreign-key relationships were tested.

All tested relationships returned zero orphan records.

## 4. Missing Values

Missing values were identified in orders, order_reviews and products.

Key observations:
- Delivery timestamps are missing for some orders.
- Review titles and messages are frequently absent.
- Some product descriptions and attributes are incomplete.

Missing values will be handled according to their business meaning rather than replaced indiscriminately.

## 5. Duplicate Records

The geolocation dataset contains:
- Total records: 1,000,163
- Exact duplicate records: 261,831
- Unique records: 738,332

Raw data will remain unchanged. Geographic aggregation and deduplication decisions will be implemented in staging after validation.

## 6. Engineering Decisions

1. Preserve original source records in the raw schema.
2. Apply cleaning and standardisation in staging.
3. Enforce appropriate keys in curated warehouse tables.
4. Maintain SQL-based data quality checks.
5. Record ETL execution metadata.
6. Design fact and dimension tables with explicitly documented grains.

## 7. Conclusion

Initial checks show that the core transactional tables have valid candidate keys and consistent tested relationships.

Additional validation of order status, timestamps, payment totals and untested keys will be performed during pipeline development.
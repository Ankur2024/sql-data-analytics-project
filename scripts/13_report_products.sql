/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================

-- Drop view if exists
DROP VIEW IF EXISTS gold.report_products;

-- Create view
CREATE VIEW gold.report_products AS

WITH base_query AS (
/*-----------------------------------------------------------------------------
1) Base Query: Retrieve core sales + product data
-----------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,

        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost

    FROM gold.fact_sales f

    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key

    WHERE f.order_date IS NOT NULL
),

product_aggregations AS (
/*-----------------------------------------------------------------------------
2) Aggregate product-level metrics
-----------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,

    -- Lifespan (months)
    (
        EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
        EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
    ) AS lifespan,

    MAX(order_date) AS last_sale_date,

    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,

    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,

    -- Average selling price
    ROUND(
        AVG((sales_amount::NUMERIC) / NULLIF(quantity, 0)),
        1
    ) AS avg_selling_price

FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*-----------------------------------------------------------------------------
3) Final Output
-----------------------------------------------------------------------------*/
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,

    last_sale_date,

    -- Recency (months since last sale)
    (
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_sale_date)) * 12 +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_sale_date))
    ) AS recency_in_months,

    -- Product segmentation
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,

    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,

    -- Average Order Revenue (AOR)
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average Monthly Revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM product_aggregations;

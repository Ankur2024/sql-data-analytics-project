/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================

-- Drop view if exists (PostgreSQL way)
DROP VIEW IF EXISTS gold.report_customers;

-- Create view
CREATE VIEW gold.report_customers AS

WITH base_query AS (
/*-----------------------------------------------------------------------------
1) Base Query: Retrieve core transaction + customer data
-----------------------------------------------------------------------------*/
SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,

    c.customer_key,
    c.customer_number,

    -- Full name
    c.first_name || ' ' || c.last_name AS customer_name,

    -- Calculate age
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birthdate)) AS age

FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key

WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
/*-----------------------------------------------------------------------------
2) Aggregate metrics at customer level
-----------------------------------------------------------------------------*/
SELECT 
    customer_key,
    customer_number,
    customer_name,
    age,

    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,

    MAX(order_date) AS last_order_date,

    -- Lifespan in months
    (
        EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
        EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
    ) AS lifespan

FROM base_query

GROUP BY 
    customer_key,
    customer_number,
    customer_name,
    age
)

SELECT
    customer_key,
    customer_number,
    customer_name,
    age,

    /*-----------------------------------------------------------------------
    3) Age Group Segmentation
    -----------------------------------------------------------------------*/
    CASE 
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,

    /*-----------------------------------------------------------------------
    4) Customer Segmentation
    -----------------------------------------------------------------------*/
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,

    last_order_date,

    /*-----------------------------------------------------------------------
    5) Recency (months since last order)
    -----------------------------------------------------------------------*/
    (
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_order_date)) * 12 +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_order_date))
    ) AS recency,

    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,

    /*-----------------------------------------------------------------------
    6) KPIs
    -----------------------------------------------------------------------*/

    -- Average Order Value
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,

    -- Average Monthly Spend
    CASE 
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spend

FROM customer_aggregation;

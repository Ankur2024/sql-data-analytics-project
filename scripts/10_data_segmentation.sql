/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into cost ranges and 
count how many products fall into each segment*/

WITH product_segments AS (
SELECT
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END cost_range
FROM gold.dim_products)

SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;



/* 
Step 1: Calculate customer-level metrics
- Total spending
- First and last order dates
- Customer lifespan in months
*/
WITH customer_spending AS (
    SELECT
        c.customer_key,

        -- Total amount spent by each customer
        SUM(f.sales_amount) AS total_spending,

        -- First and last purchase dates
        MIN(f.order_date) AS first_order,
        MAX(f.order_date) AS last_order,

        -- Calculate lifespan in months using AGE()
        (
            EXTRACT(YEAR FROM AGE(MAX(f.order_date), MIN(f.order_date))) * 12 +
            EXTRACT(MONTH FROM AGE(MAX(f.order_date), MIN(f.order_date)))
        ) AS lifespan

    FROM gold.fact_sales f

    -- Join to get customer info
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key

    -- Exclude null dates
    WHERE f.order_date IS NOT NULL

    -- Group by customer
    GROUP BY c.customer_key
)

/*
Step 2: Segment customers based on business rules
*/
SELECT 
    customer_segment,

    -- Count number of customers in each segment
    COUNT(customer_key) AS total_customers

FROM (
    SELECT 
        customer_key,

        -- Apply segmentation logic
        CASE 
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'       -- High-value loyal customers
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular' -- Long-term but lower spend
            ELSE 'New'                                                    -- New customers (< 12 months)
        END AS customer_segment

    FROM customer_spending

) AS segmented_customers

/*
Step 3: Aggregate results
*/
GROUP BY customer_segment

-- Show highest segment first
ORDER BY total_customers DESC;

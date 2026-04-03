/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/

-- Retrieve a list of unique countries from which customers originate
SELECT DISTINCT 
    country 
FROM gold.dim_customers
WHERE country IS NOT NULL          -- Optional: avoid NULL values in PostgreSQL results
ORDER BY country;

-- Retrieve a list of unique categories, subcategories, and products
SELECT DISTINCT 
    category, 
    subcategory, 
    product_name 
FROM gold.dim_products
WHERE category IS NOT NULL         -- Optional cleanup
  AND subcategory IS NOT NULL
  AND product_name IS NOT NULL
ORDER BY category, subcategory, product_name;

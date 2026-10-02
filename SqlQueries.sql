CREATE TABLE superstore (
    row_id INTEGER,
    order_id VARCHAR(50),
    order_date TEXT,
    ship_date TEXT,
    ship_mode VARCHAR(30),
    customer_id VARCHAR(30),
    customer_name VARCHAR(150),
    segment VARCHAR(30),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    market VARCHAR(30),
    region VARCHAR(50),
    product_id VARCHAR(30),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name TEXT,
    sales NUMERIC(14,2),
    quantity INTEGER,
    discount NUMERIC(5,2),
    profit NUMERIC(14,4),
    shipping_cost NUMERIC(14,2),
    order_priority VARCHAR(20)
);
SELECT * FROM superstore ;

--Check for duplicate row IDs.
SELECT row_id, COUNT(*) AS occurrences
FROM superstore
GROUP BY row_id
HAVING COUNT(*)>1
ORDER BY occurrences DESC;

--Q1. calculating Total revenue, total profit, profit margin, shipping cost, total orders and total customers.
SELECT 
      ROUND(SUM(sales),2) AS total_revenue,
	  ROUND(SUM(profit),2) AS total_profit, 
	  ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_perctage,
	  ROUND(SUM(shipping_cost),2) AS total_shipping_cost,
	  SUM(quantity) AS total_quantity_sold,
	  COUNT(DISTINCT order_id) AS total_orders,
	  COUNT(DISTINCT customer_id) AS total_customers
FROM superstore;

--Q2. Calculating Average order value (AOV).
SELECT 
      ROUND(SUM(sales)/ NULLIF(COUNT(DISTINCT order_id),0),2) AS avg_order_value
FROM superstore;
 
--Q3. Calculating average discount, average shipping and average quantity.
SELECT
      ROUND(AVG(discount),3) AS avg_discount,
	  ROUND(AVG(shipping_cost),2) AS avg_shipping_cost,
	  ROUND(AVG(quantity),2) AS avg_quantity
FROM superstore;

--Converting order date and ship date column TEXT to DATE type.
ALTER TABLE superstore
ALTER COLUMN order_date TYPE DATE
USING TO_DATE(order_date, 'DD-MM-YYYY');

ALTER TABLE superstore
ALTER COLUMN ship_date TYPE DATE
USING TO_DATE(ship_date, 'DD-MM-YYYY');

--Q4. Calculating  monthly revenue, profit and profit margin.
SELECT 
      DATE_TRUNC('month', order_date):: DATE AS month,
	  ROUND(SUM(sales),2) AS revenue,
	  ROUND(SUM(profit),2) AS profit,
	  ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage
FROM superstore
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

--Q5. Calculating  Yearly business performance.
SELECT 
      EXTRACT(YEAR FROM order_date)::INTEGER AS year,
	  ROUND(SUM(sales),2) AS revenue,
	  ROUND(SUM(profit),2) AS profit,
	  ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage,
	  COUNT(DISTINCT order_id) AS total_orders
FROM superstore
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY year;

--Q6. Calculating  Year-Over-Year (YOY) revenue and profit growth.
WITH yearly AS (
      SELECT
	     EXTRACT(YEAR FROM order_date)::INTEGER AS year,
	     SUM(sales) AS revenue,
	     SUM(profit) AS profit
	  FROM superstore
	  GROUP BY EXTRACT(YEAR FROM order_date)	  
),
comparison AS (
      SELECT 
	     year,revenue, profit,
		 LAG(revenue) OVER (ORDER BY year) AS previous_revenue,
		 LAG(profit) OVER (ORDER BY year) AS previous_profit
	  FROM yearly
)
SELECT year,
      ROUND(revenue,2) AS revenue,
	  ROUND(profit,2) AS profit,
	  ROUND(
         (revenue - previous_revenue)*100/ NULLIF(previous_revenue,0),2) AS revenue_growth_percentage,
	  ROUND(
         (profit - previous_profit)*100/NULLIF(ABS(previous_profit),0),2) AS profit_change_percentage
FROM comparison
ORDER BY year;

--Q7. Find which products and categories affect profitability ?
SELECT category,
	  ROUND(SUM(sales),2) AS revenue,
	  ROUND(SUM(profit),2) AS profit,
	  ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage,
	  SUM(quantity) AS quantity_sold
FROM superstore
GROUP BY category
ORDER BY profit DESC;

--Q8. Performance by sub-category.
SELECT category, sub_category,
      ROUND(SUM(sales),2) AS revenue,
	  ROUND(SUM(profit),2) AS profit,
      ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage,
	  ROUND(AVG(discount),3) AS avg_discount,
	  COUNT(DISTINCT order_id) AS total_orders
FROM superstore
GROUP BY category, sub_category
ORDER BY profit ASC;

--Q9. Identify loss-making products.
SELECT product_id, product_name, category, sub_category,
      SUM(quantity) AS quantity_sold,
	  ROUND(SUM(sales),2) AS revenue,
	  ROUND(SUM(profit),2) AS total_profit,
	  ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage
FROM superstore
GROUP BY product_id, product_name, category, sub_category
HAVING SUM(profit)<0
ORDER BY SUM(profit) ASC
LIMIT 20;

--Q10. Analyse whether discounts are reducing profit.
SELECT 
    CASE 
	    WHEN discount = 0 THEN '0% - No Discount'
		WHEN discount <= 0.10 THEN '1% - 10%'
		WHEN discount <= 0.20 THEN '11% - 20%'
		WHEN discount <= 0.30 THEN '21% - 30%'
		ELSE 'Above 30%'
	END AS discount_range,
	COUNT(*) AS order_lines,
	ROUND(SUM(sales),2) AS revenue,
	ROUND(SUM(profit),2) AS profit,
	ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage
FROM superstore
GROUP BY 
    CASE
	WHEN discount = 0 THEN '0% - No Discount'
		WHEN discount <= 0.10 THEN '1% - 10%'
		WHEN discount <= 0.20 THEN '11% - 20%'
		WHEN discount <= 0.30 THEN '21% - 30%'
		ELSE 'Above 30%'
	END
ORDER BY MIN(discount);
	
--Q11. Find the highest-discount loss-making products.
SELECT product_name, category, sub_category,
     ROUND(AVG(discount),3) AS avg_discount,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit
FROM superstore
GROUP BY product_name, category, sub_category
HAVING SUM(profit)<0
ORDER BY AVG(discount) DESC
LIMIT 20;

--Q12. Analyse regional and customer-segment performance.
SELECT region,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit,
	 ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage,
	 COUNT(DISTINCT order_id) AS total_orders
FROM superstore
GROUP BY region
ORDER BY profit ASC;

--Q13. Analyse country-level performance.
SELECT country,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit,
	 ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage,
	 COUNT(DISTINCT order_id) AS total_orders
FROM superstore
GROUP BY country
ORDER BY profit ASC
LIMIT 20;

--Q14. Profitability by customer-segment.
SELECT segment,
     COUNT(DISTINCT customer_id) AS total_customers,
	 COUNT(DISTINCT order_id) AS total_orders,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit,
	 ROUND(SUM(profit)*100/ NULLIF(SUM(sales),0),2) AS profit_margin_percentage
FROM superstore
GROUP BY segment
ORDER BY profit ASC;

--Q15. Shipping cost by shipping mode.
SELECT ship_mode,
	 COUNT(DISTINCT order_id) AS total_orders,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit,
	 ROUND(SUM(shipping_cost),2) AS total_shipping_cost,
	 ROUND(SUM(shipping_cost)*100/ NULLIF(SUM(sales),0),2) AS shipping_cost_percentage
FROM superstore
GROUP BY ship_mode
ORDER BY total_shipping_cost DESC;

--Q16. Profitability by order priority.
SELECT order_priority,
     COUNT(*) AS order_lines,
	 COUNT(DISTINCT order_id) AS total_orders,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit,
	 ROUND(SUM(shipping_cost)*100/ NULLIF(SUM(sales),0),2) AS shipping_cost_percentage
FROM superstore
GROUP BY order_priority
ORDER BY profit ASC;

--Q17. Top 10 customers by revenue.
SELECT customer_id, customer_name,
	 COUNT(DISTINCT order_id) AS total_orders,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit,
	 ROUND(SUM(shipping_cost)*100/ NULLIF(SUM(sales),0),2) AS shipping_cost_percentage
FROM superstore
GROUP BY customer_id, customer_name
ORDER BY SUM(sales) DESC
LIMIT 10;

--Q18. Customers generating losses.
SELECT customer_id, customer_name,
	 COUNT(DISTINCT order_id) AS total_orders,
     ROUND(SUM(sales),2) AS revenue,
	 ROUND(SUM(profit),2) AS profit
FROM superstore
GROUP BY customer_id, customer_name
HAVING SUM(profit)<0
ORDER BY SUM(profit) ASC
LIMIT 20;










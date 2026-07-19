-- ============================================
-- DELIVERY ZONE ANALYZER — SQL Analysis Queries
-- Author: Julio Cesar Zamora Ramirez
-- Dataset: Olist Brazilian E-Commerce
-- ============================================

-- ── QUERY 1 ─────────────────────────────────
-- KPI: Order Distribution by Delivery Status
-- Purpose: Understand split between Early, Late, On Time
-- ─────────────────────────────────────────────
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    delivery_status
FROM orders_summary
GROUP BY delivery_status
ORDER BY total_orders DESC;


-- ── QUERY 2 ─────────────────────────────────
-- KPI: Average Days Late by State
-- Purpose: Identify which states have worst delivery timing
-- ─────────────────────────────────────────────
SELECT 
    customer_state,
    ROUND(AVG(days_late)::numeric, 2) AS avg_days_late
FROM orders_summary
GROUP BY customer_state
ORDER BY avg_days_late DESC;


-- ── QUERY 3 ─────────────────────────────────
-- KPI: Late Order Count by State
-- Purpose: Volume of late deliveries per state
-- ─────────────────────────────────────────────
SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS late_orders
FROM orders_summary
WHERE delivery_status = 'Late'
GROUP BY customer_state
ORDER BY late_orders DESC
LIMIT 10;


-- ── QUERY 4 ─────────────────────────────────
-- KPI: Late Rate by State (above 5%)
-- Purpose: Flag states with serious SLA compliance issues
-- ─────────────────────────────────────────────
SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) AS late_orders,
    ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) * 100.0 
    / COUNT(DISTINCT order_id), 2) AS late_rate
FROM orders_summary
GROUP BY customer_state
HAVING ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) * 100.0 
    / COUNT(DISTINCT order_id), 2) > 5
ORDER BY late_rate DESC;


-- ── QUERY 5 ─────────────────────────────────
-- KPI: Average Days Late by Breach Severity
-- Purpose: Validate breach severity classification
-- ─────────────────────────────────────────────
SELECT
    breach_severity,
    ROUND(AVG(days_late)::numeric, 2) AS avg_days_late
FROM orders_summary
GROUP BY breach_severity
ORDER BY avg_days_late DESC;


-- ── QUERY 6 ─────────────────────────────────
-- KPI: Average Freight Value by Product Category
-- Purpose: Identify which categories cost most to ship
-- ─────────────────────────────────────────────
SELECT
    product_category_name_english,
    ROUND(AVG(freight_value::numeric), 2) AS avg_freight_val
FROM orders_summary
WHERE product_category_name_english != 'Unknown'
AND product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
ORDER BY avg_freight_val DESC
LIMIT 5;


-- ── QUERY 7 ─────────────────────────────────
-- KPI: Multi-Metric Business Summary by State
-- Purpose: One view of orders, revenue, and late performance per state
-- ─────────────────────────────────────────────
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value::numeric), 2) AS total_revenue,
    ROUND(AVG(days_late)::numeric, 2) AS avg_days_late,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) AS orders_late
FROM orders_summary
GROUP BY customer_state
ORDER BY orders_late DESC;


-- ── QUERY 8 ─────────────────────────────────
-- KPI: High Volume States with Poor Delivery Performance
-- Purpose: Find states with over 500 orders AND avg days late above -10
-- ─────────────────────────────────────────────
SELECT	
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(days_late)::numeric, 2) AS avg_days_late
FROM orders_summary
GROUP BY customer_state
HAVING 
    COUNT(DISTINCT order_id) > 500
    AND AVG(days_late) > -10
ORDER BY avg_days_late DESC;


-- ── QUERY 9 ─────────────────────────────────
-- KPI: Top 10 Sellers by Total Revenue
-- Purpose: Identify highest performing sellers
-- ─────────────────────────────────────────────
SELECT
    ROUND(SUM(payment_value::numeric), 2) AS seller_total,
    seller_id,
    seller_city
FROM orders_summary
GROUP BY seller_id, seller_city
ORDER BY seller_total DESC
LIMIT 10;


-- ── QUERY 10 ────────────────────────────────
-- KPI: Late Rate Percentage by State (500+ orders only)
-- Purpose: Fair late rate comparison excluding low volume states
-- ─────────────────────────────────────────────
SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) AS late_orders,
    ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) * 100.0
    / COUNT(DISTINCT order_id), 2) AS late_rate
FROM orders_summary
GROUP BY customer_state
HAVING COUNT(DISTINCT order_id) > 500
ORDER BY late_rate DESC;


-- ── QUERY 11 ────────────────────────────────
-- KPI: State Revenue Ranking
-- Window Function: RANK()
-- Purpose: Rank all states by total revenue
-- ─────────────────────────────────────────────
SELECT
    customer_state,
    ROUND(SUM(payment_value::numeric), 2) AS total_revenue,
    RANK() OVER(ORDER BY SUM(payment_value) DESC) AS rev_rank
FROM orders_summary
GROUP BY customer_state
ORDER BY rev_rank;


-- ── QUERY 12 ────────────────────────────────
-- KPI: Cumulative Revenue Over Time
-- Window Function: SUM() OVER(ORDER BY)
-- Purpose: Track running total of revenue chronologically
-- ─────────────────────────────────────────────
SELECT
    order_id,
    order_purchase_timestamp,
    payment_value,
    ROUND(SUM(payment_value) OVER(ORDER BY order_purchase_timestamp)::numeric, 2) AS running_total
FROM orders_summary
WHERE payment_value IS NOT NULL
AND order_purchase_timestamp IS NOT NULL
ORDER BY order_purchase_timestamp;


-- ── QUERY 13 ────────────────────────────────
-- KPI: State Freight vs National Average
-- Window Function: AVG() OVER()
-- Purpose: Compare each state's freight cost to the national benchmark
-- ─────────────────────────────────────────────
WITH state_freight AS (
    SELECT
        customer_state,
        ROUND(AVG(freight_value::numeric), 2) AS freight_avg
    FROM orders_summary
    GROUP BY customer_state
)
SELECT
    customer_state,
    freight_avg,
    ROUND(AVG(freight_avg) OVER()::numeric, 2) AS national_avg,
    ROUND((freight_avg - AVG(freight_avg) OVER())::numeric, 2) AS diff_from_national
FROM state_freight
ORDER BY freight_avg DESC;


-- ── QUERY 14 ────────────────────────────────
-- KPI: Top 3 Product Categories per State
-- Window Function: RANK() OVER(PARTITION BY)
-- Purpose: Identify most popular categories in each state
-- ─────────────────────────────────────────────
WITH orders_t AS (
    SELECT
        customer_state,
        product_category_name_english,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_summary
    WHERE product_category_name_english != 'Unknown'
    GROUP BY customer_state, product_category_name_english
),
ranked AS (
    SELECT
        customer_state,
        product_category_name_english,
        total_orders,
        RANK() OVER(PARTITION BY customer_state ORDER BY total_orders DESC) AS state_rank
    FROM orders_t
)
SELECT *
FROM ranked
WHERE state_rank <= 3
ORDER BY customer_state, state_rank;


-- ── QUERY 15 ────────────────────────────────
-- KPI: States Above Average Late Rate
-- Technique: CTE + Subquery
-- Purpose: Flag underperforming states relative to national benchmark
-- ─────────────────────────────────────────────
WITH late_time AS (
    SELECT
        customer_state,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) AS late_orders,
        ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id), 2) AS late_rate
    FROM orders_summary
    GROUP BY customer_state
)
SELECT
    customer_state,
    total_orders,
    late_orders,
    late_rate
FROM late_time
WHERE late_rate > (SELECT AVG(late_rate) FROM late_time)
ORDER BY late_rate DESC;


-- ── QUERY 16 ────────────────────────────────
-- KPI: Orders Above Average Freight Value
-- Technique: Subquery in WHERE clause
-- Purpose: Identify high shipping cost orders for cost optimization
-- ─────────────────────────────────────────────
SELECT 
    order_id,
    customer_state,
    freight_value,
    ROUND((SELECT AVG(freight_value) FROM orders_summary)::numeric, 2) AS avg_freight
FROM orders_summary
WHERE freight_value > (SELECT AVG(freight_value) FROM orders_summary)
ORDER BY freight_value DESC;


-- ── QUERY 17 ────────────────────────────────
-- KPI: States Above Average Order Count
-- Technique: CTE + Subquery
-- Purpose: Identify high volume markets
-- ─────────────────────────────────────────────
WITH state_orders AS (
    SELECT
        customer_state,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_summary
    GROUP BY customer_state
)
SELECT
    customer_state,
    total_orders,
    ROUND((SELECT AVG(total_orders) FROM state_orders)::numeric, 2) AS avg_orders
FROM state_orders
WHERE total_orders > (SELECT AVG(total_orders) FROM state_orders)
ORDER BY total_orders DESC;


-- ── QUERY 18 ────────────────────────────────
-- KPI: Month Over Month Order Growth
-- Window Function: LAG()
-- Purpose: Track business growth and identify seasonal patterns
-- ─────────────────────────────────────────────
WITH monthly AS (
    SELECT 
        TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS order_month,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders_summary
    WHERE order_purchase_timestamp IS NOT NULL
    GROUP BY order_month
)
SELECT
    order_month,
    total_orders,
    LAG(total_orders, 1) OVER(ORDER BY order_month) AS prev_month_orders,
    total_orders - LAG(total_orders, 1) OVER(ORDER BY order_month) AS mom_difference,
    ROUND((total_orders - LAG(total_orders, 1) OVER(ORDER BY order_month)) * 100.0 
    / LAG(total_orders, 1) OVER(ORDER BY order_month), 2) AS pct_growth
FROM monthly
ORDER BY order_month;


-- ── QUERY 19 ────────────────────────────────
-- KPI: Product Category Revenue Ranking
-- Technique: CTE + RANK() Window Function
-- Purpose: Identify highest revenue generating categories
-- ─────────────────────────────────────────────
WITH revenue_category AS ( 
    SELECT
        product_category_name_english,
        ROUND(SUM(payment_value::numeric), 2) AS total_revenue
    FROM orders_summary
    GROUP BY product_category_name_english
) 
SELECT
    product_category_name_english,
    total_revenue,
    RANK() OVER(ORDER BY total_revenue DESC) AS revenue_rank
FROM revenue_category
ORDER BY revenue_rank;


-- ── QUERY 20 ────────────────────────────────
-- KPI: Complete Business Intelligence Summary by State
-- Technique: CTE + Multiple Window Functions
-- Purpose: Full picture of orders, revenue, and delivery performance per state
-- ─────────────────────────────────────────────
WITH biz_summary AS ( 
    SELECT
        customer_state,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(payment_value::numeric), 2) AS total_revenue_by_state,
        ROUND(COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) * 100.0
        / COUNT(DISTINCT order_id), 2) AS late_rate
    FROM orders_summary
    GROUP BY customer_state
)
SELECT
    customer_state,
    total_orders,
    total_revenue_by_state,
    late_rate,
    RANK() OVER(ORDER BY total_revenue_by_state DESC) AS rank_state_revenue,
    RANK() OVER(ORDER BY late_rate) AS rank_late_by_state
FROM biz_summary
ORDER BY rank_state_revenue;
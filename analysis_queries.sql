-- ============================================
-- DELIVERY ZONE ANALYZER — SQL Analysis Queries
-- Author: Julio Cesar Zamora Ramirez
-- Dataset: Olist Brazilian E-Commerce
-- ============================================


-- ── QUERY 1: Orders by Delivery Status ──────
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    delivery_status
FROM orders_summary
GROUP BY delivery_status
ORDER BY total_orders DESC;


-- ── QUERY 2: Average Days Late by State ─────
SELECT 
    customer_state,
    ROUND(AVG(days_late)::numeric, 2) AS avg_days_late
FROM orders_summary
GROUP BY customer_state
ORDER BY avg_days_late DESC;


-- ── QUERY 3: Late Orders Count by State ─────
SELECT 
    customer_state,
    COUNT(DISTINCT order_id) AS late_orders
FROM orders_summary
WHERE delivery_status = 'Late'
GROUP BY customer_state
ORDER BY late_orders DESC
LIMIT 10;


-- ── QUERY 4: Late Rate by State (>5%) ───────
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


-- ── QUERY 5: Avg Days Late by Breach Severity 
SELECT
    breach_severity,
    ROUND(AVG(days_late)::numeric, 2) AS avg_days_late
FROM orders_summary
GROUP BY breach_severity
ORDER BY avg_days_late DESC;


-- ── QUERY 6: Top 5 Categories by Freight ────
SELECT
    product_category_name_english,
    ROUND(AVG(freight_value::numeric), 2) AS avg_freight_val
FROM orders_summary
WHERE product_category_name_english != 'Unknown'
AND product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
ORDER BY avg_freight_val DESC
LIMIT 5;


-- ── QUERY 7: Multi-Metric Summary by State ──
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value::numeric), 2) AS total_revenue,
    ROUND(AVG(days_late)::numeric, 2) AS avg_days_late,
    COUNT(DISTINCT CASE WHEN delivery_status = 'Late' THEN order_id END) AS orders_late
FROM orders_summary
GROUP BY customer_state
ORDER BY orders_late DESC;


-- ── QUERY 8: States >500 Orders & Avg Late > -10
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


-- ── QUERY 9: Top 10 Sellers by Revenue ──────
SELECT
    ROUND(SUM(payment_value::numeric), 2) AS seller_total,
    seller_id,
    seller_city
FROM orders_summary
GROUP BY seller_id, seller_city
ORDER BY seller_total DESC
LIMIT 10;


-- ── QUERY 10: Late Rate % by State (>500 orders)
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
USE olist;

-- 1. Overall numbers
SELECT COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.price),2) AS revenue,
       ROUND(SUM(oi.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- 2. Monthly revenue and month-over-month growth (CTE + window function)
WITH monthly AS (
  SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
         SUM(oi.price) AS revenue
  FROM olist_orders_dataset o
  JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY month
)
SELECT month,
       ROUND(revenue,2) AS revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month) * 100, 1) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- 3. Top 10 categories by revenue (joins + RANK)
SELECT t.product_category_name_english AS category,
       ROUND(SUM(oi.price),2) AS revenue,
       RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
JOIN product_category_name_translation t
     ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;

-- 4. Repeat customers
WITH cust AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS orders
  FROM olist_orders_dataset o
  JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
SELECT SUM(orders > 1) AS repeat_customers,
       COUNT(*) AS total_customers,
       ROUND(100 * SUM(orders > 1) / COUNT(*), 1) AS repeat_pct
FROM cust;

-- 5. Do late deliveries get worse reviews?
SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late' ELSE 'On time' END AS delivery,
       COUNT(*) AS orders,
       ROUND(AVG(r.review_score),2) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery;

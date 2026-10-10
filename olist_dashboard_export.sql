-- Flat dataset for the Tableau dashboard: one row per item in a delivered order.
-- Blank review_score means the order had no review.
SELECT o.order_id,
       DATE(o.order_purchase_timestamp)                             AS order_date,
       DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')          AS order_month,
       c.customer_unique_id,
       c.customer_state,
       COALESCE(t.product_category_name_english, 'unknown')         AS category,
       oi.price,
       oi.freight_value,
       IFNULL(r.review_score, '')                                   AS review_score,
       CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late' ELSE 'On time' END                          AS delivery_status
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_customers_dataset c    ON o.customer_id = c.customer_id
LEFT JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
LEFT JOIN (SELECT order_id, ROUND(AVG(review_score), 2) AS review_score
           FROM olist_order_reviews_dataset GROUP BY order_id) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01';

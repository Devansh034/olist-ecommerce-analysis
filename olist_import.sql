-- olist_import.sql
-- Creates 8 tables in the `olist` database and loads the Olist CSV files into them.
-- The text __DIR__ is replaced with your folder path by the command in the instructions.
-- (The geolocation file is skipped on purpose: it is large and the project does not need it.)

SET GLOBAL local_infile = 1;
SET NAMES utf8mb4;
USE olist;

-- ---------- Start clean so the script can be re-run ----------
DROP TABLE IF EXISTS olist_customers_dataset;
DROP TABLE IF EXISTS olist_orders_dataset;
DROP TABLE IF EXISTS olist_order_items_dataset;
DROP TABLE IF EXISTS olist_order_payments_dataset;
DROP TABLE IF EXISTS olist_order_reviews_dataset;
DROP TABLE IF EXISTS olist_products_dataset;
DROP TABLE IF EXISTS olist_sellers_dataset;
DROP TABLE IF EXISTS product_category_name_translation;

-- ---------- Tables ----------
CREATE TABLE olist_customers_dataset (
  customer_id              VARCHAR(32) NOT NULL,
  customer_unique_id       VARCHAR(32),
  customer_zip_code_prefix VARCHAR(10),
  customer_city            VARCHAR(100),
  customer_state           VARCHAR(5),
  PRIMARY KEY (customer_id),
  KEY idx_customer_unique (customer_unique_id)
) DEFAULT CHARSET = utf8mb4;

CREATE TABLE olist_orders_dataset (
  order_id                      VARCHAR(32) NOT NULL,
  customer_id                   VARCHAR(32),
  order_status                  VARCHAR(20),
  order_purchase_timestamp      DATETIME,
  order_approved_at             DATETIME,
  order_delivered_carrier_date  DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME,
  PRIMARY KEY (order_id),
  KEY idx_orders_customer (customer_id)
) DEFAULT CHARSET = utf8mb4;

CREATE TABLE olist_order_items_dataset (
  order_id            VARCHAR(32) NOT NULL,
  order_item_id       INT NOT NULL,
  product_id          VARCHAR(32),
  seller_id           VARCHAR(32),
  shipping_limit_date DATETIME,
  price               DECIMAL(10,2),
  freight_value       DECIMAL(10,2),
  PRIMARY KEY (order_id, order_item_id),
  KEY idx_items_product (product_id),
  KEY idx_items_seller (seller_id)
) DEFAULT CHARSET = utf8mb4;

CREATE TABLE olist_order_payments_dataset (
  order_id             VARCHAR(32) NOT NULL,
  payment_sequential   INT,
  payment_type         VARCHAR(20),
  payment_installments INT,
  payment_value        DECIMAL(10,2),
  KEY idx_payments_order (order_id)
) DEFAULT CHARSET = utf8mb4;

CREATE TABLE olist_order_reviews_dataset (
  review_id               VARCHAR(32),
  order_id                VARCHAR(32),
  review_score            INT,
  review_comment_title    TEXT,
  review_comment_message  TEXT,
  review_creation_date    DATETIME,
  review_answer_timestamp DATETIME,
  KEY idx_reviews_order (order_id)
) DEFAULT CHARSET = utf8mb4;

CREATE TABLE olist_products_dataset (
  product_id                 VARCHAR(32) NOT NULL,
  product_category_name      VARCHAR(100),
  product_name_lenght        DECIMAL(10,2),
  product_description_lenght DECIMAL(10,2),
  product_photos_qty         DECIMAL(10,2),
  product_weight_g           DECIMAL(10,2),
  product_length_cm          DECIMAL(10,2),
  product_height_cm          DECIMAL(10,2),
  product_width_cm           DECIMAL(10,2),
  PRIMARY KEY (product_id)
) DEFAULT CHARSET = utf8mb4;

CREATE TABLE olist_sellers_dataset (
  seller_id              VARCHAR(32) NOT NULL,
  seller_zip_code_prefix VARCHAR(10),
  seller_city            VARCHAR(100),
  seller_state           VARCHAR(5),
  PRIMARY KEY (seller_id)
) DEFAULT CHARSET = utf8mb4;

CREATE TABLE product_category_name_translation (
  product_category_name         VARCHAR(100) NOT NULL,
  product_category_name_english VARCHAR(100),
  PRIMARY KEY (product_category_name)
) DEFAULT CHARSET = utf8mb4;

-- ---------- Load the data ----------
-- Blank values become NULL, and a stray carriage return at the end of a line is removed.

LOAD DATA LOCAL INFILE '__DIR__/olist_customers_dataset.csv'
INTO TABLE olist_customers_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, @state)
SET customer_state = TRIM(TRAILING '\r' FROM @state);

LOAD DATA LOCAL INFILE '__DIR__/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp      = NULLIF(@purchase, ''),
    order_approved_at             = NULLIF(@approved, ''),
    order_delivered_carrier_date  = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(TRIM(TRAILING '\r' FROM @estimated), '');

LOAD DATA LOCAL INFILE '__DIR__/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, @freight)
SET freight_value = NULLIF(TRIM(TRAILING '\r' FROM @freight), '');

LOAD DATA LOCAL INFILE '__DIR__/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, payment_sequential, payment_type, payment_installments, @value)
SET payment_value = NULLIF(TRIM(TRAILING '\r' FROM @value), '');

LOAD DATA LOCAL INFILE '__DIR__/olist_order_reviews_dataset.csv'
INTO TABLE olist_order_reviews_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, review_score, review_comment_title, review_comment_message, @created, @answered)
SET review_creation_date    = NULLIF(@created, ''),
    review_answer_timestamp = NULLIF(TRIM(TRAILING '\r' FROM @answered), '');

LOAD DATA LOCAL INFILE '__DIR__/olist_products_dataset.csv'
INTO TABLE olist_products_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @cat, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET product_category_name      = NULLIF(@cat, ''),
    product_name_lenght        = NULLIF(@name_len, ''),
    product_description_lenght = NULLIF(@desc_len, ''),
    product_photos_qty         = NULLIF(@photos, ''),
    product_weight_g           = NULLIF(@weight, ''),
    product_length_cm          = NULLIF(@length, ''),
    product_height_cm          = NULLIF(@height, ''),
    product_width_cm           = NULLIF(TRIM(TRAILING '\r' FROM @width), '');

LOAD DATA LOCAL INFILE '__DIR__/olist_sellers_dataset.csv'
INTO TABLE olist_sellers_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(seller_id, seller_zip_code_prefix, seller_city, @state)
SET seller_state = TRIM(TRAILING '\r' FROM @state);

LOAD DATA LOCAL INFILE '__DIR__/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_category_name, @english)
SET product_category_name_english = TRIM(TRAILING '\r' FROM @english);

-- ---------- Check: row counts ----------
-- Roughly expected: customers 99441, orders 99441, order_items 112650, payments 103886,
-- reviews ~99224, products 32951, sellers 3095, translation 71 to 73.
SELECT 'customers'   AS table_name, COUNT(*) AS row_count FROM olist_customers_dataset
UNION ALL SELECT 'orders',         COUNT(*) FROM olist_orders_dataset
UNION ALL SELECT 'order_items',    COUNT(*) FROM olist_order_items_dataset
UNION ALL SELECT 'payments',       COUNT(*) FROM olist_order_payments_dataset
UNION ALL SELECT 'reviews',        COUNT(*) FROM olist_order_reviews_dataset
UNION ALL SELECT 'products',       COUNT(*) FROM olist_products_dataset
UNION ALL SELECT 'sellers',        COUNT(*) FROM olist_sellers_dataset
UNION ALL SELECT 'translation',    COUNT(*) FROM product_category_name_translation;

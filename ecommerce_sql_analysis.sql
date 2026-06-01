USE Ecommerce;

-- ============================================================
-- ECOMMERCE SALES ANALYSIS - Complete SQL Scripts
-- Tools: SQL SERVER
-- Author: Nitesh Jangid
-- ============================================================

-- ============================================================
-- STEP 1: CREATE TABLES IN DATABASE
-- ============================================================

USE Ecommerce;

-- Customers Table
CREATE TABLE customers (
    customer_id     VARCHAR(10) PRIMARY KEY,
    customer_name   VARCHAR(100),
    city            VARCHAR(50),
    segment         VARCHAR(20),
    registration_date DATE
);

BULK INSERT customers
FROM "C:\Users\mrnj1\Downloads\Ecommerce_data\customers.csv"
WITH (
    FORMAT = 'CSV',         -- Required for SQL Server 2017 and later
    FIRSTROW = 2,           -- Skips the header row
    FIELDTERMINATOR = ',',  -- Character that separates columns
    ROWTERMINATOR = '\n'    -- Character that starts a new line
);

SELECT * FROM customers;

-- Products Table
CREATE TABLE products (
    product_id      VARCHAR(10) PRIMARY KEY,
    product_name    VARCHAR(100),
    category        VARCHAR(50),
    unit_price      DECIMAL(10,2),
    cost_price      DECIMAL(10,2)
);

BULK INSERT products
FROM "C:\Users\mrnj1\Downloads\Ecommerce_data\products.csv"
WITH (
    FORMAT = 'CSV',         
    FIRSTROW = 2,           
    FIELDTERMINATOR = ',',  
    ROWTERMINATOR = '\n'    
);

SELECT * FROM products;

-- Orders Table
CREATE TABLE orders (
    order_id        VARCHAR(10) PRIMARY KEY,
    customer_id     VARCHAR(10),
    order_date      DATE,
    channel         VARCHAR(20),
    status          VARCHAR(20),
    city            VARCHAR(50),
    discount_pct    INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

BULK INSERT orders
FROM "C:\Users\mrnj1\Downloads\Ecommerce_data\orders.csv"
WITH (
    FORMAT = 'CSV',         
    FIRSTROW = 2,           
    FIELDTERMINATOR = ',',  
    ROWTERMINATOR = '\n'    
);

SELECT * FROM orders;

-- Order Items Table
CREATE TABLE order_items (
    item_id         VARCHAR(10) PRIMARY KEY,
    order_id        VARCHAR(10),
    product_id      VARCHAR(10),
    product_name    VARCHAR(100),
    category        VARCHAR(50),
    quantity        INT,
    unit_price      DECIMAL(10,2),
    cost_price      DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

BULK INSERT order_items
FROM "C:\Users\mrnj1\Downloads\Ecommerce_data\order_items.csv"
WITH (
    FORMAT = 'CSV',         
    FIRSTROW = 2,           
    FIELDTERMINATOR = ',',  
    ROWTERMINATOR = '\n'    
);

SELECT * FROM order_items;



-- ============================================================
-- STEP 2: DATA VALIDATION & QUALITY CHECK
-- ============================================================

-- Check row counts
SELECT 'customers'   AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'products',    COUNT(*) FROM products
UNION ALL
SELECT 'orders',      COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

-- Check for NULL values in critical columns
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)   AS null_customer_id,
    SUM(CASE WHEN order_date  IS NULL THEN 1 ELSE 0 END)   AS null_order_date,
    SUM(CASE WHEN status      IS NULL THEN 1 ELSE 0 END)   AS null_status,
    SUM(CASE WHEN channel     IS NULL THEN 1 ELSE 0 END)   AS null_channel
FROM orders;

-- Check order status distribution
SELECT status, COUNT(*) AS order_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM orders
GROUP BY status
ORDER BY order_count DESC;

-- Check date range
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order FROM orders;


-- ============================================================
-- STEP 3: REVENUE & SALES OVERVIEW KPIs
-- ============================================================

-- Total Revenue, Orders, AOV (only Delivered orders)
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - oi.cost_price) * (1 - o.discount_pct/100.0)), 2) AS gross_profit,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) /
          COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    ROUND(SUM(oi.quantity * (oi.unit_price - oi.cost_price) * (1 - o.discount_pct/100.0)) /
          SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) * 100, 2) AS gross_margin_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered';


-- ============================================================
-- STEP 4: MONTHLY REVENUE TREND
-- ============================================================

SELECT
    FORMAT(o.order_date, 'yyyy-MM') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS monthly_revenue,
    ROUND(AVG(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS avg_order_value,
    LAG(ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)),2))
        OVER (ORDER BY FORMAT(o.order_date, 'yyyy-MM')) AS prev_month_revenue,
    ROUND(
        (SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) -
         LAG(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)))
             OVER (ORDER BY FORMAT(o.order_date, 'yyyy-MM'))) /
        NULLIF(LAG(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)))
             OVER (ORDER BY FORMAT(o.order_date, 'yyyy-MM')), 0) * 100, 2) AS mom_growth_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY FORMAT(o.order_date, 'yyyy-MM')
ORDER BY month;


-- ============================================================
-- STEP 5: CATEGORY PERFORMANCE
-- ============================================================

SELECT
    oi.category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - oi.cost_price) * (1 - o.discount_pct/100.0)), 2) AS gross_profit,
    ROUND(SUM(oi.quantity * (oi.unit_price - oi.cost_price) * (1 - o.discount_pct/100.0)) /
          SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) * 100, 2) AS margin_pct,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) /
          SUM(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0))) OVER() * 100, 2) AS revenue_share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY oi.category
ORDER BY total_revenue DESC;


-- ============================================================
-- STEP 6: TOP 10 PRODUCTS BY REVENUE
-- ============================================================

SELECT TOP 10
    oi.product_name,
    oi.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - oi.cost_price) * (1 - o.discount_pct/100.0)), 2) AS gross_profit,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) DESC) AS revenue_rank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY oi.product_name, oi.category
ORDER BY revenue_rank;


-- ============================================================
-- STEP 7: CHANNEL PERFORMANCE ANALYSIS
-- ============================================================

SELECT
    o.channel,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) /
          COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) /
          SUM(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0))) OVER() * 100, 2) AS revenue_share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY o.channel
ORDER BY total_revenue DESC;


-- ============================================================
-- STEP 8: CITY-WISE SALES PERFORMANCE
-- ============================================================

SELECT
    o.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)) /
          COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY o.city
ORDER BY total_revenue DESC;


-- ============================================================
-- STEP 9: CUSTOMER SEGMENTATION — RFM ANALYSIS
-- ============================================================

-- 9A: Calculate Raw RFM Scores per Customer
WITH rfm_base AS (
    SELECT
        o.customer_id,
        c.customer_name,
        c.city,
        c.segment,
        DATEDIFF(DAY,MAX(o.order_date), '2024-01-01') AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)),2) AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c    ON o.customer_id = c.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id, c.customer_name, c.city, c.segment
    ),

-- 9B: Score R, F, M on 1-5 scale using NTILE
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,  -- lower recency = better
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
),

-- 9C: Combined RFM Score & Segment Label
rfm_labeled AS (
    SELECT *,
        CONCAT(r_score, f_score, m_score)           AS rfm_score,
        (r_score + f_score + m_score)               AS total_score,
        CASE
            WHEN (r_score + f_score + m_score) >= 13                THEN 'Champions'
            WHEN r_score >= 4 AND f_score >= 3                      THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score <= 2                      THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3     THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 4                      THEN 'Cannot Lose Them'
            WHEN r_score >= 4 AND f_score = 1                       THEN 'New Customers'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2     THEN 'Lost Customers'
            ELSE 'Needs Attention'
        END AS rfm_segment
    FROM rfm_scores
)

SELECT
    rfm_segment,
    COUNT(*)                        AS customer_count,
    ROUND(AVG(recency_days),1)      AS avg_recency_days,
    ROUND(AVG(frequency),1)         AS avg_orders,
    ROUND(AVG(monetary),2)          AS avg_revenue,
    ROUND(SUM(monetary),2)          AS total_revenue
FROM rfm_labeled
GROUP BY rfm_segment
ORDER BY total_revenue DESC;


-- 9D: Export Full RFM Table for Power BI
WITH rfm_base AS (
    SELECT o.customer_id, c.customer_name, c.city, c.segment,
        DATEDIFF(DAY,MAX(o.order_date),'2024-01-01') AS recency_days,
        COUNT(DISTINCT o.order_id)                AS frequency,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)),2) AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c    ON o.customer_id = c.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id, c.customer_name, c.city, c.segment
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)     AS m_score
    FROM rfm_base
)
SELECT *,
    (r_score + f_score + m_score) AS total_score,
    CASE
        WHEN (r_score + f_score + m_score) >= 13                THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3                      THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score <= 2                      THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3     THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 4                      THEN 'Cannot Lose Them'
        WHEN r_score >= 4 AND f_score = 1                       THEN 'New Customers'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2     THEN 'Lost Customers'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM rfm_scores
ORDER BY total_score DESC;


-- ============================================================
-- STEP 10: COHORT ANALYSIS
-- (Which customer groups retained best over time?)
-- ============================================================

WITH first_order AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date,
        FORMAT(MIN(order_date), 'yyyy-MM') AS cohort_month
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),

orders_with_cohort AS (
    SELECT
        o.customer_id,

        fo.cohort_month,

        FORMAT(o.order_date, 'yyyy-MM') AS order_month,

        DATEDIFF(
            MONTH,
            fo.first_order_date,
            o.order_date
        ) AS month_number

    FROM orders o
    JOIN first_order fo 
        ON o.customer_id = fo.customer_id

    WHERE o.status = 'Delivered'
)

SELECT
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_id) AS active_customers

FROM orders_with_cohort

GROUP BY 
    cohort_month,
    month_number

ORDER BY 
    cohort_month,
    month_number;

-- Cohort Size (for retention % calculation in Power BI)
SELECT
    FORMAT(MIN(order_date), 'yyyy-MM') AS cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size
FROM orders
WHERE status = 'Delivered'
GROUP BY customer_id
ORDER BY cohort_month;


-- ============================================================
-- STEP 11: RETURN RATE ANALYSIS
-- ============================================================

SELECT
    oi.category,
    COUNT(CASE WHEN o.status = 'Delivered' THEN 1 END)  AS delivered_orders,
    COUNT(CASE WHEN o.status = 'Returned'  THEN 1 END)  AS returned_orders,
    ROUND(COUNT(CASE WHEN o.status = 'Returned' THEN 1 END) * 100.0 /
          NULLIF(COUNT(*),0), 2)                         AS return_rate_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY oi.category
ORDER BY return_rate_pct DESC;


-- ============================================================
-- STEP 12: REVENUE FORECASTING BASE DATA
-- (Export this to Excel for 3-month moving average forecast)
-- ============================================================

SELECT
    FORMAT(o.order_date, 'yyyy-MM') AS month,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)), 2) AS monthly_revenue,
    COUNT(DISTINCT o.order_id)                                               AS total_orders,
    COUNT(DISTINCT o.customer_id)                                            AS active_customers
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY FORMAT(o.order_date, 'yyyy-MM')
ORDER BY month;


-- ============================================================
-- STEP 13: CUSTOMER LIFETIME VALUE (CLV)
-- ============================================================

WITH customer_stats AS (
    SELECT TOP 20
        o.customer_id,
        c.customer_name,
        c.segment,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - o.discount_pct/100.0)),2) AS total_revenue,
        ROUND(SUM(oi.quantity * (oi.unit_price - oi.cost_price) * (1 - o.discount_pct/100.0)),2) AS total_profit,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) AS customer_lifespan_days
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c    ON o.customer_id = c.customer_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id, c.customer_name, c.segment
)
SELECT *,
    ROUND(total_revenue / total_orders, 2)   AS avg_order_value,
    ROUND(total_profit  / total_orders, 2)   AS avg_profit_per_order,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS clv_rank
FROM customer_stats
ORDER BY total_revenue DESC;


-- ============================================================
-- END OF SCRIPT
-- ============================================================

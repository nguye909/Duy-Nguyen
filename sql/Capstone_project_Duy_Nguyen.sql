/* ============================================================
   CAPSTONE PROJECT: XMAS GIFT SALES ANALYSIS
   Student: Duy Nguyen
   Dataset: FP20Analytics Challenge 12
   Database: fp20c12

   ============================================================ */

USE fp20c12;
GO

/* ============================================================
   Sales information by Xmas season:
   Revenue, Quantity Sold, Cost, Profit
   ============================================================ */

;WITH xmas_sales AS
(
    SELECT

        -- Bổ sung thông tin về thời gian

        CASE
            WHEN MONTH([date]) = 1
                THEN YEAR([date]) - 1
            ELSE YEAR([date])
        END AS xmas_year,

        CASE
            WHEN MONTH([date]) = 1
                THEN CONCAT(YEAR([date]) - 1, '-', YEAR([date]))
            ELSE CONCAT(YEAR([date]), '-', YEAR([date]) + 1)
        END AS xmas_season,

        YEAR([date]) AS [year],

        EOMONTH([date]) AS end_date_of_month,

        DATEPART(WEEKDAY, [date]) AS [weekday],

        CASE DATEPART(WEEKDAY, [date])
            WHEN 1 THEN 'Sunday'
            WHEN 2 THEN 'Monday'
            WHEN 3 THEN 'Tuesday'
            WHEN 4 THEN 'Wednesday'
            WHEN 5 THEN 'Thursday'
            WHEN 6 THEN 'Friday'
            WHEN 7 THEN 'Saturday'
        END AS weekday_name,

        DATEPART(HOUR, [time]) AS [hour],

        *

    FROM dbo.xmas_sales AS s

    WHERE EOMONTH([date]) <> '2018-01-31'
),

s AS
(
    SELECT
        xmas_year,
        xmas_season,
        SUM(total_sales) AS sales,
        SUM(quantity) AS quantity,
        SUM(cost) AS cost,
        SUM(profit) AS profit

    FROM xmas_sales

    GROUP BY
        xmas_year,
        xmas_season
)

SELECT
    xmas_year,
    xmas_season,

    ROUND(
        sales / POWER(10, 6),
        2
    ) AS sales,

    ROUND(
        quantity * 1.0 / POWER(10, 3),
        1
    ) AS quantity,

    ROUND(
        cost / POWER(10, 6),
        2
    ) AS cost,

    ROUND(
        profit / POWER(10, 6),
        2
    ) AS profit

FROM s;


/* ============================================================
   Growth of revenue, quantity and profit for the latest
   Xmas season vs the previous season
   ============================================================ */
GO
SELECT * FROM dbo.v_xmas_sales

--
SELECT MAX(xmas_year) FROM dbo.v_xmas_sales -- 2021

; WITH s AS (
    SELECT xmas_year, xmas_season,
           SUM(total_sales) AS sales,
           SUM(quantity) AS quantity,
           SUM(cost) AS cost,
           SUM(profit) AS profit
    FROM dbo.v_xmas_sales
    GROUP BY xmas_year, xmas_season
), r AS (
    SELECT
        s.xmas_year,
        s.xmas_season,
        s.sales,
        prev.sales AS sales_prev_season,
        (s.sales - prev.sales) / prev.sales AS sales_growth_percentage,

        s.quantity,
        prev.quantity AS quantity_prev_season,
        (s.quantity - prev.quantity) * 1.0 / prev.quantity AS quantity_growth_percentage,

        s.profit,
        prev.profit AS profit_prev_season,
        (s.profit - prev.profit) / prev.profit AS profit_growth_percentage

    FROM s, s prev
    WHERE s.xmas_year = (SELECT MAX(xmas_year) FROM dbo.v_xmas_sales)
      AND prev.xmas_year = s.xmas_year - 1
)

SELECT
    xmas_year,
    xmas_season,
    ROUND(sales / POWER(10, 6), 2) AS sales,
    ROUND(sales_prev_season / POWER(10, 6), 2) AS sales_prev_season,
    ROUND(sales_growth_percentage, 3) AS sales_growth_percentage,

    ROUND(quantity / POWER(10, 3), 1) AS quantity,
    ROUND(quantity_prev_season / POWER(10, 3), 1) AS quantity_prev_season,
    ROUND(quantity_growth_percentage, 3) AS quantity_growth_percentage,

    ROUND(profit / POWER(10, 6), 2) AS profit,
    ROUND(profit_prev_season / POWER(10, 6), 2) AS profit_prev_season,
    ROUND(profit_growth_percentage, 3) AS profit_growth_percentage

FROM r
/* ============================================================
   Revenue growth across each Xmas season
   ============================================================ */

;WITH s AS (
    SELECT xmas_year, xmas_season, SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY xmas_year, xmas_season
)

SELECT
    s.xmas_year,
    s.xmas_season,
    ROUND(s.sales / POWER(10, 6), 2) AS sales,
    ROUND(prev.sales / POWER(10, 6), 2) AS sales_prev_season,
    ROUND((s.sales - prev.sales) / prev.sales, 3) AS growth_yoy
FROM s
JOIN s prev ON s.xmas_year = prev.xmas_year + 1


/* ============================================================
   Revenue and revenue contribution % by purchase_type
   for each Xmas season
   ============================================================ */

;WITH xmas_season_sales AS (
    SELECT xmas_year, xmas_season, SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY xmas_year, xmas_season
),
s AS (
    SELECT xmas_year, purchase_type, SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY xmas_year, purchase_type
)

SELECT
    x.xmas_year,
    x.xmas_season,
    s.purchase_type,
    ROUND(s.sales / POWER(10, 6), 2) AS sales,
    ROUND(x.sales / POWER(10, 6), 6) AS total_sales,
    ROUND(s.sales / x.sales, 3) AS sales_ratio
FROM s
JOIN xmas_season_sales x ON s.xmas_year = x.xmas_year
ORDER BY x.xmas_year, s.purchase_type


/* ============================================================
   Revenue by country and city
   ============================================================ */

-- Sales by country
SELECT country, ROUND(SUM(total_sales) / POWER(10, 6), 2) AS sales
FROM dbo.v_xmas_sales
GROUP BY country
ORDER BY sales DESC

-- Sales by city
SELECT country, city, ROUND(SUM(total_sales) / POWER(10, 6), 2) AS sales
FROM dbo.v_xmas_sales
GROUP BY country, city
ORDER BY country, sales DESC


/* ============================================================
   Rank countries by latest Xmas season:
   A. Revenue
   B. Revenue growth %
   ============================================================ */

;WITH s AS (
    SELECT
        xmas_year,
        xmas_season,
        country,
        SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY xmas_year, xmas_season, country
)

SELECT
    s.xmas_year,
    s.xmas_season,
    s.country,
    ROUND(s.sales / POWER(10, 6), 2) AS sales,
    ROUND(prev.sales / POWER(10, 6), 2) AS prev_sales,
    (s.sales - prev.sales) / prev.sales AS sales_growth_percentage
FROM s
LEFT JOIN s prev
    ON s.xmas_year = prev.xmas_year + 1
    AND s.country = prev.country
WHERE s.xmas_year = (
    SELECT MAX(xmas_year)
    FROM dbo.v_xmas_sales
)
ORDER BY xmas_year, sales DESC

/* ============================================================
   Revenue share by age, gender, purchase type
   ============================================================ */
-- the data got customer_age_range written wrong
-- By age
DECLARE @total_sales DECIMAL(18, 0) = (SELECT SUM(total_sales) FROM dbo.v_xmas_sales);

SELECT
    customer_age_tange AS customer_age_range,
    SUM(total_sales) AS sales,
    SUM(total_sales) * 1.0 / @total_sales AS sales_proportion
FROM dbo.v_xmas_sales
GROUP BY customer_age_tange
ORDER BY customer_age_range;


-- By gender

SELECT
    gender,
    SUM(total_sales) AS sales,
    SUM(total_sales) * 1.0 / @total_sales AS sales_proportion
FROM dbo.v_xmas_sales
GROUP BY gender
ORDER BY gender;


-- By purchase type
SELECT
    purchase_type,
    SUM(total_sales) AS sales,
    SUM(total_sales) * 1.0 / @total_sales AS sales_proportion
FROM dbo.v_xmas_sales
GROUP BY purchase_type
ORDER BY purchase_type;

/* ============================================================
   Sales proportion by:
   A. purchase_type within each age group
   B. payment_method within each age group
   ============================================================ */
-- A. Calculate sales proportion by purchase type for each age group
;WITH t AS (
    SELECT
        customer_age_tange AS customer_age_range,
        SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY customer_age_tange
),
s AS (
    SELECT
        customer_age_tange AS customer_age_range,
        purchase_type,
        SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY customer_age_tange, purchase_type
)

SELECT
    s.customer_age_range,
    s.purchase_type,
    ROUND(s.sales / POWER(10, 6), 2) AS sales,
    ROUND(t.sales / POWER(10, 6), 2) AS total_sales,
    ROUND(s.sales / t.sales, 3) AS sales_proportion
FROM s
LEFT JOIN t
    ON s.customer_age_range = t.customer_age_range
ORDER BY customer_age_range, purchase_type;

-- B. Calculate sales proportion by payment method for each age group
;WITH t AS (
    SELECT
        customer_age_tange AS customer_age_range,
        SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY customer_age_tange
),
s AS (
    SELECT
        customer_age_tange AS customer_age_range,
        payment_method,
        SUM(total_sales) AS sales
    FROM dbo.v_xmas_sales
    GROUP BY customer_age_tange, payment_method
)

SELECT
    s.customer_age_range,
    s.payment_method,
    ROUND(s.sales / POWER(10, 6), 2) AS sales,
    ROUND(t.sales / POWER(10, 6), 2) AS total_sales,
    ROUND(s.sales / t.sales, 3) AS sales_proportion
FROM s
LEFT JOIN t
    ON s.customer_age_range = t.customer_age_range
ORDER BY customer_age_range, payment_method;


/* ============================================================
   Sales analysis by category and product
   ============================================================ */

DECLARE @total_sales DECIMAL(18, 0) =
    (SELECT SUM(total_sales) FROM dbo.v_xmas_sales);
-- By product category
;WITH s AS (
    SELECT
        product_category,
        SUM(total_sales) AS sales,
        AVG(unit_price) AS avg_unit_price,
        SUM(profit) AS profit,
        SUM(profit) / SUM(total_sales) AS profit_ratio
    FROM dbo.v_xmas_sales
    GROUP BY product_category
)

SELECT
    product_category,
    ROUND(s.sales / POWER(10, 6), 2) AS sales,
    ROUND(sales / @total_sales, 3) AS sales_proportion,
    ROUND(avg_unit_price, 2) AS avg_unit_price,
    ROUND(profit_ratio, 4) AS profit_ratio
FROM s
ORDER BY product_category;


-- Analyze by product

;WITH s AS (
    SELECT
        product_category,
        product_name,
        SUM(total_sales) AS sales,
        SUM(quantity) AS quantity,
        MIN(unit_price) AS min_unit_price,
        MAX(unit_price) AS max_unit_price,
        AVG(unit_price) AS avg_unit_price,
        SUM(profit) AS profit,
        SUM(profit) / SUM(total_sales) AS profit_ratio
    FROM dbo.v_xmas_sales
    GROUP BY product_category, product_name
)

SELECT
    product_category,
    ROUND(s.sales / POWER(10, 6), 2) AS sales,
    ROUND(sales / @total_sales, 3) AS sales_proportion,
    quantity,
    ROUND(min_unit_price, 2) AS min_unit_price,
    ROUND(max_unit_price, 2) AS max_unit_price,
    ROUND(avg_unit_price, 2) AS avg_unit_price,
    ROUND(profit_ratio, 4) AS profit_ratio
FROM s
ORDER BY product_category,product_name

/* ============================================================
   Which weekdays do male/female customers shop most?
   Which hours do customers shop most?
   ============================================================ */

-- Orders by gender and weekday
SELECT
    gender,
    weekday,
    weekday_name,
    COUNT(*) AS nb_orders
FROM dbo.v_xmas_sales
GROUP BY gender, weekday, weekday_name
ORDER BY gender, weekday;


-- Orders by hour
SELECT
    [hour],
    COUNT(*) AS nb_orders
FROM dbo.v_xmas_sales
GROUP BY [hour]
ORDER BY [hour];
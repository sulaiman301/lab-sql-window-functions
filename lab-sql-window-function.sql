USE sakila;

-- Challenge 1: Using the SQL RANK() function

--  1: Rank films by their length
SELECT 
    title,
    length,
    RANK() OVER (ORDER BY length DESC) AS length_rank
FROM film
WHERE length IS NOT NULL AND length > 0;

--  2: Rank films by length within the rating category

SELECT 
    title,
    length,
    rating,
    RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS length_rank_within_rating
FROM film
WHERE length IS NOT NULL AND length > 0;

-- 3: List actors/actresses with the greatest number of films
-- First, create a temporary table or a CTE to calculate the number of films each actor has acted in.
-- Temporary Table
-- Create a temporary table to calculate actor film counts
CREATE TEMPORARY TABLE IF NOT EXISTS actor_film_count AS
SELECT 
    fa.film_id,
    COUNT(*) AS film_count
FROM film_actor fa
GROUP BY fa.film_id;

-- Query to find the actor with the highest film count per film
SELECT 
    f.title,
    af.actor_name,
    af.film_count
FROM film f
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN (
    SELECT 
        af.film_id,
        fa.actor_id,
        af.film_count,
        ROW_NUMBER() OVER (PARTITION BY af.film_id ORDER BY af.film_count DESC) AS rn
    FROM (
        SELECT 
            fa.film_id,
            fa.actor_id,
            COUNT(*) AS film_count
        FROM film_actor fa
        GROUP BY fa.film_id, fa.actor_id
    ) AS af
) AS af ON fa.film_id = af.film_id AND fa.actor_id = af.actor_id
WHERE af.rn = 1;

-- Challenge 2: Analyzing Customer Activity and Retention

--  1: Retrieve the number of monthly active customers

SELECT 
    DATE_FORMAT(r.rental_date, '%Y-%m') AS month,
    COUNT(DISTINCT r.customer_id) AS active_customers
FROM rental r
GROUP BY DATE_FORMAT(r.rental_date, '%Y-%m');

--  2: Retrieve the number of active users in the previous month
-- Using a CTE to calculate the previous month's active customers:

WITH monthly_active AS (
    SELECT 
        DATE_FORMAT(r.rental_date, '%Y-%m') AS month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY DATE_FORMAT(r.rental_date, '%Y-%m')
),
previous_month AS (
    SELECT 
        month,
        LAG(active_customers, 1) OVER (ORDER BY month) AS previous_month_customers
    FROM monthly_active
)
SELECT 
    ma.month,
    ma.active_customers,
    pm.previous_month_customers
FROM monthly_active ma
JOIN previous_month pm ON ma.month = pm.month;

--  3: Calculate the percentage change in the number of active customers
WITH monthly_active AS (
    SELECT 
        DATE_FORMAT(r.rental_date, '%Y-%m') AS month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY DATE_FORMAT(r.rental_date, '%Y-%m')
),
previous_month AS (
    SELECT 
        month,
        active_customers,
        LAG(active_customers, 1) OVER (ORDER BY month) AS previous_month_customers
    FROM monthly_active
)
SELECT 
    month,
    active_customers,
    previous_month_customers,
    ROUND(((active_customers - previous_month_customers) / previous_month_customers) * 100, 2) AS percent_change
FROM previous_month
WHERE previous_month_customers IS NOT NULL;


--  4: Calculate the number of retained customers every month
WITH monthly_customers AS (
    SELECT 
        customer_id,
        DATE_FORMAT(rental_date, '%Y-%m') AS month
    FROM rental
    GROUP BY customer_id, DATE_FORMAT(rental_date, '%Y-%m')
),
current_and_previous AS (
    SELECT 
        mc1.month AS current_month,
        mc2.month AS previous_month,
        mc1.customer_id
    FROM monthly_customers mc1
    JOIN monthly_customers mc2 ON mc1.customer_id = mc2.customer_id
    AND mc1.month = DATE_FORMAT(DATE_ADD(STR_TO_DATE(mc2.month, '%Y-%m'), INTERVAL 1 MONTH), '%Y-%m')
)
SELECT 
    current_month,
    COUNT(DISTINCT customer_id) AS retained_customers
FROM current_and_previous
GROUP BY current_month;





SELECT @@hostname;
CREATE DATABASE masters;
use masters;
CREATE TABLE orders (
    order_id INT primary key,
    order_date DATE,
    ship_mode VARCHAR(20),
    segment VARCHAR(20),
    country VARCHAR(20),
    city VARCHAR(20),
    state VARCHAR(20),
    postal_code INT,
    region VARCHAR(20),
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_id VARCHAR(50),
    quantity INT,
    discount_price decimal(7,2),
    sales_price decimal(7,2),
    profit decimal(7,2)
);
use masters;
select * from orders;

-- question

-- 1. find top 10 highest revenue generating product-- 
select product_id, sum(sales_price) as sales
from orders
group by product_id
order by sales desc
limit 10;

-- 2. find top 5 highest  selling product in each region 
select region,product_id,sum(sales_price) as sales
from orders
group by region,product_id
order by region,sales desc
limit 5;

WITH RankedProducts AS (
    SELECT
        region,
        product_id,
        SUM(sales_price) AS sales,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sales_price) DESC) AS sales_rank
    FROM orders
    GROUP BY region, product_id
)
SELECT
    region,
    product_id,
    sales
FROM RankedProducts
WHERE sales_rank <= 5
ORDER BY region, sales_rank
limit 5;


SELECT 
    region,
    product_id,
    sales
FROM
    (SELECT 
        region, 
        product_id, 
        SUM(sales_price) AS sales,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sales_price) DESC) AS sales_rank
    FROM
        orders
    GROUP BY 
        region, product_id
    ) AS rankproduct
WHERE 
    sales_rank <= 5;
    
--  3. find month over month  growth comparison  for 2022  and 2023 sales eg:   jan 2022 vs jan 2023
select * from orders;

-- -- WITH MonthlySales AS (
--     SELECT
--         DATE_FORMAT(order_date, '%Y-%m') AS month,
--         YEAR(order_date) AS year,
--         SUM(sales_price) AS total_sales
--     FROM orders
--     WHERE YEAR(order_date) IN (2022, 2023)
--     GROUP BY DATE_FORMAT(order_date, '%Y-%m'), YEAR(order_date);
-- -- ),
with cte as (
select year(order_date) as order_year, month(order_date) as order_month, sum(sales_price) as sales
from orders
group by order_year,order_month
-- order by order_year,order_month
	)
select order_month
, sum(case when order_year = 2022 then sales else 0 end) as 2022_sales
,sum(case when order_year = 2023 then sales else 0 end) as 2023_sales
from cte
group by order_month
order by order_month;

-- 4. for each category which month had highest sales
with cte as (
select category,DATE_FORMAT(order_date, '%Y%m') AS order_year_month, sum(sales_price) as sales
from orders
group by category,DATE_FORMAT(order_date, '%Y%m') 
order by category,DATE_FORMAT(order_date, '%Y%m')
)
select * from(
	select *,
	row_number()  over(partition by category order  by sales desc) as rn
	from cte) as a
where rn =1;

-- 5. which sub category had highest  growth  by profit in 2023 compare to 2022-- 

with cte as (
select sub_category, year(order_date) as order_year, sum(sales_price) as sales
from orders
group by  sub_category,order_year
-- order by order_year,order_month
	)
, cte2 as(
select sub_category
, sum(case when order_year = 2022 then sales else 0 end) as 2022_sales
,sum(case when order_year = 2023 then sales else 0 end) as 2023_sales
from cte
group by sub_category
order by sub_category
)
select *
,(2023_sales - 2022_sales)*100/2022_sales as "%growth"
from cte2
order by (2023_sales - 2022_sales)*100/2022_sales  desc
limit 1;







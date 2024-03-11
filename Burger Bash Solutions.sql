--importing data from csv
SELECT * FROM burger_bash.runner_orders;
SELECT * FROM burger_bash.customer_orders;

--Data Cleaning

--Replacing the 'null' values with null and creating a new table for runner_orders
SELECT order_id,runner_id,
CASE 
WHEN pickup_time='null' THEN NULL
ELSE pickup_time
END AS pickup_time,
CASE 
WHEN distance='null' THEN NULL
ELSE distance
END AS distance,
CASE 
WHEN duration='null' THEN NULL
ELSE duration
END AS duration,
CASE 
WHEN cancellation='null' THEN NULL
ELSE cancellation
END AS cancellation
INTO burger_bash.cleaned_runner_orders
FROM burger_bash.runner_orders;

--Changing the data type of pickup_time column to timestamp
ALTER TABLE burger_bash.cleaned_runner_orders
ALTER COLUMN pickup_time
TYPE TIMESTAMP
USING pickup_time::TIMESTAMP;

----Replacing the 'null' values with null and creating a new table for customer_orders

SELECT * FROM burger_bash.customer_orders;

SELECT order_id,customer_id,burger_id,
CASE
WHEN exclusions='null' THEN null
ELSE exclusions
END AS exclusions,
CASE
WHEN extras='null' THEN null
ELSE extras
END AS extras,
order_time
INTO burger_bash.cleaned_customer_orders
FROM burger_bash.customer_orders;

--Removing text from order_time column and creating a new table
SELECT order_id,customer_id,burger_id,exclusions,extras,
LEFT(CONCAT(SUBSTRING(order_time,1,POSITION('T' IN order_time)-1),' ',SUBSTRING(order_time,POSITION('T' IN order_time)+1)),
			LENGTH(order_time)-5) AS order_time
			INTO burger_bash.new_customer_orders
FROM burger_bash.cleaned_customer_orders;

--Converting order time column to timestamp
ALTER TABLE burger_bash.new_customer_orders
ALTER COLUMN order_time
TYPE TIMESTAMP
USING order_time::TIMESTAMP;

--Renaming cleaned runner orders table
ALTER TABLE burger_bash.cleaned_runner_orders
RENAME TO new_runner_orders;

CREATE TABLE burger_bash.burger_name(
burger_id INT,
burger_name VARCHAR(30));

INSERT INTO burger_bash.burger_name
VALUES
(1,'meatlovers'),
(2,'vegetarian');

CREATE TABLE burger_bash.burger_runners(
runner_id INT,
registration_date DATE);

INSERT INTO burger_bash.burger_runners
VALUES
(1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');

--Now the 4 tables that we will use are:
SELECT * FROM burger_bash.new_customer_orders;
SELECT * FROM burger_bash.new_runner_orders;
SELECT * FROM burger_bash.burger_name;
SELECT * FROM burger_bash.runner_orders;

--Questions

--1)How many burgers were ordered?
SELECT COUNT(order_id) AS total_burgers_ordered
FROM burger_bash.new_customer_orders;

--2)How many unique customer orders were made?
SELECT COUNT(DISTINCT(customer_id))
FROM burger_bash.new_customer_orders;

--3)How many successful orders were delivered by each runner?
SELECT runner_id,COUNT(order_id) AS "sucessfull orders delivered"
FROM burger_bash.new_runner_orders
WHERE cancellation IS null
GROUP BY runner_id;

--4)How many of each type of burger was delivered?
SELECT x.burger_id,y.burger_name,COUNT(*) 
FROM
(SELECT nco.order_id,nco.burger_id,nro.cancellation
FROM burger_bash.new_customer_orders AS nco
INNER JOIN burger_bash.new_runner_orders AS nro
ON nco.order_id=nro.order_id 
WHERE nro.cancellation IS NULL)AS x
INNER JOIN burger_bash.burger_name AS y
ON x.burger_id=y.burger_id
GROUP BY x.burger_id,y.burger_name;

--5)How many Vegetarian and Meatlovers were ordered by each customer?
SELECT nco.customer_id,bn.burger_id,bn.burger_name,COUNT(*) AS "total delivered"
FROM burger_bash.new_customer_orders nco,burger_bash.burger_name bn
WHERE nco.burger_id=bn.burger_id
GROUP BY nco.customer_id,bn.burger_id,bn.burger_name
ORDER BY nco.customer_id;

--6)What was the maximum number of burgers delivered in a single order?
SELECT "total_burgers_delivered" AS "maximum burgers delivered in single order"
FROM
(SELECT order_id,COUNT(*) AS total_burgers_delivered
FROM burger_bash.new_customer_orders
GROUP BY order_id
ORDER BY COUNT(*) DESC
LIMIT 1);

--7)For each customer, how many delivered burgers had at least 1 change and how many had no changes?
SELECT customer_id,
SUM(CASE WHEN exclusions=NULL AND extras=NULL THEN 1
ELSE 0
END) AS no_change,
SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1
ELSE 0
END) AS atleast_one_change
FROM
(SELECT nco.order_id,nco.customer_id,nco.exclusions,nco.extras,nro.cancellation
FROM burger_bash.new_customer_orders nco,burger_bash.new_runner_orders nro
WHERE nco.order_id=nro.order_id AND nro.cancellation IS NULL)
GROUP BY customer_id;

--8)What was the total volume of burgers ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS "hour",COUNT(*) AS total_burgers_ordered
FROM burger_bash.new_customer_orders
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY EXTRACT(HOUR FROM order_time);

--9)How many runners signed up for each 1 week period?
WITH my_cte AS
(SELECT EXTRACT(MONTH FROM pickup_time) AS days,COUNT(DISTINCT(runner_id)) AS number_of_runner
FROM burger_bash.new_runner_orders
WHERE cancellation IS NULL
GROUP BY days
ORDER BY days
)
SELECT 
CAST(CASE WHEN days<=7 THEN 'week1'
	ELSE 'week2'
	END AS VARCHAR(20)) AS week,
	SUM(number_of_runner) AS total_runner_signedup
	FROM my_cte
	GROUP BY week;
	
--10)What was the average distance travelled for each customer?
SELECT * FROM burger_bash.new_runner_orders;

SELECT customer_id,ROUND(SUM(distance::DECIMAL)/COUNT(customer_id),2) AS "average distance(km)"
FROM
(SELECT nco.order_id,nro.runner_id,nco.customer_id,TRIM('km' FROM distance) AS distance
FROM burger_bash.new_runner_orders AS nro
INNER JOIN burger_bash.new_customer_orders AS nco
ON nro.order_id=nco.order_id
WHERE nro.cancellation IS NULL)
GROUP BY customer_id
ORDER BY customer_id;






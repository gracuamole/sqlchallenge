````sql
USE pizza_runner;
````

# Data Cleaning and Preparation
Summary of data manipulation queries done:
- Remove NaN / NULL values and replace with blanks
- Convert VARCHAR columns to DATETIME, FLOAT, INT types
- Remove units from cells (eg 'km' or 'minutes')

````sql
CREATE TEMPORARY TABLE customer_orders_temporary
SELECT
	order_id,
    customer_id,
    pizza_id,
    CASE
		WHEN exclusions IS null OR exclusions LIKE 'null'
        THEN ' '
        ELSE exclusions
        END AS exclusions,
	CASE
		WHEN extras is null OR extras LIKE 'null'
        THEN ' '
        ELSE extras
        END AS extras,
	order_time
FROM customer_orders;
````

````sql
SELECT * FROM customer_orders_temporary;
````

-- check for NULLs --
````sql
SELECT * FROM runner_orders
WHERE pickup_time IS NULL OR pickup_time LIKE 'null' 
OR distance IS NULL OR distance LIKE 'null'
OR duration IS NULL OR duration LIKE 'null'
OR cancellation IS NULL OR cancellation LIKE 'null';
````

````sql
SELECT * FROM runner_orders;
````

````sql
CREATE TEMPORARY TABLE runner_orders_temporary
SELECT order_id,
runner_id,
CASE
	WHEN pickup_time LIKE 'null' THEN NULL
    ELSE pickup_time
    END AS pickup_time,
CASE
		WHEN distance IS NULL OR distance LIKE 'null' THEN ' '
        WHEN distance LIKE '%km' THEN TRIM('km' from distance)
        ELSE distance
        END AS distance,
	CASE
		WHEN duration IS NULL OR duration LIKE 'null' THEN ' '
        WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
        WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
        WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
        ELSE duration
        END AS duration,
	CASE
		WHEN cancellation IS NULL OR cancellation LIKE 'null' 
        THEN ' '
        ELSE cancellation
        END AS cancellation
FROM runner_orders;
````

````sql
UPDATE runner_orders_temporary
SET pickup_time = STR_TO_DATE(pickup_time, '%Y-%m-%d %H:%i:%s'),
distance = CAST(distance AS float),
duration = CAST(duration AS UNSIGNED);
````

````sql
UPDATE runner_orders_temporary
SET pickup_time = ' '
WHERE pickup_time IS NULL;

UPDATE runner_orders_temporary
SET distance = ' '
WHERE distance = 0;

SELECT * FROM runner_orders_temporary;
````

# Case Study 2: A Pizza Metrics

### Question 1: How many pizzas were ordered?
````sql
SELECT COUNT(*) AS total_pizza
FROM customer_orders;
````
| Total Pizzas | 
| ------------- | 
| 14 | 

### Question 2: How many unique customer orders were made?
````sql
SELECT 
COUNT(DISTINCT(order_id)) AS unique_orders
FROM customer_orders;
````
| Unique Orders | 
| ------------- | 
| 10 | 

### Question 3: How many successful orders were delivered by each runner?
````sql
SELECT
runner_id,
COUNT(order_id) AS successful_orders
FROM runner_orders_temporary
WHERE duration != 0
GROUP BY runner_id;
````

| Runner ID  | Successful Orders|
| ------------- | ------------- |
| 1  | 4 |
| 2  | 3  |
| 3  | 1  |

### Question 4: How many of each type of pizza was delivered?
````sql
SELECT
n.pizza_name,
COUNT(r.order_id) AS successful_orders
FROM runner_orders_temporary as r
JOIN customer_orders as c
ON r.order_id = c.order_id
JOIN pizza_names as n
ON c.pizza_id = n.pizza_id
WHERE duration != 0
GROUP BY n.pizza_name;
````

| Pizza Name  | Successful Orders|
| ------------- | ------------- |
| Meatlovers | 9 |
| Vegetarian  | 3  |

### Question 5: How many Vegetarian and Meatlovers were ordered by each customer?
````sql
SELECT
	c.customer_id,
	n.pizza_name,
	COUNT(n.pizza_name) AS total
FROM
	customer_orders as c
JOIN pizza_names as n
	ON c.pizza_id = n.pizza_id
GROUP BY c.customer_id, n.pizza_name
ORDER BY c.customer_id;
````
<img width="195" alt="Screenshot 2022-06-18 at 3 28 29 PM" src="https://user-images.githubusercontent.com/86179638/174427691-05f590f3-f6c4-432b-8bdc-13f54480186d.png">

### Question 6: What was the maximum number of pizzas delivered in a single order?
````sql
WITH pizza_order AS
(
SELECT
	c.order_id,
    COUNT(pizza_id) as pizza_orders
FROM customer_orders_temporary as c
JOIN runner_orders_temporary as r
ON c.order_id = r.order_id
WHERE r.duration != 0
GROUP BY c.order_id
)
SELECT
	MAX(pizza_orders)
FROM pizza_order;
````

| Max Pizza Ordered| 
| ------------- | 
| 3 | 

### Question 7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
### My Thought Process:
logic: if 0 change, then exclusions and extras are NULL
if at least 1 change, then exclusions OR extras will be NON-NULL

````sql
SELECT
	c.customer_id,
	SUM(
    CASE
		WHEN c.exclusions = ' ' AND c.extras = ' '
        THEN 1
        ELSE 0
        END
		) AS no_changes,
	SUM(
    CASE
		WHEN c.exclusions <> ' ' OR c.extras <> ' '
        THEN 1
        ELSE 0
        END
	) AS at_least_1_change
FROM customer_orders_temporary as c
JOIN runner_orders_temporary as r
ON c.order_id = r.order_id
WHERE r.distance != ' '
GROUP BY c.customer_id;
````
<img width="235" alt="Screenshot 2022-06-18 at 3 30 34 PM" src="https://user-images.githubusercontent.com/86179638/174427757-9603535e-9357-4725-9b6d-63f77e62a062.png">

### Question 8: How many pizzas were delivered that had both exclusions and extras?
````sql
SELECT
	COUNT(c.pizza_id) AS pizza_count
FROM customer_orders_temporary as c
JOIN runner_orders_temporary as r
ON c.order_id = r.order_id
WHERE 
	r.distance != ' ' AND
	c.exclusions != ' ' AND
	c.extras != ' '
    ;
````

| Pizza Count| 
| ------------- | 
| 1 | 

### Question 9: What was the total volume of pizzas ordered for each hour of the day?
````sql
SELECT
	HOUR(order_time) AS hour_of_day,
    SUM(pizza_id) as total_pizza
FROM customer_orders_temporary
GROUP BY hour_of_day
ORDER BY hour_of_day;
````
| Hour of Day  | Total Pizza|
| ------------- | ------------- |
| 11:00AM | 1|
| 1:00PM | 4  |
| 6:00PM | 3  |
| 7:00PM | 1 |
| 9:00PM | 5 |
| 11:00PM | 4 |

### Question 10: What was the volume of orders for each day of the week?
````sql
SELECT
DAYNAME(order_time) AS day_of_week,
SUM(pizza_id) as total_pizza
FROM customer_orders_temporary
GROUP BY day_of_week;
````
<img width="156" alt="Screenshot 2022-06-18 at 3 32 46 PM" src="https://user-images.githubusercontent.com/86179638/174427807-322a3301-ace8-4da6-a46c-8bb584406be1.png">


USE dannys_diner;

SELECT
  s.customer_id,
  SUM(m.price) as total_price
FROM menu as m
JOIN sales as s
ON m.product_id = s.product_id
GROUP BY s.customer_id;

SELECT 
  customer_id,
COUNT(DISTINCT(order_date)) AS visit_counts
FROM sales
GROUP BY customer_id;


WITH t1 AS(
	SELECT
	s.customer_id,
	s.order_date,
	m.product_name,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as ranked
	FROM menu as m 
	JOIN sales as s
	ON m.product_id = s.product_id
	ORDER BY s.order_date ASC
)
SELECT customer_id, product_name
FROM t1	
WHERE ranked = 1
GROUP BY customer_id, product_name;

SELECT 
  COUNT(s.product_id) as count,
  product_name
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY count DESC LIMIT 1;

WITH t2 AS(
	SELECT
	s.customer_id,
	m.product_name,
	COUNT(m.product_id) as order_count,
	DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(m.product_id) DESC) as rankers
	FROM menu as m
	JOIN sales as s
	ON m.product_id = s.product_id
	GROUP BY s.customer_id, m.product_name
)
SELECT
  customer_id,
  product_name
FROM t2
WHERE rankers = 1;

WITH t3 AS (
	SELECT
	m.customer_id,
	m.join_date,
	S.order_date,
	s.product_id,
	DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as rankers
	FROM sales as s
	JOIN members as m
	ON s.customer_id = m.customer_id
	WHERE order_date >= join_date
)
SELECT
  customer_id,
  order_date,
  product_name
FROM t3 as t
JOIN menu as u
ON t.product_id = u.product_id
WHERE rankers = 1;

WITH t4 AS (
	SELECT
	m.customer_id,
	m.join_date,
	S.order_date,
	s.product_id,
	DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) as rankers
	FROM sales as s
	JOIN members as m
	ON s.customer_id = m.customer_id
	WHERE order_date < join_date
)
SELECT
  customer_id,
  order_date,
  product_name
FROM t4 as tt
JOIN menu as u
ON tt.product_id = u.product_id
WHERE rankers = 1;


WITH t5 AS (
	SELECT
	m.customer_id,
	m.join_date,
	s.order_date,
    s.product_id
	FROM sales as s
	JOIN members as m
	ON s.customer_id = m.customer_id
	WHERE order_date < join_date
    )
SELECT
  customer_id,
  SUM(u.price) as AMT,
  COUNT(DISTINCT u.product_id) AS ITEMS
FROM t5 as x
JOIN menu as u
ON x.product_id = u.product_id
GROUP BY x.customer_id;

WITH points_sys AS (
SELECT *,
CASE
	WHEN product_id = 1 THEN price*20
    ELSE price*10
    END AS points
FROM menu
)
SELECT
  s.customer_id,
  SUM(p.points) AS total_points
FROM points_sys as p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY s.customer_id;

WITH dates AS 
(
 SELECT *, 
  DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date, 
  LAST_DAY('2021-01-31') AS last_date
 FROM members AS m
)
SELECT
  d.customer_id,
  d.join_date,
  s.order_date,
  d.valid_date,
  d.last_date,
  m.product_name,
  m.price,
  SUM(
  CASE 
  WHEN s.order_date BETWEEN d.join_date AND d.valid_date
  THEN 2*10*m.price
  ELSE 10*m.price
  END
  ) AS points
FROM dates AS d
  JOIN sales AS s
  ON d.customer_id = s.customer_id
    JOIN menu AS m
     ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY 
  d.customer_id,
  d.join_date,
  s.order_date,
  d.valid_date,
  d.last_date,
  m.product_name,
  m.price;


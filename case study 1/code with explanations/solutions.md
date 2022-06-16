# Case Study 1: Danny's Diner

## Full Solution
View my full MySQL code here: [case study 1/casestudy1.sql](https://github.com/gracuamole/sqlchallenge/blob/7772e60968e7ef708ff1774b5df25cb21cdeccf5/case%20study%201/casestudy1.sql)

### First, tell MySQL workbench that you would like to use this specific schema and the tables inside it.
````sql
USE dannys_diner;
````

### Question 1: What is the total amount each customer spent at the restaurant?
````sql
SELECT
  s.customer_id,
  SUM(m.price) as total_price
FROM menu as m
JOIN sales as s
ON m.product_id = s.product_id
GROUP BY s.customer_id;
````

note: when inner join is used, it is rank as B -> A -> C

| Customer_ID     | Total_Price           | 
| :-------------: |:-------------:| 
| A | 76| 
| B | 74|  
| C | 36 |  

Answer:
Customer A spent $76 in total at the restaurant.
Customer B spent $74 in total at the restaurant.
Customer C spent $36 in total at the restaurant.

### Question 2: How many days has each customer visited the restaurant?
````sql
SELECT 
customer_id,
COUNT(DISTINCT(order_date)) AS visit_counts
FROM sales
GROUP BY customer_id;
````
| Customer_ID     | Visit_Counts | 
| :-------------: |:-------------:| 
| A | 4| 
| B | 6|  
| C | 2 |  

Answer:
Customer A visited the restaurant on 4 occasions. 
Customer B visited the restaurant on 6 occasions.
Customer C visited the restaurant on 2 occasions.

### Question 3: What was the first item from the menu purchased by each customer?
````sql
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
````
| Customer_ID     | Product_Name| 
| :-------------: |:-------------:| 
| A | sushi | 
| A | curry | 
| B | curry |  
| C | ramen |  

Answer:
Customer A purchased both sushi and curry (hmmm.. definitely not together in the same meal!)
Customer B purchased curry.
Customer C purchased ramen.

### Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?
````sql
SELECT 
COUNT(s.product_id) as count,
product_name
FROM sales as s
JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY count DESC LIMIT 1;
````
| Count | Product_Name| 
| :-------------: |:-------------:| 
| 8 | ramen | 

Answer:
Ramen was the most purchased item, it was bought 8 times.

### Question 5: Which item was the most popular for each customer?
````sql
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
````
| Customer_ID     | Product_Name| 
| :-------------: |:-------------:| 
| A | ramen | 
| B | curry | 
| B | sushi | 
| B | ramen | 
| C | ramen | 

Answer:
Customer A loved ramen the most.
Customer B.... loved ALL! (True foodie!)
Customer C loved ramen too.

### Question 6: Which item was purchased first by the customer after they became a member?
````sql
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
````

| Customer_ID     | Order_Date| Product_Name | 
| :-------------: |:-------------:| :-------------:| 
| A | 2021-01-07 | curry |
| B | 2021-01-11 | sushi |

Answer:
The first thing Customer A purchased was curry, on 7th January 2021.
The first thing Customer B purchased was sushi, on 11th January 2021.

### Question 7: Which item was purchased just before the customer became a member?
````sql
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
````

| Customer_ID     | Order_Date| Product_Name | 
| :-------------: |:-------------:| :-------------:| 
| A | 2021-01-01 | sushi |
| A | 2021-01-01 | curry |
| B | 2021-01-04 | sushi |

Answer:
Customer A purchased both sushi and curry on 1st January 2021 before deciding that Danny's Diner was worth being a member of!
Customer B bought sushi on 4th January 2021 before membership.


### Question 8: What is the total items and amount spent for each member before they became a member?
````sql
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
````
| Customer_ID     | Total Amt | Total Items | 
| :-------------: |:-------------:| :-------------:| 
| A | 25 | 2|
| B | 40 | 2 |

Answer:
Customer A bought $25 worth of 2 items. (For Sushi and Curry - so the sushi costs $20, and the curry costs $5)
Customer B bought $40 worth of 2 items. ($20 per sushi!)

### Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
````sql
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
````

| Customer_ID     | Total_Points |
| :-------------: |:-------------:|
| A | 860 |
| B | 940|
| C | 360 |

Answer:
Customer A has 860 points.
Customer B has 940 points.
Customer C has 360 points. (Assumption: In reality, Customer C is not a member, sadly :( However, if she/he were, these will be the number of points they have)

### Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
````sql
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
GROUP BY d.customer_id,
d.join_date,
s.order_date,
d.valid_date,
d.last_date,
m.product_name,
m.price;
````
Interim Result for full details of points:
<img width="588" alt="Screenshot 2022-06-16 at 6 03 21 PM" src="https://user-images.githubusercontent.com/86179638/174046680-58d69b6f-1f1c-4602-acb2-c3d1c04687c6.png">

Final table:
| Customer_ID     | Total_Points |
| :-------------: |:-------------:|
| A | 1270 |
| B | 720|

Answer:
Customer A has 1270 points and B has 720 points
Customer C does not have membership.

This can be verified using:
````sql
SELECT
customer_id
FROM members;
````
| Customer_ID     | 
| :-------------: |
| A |
| B |

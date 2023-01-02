/* --------------------
Case Study Questions
-----------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

WITH sales AS (
  SELECT sales.customer_id, sales.order_date, sales.product_id, menu.price 
  FROM dannys_diner.sales sales 
  LEFT JOIN dannys_diner.menu menu
  ON sales.product_id = menu.product_id
 )
 
 SELECT customer_id, SUM(price)
 FROM sales
 GROUP BY customer_id


 -- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) as visit_no
FROM dannys_diner.sales
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?

WITH ranked_sales AS (
  SELECT customer_id, order_date, product_id,
  DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) as rank
FROM dannys_diner.sales
)

SELECT customer_id, product_name
FROM ranked_sales
LEFT JOIN dannys_diner.menu menu
ON ranked_sales.product_id = menu.product_id
WHERE rank = 1
GROUP BY customer_id, product_name
ORDER BY customer_id

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(sales.product_id) as purchase_count
FROM dannys_diner.sales sales
LEFT JOIN dannys_diner.menu menu
ON sales.product_id = menu.product_id
GROUP BY 1
ORDER BY purchase_count desc
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH sales_cte AS (
SELECT sales.customer_id, menu.product_name, COUNT(sales.product_id) as purchase_count
FROM dannys_diner.sales sales
LEFT JOIN dannys_diner.menu menu
ON sales.product_id = menu.product_id
GROUP BY 1, 2
),

ranked_purchase AS (SELECT customer_id, product_name, purchase_count,
RANK() OVER (PARTITION BY customer_id ORDER BY purchase_count desc) as rank
FROM sales_cte)

SELECT customer_id, product_name
FROM ranked_purchase
WHERE rank = 1

-- 6. Which item was purchased first by the customer after they became a member?

WITH sales_cte AS (
  SELECT sales.customer_id, menu.product_name, sales.order_date, members.join_date,
  (sales.order_date - members.join_date) as purchase_after_member_date
  FROM dannys_diner.sales sales
  LEFT JOIN dannys_diner.menu menu
  ON sales.product_id = menu.product_id
  LEFT JOIN dannys_diner.members members
  ON sales.customer_id = members.customer_id
),

sales_cte_ranked AS (
  SELECT customer_id, product_name, order_date, join_date, purchase_after_member_date,
  RANK() OVER (PARTITION BY customer_id ORDER BY purchase_after_member_date) as rank
  FROM sales_cte
  WHERE join_date IS NOT NULL AND purchase_after_member_date >= 0
)

SELECT customer_id, order_date, product_name
FROM sales_cte_ranked
WHERE rank = 1

-- 7. Which item was purchased just before the customer became a member?

WITH sales_cte AS (
  SELECT sales.customer_id, menu.product_name, sales.order_date, members.join_date,
  (sales.order_date - members.join_date) as purchase_after_member_date
  FROM dannys_diner.sales sales
  JOIN dannys_diner.menu menu
  ON sales.product_id = menu.product_id
  JOIN dannys_diner.members members
  ON sales.customer_id = members.customer_id
),

sales_cte_ranked AS (
  SELECT customer_id, product_name, order_date, join_date, purchase_after_member_date,
  RANK() OVER (PARTITION BY customer_id ORDER BY purchase_after_member_date desc) as rank
  FROM sales_cte
  WHERE purchase_after_member_date < 0
)

SELECT customer_id, order_date, product_name
FROM sales_cte_ranked
WHERE rank = 1

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT sales.customer_id, COUNT(DISTINCT menu.product_name) as total_item, SUM(menu.price) as amount_spent
FROM dannys_diner.sales sales
JOIN dannys_diner.menu menu
ON sales.product_id = menu.product_id
JOIN dannys_diner.members
ON sales.customer_id = members.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH sales_cte AS (
  SELECT sales.customer_id, sales.product_id, price,
  CASE WHEN sales.product_id = 1 THEN price * 20 ELSE price * 10 END as points
  FROM dannys_diner.sales sales
  JOIN dannys_diner.menu menu
  ON sales.product_id = menu.product_id
)

SELECT customer_id, SUM(points) as total_points
FROM sales_cte
GROUP BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH sales_cte AS (
  SELECT s.customer_id, s.product_id, s.order_date, mm.join_date, (s.order_date - mm.join_date) as days_after_purchase, price
  FROM dannys_diner.sales s
  JOIN dannys_diner.members mm
  	ON s.customer_id = mm.customer_id
  JOIN dannys_diner.menu m
  	ON s.product_id = m.product_id
),

sales_cte_extend AS (
  SELECT customer_id, 
	 CASE WHEN days_after_purchase >= 0 and days_after_purchase <= 7 THEN price * 20
	 WHEN product_id = 1 THEN price * 20
     ELSE price * 10
     END as points 
  FROM sales_cte
  WHERE EXTRACT(month from order_date) = 1
)

SELECT customer_id, SUM(points) as points
FROM sales_cte_extend
GROUP BY customer_id

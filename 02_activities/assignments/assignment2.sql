/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product



But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

--problem 1
SELECT *
-- ,product_name || ', ' || product_size|| ' (' || product_qty_type || ')' as list
,product_name || ', ' || coalesce(product_size,'')|| ' (' || coalesce(product_qty_type,'') || ')' as product_list
from product

--problem 2
SELECT *
-- ,product_name || ', ' || product_size|| ' (' || product_qty_type || ')' as list
,product_name || ', ' || coalesce(product_size,'unit')|| ' (' || coalesce(product_qty_type,'unit') || ')' as product_list
from product

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT
* 
-- customer_id,market_date
,row_number() OVER (PARTITION by customer_id ORDER by market_date ASC) as count
-- ,dense_rank() OVER (PARTITION by customer_id ORDER by market_date) as count
from customer_purchases
-- where customer_id = 1 ORDER by market_date

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

--problem 1
SELECT
* 
-- customer_id,market_date
,row_number() OVER (PARTITION by customer_id ORDER by market_date DESC) as count
-- ,dense_rank() OVER (PARTITION by customer_id ORDER by market_date) as count
from customer_purchases
-- where customer_id = 1 ORDER by market_date

-- problem 2
SELECT *
FROM 
(SELECT
* 
-- customer_id,market_date
,row_number() OVER (PARTITION by customer_id ORDER by market_date DESC) as count
-- ,dense_rank() OVER (PARTITION by customer_id ORDER by market_date) as count
from customer_purchases
-- where customer_id = 1 ORDER by market_date
)
where count = 1

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT * 
, count() over (
	PARTITION by customer_id,product_id
	ORDER by customer_id,product_id ASC
) as purchase_count
from customer_purchases

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_name,description
FROM
(SELECT
*
,case 
	when test1 > 0 then "Organic"
	when test2 > 0 then "Jar"
	else NULL
end as description
FROM
(SELECT

*
-- ,REGEXP(product_name,'.*Jar$') as new_product
,instr(product_name,'Organic') as test1
,instr(product_name,'Jar') as test2
FROM product
)
)


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT product_name,product_size,description
FROM
(SELECT
*
,case 
	when test1 > 0 then "Organic"
	when test2 > 0 then "Jar"
	else NULL
end as description
FROM
(SELECT

*
-- ,REGEXP(product_name,'.*Jar$') as new_product
,instr(product_name,'Organic') as test1
,instr(product_name,'Jar') as test2
FROM product
)
)
where product_size like '%1%'


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

SELECT 
sale,market_date, "best_day "as type
FROM
(
SELECT
product_id,vendor_id,customer_id,market_date,sale
,row_number() OVER (ORDER by sale DESC) as rn_high
FROM
(
SELECT
*
,(quantity*cost_to_customer_per_qty) as sale
FROM customer_purchases
ORDER by sale DESC
)
)
where rn_high = 1

UNION

SELECT 
sale,market_date, "worst_day "as type
FROM
(
SELECT
product_id,vendor_id,customer_id,market_date,sale
,row_number() OVER (ORDER by sale ASC) as rn_low
FROM
(
SELECT
*
,(quantity*cost_to_customer_per_qty) as sale
FROM customer_purchases
ORDER by sale ASC
)
)
where rn_low = 1

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

----------
-- create 'vendor_products' table
drop TABLE if EXISTS temp.vendor_products;
CREATE TEMP TABLE IF NOT EXISTS temp.vendor_products as
-- ------------
SELECT
vendor_id,product_id, vendor_name, product_name,original_price,5 as quantity
FROM
(SELECT *
FROM
(
select 
DISTINCT
vendor_id,product_id,original_price
from 
vendor_inventory
order by vendor_id
) as test
LEFT JOIN vendor on test.vendor_id = vendor.vendor_id
LEFT JOIN product on test.product_id = product.product_id
)
-- -------------------------
-- check the temp table containing DISTINCT vendors and their products from vendor_inventory
-- SELECT *
-- FROM
-- vendor_products
-- -------------------------
-- checking
-- SELECT 
-- customer_id,vendor_name,product_name,original_price,quantity
-- , original_price*quantity as sale
-- from customer
-- CROSS JOIN vendor_products;
-- -------------------------
SELECT 
vendor_name,product_name
,sum(sale) as total_sales
FROM
(
SELECT 
customer_id,vendor_name,product_name,original_price,quantity
,original_price*quantity as sale
from customer
CROSS JOIN vendor_products
)
GROUP by vendor_name,product_name
-- -------------------------------------
-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE if EXISTS product_units;
CREATE TABLE if NOT EXISTS product_units as
SELECT
*,CURRENT_TIMESTAMP as snapshot_timestamp
FROM
product
where product_qty_type like "unit";
SELECT *
from product_units

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT into product_units
VALUES(25,'Cheddar Cheese Mild','6 slices',8,'unit',CURRENT_TIMESTAMP);
SELECT *
from product_units
order by product_id

-- drop TABLE product_units

-- DELETE

/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE from product_units
WHERE product_id = 25;
SELECT *
from product_units
order by product_id

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


ALTER table product_units
ADD current_quantity INT;

SELECT *
from product_units
order by product_id

-- SELECT *
-- FROM
-- vendor_inventory
-- order by product_id,vendor_id


SELECT * 
FROM
(SELECT *
,row_number() over(PARTITION by vendor_id,product_id order by market_date DESC) as rn
FROM
vendor_inventory
order by product_id,vendor_id DESC
)
WHERE rn = 1

SELECT
*
,CASE
	when market_date = '2023-10-13' then quantity
	else NULL
END as new_quantity
FROM
vendor_inventory
ORDER by market_date DESC


-- SELECT
-- DISTINCT
-- market_date
-- FROM vendor_inventory
-- ORDER by market_date DESC

-----------------------------------------
-- I took last quantity as the quantity at thr last market_date which is 2023-10-13
-- I first crete a tem table that holds the values  for last_quantity

DROP TABLE if EXISTS temp.product_last_qty;
CREATE TABLE if NOT EXISTS temp.product_last_qty as
-- -------------
SELECT
-- product_id,market_date,coalesce(last_quantity,0) as last_quantity
product_id,coalesce(last_quantity,0) as last_quantity
FROM
(SELECT
*
,CASE
	when market_date = '2023-10-13' then quantity
	else NULL
END as last_quantity
FROM
(SELECT * 
FROM
(SELECT *
,row_number() over(PARTITION by vendor_id,product_id order by market_date DESC) as rn
FROM
vendor_inventory
order by product_id,vendor_id DESC
)
WHERE rn = 1)
)
-- -------------
-- created a new table 'product_last_qty' that holds the 'last' quantity
-- SELECT *
-- FROM
-- product_last_qty
-- -------------

UPDATE product_units
SET current_quantity = product_last_qty.last_quantity
FROM product_last_qty
WHERE
(product_last_qty.product_id = product_units.product_id);

------------------
-- check the results
SELECT *
FROM
product_units
-- there are null values for 'current_quantity' in the 'product_units' TABLE
-- Because some products are not in the 'vendor_inventory' table. 
------------------
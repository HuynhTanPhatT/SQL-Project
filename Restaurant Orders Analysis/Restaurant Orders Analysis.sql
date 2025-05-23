select *
from dbo.menu_items
select *
from dbo.order_details
select *
from dbo.restaurant_dictionary
-------------------------------------------------------------------------------------------------------------
/* Explore the menu_items table */
---- 1. The number of items on the menu: 32
select count(distinct(item_name)) as dishes
from dbo.menu_items;

---- 2. What are the least and expensive items on the menu ?
-- On the menu, the Shrimp Scampi are the expensive || Edamame are the least
with rank_items as (
select	item_name, price,
		DENSE_RANK() over (order by price desc) as rank_price
from dbo.menu_items
)
select *
from rank_items
where rank_price in (
select top 1 min(rank_price) from rank_items
union all
select top 1 max(rank_price) from rank_items
);
---- 3. How many Italian dishes on the menu ? What are the least and most expensive Italian dishes on the menu ?
--- There are 9 Italian Dishes on the menu
select count(item_name) as dishes
from dbo.menu_items
where category = 'Italian';

--Shrimp Scampi are the most expensive || both Fettuccine Alfredo & Spaghetti are the least
with rank_items as (
select	item_name, category, price,
		DENSE_RANK() over (order by price desc) as rank_price
from dbo.menu_items
where category = 'Italian'
)
select *
from rank_items
where rank_price in (
select top 1 min(rank_price) from rank_items
union all
select top 1 max(rank_price) from rank_items
);
---- 4. How many dishes are in each category ?
-- Italian: 9 & Mexican: 9 & Asian: 8 & American: 6
select	category, count(category) as dishes
from dbo.menu_items
group by category
order by dishes desc;
---- 5. What is the average dish price within each category ?
-- Italian: $16,75 & Mexican: $13,48 & Asian: $11,8 & American: $10,07
select	category, round(AVG(price),2) as average_price
from dbo.menu_items
group by category
order by average_price desc;
-------------------------------------------------------------------------------------------------------------
/* Explore the Orders table */
select *
from dbo.order_details

---- 1. How many orders were made within this date range ? How many items were ordered within this date range?
-- 01/01/2023 -> 03/09/2023 : 5370 Total orders
select	min(order_date) as StartDate,	
		max(order_date) as CurrtenDate, 
		count(distinct(order_id)) as Total_orders
from dbo.order_details;

-- 01/01/2023 -> 03/09/2023 : 32 Total orders
select	min(order_date) as StartDate,	
		max(order_date) as CurrtenDate, 
		count(item_id) as Total_items
from dbo.order_details;
---- 2. Rolling total
with rolling_total as(
select	cast(year(order_date) as VARCHAR(4)) + '-' + right('0' + cast(month(order_date) as varchar(2)),2) as YearMonth,
		count(order_details_id) as Order_Volume
from dbo.order_details
group by year(order_date), MONTH(order_date)
)
select	*,
		sum(Order_Volume) over (order by YearMonth) as Rolling_Total
from rolling_total;

---- 3. Which orders had the most number of items ?
select	order_id, count(item_id) as num_orders
from dbo.order_details
group by order_id
order by num_orders desc;
---- 4. How many orders had more than 12 items ?
-- There are 20 orders which have more than 12 items
With order_12 as (
select	order_id, count(item_id) as num_items
from dbo.order_details
group by order_id
having count(item_id) > 12
)
select count(order_id) as orders
from order_12;
-------------------------------------------------------------------------------------------------------------
/*Analyze Customer Behavior */
/* A grouped Table*/
select	ms.menu_item_id, ms.item_name, ms.category, ms.price, 
		os.order_date,os.order_time, os.order_details_id, os.order_id
into #temp_table1 ---Temporary table
from dbo.menu_items ms
right join dbo.order_details os
on ms.menu_item_id = os.item_id;

---- 1. What were the least and most ordered items ? What categories were they in ?
select	item_name,category, count(order_details_id) as num_orders
from #temp_table1
where item_name is not null
group by item_name, category
order by num_orders desc;

---- 2. What were the top 5 orders that spent the most money ?
select top 5 order_id, sum(price) as total_spend
from #temp_table1
group by order_id
order by total_spend desc;

---- 3. View the details of the highest spend order. What insights can you gather from the results ?
--- The highest spend order bought a lot of Italian food
select category, count(menu_item_id) as count
from #temp_table1
where order_id = '440'
group by category;
---- 4. View the details of the top 5 highest spend orders. What insights can you gather from the results ?
--- Top 5 spend orders tend to be spending a lot on Italian food
select order_id, category, count(menu_item_id) as count
from #temp_table1
where order_id in('440','2075','1957','330', '2675')
group by order_id, category;

select order_id, sum(price) as total_spend
from #temp_table1
group by order_id
order by total_spend desc;

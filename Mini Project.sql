/*
Composite data of a business organisation, confined to ‘sales and delivery’ domain is given for the period of last decade.
 From the given data retrieve solutions for the given scenario.
*/
create database Miniproject;
use Miniproject;
#1.	Join all the tables and create a new table called combined_table.
#(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
create table combined_table as
select mf.*,cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment,od.Order_ID, od.Order_Date, od.Order_Priority,
pd.Product_Category, pd.Product_Sub_Category, sd.Ship_Mode, sd.Ship_Date
from  market_fact as mf join cust_dimen as cd 
on mf.cust_id = cd.cust_id
join orders_dimen od
on od.ord_id = mf.ord_id
join prod_dimen pd
on pd.prod_id = mf.prod_id
join shipping_dimen sd
on sd.ship_id = mf.ship_id;

select * from combined_table;

#2.	Find the top 3 customers who have the maximum number of orders
select cust_id,customer_name,province,region,customer_Segment,sum(order_quantity) as No_of_Orders
from combined_table
group by cust_id,customer_name,province,region,customer_Segment
order by sum(order_quantity) desc
limit 3;





#3. Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
select * from combined_table;
desc combined_table;
update combined_table set ship_date = str_to_date(ship_date,'%d-%m-%Y');
alter table combined_table
modify ship_date date;
update combined_table set order_date = str_to_date(order_date,'%d-%m-%Y');
alter table combined_table
modify order_date date;

select Ord_id, Prod_id, Ship_id, Sales, Discount, Order_Quantity, Profit, Shipping_Cost, 
Customer_Name, Order_ID, Ship_Mode, order_date, ship_date, datediff(ship_date,order_date) as DaysTakenForDelivery
from combined_table;


#4.	Find the customer whose order took the maximum time to get delivered.
select cust_id,max(DaysTakenForDelivery) from (select Ord_id, Prod_id, Ship_id,cust_id, Sales, Discount, Order_Quantity, Profit, Shipping_Cost, 
Customer_Name, Order_ID, Ship_Mode, order_date, ship_date, datediff(ship_date,order_date) as DaysTakenForDelivery
from combined_table)t
group by cust_id
order by max(DaysTakenForDelivery) desc
limit 1;


#5.	Retrieve total sales made by each product from the data (use Windows function)
select distinct prod_id,product_category,sum(sales) over(partition by prod_id,product_category) as Total_sales 
from combined_table;


#6.	Retrieve total profit made from each product from the data (use windows function)
select distinct prod_id,product_category,sum(profit) over(partition by prod_id,product_category) as Total_profit 
from combined_table;

#7.	Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
with t as (select cust_id,order_date,year(order_date) as year_of_od,month(order_Date) as month_of_od
from combined_table)
select cust_id,count(distinct month_of_od) as No_of_Regular_customers from t
where year_of_od = 2011 
group by cust_id
having count(distinct month_of_od) = 12;


#8.	Retrieve month-by-month customer retention rate since the start of the business.(using views)
/*
Tips: 
#1: Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple # years since whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
# 5: calculate the retention month wise

*/
select Cust_id, year(order_date),month(order_date),count(cust_id) over(partition by cust_id order by order_date) from combined_table;



with t as (select year(order_date) as year_of_od,month(order_Date) as month_of_od,count(cust_id) as count_of_customers
from combined_table
group by year(order_date),month(order_Date)
order by order_date)
select Year_of_od,month_of_od, lag(count_of_customers) over() as prev_month_count, count_of_customers,
(count_of_customers - lag(count_of_customers) over())*100/lag(count_of_customers) over() as Retention_rate
from t;

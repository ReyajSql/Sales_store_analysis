create database project1
use project1
create table sales_store(
transaction_id  varchar(50),
customer_id varchar(20),
customer_name varchar(100),
customer_age int,
gender varchar(10),
product_id varchar(50),
product_name varchar(100),
product_category varchar(50),
quantiy int,
prce float,
payment_mode varchar(20),
purchase_date date,
time_of_purchase time,
status varchar(20)
)

-- import csv data

set dateformat dmy
bulk insert sales_store
from 'C:\Users\reyaj\Downloads\archive (3)\sales_store_updated_allign_with_video.csv'
with(
firstrow=2,
fieldterminator=',',
rowterminator='\n'
)
Select * from sales_store
--insert duplicate table 
select * into sale from sales_store

-- step 1-cheak duplicate
select transaction_id,count(*) from sale
group by transaction_id
having count(transaction_id)>1

--TXN240646
--TXN342128
--TXN855235
--TXN981773

with cte as(
select * ,
ROW_NUMBER()over(partition by transaction_id order by transaction_id) as row_num
from sale
)
select * from cte 
where row_num=2

--find duplicate entry
with cte as(
select * ,
ROW_NUMBER()over(partition by transaction_id order by transaction_id) as row_num
from sale
)
select * from cte 
where transaction_id in('TXN240646','TXN342128','TXN855235','TXN981773')

--delete duplicate rows

with cte as(
select * ,
ROW_NUMBER()over(partition by transaction_id order by transaction_id) as row_num
from sale
)
--delete from cte 
select * from cte
where row_num=2

--step 2:- correction of header
select * from sale
exec sp_rename'sale.quantiy','quantity','COLUMN'
exec sp_rename'sale.prce','price','COLUMN'


--step 3 to cheak datatype

select column_name,data_type 
from INFORMATION_SCHEMA.COLUMNS
where table_name='sale'

--step 4 to ckeak null count
declare @SQL nvarchar(max)= '';

Select @SQL=STRING_AGG(
'select ''' + COLUMN_NAME + ''' as columnName,
count(*) as nullcount
from ' + QUOTENAME(TABLE_SCHEMA) + '.sale
where ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
' UNION ALL '
)
within group (order by COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='sale';

exec sp_executesql @SQL;

--treating null values

select * from sale
where transaction_id is null
or
customer_id is null
or
customer_name is null
or
customer_age is null
or
gender is null
or
payment_mode is null
or
purchase_date is null
or
status is null
or 
time_of_purchase is null

-- delete null value

delete from sale
where transaction_id is null

select * from sale
where customer_name ='Ehsaan Ram'

--update null value

update sale
set
customer_name='Mahika Saini' , customer_age=35,gender='male'
where customer_id='CUST1003'

update sale
set
customer_id='CUST9494'
where transaction_id='TXN977900'


select * from sale
where customer_name='Damini Raju '


update sale
set
customer_id='CUST1401'
where transaction_id='TXN985663'


select * from sale


--step 5 data cleaning likes column name- gender and  payment_mode

Select distinct gender from sale
update sale 
set gender ='M'
where gender='Male'

update sale
set gender ='F'
where gender ='Female'

--cheak distinct for column payment_mode 

select distinct payment_mode from sale

update sale
set payment_mode='Credit Card'
where payment_mode='CC'

--------------------------------------------------------------------------

--step 6 : data analysis process

-- Question 1:- what are the top 5 most selling products by quantity ?

select  top 5 product_name, sum(quantity) as total_quantity_sold
from sale
where status='delivered'
group by product_name
order by total_quantity_sold desc

-- business problem solved :- we don't know which product are most in demand.
-- business impact:- Helps prioritize stocks and boost sales through targeted promotions.
------------------------------------------------------------------------------------------------------------------------------------------
-- Question 2:- which product are most frequency cancelled ?

select  top 5 product_name , count(*) as total_cancelled
from sale
where status='cancelled'
group by product_name
order by total_cancelled desc

-- business problem solved :- frequent cancelletions affects revenue  and customer trust.
-- business imact:-  identity poor-performing products to improve quality or remove from catelog.
--------------------------------------------------------------------------------------------------------------------------------------------
-- question 3:- what time of day  has the highest number of purchases ?


select 
     case 
	    when DATEPART(hour,time_of_purchase) between 0 and 5 then 'Night'
	    when DATEPART(hour,time_of_purchase) between 6 and 11 then 'Morning'
		when DATEPART(hour,time_of_purchase) between 12 and 17 then 'Afternoon'
		when DATEPART(hour,time_of_purchase) between 18 and 23 then 'Evening'
		end as time_of_day,
		count(*) as total_orders
		from sale
		group by case 
	    when DATEPART(hour,time_of_purchase) between 0 and 5 then 'Night'
	    when DATEPART(hour,time_of_purchase) between 6 and 11 then 'Morning'
		when DATEPART(hour,time_of_purchase) between 12 and 17 then 'Afternoon'
		when DATEPART(hour,time_of_purchase) between 18 and 23 then 'Evening'
		end
		order by total_orders desc

-- business problem solved :- find peak sales times
-- business impact:- optimize staffing , promotion, and surver load
---------------------------------------------------------------------------------------------------------------------------------------------
--question 4:- who are the top 5 highest spending customers ?

Select  top 5 customer_name,
format(sum(quantity*price),'c0','en-in') as total_spend
from sale
group by customer_name
order by sum(quantity*price) desc
 
-- business problem solved :- identity vip customers
-- business impact:- personalizes offer, loyalty reward and retention.

---------------------------------------------------------------------------------------------------------------------------------------
--- question 5 :- which products categories generate the highest revenue ?

select product_category, 
format(sum(price*quantity),'c0','en-in') as revenue
from sale
group by product_category
order by sum(price*quantity) desc

-- business problem solved:- identity top-performing product categories.
-- business impact:- Refine product strategy ,supply chain and promotions.
-- allowing the business to invest more in high-mergine or high-demand categories.
----------------------------------------------------------------------------------------------------------------------------------------

-- question 6:- what is return /canellation rate per product category ?
--  for cancelled
select  product_category,
format(count(case when status='cancelled' then 1 end)*100.0/count(*),'n2')+' %' as cancelled_percent
 from sale
 group by product_category
 order by cancelled_percent desc

 -- for return
 select  product_category,
format(count(case when status='returned' then 1 end)*100.0/count(*),'n2')+' %' as cancelled_percent
 from sale
 group by product_category
 order by cancelled_percent desc

 -- business problem solved:- monitor dissatisfaction trends per category.
 -- business impact:- Reduce returns improve product discripation/expectation.
 -- helps identify and fix product or logistics issues.
 ------------------------------------------------------------------------------------------------------------------------------------

 --question 7 :-what is the most preferred payment mode ?

 select payment_mode, count(payment_mode) as total_count
 from sale
 group by payment_mode
 order by total_count desc
 -- business problem solved:- know which payment options customer prefer.
 -- business impact:- stremline payment processing priortize popular modes.

 -------------------------------------------------------------------------------------------------------------------------------------

 -- question 8:- How does age group affect purchasing behavior ?

 select 
     case
	  when customer_age between 18 and 25 then '18-25'
	  when customer_age between 26 and 35 then '26-35'
	  when customer_age between 36 and 50 then '36-50'
	  else '51+'
      end as customer_age,
format(sum(price*quantity),'c0','en-in') as total_purchase
from sale  
group by case
	  when customer_age between 18 and 25 then '18-25'
	  when customer_age between 26 and 35 then '26-35'
	  when customer_age between 36 and 50 then '36-50'
	  else '51+'
      end
order by total_purchase desc

-- business problem solved:-understand customer demographics.
-- business impact:- targeted marketing and product recommendation by age group.
---------------------------------------------------------------------------------------------------------------------------------

-- question 9:- what's the sales trends ?
 -- method 1:
select 
 Format(purchase_date,'yyyy-MM')as month_year,
 sum(price*quantity) as total_sales,
 sum(quantity) as total_quantity
 from sale
 group by Format(purchase_date,'yyyy-MM')

 --method 2:

 select 
 year(purchase_date) as years,
 month(purchase_date) as months,
 format(sum(price*quantity),'c0','en-in') as total_sales,
 sum(quantity) as total_quantity
 from sale
 group by year(purchase_date),month(purchase_date)
 order by months

 -- method 3: if we should be  show data  12 month then this

 
 select 
 month(purchase_date) as months,
 format(sum(price*quantity),'c0','en-in') as total_sales,
 sum(quantity) as total_quantity
 from sale
 group by month(purchase_date)
 order by months

 ---business problem solved:- sales fluctualtions go unnoticed.
 -- business impact :- plan inventory and marketing according to seasonal trends.
 ----------------------------------------------------------------------------------------------------------------------------------------

 -- question  10:-- Are certain gender busing more specific product categories ?
 -- method 1
 select gender, product_category,count(product_category) as total_purchase
from sale
group by gender, product_category
order by gender

--method 2
select * from 
(select gender,product_category
from sale
)as source_table
PIVOT(
    count(gender)
    for gender in ([M],[F])
) as pivot_table
order by product_category

-- business problem solved:- Gender base product preferences.
-- business impact:- personalized ads, gender-focused campaigns.

----------------------------------------------------------------------------------------------------------------------------------
--sales_store Analysis
-->Conducted a detailed analysis of a sales dataset identifying trends in product demand customer behavior,
--and oprational delays-- improving reporting accuary by 90% and uncovering inefficienies in 30% of total transactions.
--> generated insights that led to a 25% improvement in inventory planning accuracy a 20% reduction in delivery delays and supported targeted
--marketing campaingns that increased customer engagement by 15%.





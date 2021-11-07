/*Creating the table*/
create table merchant_transactions
(
	merchant_id varchar(30),
    trans_time varchar(30),
    amount_usd_in_cents integer
);

/* Loading the data manually from CSV */

LOAD DATA INFILE 'C:\Siddhesh Data\Study\Career Planning\Job Applications\Stripe\TakeHomeAssignment\takehome_ds_written - Copy.csv' 
INTO TABLE merchant_transactions 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

/*Variables check for loading*/
show variables like "secure_file_priv";  
show variables like "local_infile";
set global local_infile = 1;

/*Getting sense on the overall data*/
select * from merchant_transactions;

select count(*) from merchant_transactions;

select database();

select merchant,amount_usd_in_cents,cast(time as date) as trans_date,cast(time as datetime) as trans_datetime,cast((amount_usd_in_cents / 100) as decimal(10,2)) as amount_in_dollars 
from merchant_transactions;

desc merchant_transactions;

-- Getting sense on the merchant 
select merchant,count(*) as cntt from merchant_transactions
group by merchant
order by cntt desc;

select min(cast((amount_usd_in_cents / 100) as decimal(10,2))),max(cast((amount_usd_in_cents / 100) as decimal(10,2))) from merchant_transactions;

-- Finding merchents who had few transactions in past and then categorizing them into "Lapsed", "At Risk", "Churned" categories.

-- Lapsed merchants
select distinct main_table.* from merchant_transactions main_table inner join (
select merchant,count(distinct cast(time as date)) as cntt
from merchant_transactions
group by merchant
having cntt >= 2 -- finding merchants who had atleast 2 transactions in past
) drv_tbl
on drv_tbl.merchant = main_table.merchant
where main_table.cast(time as date) <= (current_date - interval '1' year)
and main_table.merchant not in (select distinct merchant from merchant_transactions where cast(time as date) > (current_date - interval '1' year); 
-- filtering if they don't have any transactions in past year, thus they are Lapsed.

-- At Risk merchants 
select distinct main_table.* from merchant_transactions main_table inner join (
select merchant,count(distinct cast(time as date)) as cntt
from merchant_transactions
group by merchant
having cntt >= 2 -- finding merchants who had atleast 2 transactions in past
) drv_tbl
on drv_tbl.merchant = main_table.merchant
where main_table.cast(time as date) <= (current_date - interval '2' year)
and main_table.merchant not in (select distinct merchant from merchant_transactions where cast(time as date) > (current_date - interval '1' year); 
-- filtering if they don't have any transactions in past year, thus they are At Risk.


-- Churned merchants 
select distinct main_table.* from merchant_transactions main_table inner join (
select merchant,count(distinct cast(time as date)) as cntt
from merchant_transactions
group by merchant
having cntt >= 10 -- finding merchants who had atleast 2 transactions in past
) drv_tbl
on drv_tbl.merchant = main_table.merchant
where main_table.cast(time as date) <= (current_date - interval '2' year)
and main_table.merchant not in (select distinct merchant from merchant_transactions where cast(time as date) > (current_date - interval '1' year); 


-- Another way to find merchant category and also if they are churned or not using window function 
select mt1.merchant,max(cast(mt1.time as date)) as max_trans,min(cast(mt2.time as date)) as min_trans
case when (max_trans - min_trans) <=365 then 'Lapsed'
	 when (max_trans - min_trans) > 365 (max_trans - min_trans) < 730 and then 'At Risk'
     else 'Churned'
     end as "Churn Type"
from merchant_transactions mt1 
group by mt1.merchant

-- These queries below can generate  some reporting insights. Please note some of them might not be supported in MySQL, as these syntax are specific to Teradata
select mt1.merchant,cast(mt1.time as date), row_number() over(partition by mt1.merchant order by time desc) as rn
from merchant_transactions mt1 ;

select mt1.merchant,cast(mt1.time as date),cast(amount_usd_in_cents / 100) as amount_usd_in_dollars, sum(amount_usd_in_dollars)
from merchant_transactions
group by rollup (merchant,extract(month from time));





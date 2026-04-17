

SET search_path TO bank_recon; 

---- MISSING LEDGER POSTING------------------------------------------------------------

select  *
		/*t.transaction_id , 
		t.transaction_reference ,
		t.transaction_id ,
		t.amount ,
		t.transaction_status */
from transactions t 
left join internal_ledger il 
on t.transaction_reference = il.transaction_reference 
where t.transaction_status = 'successful' and il.transaction_reference is null ;

select  'Missing Ledger' anomaly_type,
		count(t.transaction_id ), 
		sum(t.amount) as missing_ledger_amount 	
from transactions t 
left join internal_ledger il 
on t.transaction_reference = il.transaction_reference 
where t.transaction_status = 'successful' and il.transaction_reference is null ;

/*
2,032 successful transactions were missing from the internal ledger, indicating a breakdown between transaction processing and accounting recognition. This creates financial reporting risk, balance inaccuracies, and potential audit concerns.
*/

------- OPHAN LEDGER ENTRIES---------------------------------------------------------------------
select * 
		/*il.ledger_id ,
		il.transaction_reference ,
		il.account_id ,
		il.posting_date ,
		il.posted_amount */
from internal_ledger il 
left join transactions t 
on il.transaction_reference = t.transaction_reference 
where  t.transaction_status is null ;

select 'Ophan Ledger' as anomaly_type,
		count(*),
		sum(il.posted_amount )as posted_amount
from internal_ledger il 
left join transactions t 
on il.transaction_reference = t.transaction_reference 
where  t.transaction_status is null ;

------------------AMOUNT MISMATCH------------------------------------------------------------

select t.transaction_id ,
		t.amount as transaction_amount,
		il.posted_amount ,
		t.transaction_date ,
		il.posting_date 
from transactions t 
left join internal_ledger il 
on t.transaction_reference  = il.transaction_reference 
where t.amount != il.posted_amount ;

select 
		'Amount Mismatch' as anomaly_type,
		count(*) as record_count,
		sum(abs(t.amount - il.posted_amount ))as total_amount
from transactions t 
left join internal_ledger il 
on t.transaction_reference  = il.transaction_reference 
where t.amount != il.posted_amount ;



-----------DUPLICATE TRANSACTION REFERENCE------------------------------------------------------------

select t.transaction_reference , count(t.transaction_reference )
from transactions t 
group by t.transaction_reference 
having count (t.transaction_reference ) > 1 ;

select 
		'Duplicate Transaction' as anomaly_type,
 		count(* ) as record_count,
 		null as total_amount
from(
		select transaction_reference 
		from internal_ledger  
		group by transaction_reference 
		having count(transaction_reference ) > 1 
 	)
;

---------DUPLICATE LEDGER POSTING--------------------------------------------------------------------------

select il.transaction_reference , count(il.transaction_reference )
from internal_ledger il 
group by il.transaction_reference 
having count(il.transaction_reference ) > 1;

select 
		'Duplicate Ledger' as anomaly_type,
		count(*)as record_count	,
		sum(posted_amount )
from (
		select transaction_reference , posted_amount 
		from internal_ledger  
		group by transaction_reference, posted_amount
		having count(transaction_reference ) > 1
		);
--------------FAILED OR PENDING TRANSACTION POSTED TO LEDGER-----------------------------------------------------

select  t.transaction_reference ,
		t.transaction_status ,
		il.ledger_status ,
		il.posted_amount  
from transactions t 
left join internal_ledger il 
on t.transaction_reference = il.transaction_reference 
where t.transaction_status in ('failed', 'pending');


select 	'Invalid Ledger Posting' as anomaly_type,
		count( t.transaction_reference ) record_count,
		sum(il.posted_amount ) as posted_amount  
from transactions t 
left join internal_ledger il 
on t.transaction_reference = il.transaction_reference 
where t.transaction_status in ('failed', 'pending');

--------------SETTLEMENT MISMATCH-----------------------------------------------------------------------------------------

select settlement_date ,
		total_transaction_amount,
		total_ledger_amount ,
		net_settlement_amount ,
		(total_transaction_amount - total_ledger_amount )as difference
from daily_settlement 
where total_transaction_amount != total_ledger_amount  ;


---------------------------------------------------------------------------------------------------------



with anomaly_summary as (
select  'Missing Ledger' anomaly_type,
		count(t.transaction_id ), 
		sum(t.amount) as missing_ledger_amount 	
from transactions t 
left join internal_ledger il 
on t.transaction_reference = il.transaction_reference 
where t.transaction_status = 'successful' and il.transaction_reference is null 
union all
select 'Ophan Ledger' ,
		count(*),
		sum(il.posted_amount )as posted_amount
from internal_ledger il 
left join transactions t 
on il.transaction_reference = t.transaction_reference 
where  t.transaction_status is null 
union all
select 
		'Amount Mismatch' ,
		count(*) as record_count,
		sum(abs(t.amount - il.posted_amount ))as total_amount
from transactions t 
left join internal_ledger il 
on t.transaction_reference  = il.transaction_reference 
where t.amount != il.posted_amount 
)
select * 
from anomaly_summary ;


-----DAILY MISSING LEDGER TREND-----------------------------------------------------------
select 
		date(t.transaction_date ) as trn_date,
		count(t.transaction_reference ) missing_ledger_count,
		sum(t.amount )as missing_ledger_amount
from transactions t 
left join internal_ledger il  
on t.transaction_reference = il.transaction_reference 
where t.transaction_status = 'successful' and il.transaction_reference is null
group by date(t.transaction_date)
order by trn_date asc
;

--------------DAILY ORPHAN LEDGER TREND----------------------------------------------------------------

select 
		date(il.posting_date ) as date_posted,
		count(il.transaction_reference ) orphan_ledger_count,
		sum(il.posted_amount ) ledger_amount
from internal_ledger il 
left join transactions t 
on il.transaction_reference = t.transaction_reference 
where t.transaction_reference is null
group by date(il.posting_date )
order by date_posted ;

------------------------DAILY AMOUNT MISMATCH---------------------------------------------------------------------------

select 
		date(t.transaction_date ) as trn_date,
		count(t.transaction_reference ) as trn_count,
		sum(abs(t.amount- il.posted_amount)) as mismatch_amount
from transactions t 
left join internal_ledger il 
on t.transaction_reference  = il.transaction_reference 
where t.amount != il.posted_amount 
group by trn_date 
order by trn_date ;

-----------------------------------------------------------------------------------------------

with daily_anomalies as (
select 
		date(t.transaction_date ) as anomaly_date,
		'missing ledger' as anomaly_type,
		count(t.transaction_reference ),
		sum(t.amount ) 
from transactions t 
left join internal_ledger il  
on t.transaction_reference = il.transaction_reference 
where t.transaction_status = 'successful' and il.transaction_reference is null
group by date(t.transaction_date) 
union all
select 
		date(il.posting_date ),
		'Orphan Ledger',
		count(il.transaction_reference ),
		sum(il.posted_amount )
from internal_ledger il 
left join transactions t 
on il.transaction_reference = t.transaction_reference 
where t.transaction_reference is null
group by date(il.posting_date )
union all
select 
		date(t.transaction_date ),
		'Amount Missing',
		count(t.transaction_reference ),
		sum(abs(t.amount- il.posted_amount))
from transactions t 
left join internal_ledger il 
on t.transaction_reference  = il.transaction_reference 
where t.amount != il.posted_amount 
group by date(t.transaction_date )  
)
select *
from daily_anomalies
--order by anomaly_date 






















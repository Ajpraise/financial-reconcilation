# Financial Data Reconcilation & Risk Analysis Report
## Project Overview
This project focuses on building a financial data reconciliation system to identify discrepancies between transaction records and internal ledger systems. Using SQL and Power BI, anomalies such as amount mismatches, missing ledger entries, and orphan records were detected and analyzed. The project also quantifies financial exposure, evaluates reconciliation performance and provides insights into operational risks through interactive dashboards.
## Objective
Analyze discrepancies between transaction records and internal ledger systems to identify anomalies, measure financial exposure, and assess reconciliation performance.
## Data Overview
The dataset consists of approximately 100,000 simulated financial transaction records. Two primary tables were used: transactions and internal_ledger. The dataset includes realistic anomalies such as amount mismatches, missing ledger entries, and orphan records.
##  Methodology
Data was structured in PostgreSQL and joined using transaction references to identify matched and unmatched records. Anomalies were classified into key categories including amount mismatches, missing ledger entries, and orphan ledger entries. Key metrics such as reconciliation rate, financial exposure, and settlement variance were calculated. Results were visualized using Power BI dashboards.
## Tools Used
PostgreSQL | Power BI | Excel

## SQL Analysis and Queries
#### MISSING LEDGER POSTING
```sql
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
```
```sql
select  'Missing Ledger' anomaly_type,
		count(t.transaction_id ), 
		sum(t.amount) as missing_ledger_amount 	
from transactions t 
left join internal_ledger il 
on t.transaction_reference = il.transaction_reference 
where t.transaction_status = 'successful' and il.transaction_reference is null ;
```
#### OPHAN LEDGER ENTRIES
```sql
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
```
#### AMOUNT MISMATCH
```sql
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
```
#### DUPLICATE TRANSACTION REFERENCE
```sql
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
```
#### DUPLICATE LEDGER POSTING
```sql
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
```
#### FAILED OR PENDING TRANSACTION POSTED TO LEDGER
```sql
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
```
#### SETTLEMENT MISMATCH
```sql
--------------SETTLEMENT MISMATCH-----------------------------------------------------------------------------------------

select settlement_date ,
		total_transaction_amount,
		total_ledger_amount ,
		net_settlement_amount ,
		(total_transaction_amount - total_ledger_amount )as difference
from daily_settlement 
where total_transaction_amount != total_ledger_amount  ;
```


























```

# Financial Data Reconcilation & Risk Analysis Report

## Table Of Contents
- [Project Overview](#Project-Overview)
- [Objective](#Objective)
- [Data Overview](#Data-Overview)
- [Methodology](#Methodology)
- [SQL Analysis and Queries](#SQL-Analysis-and-Queries)
- [Key Insights](#Key-Insights)


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
#### TOTAL COUNT AND AMOUNT
```sql
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
```

### Key Insights
- Reconciliation rate of approximately 87% indicates operational inefficiencies.
- Amount mismatches contributed the highest financial exposure.
- Financial risk is concentrated among a small number of accounts.
- Monthly trends show consistent anomaly patterns, suggesting systemic issues.

## Conclusion
This project demonstrates how data reconciliation can uncover hidden discrepancies within financial systems. Although most transactions were successfully reconciled, the presence of anomalies and financial exposure indicates that critical inconsistencies remain. This highlights the importance of robust reconciliation systems, as even small discrepancies can accumulate into significant financial risk if left undetected.

Interact with dashborad here https://drive.google.com/file/d/1jPTLxM-QhgsNblYpHkkAog42WeNcREZo/view?usp=sharing
--
<img width="1380" height="938" alt="Screenshot 2026-04-14 094010" src="https://github.com/user-attachments/assets/dccee6a9-234a-426c-adca-376b36e7b31d" />



























```

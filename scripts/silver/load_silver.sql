USE DataWareHouse;

INSERT INTO silver.crm_cust_info 
(
cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date
)
select 
cst_id, 
cst_key,
TRIM(cst_firstname) cst_firstname,
TRIM(cst_lastname) cst_lastname,
CASE UPPER(TRIM(cst_marital_status))
WHEN 'M' THEN 'Married'
WHEN 'S' THEN 'Single'
ELSE 'Unknown'
END as cst_marital_status,
CASE UPPER(TRIM(cst_gndr))
WHEN 'M' THEN 'Male'
WHEN 'F' THEN 'Female'
ELSE 'Unknown'
END as cst_gndr,
cst_create_date
from
(
select *,rank() over(partition by cst_id order by cst_create_date desc) as latest_rec
from bronze.crm_cust_info where cst_id is not null
)t where latest_rec=1  ;


INSERT INTO silver.crm_prd_info 
(
prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_Start_dt, prd_end_dt
)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '', '') as cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key, 
prd_nm,
ISNULL(prd_cost,0) prd_cost,
CASE UPPER(TRIM(prd_line))
WHEN 'R' THEN 'Road'
WHEN 'S' THEN 'Other Sales'
WHEN 'M' THEN 'Mountain'
WHEN 'T' THEN 'Touring'
ELSE 'n/a'
END as prd_line,
prd_start_dt,
DATEADD(DAY, -1, lead(prd_start_dt) over(partition by prd_key order by prd_start_dt))  AS prd_end_dt
from bronze.crm_prd_info

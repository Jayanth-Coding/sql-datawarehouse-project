USE DataWareHouse;

TRUNCATE TABLE silver.crm_cust_info;
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


TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info 
(
prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_Start_dt, prd_end_dt
)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
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
from bronze.crm_prd_info;


TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details
(
sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
)
SELECT sls_ord_num,
       sls_prd_key,
       sls_cust_id,
       CASE 
       WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_order_dt as VARCHAR) AS DATE)
       END AS sls_order_dt,
       
       CASE 
       WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_ship_dt as VARCHAR) AS DATE)
       END AS sls_ship_dt,

       CASE 
       WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_due_dt as VARCHAR) AS DATE)
       END AS sls_due_dt,
       CASE
       WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
       THEN sls_quantity * ABS(sls_price)
       ELSE sls_sales
       END AS sls_sales,
       sls_quantity,       
       CASE WHEN sls_price IS NULL OR sls_price <=0
       THEN sls_sales / NULLIF(sls_quantity, 0)
       ELSE sls_price
       END AS sls_price
  FROM [DataWareHouse].[bronze].[crm_sales_details]

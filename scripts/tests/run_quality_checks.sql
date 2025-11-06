/*
===============================================================================
 Script:      run_quality_checks.sql
 Project:     SQL Data Warehouse & Analytics
 Purpose:     Execute repeatable quality checks across the silver and gold
              layers to validate data completeness, standardisation, and
              dimensional relationships after a load.
===============================================================================
 Usage:
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\tests\run_quality_checks.sql
 Notes:
   - Review each result set; any returned rows indicate an issue that needs
     investigation.
   - All checks are idempotent and safe to rerun after incremental loads.
===============================================================================
*/

USE DataWarehouse;
GO

SET NOCOUNT ON;
GO

PRINT '================================================';
PRINT ' Quality Checks - SILVER LAYER';
PRINT '================================================';

-------------------------------------------------------------------------------
-- silver.crm_cust_info
-------------------------------------------------------------------------------
PRINT '>> Duplicate or NULL cust_sk in silver.crm_cust_info';
SELECT cust_sk, COUNT(*) AS row_count
FROM silver.crm_cust_info
GROUP BY cust_sk
HAVING COUNT(*) > 1 OR MIN(cust_sk) IS NULL;

PRINT '>> Trim validation for cst_key (expected: 0 rows)';
SELECT cst_key
FROM silver.crm_cust_info
WHERE cst_key <> TRIM(cst_key);

PRINT '>> Gender domain values (investigate values outside expected set)';
SELECT DISTINCT gender
FROM silver.crm_cust_info
WHERE gender NOT IN ('Male','Female','Unknown');

PRINT '>> Birthdate range outside reasonable bounds';
SELECT cust_sk, birth_date
FROM silver.crm_cust_info
WHERE birth_date IS NOT NULL
  AND (birth_date < DATEFROMPARTS(1924,1,1) OR birth_date > CAST(GETDATE() AS date));

-------------------------------------------------------------------------------
-- silver.crm_prd_info
-------------------------------------------------------------------------------
PRINT '>> Duplicate or NULL product_sk in silver.crm_prd_info';
SELECT product_sk, COUNT(*) AS row_count
FROM silver.crm_prd_info
GROUP BY product_sk
HAVING COUNT(*) > 1 OR MIN(product_sk) IS NULL;

PRINT '>> Trim validation for prd_key (expected: 0 rows)';
SELECT prd_key
FROM silver.crm_prd_info
WHERE prd_key <> TRIM(prd_key);

PRINT '>> Negative or NULL product_cost';
SELECT product_sk, product_cost
FROM silver.crm_prd_info
WHERE product_cost IS NULL OR product_cost < 0;

PRINT '>> Missing category enrichment from ERP';
SELECT product_sk, prd_key
FROM silver.crm_prd_info
WHERE cat_id IS NULL
   OR category_name IS NULL
   OR subcategory_name IS NULL
   OR is_maintenance IS NULL;

PRINT '>> Invalid date ranges (valid_to earlier than valid_from)';
SELECT product_sk, valid_from, valid_to
FROM silver.crm_prd_info
WHERE valid_from IS NOT NULL
  AND valid_to   IS NOT NULL
  AND valid_to < valid_from;

-------------------------------------------------------------------------------
-- silver.crm_sales_details
-------------------------------------------------------------------------------
PRINT '>> Sales rows with null surrogate keys (expected: 0 rows)';
SELECT sls_ord_num, sls_prd_key, sls_cust_id
FROM silver.crm_sales_details
WHERE product_sk IS NULL OR cust_sk IS NULL;

PRINT '>> Shipping/due dates preceding order date';
SELECT sls_ord_num, order_date, ship_date, due_date
FROM silver.crm_sales_details
WHERE (ship_date IS NOT NULL AND order_date > ship_date)
   OR (due_date  IS NOT NULL AND order_date > due_date);

PRINT '>> Sales amount mismatch vs quantity * unit_price';
SELECT sls_ord_num, sls_prd_key, sales_amount, quantity, unit_price
FROM silver.crm_sales_details
WHERE sales_amount IS NULL
   OR quantity     IS NULL
   OR unit_price   IS NULL
   OR sales_amount <= 0
   OR quantity     <= 0
   OR unit_price   <= 0
   OR sales_amount <> TRY_CONVERT(decimal(18,2), quantity * unit_price);

-------------------------------------------------------------------------------
-- silver.erp_cust_az12
-------------------------------------------------------------------------------
PRINT '>> ERP demographics with out-of-range birthdates';
SELECT cid, bdate
FROM silver.erp_cust_az12
WHERE bdate IS NOT NULL
  AND (bdate < DATEFROMPARTS(1924,1,1) OR bdate > CAST(GETDATE() AS date));

PRINT '>> Unexpected gender values in ERP demographics';
SELECT DISTINCT gen
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male','Female','Unknown');

-------------------------------------------------------------------------------
-- silver.erp_loc_a101
-------------------------------------------------------------------------------
PRINT '>> Location rows with blank country codes';
SELECT cid, cntry
FROM silver.erp_loc_a101
WHERE cntry IS NULL OR LTRIM(RTRIM(cntry)) = '';

-------------------------------------------------------------------------------
-- silver.erp_px_cat_g1v2
-------------------------------------------------------------------------------
PRINT '>> Category lookup values with trailing spaces';
SELECT id, cat, subcat, maintenance
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);

PRINT '>> Unexpected maintenance flags';
SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2
WHERE UPPER(TRIM(maintenance)) NOT IN ('YES','NO');

PRINT '================================================';
PRINT ' Quality Checks - GOLD LAYER';
PRINT '================================================';

-------------------------------------------------------------------------------
-- gold.dim_customers
-------------------------------------------------------------------------------
PRINT '>> Duplicate customer_key values in gold.dim_customers';
SELECT customer_key, COUNT(*) AS row_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-------------------------------------------------------------------------------
-- gold.dim_products
-------------------------------------------------------------------------------
PRINT '>> Duplicate product_key values in gold.dim_products';
SELECT product_key, COUNT(*) AS row_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-------------------------------------------------------------------------------
-- gold.fact_sales
-------------------------------------------------------------------------------
PRINT '>> Fact rows without matching dimension keys';
SELECT f.order_number, f.product_key, f.customer_key
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products  AS p ON p.product_key  = f.product_key
LEFT JOIN gold.dim_customers AS c ON c.customer_key = f.customer_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;

PRINT '>> Fact rows with non-positive metrics';
SELECT order_number, sales_amount, quantity, unit_price
FROM gold.fact_sales
WHERE sales_amount <= 0
   OR quantity     <= 0
   OR unit_price   <= 0;

PRINT '================================================';
PRINT ' Quality checks complete. Review result sets for any anomalies.';

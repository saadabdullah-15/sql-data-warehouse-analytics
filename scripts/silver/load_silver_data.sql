/*
===============================================================================
 File: load_silver_data.sql
===============================================================================
 Purpose:
   Create or replace the silver.load_silver stored procedure that loads the
   [silver] layer from [bronze] with:
     - canonical ID normalization (customer ids across CRM and ERP)
     - product category enrichment from ERP category table
     - robust date parsing for yyyymmdd ints
     - money math with decimal(18,2)
     - surrogate key resolution in sales (product_sk, cust_sk)
     - rejects capture and load summary

 Usage:
   EXEC silver.load_silver;
===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  DECLARE
      @batch_start_time datetime,
      @batch_end_time   datetime,
      @start_time       datetime,
      @end_time         datetime;

  -- Guard rails
  IF SCHEMA_ID(N'silver') IS NULL
  BEGIN
      THROW 50031, N'Schema [silver] not found. Run create_silver_tables.sql first.', 1;
  END;

  -- Ensure rejects table exists once
  IF OBJECT_ID(N'silver.crm_sales_details_rejects', N'U') IS NULL
  BEGIN
      CREATE TABLE silver.crm_sales_details_rejects
      (
          sls_ord_num       nvarchar(50)  NOT NULL,
          sls_prd_key       nvarchar(50)  NOT NULL,
          sls_cust_id       int           NOT NULL,
          order_date        date          NULL,
          ship_date         date          NULL,
          due_date          date          NULL,
          sales_amount      decimal(18,2) NULL,
          quantity          int           NULL,
          unit_price        decimal(18,2) NULL,
          reject_reason     nvarchar(200) NOT NULL,
          dwh_create_date   datetime2     NOT NULL DEFAULT sysutcdatetime()
      );
  END;

  BEGIN TRY
    SET @batch_start_time = GETDATE();

    PRINT '================================================';
    PRINT '               LOADING SILVER LAYER              ';
    PRINT '================================================';

    BEGIN TRAN;

    /* ----------------------------------------------------------
       Truncate in dependency-safe order
    -----------------------------------------------------------*/
    TRUNCATE TABLE silver.crm_sales_details;
    TRUNCATE TABLE silver.crm_sales_details_rejects;
    TRUNCATE TABLE silver.crm_prd_info;
    TRUNCATE TABLE silver.crm_cust_info;
    TRUNCATE TABLE silver.erp_cust_az12;
    TRUNCATE TABLE silver.erp_loc_a101;
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    /* ----------------------------------------------------------
       ERP lookups
    -----------------------------------------------------------*/
    PRINT 'Loading ERP lookup: px_cat_g1v2';
    SET @start_time = GETDATE();

    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT id, cat, subcat, maintenance
    FROM bronze.erp_px_cat_g1v2;

    SET @end_time = GETDATE();
    PRINT '>> px_cat_g1v2 loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS nvarchar(10)) + ' sec';

    PRINT 'Loading ERP lookup: loc_a101';
    SET @start_time = GETDATE();

    INSERT INTO silver.erp_loc_a101 (cid, canon_cid, cntry)
    SELECT
        b.cid,
        REPLACE(b.cid, '-', '') AS canon_cid,                                   -- join-friendly
        CASE
            WHEN TRIM(b.cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(b.cntry) IN ('US','USA') THEN 'United States'
            WHEN TRIM(b.cntry) = '' OR b.cntry IS NULL THEN 'n/a'
            ELSE TRIM(b.cntry)
        END AS cntry
    FROM bronze.erp_loc_a101 b;

    SET @end_time = GETDATE();
    PRINT '>> loc_a101 loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS nvarchar(10)) + ' sec';

    PRINT 'Loading ERP lookup: cust_az12';
    SET @start_time = GETDATE();

    INSERT INTO silver.erp_cust_az12 (cid, canon_cid, bdate, gen)
    SELECT
        b.cid,
        REPLACE(REPLACE(b.cid, '-', ''), 'NAS', '') AS canon_cid,               -- remove dash and NAS prefix
        CASE WHEN TRY_CONVERT(date, b.bdate) > CAST(GETDATE() AS date)          -- future birthdates to NULL
             THEN NULL ELSE TRY_CONVERT(date, b.bdate) END AS bdate,
        CASE
            WHEN UPPER(TRIM(b.gen)) IN ('F','FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(b.gen)) IN ('M','MALE')   THEN 'Male'
            ELSE 'Unknown'
        END AS gen
    FROM bronze.erp_cust_az12 b;

    SET @end_time = GETDATE();
    PRINT '>> cust_az12 loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS nvarchar(10)) + ' sec';

    /* ----------------------------------------------------------
       CRM products enriched with ERP category
    -----------------------------------------------------------*/
    PRINT 'Loading CRM products';
    SET @start_time = GETDATE();

    ;WITH base AS (
      SELECT
          prd_id,
          prd_key,                                              -- keep full key intact
          LTRIM(RTRIM(prd_nm)) AS product_name,
          TRY_CONVERT(decimal(18,2), prd_cost) AS product_cost, -- money to decimal
          prd_line,
          TRY_CONVERT(date, prd_start_dt) AS valid_from,
          ISNULL(TRY_CONVERT(date, prd_end_dt), CONVERT(date,'9999-12-31')) AS valid_to,
          ROW_NUMBER() OVER (
              PARTITION BY prd_key
              ORDER BY
                  CASE WHEN TRY_CONVERT(date, prd_start_dt) IS NULL THEN 1 ELSE 0 END,
                  TRY_CONVERT(date, prd_start_dt) DESC,
                  CASE WHEN TRY_CONVERT(date, prd_end_dt) IS NULL THEN 1 ELSE 0 END,
                  TRY_CONVERT(date, prd_end_dt) DESC,
                  prd_id DESC
          ) AS rn
      FROM bronze.crm_prd_info
    ),
    latest AS (
      SELECT *
      FROM base
      WHERE rn = 1
    ),
    catkey AS (
      SELECT
          *,
          CONCAT(
              PARSENAME(REPLACE(prd_key,'-','.'),5),'_',
              PARSENAME(REPLACE(prd_key,'-','.'),4)
          ) AS cat_id
      FROM latest
    )
    INSERT INTO silver.crm_prd_info
    (
        prd_id, prd_key, canon_prd_key, product_name, product_cost, prd_line,
        valid_from, valid_to, cat_id, category_name, subcategory_name, is_maintenance
    )
    SELECT
        c.prd_id,
        key_raw.prd_key_clean AS prd_key,
        CASE
          WHEN key_parts.second_dash > 0
            THEN SUBSTRING(key_raw.prd_key_clean, key_parts.second_dash + 1, LEN(key_raw.prd_key_clean))
          ELSE key_raw.prd_key_clean
        END AS canon_prd_key,
        c.product_name,
        c.product_cost,
        CASE UPPER(TRIM(c.prd_line))
          WHEN 'M' THEN 'Mountain'
          WHEN 'R' THEN 'Road'
          WHEN 'S' THEN 'Other Sales'
          WHEN 'T' THEN 'Touring'
          ELSE 'n/a'
        END AS prd_line,
        c.valid_from,
        c.valid_to,
        c.cat_id,
        e.cat,
        e.subcat,
        CASE WHEN e.maintenance = 'Yes' THEN 1
             WHEN e.maintenance = 'No'  THEN 0
             ELSE NULL END AS is_maintenance
    FROM catkey c
    CROSS APPLY (
        SELECT
            UPPER(LTRIM(RTRIM(c.prd_key))) AS prd_key_clean,
            CHARINDEX('-', UPPER(LTRIM(RTRIM(c.prd_key)))) AS first_dash
    ) key_raw
    CROSS APPLY (
        SELECT
            CASE
              WHEN key_raw.first_dash > 0
                THEN CHARINDEX('-', key_raw.prd_key_clean, key_raw.first_dash + 1)
              ELSE 0
            END AS second_dash
    ) key_parts
    LEFT JOIN silver.erp_px_cat_g1v2 e
           ON e.id = c.cat_id;

    SET @end_time = GETDATE();
    PRINT '>> products loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS nvarchar(10)) + ' sec';

    /* ----------------------------------------------------------
       CRM customers enriched with ERP demographics and location
    -----------------------------------------------------------*/
    PRINT 'Loading CRM customers';
    SET @start_time = GETDATE();

    ;WITH crm_base AS (
      SELECT
          cst_id,
          cst_key,
          cst_key AS canon_cst_key,                             -- CRM key is already AW + digits
          LTRIM(RTRIM(cst_firstname)) AS first_name,
          LTRIM(RTRIM(cst_lastname))  AS last_name,
          CASE UPPER(LTRIM(RTRIM(cst_gndr)))
               WHEN 'M' THEN 'Male'
               WHEN 'F' THEN 'Female'
               ELSE 'Unknown'
          END AS gender_norm,
          CASE UPPER(LTRIM(RTRIM(cst_marital_status)))
               WHEN 'M' THEN 'Married'
               WHEN 'S' THEN 'Single'
               ELSE 'Unknown'
          END AS marital_status,
          TRY_CONVERT(date, cst_create_date) AS created_date,
          ROW_NUMBER() OVER (
              PARTITION BY cst_key
              ORDER BY
                  CASE WHEN TRY_CONVERT(date, cst_create_date) IS NULL THEN 1 ELSE 0 END,
                  TRY_CONVERT(date, cst_create_date) DESC,
                  cst_id DESC
          ) AS rn
      FROM bronze.crm_cust_info
      WHERE cst_id IS NOT NULL
    ),
    crm AS (
      SELECT
          cst_id,
          cst_key,
          canon_cst_key,
          first_name,
          last_name,
          gender_norm,
          marital_status,
          created_date
      FROM crm_base
      WHERE rn = 1
    ),
    joined AS (
      SELECT
          c.cst_id,
          c.cst_key,
          c.canon_cst_key,
          c.first_name,
          c.last_name,
          COALESCE(d.gen, c.gender_norm, 'Unknown') AS gender,
          c.marital_status,
          c.created_date,
          d.bdate AS birth_date,
          l.cntry AS country
      FROM crm c
      LEFT JOIN silver.erp_cust_az12 d
             ON d.canon_cid = c.canon_cst_key
      LEFT JOIN silver.erp_loc_a101 l
             ON l.canon_cid = c.canon_cst_key
    )
    INSERT INTO silver.crm_cust_info
    (
        cst_id, cst_key, canon_cst_key, first_name, last_name, gender,
        marital_status, created_date, birth_date, country, age_years
    )
    SELECT
        j.cst_id,
        j.cst_key,
        j.canon_cst_key,
        j.first_name,
        j.last_name,
        j.gender,
        j.marital_status,
        j.created_date,
        j.birth_date,
        j.country,
        CASE
          WHEN j.birth_date IS NULL THEN NULL
          ELSE DATEDIFF(year, j.birth_date, CAST(GETDATE() AS date))
               - CASE
                   WHEN DATEADD(year, DATEDIFF(year, j.birth_date, CAST(GETDATE() AS date)), j.birth_date) > CAST(GETDATE() AS date)
                     THEN 1 ELSE 0 END
        END AS age_years
    FROM joined j;

    SET @end_time = GETDATE();
    PRINT '>> customers loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS nvarchar(10)) + ' sec';

    /* ----------------------------------------------------------
       CRM sales parsed, fixed and keyed to Silver dims
    -----------------------------------------------------------*/
    PRINT 'Loading CRM sales';
    SET @start_time = GETDATE();

    IF OBJECT_ID('tempdb..#sales_resolved') IS NOT NULL
        DROP TABLE #sales_resolved;

    ;WITH parsed AS (
      SELECT
          b.sls_ord_num,
          b.sls_prd_key,
          b.sls_cust_id,
          CASE WHEN b.sls_order_dt = 0 OR LEN(b.sls_order_dt) <> 8
               THEN NULL ELSE TRY_CONVERT(date, CONVERT(varchar(8), b.sls_order_dt)) END AS order_date,
          CASE WHEN b.sls_ship_dt  = 0 OR LEN(b.sls_ship_dt)  <> 8
               THEN NULL ELSE TRY_CONVERT(date, CONVERT(varchar(8), b.sls_ship_dt))  END AS ship_date,
          CASE WHEN b.sls_due_dt   = 0 OR LEN(b.sls_due_dt)   <> 8
               THEN NULL ELSE TRY_CONVERT(date, CONVERT(varchar(8), b.sls_due_dt))   END AS due_date,
          TRY_CONVERT(int, b.sls_quantity)            AS quantity_raw,
          TRY_CONVERT(decimal(18,2), b.sls_price)     AS price_raw,
          TRY_CONVERT(decimal(18,2), b.sls_sales)     AS sales_raw
      FROM bronze.crm_sales_details b
    ),
    computed AS (
      SELECT
          p.*,
          UPPER(LTRIM(RTRIM(p.sls_prd_key))) AS sls_prd_key_clean,
          UPPER(LTRIM(RTRIM(p.sls_prd_key))) AS canon_sls_prd_key,
          CASE
            WHEN p.sales_raw IS NULL OR p.sales_raw <= 0
                 OR (p.price_raw IS NOT NULL AND p.quantity_raw IS NOT NULL AND p.sales_raw <> p.quantity_raw * ABS(p.price_raw))
            THEN TRY_CONVERT(decimal(18,2), p.quantity_raw * ABS(p.price_raw))
            ELSE p.sales_raw
          END AS sales_amount,
          p.quantity_raw AS quantity,
          CASE
            WHEN (p.price_raw IS NULL OR p.price_raw <= 0) AND p.quantity_raw IS NOT NULL AND p.quantity_raw <> 0
              THEN TRY_CONVERT(decimal(18,2), p.sales_raw / NULLIF(p.quantity_raw, 0))
            ELSE p.price_raw
          END AS unit_price
      FROM parsed p
    ),
    resolved AS (
      SELECT
          c.sls_ord_num,
          c.sls_prd_key,
          c.sls_cust_id,
          c.order_date,
          c.ship_date,
          c.due_date,
          c.sales_amount,
          c.quantity,
          c.unit_price,
          dp.product_sk,
          dc.cust_sk
      FROM computed c
      LEFT JOIN silver.crm_prd_info  dp ON dp.canon_prd_key = c.canon_sls_prd_key
      LEFT JOIN silver.crm_cust_info dc ON dc.cst_id  = c.sls_cust_id
    )
    SELECT
        r.sls_ord_num,
        r.sls_prd_key,
        r.sls_cust_id,
        r.order_date,
        r.ship_date,
        r.due_date,
        r.sales_amount,
        r.quantity,
        r.unit_price,
        r.product_sk,
        r.cust_sk
    INTO #sales_resolved
    FROM resolved r;

    INSERT INTO silver.crm_sales_details
    (
        sls_ord_num, sls_prd_key, sls_cust_id,
        order_date, ship_date, due_date,
        sales_amount, quantity, unit_price,
        product_sk, cust_sk
    )
    SELECT
        sr.sls_ord_num,
        sr.sls_prd_key,
        sr.sls_cust_id,
        sr.order_date,
        sr.ship_date,
        sr.due_date,
        sr.sales_amount,
        sr.quantity,
        sr.unit_price,
        sr.product_sk,
        sr.cust_sk
    FROM #sales_resolved AS sr
    WHERE sr.product_sk IS NOT NULL
      AND sr.cust_sk    IS NOT NULL;

    -- Rejects for visibility
    INSERT INTO silver.crm_sales_details_rejects
    (
        sls_ord_num, sls_prd_key, sls_cust_id,
        order_date, ship_date, due_date,
        sales_amount, quantity, unit_price, reject_reason
    )
    SELECT
        sr.sls_ord_num,
        sr.sls_prd_key,
        sr.sls_cust_id,
        sr.order_date,
        sr.ship_date,
        sr.due_date,
        sr.sales_amount,
        sr.quantity,
        sr.unit_price,
        CASE
          WHEN sr.product_sk IS NULL AND sr.cust_sk IS NULL THEN 'Missing product and customer'
          WHEN sr.product_sk IS NULL THEN 'Missing product'
          WHEN sr.cust_sk    IS NULL THEN 'Missing customer'
          ELSE 'Unknown'
        END AS reject_reason
    FROM #sales_resolved AS sr
    WHERE sr.product_sk IS NULL
       OR sr.cust_sk    IS NULL;

    DROP TABLE #sales_resolved;

    SET @end_time = GETDATE();
    PRINT '>> sales loaded in ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS nvarchar(10)) + ' sec';

    /* ----------------------------------------------------------
       Commit and summaries
    -----------------------------------------------------------*/
    COMMIT;

    PRINT '------------------------------------------------';
    PRINT 'Row counts after load';
    PRINT '------------------------------------------------';

    SELECT 'silver.erp_px_cat_g1v2'  AS table_name, COUNT(*) AS rows FROM silver.erp_px_cat_g1v2
    UNION ALL SELECT 'silver.erp_loc_a101',        COUNT(*) FROM silver.erp_loc_a101
    UNION ALL SELECT 'silver.erp_cust_az12',       COUNT(*) FROM silver.erp_cust_az12
    UNION ALL SELECT 'silver.crm_prd_info',        COUNT(*) FROM silver.crm_prd_info
    UNION ALL SELECT 'silver.crm_cust_info',       COUNT(*) FROM silver.crm_cust_info
    UNION ALL SELECT 'silver.crm_sales_details',   COUNT(*) FROM silver.crm_sales_details
    UNION ALL SELECT 'silver.crm_sales_details_rejects', COUNT(*) FROM silver.crm_sales_details_rejects
    ORDER BY table_name;

    PRINT '------------------------------------------------';
    PRINT 'Data quality checks';
    PRINT '------------------------------------------------';

    -- Unmapped categories
    SELECT COUNT(*) AS unmapped_products
    FROM silver.crm_prd_info
    WHERE cat_id IS NULL;

    -- Orphan checks as seen in rejects
    SELECT
      SUM(CASE WHEN reject_reason = 'Missing product'              THEN 1 ELSE 0 END) AS missing_product,
      SUM(CASE WHEN reject_reason = 'Missing customer'             THEN 1 ELSE 0 END) AS missing_customer,
      SUM(CASE WHEN reject_reason = 'Missing product and customer' THEN 1 ELSE 0 END) AS missing_both
    FROM silver.crm_sales_details_rejects;

    SET @batch_end_time = GETDATE();
    PRINT '================================================';
    PRINT ' Silver Layer Load Completed Successfully';
    PRINT '   Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS nvarchar(10)) + ' seconds';
    PRINT '================================================';
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;

    PRINT '================================================';
    PRINT ' Error while loading Silver';
    PRINT '   Message : ' + ERROR_MESSAGE();
    PRINT '   Number  : ' + CAST(ERROR_NUMBER() AS nvarchar(10));
    PRINT '   State   : ' + CAST(ERROR_STATE()  AS nvarchar(10));
    PRINT '   Line    : ' + CAST(ERROR_LINE()   AS nvarchar(10));
    PRINT '================================================';

    THROW;
  END CATCH
END;
GO

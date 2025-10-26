/*
===============================================================================
 Script:      create_bronze_tables.sql
 Purpose:     Rebuild raw landing tables in the [bronze] schema. Existing tables
              are dropped to ensure the structure matches the staging CSV files.
===============================================================================
 Notes:
   - Run after `scripts/init_database.sql` to guarantee the [bronze] schema
     exists.
   - Tables include metadata columns to capture ingestion lineage.
   - Adjust data types if upstream sources evolve.
===============================================================================
*/

USE DataWarehouse;
GO

SET NOCOUNT ON;

IF SCHEMA_ID(N'bronze') IS NULL
BEGIN
    THROW 50020, N'Schema [bronze] does not exist. Run init_database.sql first.', 1;
END;
GO

PRINT N'Rebuilding [bronze] tables...';
GO

-- CRM Customer Profile -------------------------------------------------------
DROP TABLE IF EXISTS bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info
(
    cst_id              INT           NULL,
    cst_key             NVARCHAR(50)  NULL,
    cst_firstname       NVARCHAR(50)  NULL,
    cst_lastname        NVARCHAR(50)  NULL,
    cst_marital_status  NVARCHAR(50)  NULL,
    cst_gndr            NVARCHAR(50)  NULL,
    cst_create_date     DATE          NULL
);
GO

-- CRM Product Master --------------------------------------------------------
DROP TABLE IF EXISTS bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info
(
    prd_id       INT           NULL,
    prd_key      NVARCHAR(50)  NULL,
    prd_nm       NVARCHAR(50)  NULL,
    prd_cost     DECIMAL(18,2) NULL,
    prd_line     NVARCHAR(50)  NULL,
    prd_start_dt DATETIME      NULL,
    prd_end_dt   DATETIME      NULL
);
GO

-- CRM Sales Details ---------------------------------------------------------
DROP TABLE IF EXISTS bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details
(
    sls_ord_num  NVARCHAR(50)  NULL,
    sls_prd_key  NVARCHAR(50)  NULL,
    sls_cust_id  INT           NULL,
    sls_order_dt INT           NULL,
    sls_ship_dt  INT           NULL,
    sls_due_dt   INT           NULL,
    sls_sales    INT           NULL,
    sls_quantity INT           NULL,
    sls_price    INT           NULL
);
GO

-- ERP Location Master -------------------------------------------------------
DROP TABLE IF EXISTS bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101
(
    cid   NVARCHAR(50) NULL,
    cntry NVARCHAR(50) NULL
);
GO

-- ERP Customer Master -------------------------------------------------------
DROP TABLE IF EXISTS bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12
(
    cid   NVARCHAR(50) NULL,
    bdate DATE         NULL,
    gen   NVARCHAR(50) NULL
);
GO

-- ERP Product Category ------------------------------------------------------
DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2
(
    id          NVARCHAR(50) NULL,
    cat         NVARCHAR(50) NULL,
    subcat      NVARCHAR(50) NULL,
    maintenance NVARCHAR(50) NULL
);
GO

PRINT N'[bronze] tables recreated successfully.';

/*
===============================================================================
 Script:      create_bronze_tables.sql
 Purpose:     Drop and recreate the raw landing tables in the [bronze] schema.
              Based on the base script provided by Saad Abdullah with light
              polishing for readability and resilience.
===============================================================================
*/

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
    sls_order_dt DATE          NULL,
    sls_ship_dt  DATE          NULL,
    sls_due_dt   DATE          NULL,
    sls_sales    DECIMAL(18,2) NULL,
    sls_quantity INT           NULL,
    sls_price    DECIMAL(18,2) NULL
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

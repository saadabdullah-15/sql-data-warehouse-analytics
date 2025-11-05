/*
===============================================================================
 File: create_silver_tables.sql
===============================================================================
 Purpose:
   Recreate tables in the [silver] schema with analytics-friendly data types,
   minimal keys, and helper indexes. Keeps a dwh_create_date audit column.
===============================================================================
 Notes:
   - Money-like fields use decimal(18,2).
   - Adds surrogate keys for customer and product.
   - Sales keeps a natural composite primary key (order + product).
   - Adjust sizes and constraints as your sources evolve.
===============================================================================
*/

USE DataWarehouse;
GO

SET NOCOUNT ON;
GO

IF SCHEMA_ID(N'silver') IS NULL
BEGIN
    THROW 50030, N'Schema [silver] does not exist. Run init_database.sql first.', 1;
END;
GO

PRINT N'Rebuilding [silver] tables...';
GO

/* Drop in dependency-friendly order */
IF OBJECT_ID(N'silver.crm_sales_details', N'U') IS NOT NULL DROP TABLE silver.crm_sales_details;
IF OBJECT_ID(N'silver.crm_prd_info',       N'U') IS NOT NULL DROP TABLE silver.crm_prd_info;
IF OBJECT_ID(N'silver.crm_cust_info',      N'U') IS NOT NULL DROP TABLE silver.crm_cust_info;
IF OBJECT_ID(N'silver.erp_cust_az12',      N'U') IS NOT NULL DROP TABLE silver.erp_cust_az12;
IF OBJECT_ID(N'silver.erp_loc_a101',       N'U') IS NOT NULL DROP TABLE silver.erp_loc_a101;
IF OBJECT_ID(N'silver.erp_px_cat_g1v2',    N'U') IS NOT NULL DROP TABLE silver.erp_px_cat_g1v2;
GO

/* Lookup: ERP product category */
CREATE TABLE silver.erp_px_cat_g1v2
(
    id               nvarchar(20)  NOT NULL PRIMARY KEY,   -- e.g., AC_HE
    cat              nvarchar(50)  NULL,
    subcat           nvarchar(50)  NULL,
    maintenance      nvarchar(50)   NULL,                   -- Yes/No from source
    dwh_create_date  datetime2     NOT NULL DEFAULT sysutcdatetime()
);
GO

/* ERP location by customer id */
CREATE TABLE silver.erp_loc_a101
(
    cid              nvarchar(32)  NOT NULL,               -- raw ERP id (may contain a dash)
    canon_cid        nvarchar(32)  NOT NULL,               -- normalized id for joins (no dash or prefixes)
    cntry            nvarchar(80)  NULL,
    dwh_create_date  datetime2     NOT NULL DEFAULT sysutcdatetime(),
    CONSTRAINT PK_erp_loc_a101 PRIMARY KEY (cid)
);
GO

/* ERP customer demographics */
CREATE TABLE silver.erp_cust_az12
(
    cid              nvarchar(32)  NOT NULL,
    canon_cid        nvarchar(32)  NOT NULL,               -- normalized join key
    bdate            date          NULL,
    gen              nvarchar(10)  NULL,                   -- Male/Female/Unknown as in source
    dwh_create_date  datetime2     NOT NULL DEFAULT sysutcdatetime(),
    CONSTRAINT PK_erp_cust_az12 PRIMARY KEY (cid)
);
GO

/* CRM customers, conformed and enriched */
CREATE TABLE silver.crm_cust_info
(
    cust_sk          bigint        NOT NULL IDENTITY(1,1) PRIMARY KEY,  -- warehouse surrogate key
    cst_id           int           NOT NULL,                             -- CRM numeric id
    cst_key          nvarchar(32)  NOT NULL,                             -- CRM business key, e.g., AW000011000
    canon_cst_key    nvarchar(32)  NOT NULL,                             -- normalized key for joins
    first_name       nvarchar(50)  NULL,
    last_name        nvarchar(50)  NULL,
    gender           nvarchar(10)  NULL,                                 -- Male/Female/Unknown
    marital_status   nvarchar(10)  NULL,                                 -- Single/Married/Unknown
    created_date     date          NULL,
    birth_date       date          NULL,
    country          nvarchar(80)  NULL,
    age_years        int           NULL,
    dwh_create_date  datetime2     NOT NULL DEFAULT sysutcdatetime(),
    CONSTRAINT UQ_cust_business UNIQUE (cst_key)
);
GO

/* CRM products, enriched with category */
CREATE TABLE silver.crm_prd_info
(
    product_sk       bigint        NOT NULL IDENTITY(1,1) PRIMARY KEY,   -- warehouse surrogate key
    prd_id           int           NULL,
    prd_key          nvarchar(50)  NOT NULL,                             -- e.g., AC-HE-HL-U509-R
    canon_prd_key    nvarchar(50)  NOT NULL,                             -- normalized key for joins (e.g., BK-*)
    product_name     nvarchar(100) NULL,
    product_cost     decimal(18,2) NULL,
    prd_line         nvarchar(20)  NULL,
    valid_from       date          NULL,
    valid_to         date          NULL,
    cat_id           nvarchar(20)  NULL,                                 -- e.g., AC_HE
    category_name    nvarchar(50)  NULL,
    subcategory_name nvarchar(50)  NULL,
    is_maintenance   bit           NULL,
    dwh_create_date  datetime2     NOT NULL DEFAULT sysutcdatetime(),
    CONSTRAINT UQ_product_business UNIQUE (prd_key),
    CONSTRAINT UQ_product_canon UNIQUE (canon_prd_key)
);
GO

/* CRM sales, cleaned and keyed to dims */
CREATE TABLE silver.crm_sales_details
(
    sls_ord_num      nvarchar(50)  NOT NULL,               -- order number
    sls_prd_key      nvarchar(50)  NOT NULL,               -- product business key from CRM
    sls_cust_id      int           NOT NULL,               -- customer numeric id from CRM
    order_date       date          NULL,
    ship_date        date          NULL,
    due_date         date          NULL,
    sales_amount     decimal(18,2) NULL,
    quantity         int           NULL,
    unit_price       decimal(18,2) NULL,
    product_sk       bigint        NULL,                    -- resolved from silver.crm_prd_info
    cust_sk          bigint        NULL,                    -- resolved from silver.crm_cust_info
    dwh_create_date  datetime2     NOT NULL DEFAULT sysutcdatetime(),
    CONSTRAINT PK_sales PRIMARY KEY (sls_ord_num, sls_prd_key)
);
GO

/* Helper indexes for joins and lookups */
CREATE INDEX IX_dim_product_prd_key   ON silver.crm_prd_info(prd_key);
CREATE INDEX IX_dim_product_canon     ON silver.crm_prd_info(canon_prd_key);
CREATE INDEX IX_dim_customer_cst_id   ON silver.crm_cust_info(cst_id);
CREATE INDEX IX_sales_prd_key         ON silver.crm_sales_details(sls_prd_key);
CREATE INDEX IX_sales_cust_id         ON silver.crm_sales_details(sls_cust_id);
CREATE INDEX IX_loc_canon_cid         ON silver.erp_loc_a101(canon_cid);
CREATE INDEX IX_demo_canon_cid        ON silver.erp_cust_az12(canon_cid);
GO

PRINT N'[silver] tables recreated successfully.';
GO

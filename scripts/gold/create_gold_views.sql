/*
===============================================================================
 Script:      create_gold_views.sql
 Project:     SQL Data Warehouse & Analytics
 Purpose:     Build presentation-ready views in the [gold] schema for analytics.
===============================================================================
 Usage:
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\gold\create_gold_views.sql
 Notes:
   - Views source the cleansed entities in [silver], enriching them and
     presenting a star-schema friendly shape (dimensions + fact).
   - Safe to rerun; views are dropped and recreated in-place.
===============================================================================
*/

USE DataWarehouse;
GO

SET NOCOUNT ON;
GO

-- Guard that the expected schemas exist before building gold views.
IF SCHEMA_ID(N'silver') IS NULL
BEGIN
    THROW 50041, N'Schema [silver] not found. Run init_database.sql and silver scripts first.', 1;
END;

IF SCHEMA_ID(N'gold') IS NULL
BEGIN
    EXEC ('CREATE SCHEMA gold');
    PRINT 'Schema [gold] created.';
END;
GO

PRINT 'Rebuilding gold layer views...';
GO

-------------------------------------------------------------------------------
-- Dimension: gold.dim_customers
-- Combines CRM customers with ERP demographics and location.
-------------------------------------------------------------------------------
IF OBJECT_ID(N'gold.dim_customers', N'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers
AS
WITH base AS (
    SELECT
        c.cust_sk,
        c.cst_id,
        c.cst_key,
        c.canon_cst_key,
        c.first_name,
        c.last_name,
        c.gender,
        c.marital_status,
        c.created_date,
        c.birth_date,
        c.country,
        COALESCE(d.gen, c.gender) AS gender_resolved,
        COALESCE(d.bdate, c.birth_date) AS birthdate_resolved
    FROM silver.crm_cust_info AS c
    LEFT JOIN silver.erp_cust_az12 AS d
        ON d.canon_cid = c.canon_cst_key
),
renamed AS (
    SELECT
        b.cust_sk          AS customer_key, -- reuse silver surrogate
        b.cst_id           AS customer_id,
        b.cst_key          AS customer_number,
        b.canon_cst_key,
        b.first_name,
        b.last_name,
        COALESCE(l.cntry, b.country, 'n/a') AS country,
        b.marital_status,
        COALESCE(NULLIF(b.gender_resolved, 'Unknown'), 'Unknown') AS gender,
        b.birthdate_resolved AS birthdate,
        b.created_date       AS created_date
FROM base AS b
LEFT JOIN silver.erp_loc_a101 AS l
        ON l.canon_cid = b.canon_cst_key
)
SELECT
    customer_key,
    customer_id,
    customer_number,
    first_name,
    last_name,
    country,
    marital_status,
    gender,
    birthdate,
    created_date
FROM renamed;
GO

-------------------------------------------------------------------------------
-- Dimension: gold.dim_products
-- Presents active CRM products with ERP category context.
-------------------------------------------------------------------------------
IF OBJECT_ID(N'gold.dim_products', N'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products
AS
SELECT
    p.product_sk        AS product_key,
    p.prd_id           AS product_id,
    p.prd_key          AS product_number,
    p.product_name,
    p.product_cost     AS cost,
    p.prd_line         AS product_line,
    p.valid_from       AS start_date,
    p.valid_to         AS end_date,
    p.cat_id           AS category_id,
    c.cat              AS category_name,
    c.subcat           AS subcategory_name,
    p.is_maintenance
FROM silver.crm_prd_info AS p
LEFT JOIN silver.erp_px_cat_g1v2 AS c
    ON c.id = p.cat_id;
GO

-------------------------------------------------------------------------------
-- Fact: gold.fact_sales
-- Provides a star-schema ready fact view referencing gold dims.
-------------------------------------------------------------------------------
IF OBJECT_ID(N'gold.fact_sales', N'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales
AS
SELECT
    sd.sls_ord_num     AS order_number,
    sd.product_sk      AS product_key,
    sd.cust_sk         AS customer_key,
    sd.order_date,
    sd.ship_date,
    sd.due_date,
    sd.sales_amount,
    sd.quantity,
    sd.unit_price
FROM silver.crm_sales_details AS sd;
GO

PRINT 'Gold views created (dim_customers, dim_products, fact_sales).';

/*
===============================================================================
 Script:      load_bronze_data.sql
 Purpose:     Bulk load CSV extracts into bronze landing tables. Based on the
              original procedure authored by Saad Abdullah with minor polish
              for configurability and diagnostics.
===============================================================================
 Usage:
     EXEC bronze.load_bronze;  -- uses default data root
     EXEC bronze.load_bronze @DataRoot = N'C:\custom\datasets';
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
(
    @DataRoot        NVARCHAR(4000) = N'C:\sql\dwh_project\datasets',
    @FirstDataRow    INT            = 2,
    @FieldTerminator NVARCHAR(10)   = N','
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @DataRoot IS NULL OR LTRIM(RTRIM(@DataRoot)) = N''
    BEGIN
        THROW 50030, N'@DataRoot cannot be null or empty.', 1;
    END;

    IF RIGHT(@DataRoot, 1) IN (N'\', N'/')
    BEGIN
        SET @DataRoot = LEFT(@DataRoot, LEN(@DataRoot) - 1);
    END;

    DECLARE @CRM_Cust NVARCHAR(4000) = @DataRoot + N'\source_crm\cust_info.csv';
    DECLARE @CRM_Prd  NVARCHAR(4000) = @DataRoot + N'\source_crm\prd_info.csv';
    DECLARE @CRM_Sls  NVARCHAR(4000) = @DataRoot + N'\source_crm\sales_details.csv';
    DECLARE @ERP_Loc  NVARCHAR(4000) = @DataRoot + N'\source_erp\loc_a101.csv';
    DECLARE @ERP_Cust NVARCHAR(4000) = @DataRoot + N'\source_erp\cust_az12.csv';
    DECLARE @ERP_Cat  NVARCHAR(4000) = @DataRoot + N'\source_erp\px_cat_g1v2.csv';

    DECLARE @batch_start_time DATETIME2(0);
    DECLARE @batch_end_time DATETIME2(0);
    DECLARE @start_time DATETIME2(0);
    DECLARE @end_time DATETIME2(0);
    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        SET @batch_start_time = SYSUTCDATETIME();

        PRINT REPLICATE('=', 48);
        PRINT 'Loading Bronze Layer';
        PRINT REPLICATE('=', 48);

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        SET @start_time = SYSUTCDATETIME();
        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;
        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        SET @sql = N'BULK INSERT bronze.crm_cust_info FROM ''' + REPLACE(@CRM_Cust, '''', '''''') + N'''
                    WITH (FIRSTROW = ' + CAST(@FirstDataRow AS NVARCHAR(10)) + N',
                          FIELDTERMINATOR = ''' + REPLACE(@FieldTerminator, '''', '''''') + N''',
                          ROWTERMINATOR = ''0x0a'',
                          TABLOCK,
                          CODEPAGE = ''65001'',
                          KEEPNULLS);';
        EXEC sys.sp_executesql @sql;
        SET @end_time = SYSUTCDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = SYSUTCDATETIME();
        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        SET @sql = N'BULK INSERT bronze.crm_prd_info FROM ''' + REPLACE(@CRM_Prd, '''', '''''') + N'''
                    WITH (FIRSTROW = ' + CAST(@FirstDataRow AS NVARCHAR(10)) + N',
                          FIELDTERMINATOR = ''' + REPLACE(@FieldTerminator, '''', '''''') + N''',
                          ROWTERMINATOR = ''0x0a'',
                          TABLOCK,
                          CODEPAGE = ''65001'',
                          KEEPNULLS);';
        EXEC sys.sp_executesql @sql;
        SET @end_time = SYSUTCDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = SYSUTCDATETIME();
        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Inserting Data Into: bronze.crm_sales_details';
        SET @sql = N'BULK INSERT bronze.crm_sales_details FROM ''' + REPLACE(@CRM_Sls, '''', '''''') + N'''
                    WITH (FIRSTROW = ' + CAST(@FirstDataRow AS NVARCHAR(10)) + N',
                          FIELDTERMINATOR = ''' + REPLACE(@FieldTerminator, '''', '''''') + N''',
                          ROWTERMINATOR = ''0x0a'',
                          TABLOCK,
                          CODEPAGE = ''65001'',
                          KEEPNULLS);';
        EXEC sys.sp_executesql @sql;
        SET @end_time = SYSUTCDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';

        SET @start_time = SYSUTCDATETIME();
        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;
        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
        SET @sql = N'BULK INSERT bronze.erp_loc_a101 FROM ''' + REPLACE(@ERP_Loc, '''', '''''') + N'''
                    WITH (FIRSTROW = ' + CAST(@FirstDataRow AS NVARCHAR(10)) + N',
                          FIELDTERMINATOR = ''' + REPLACE(@FieldTerminator, '''', '''''') + N''',
                          ROWTERMINATOR = ''0x0a'',
                          TABLOCK,
                          CODEPAGE = ''65001'',
                          KEEPNULLS);';
        EXEC sys.sp_executesql @sql;
        SET @end_time = SYSUTCDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = SYSUTCDATETIME();
        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
        SET @sql = N'BULK INSERT bronze.erp_cust_az12 FROM ''' + REPLACE(@ERP_Cust, '''', '''''') + N'''
                    WITH (FIRSTROW = ' + CAST(@FirstDataRow AS NVARCHAR(10)) + N',
                          FIELDTERMINATOR = ''' + REPLACE(@FieldTerminator, '''', '''''') + N''',
                          ROWTERMINATOR = ''0x0a'',
                          TABLOCK,
                          CODEPAGE = ''65001'',
                          KEEPNULLS);';
        EXEC sys.sp_executesql @sql;
        SET @end_time = SYSUTCDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = SYSUTCDATETIME();
        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        SET @sql = N'BULK INSERT bronze.erp_px_cat_g1v2 FROM ''' + REPLACE(@ERP_Cat, '''', '''''') + N'''
                    WITH (FIRSTROW = ' + CAST(@FirstDataRow AS NVARCHAR(10)) + N',
                          FIELDTERMINATOR = ''' + REPLACE(@FieldTerminator, '''', '''''') + N''',
                          ROWTERMINATOR = ''0x0a'',
                          TABLOCK,
                          CODEPAGE = ''65001'',
                          KEEPNULLS);';
        EXEC sys.sp_executesql @sql;
        SET @end_time = SYSUTCDATETIME();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = SYSUTCDATETIME();
        PRINT '==========================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '==========================================';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorState  INT = ERROR_STATE();

        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'Error Number: ' + CAST(@ErrorNumber AS NVARCHAR(10));
        PRINT 'Error State : ' + CAST(@ErrorState AS NVARCHAR(10));
        PRINT 'Error Message: ' + @ErrorMessage;
        PRINT '==========================================';

        THROW;
    END CATCH;
END;
GO

/*
===============================================================================
 Script:      load_bronze_data.sql
 Purpose:     Define procedure [bronze].[load_bronze] that bulk-loads CSV files
              from the local file system into the bronze landing tables.
===============================================================================
 Usage:
     EXEC bronze.load_bronze @DataRoot = N'C:\sql\dwh_project\datasets';
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
(
    @DataRoot         NVARCHAR(4000),
    @FirstDataRow     INT          = 2,
    @FieldTerminator  NVARCHAR(10) = N',',
    @RowTerminator    NVARCHAR(10) = N'0x0a'
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @DataRoot IS NULL OR LTRIM(RTRIM(@DataRoot)) = N''
    BEGIN
        THROW 50010, N'Parameter @DataRoot cannot be null or empty.', 1;
    END;

    IF RIGHT(@DataRoot, 1) IN ('\', '/')
    BEGIN
        SET @DataRoot = LEFT(@DataRoot, LEN(@DataRoot) - 1);
    END;

    DECLARE @batch_start DATETIME2(0) = SYSUTCDATETIME();

    PRINT REPLICATE('=', 80);
    PRINT FORMATMESSAGE(N'Bronze load started at %s (UTC)', CONVERT(VARCHAR(30), @batch_start, 126));
    PRINT FORMATMESSAGE(N'Data root: %s', @DataRoot);
    PRINT REPLICATE('=', 80);

    DECLARE @targets TABLE
    (
        seq       INT IDENTITY(1,1) PRIMARY KEY,
        table_name NVARCHAR(256),
        file_path  NVARCHAR(4000)
    );

    INSERT INTO @targets (table_name, file_path)
    VALUES
        (N'bronze.crm_cust_info',    @DataRoot + N'\source_crm\cust_info.csv'),
        (N'bronze.crm_prd_info',     @DataRoot + N'\source_crm\prd_info.csv'),
        (N'bronze.crm_sales_details',@DataRoot + N'\source_crm\sales_details.csv'),
        (N'bronze.erp_loc_a101',     @DataRoot + N'\source_erp\loc_a101.csv'),
        (N'bronze.erp_cust_az12',    @DataRoot + N'\source_erp\cust_az12.csv'),
        (N'bronze.erp_px_cat_g1v2',  @DataRoot + N'\source_erp\px_cat_g1v2.csv');

    DECLARE @table_name NVARCHAR(256);
    DECLARE @file_path NVARCHAR(4000);
    DECLARE @step_start DATETIME2(0);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @rowcount INT;

    DECLARE load_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT table_name, file_path FROM @targets ORDER BY seq;

    BEGIN TRY
        OPEN load_cursor;

        FETCH NEXT FROM load_cursor INTO @table_name, @file_path;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF OBJECT_ID(@table_name, N'U') IS NULL
            BEGIN
                THROW 50011, FORMATMESSAGE(N'Table %s does not exist. Run create_bronze_tables.sql first.', @table_name), 1;
            END;

            SET @step_start = SYSUTCDATETIME();
            PRINT REPLICATE('-', 80);
            PRINT FORMATMESSAGE(N'Truncating %s', @table_name);

            SET @sql = N'TRUNCATE TABLE ' + @table_name + N';';
            EXEC sp_executesql @sql;

            PRINT FORMATMESSAGE(N'Bulk loading %s from %s', @table_name, @file_path);

            SET @sql = N'BULK INSERT ' + @table_name + N'
                FROM ''' + REPLACE(@file_path, '''', '''''') + N'''
                WITH (
                    FIRSTROW = ' + CAST(@FirstDataRow AS NVARCHAR(10)) + N',
                    FIELDTERMINATOR = ''' + REPLACE(@FieldTerminator, '''', '''''') + N''',
                    ROWTERMINATOR = ''' + REPLACE(@RowTerminator, '''', '''''') + N''',
                    TABLOCK,
                    CODEPAGE = ''65001'',
                    KEEPNULLS
                );';

            EXEC sp_executesql @sql;
            SET @rowcount = @@ROWCOUNT;

            SET @sql = N'UPDATE ' + @table_name + N'
                        SET source_file_name = ''' + REPLACE(@file_path, '''', '''''') + N'''
                      WHERE source_file_name IS NULL;';
            EXEC sp_executesql @sql;

            PRINT FORMATMESSAGE(N'Rows loaded: %d | Duration: %d seconds',
                @rowcount,
                DATEDIFF(SECOND, @step_start, SYSUTCDATETIME()));

            FETCH NEXT FROM load_cursor INTO @table_name, @file_path;
        END

        CLOSE load_cursor;
        DEALLOCATE load_cursor;

        DECLARE @batch_end DATETIME2(0) = SYSUTCDATETIME();
        PRINT REPLICATE('=', 80);
        PRINT FORMATMESSAGE(N'Bronze load completed at %s (UTC)', CONVERT(VARCHAR(30), @batch_end, 126));
        PRINT FORMATMESSAGE(N'Total duration: %d seconds', DATEDIFF(SECOND, @batch_start, @batch_end));
        PRINT REPLICATE('=', 80);
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'load_cursor') >= -1
        BEGIN
            CLOSE load_cursor;
            DEALLOCATE load_cursor;
        END;

        DECLARE @err NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @errnum INT = ERROR_NUMBER();
        DECLARE @errstate INT = ERROR_STATE();

        PRINT REPLICATE('!', 80);
        PRINT N'Error occurred during bronze load.';
        PRINT FORMATMESSAGE(N'Error %d (state %d): %s', @errnum, @errstate, @err);
        PRINT REPLICATE('!', 80);

        THROW;
    END CATCH;
END;
GO

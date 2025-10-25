/*
===============================================================================
 Script:      init_database.sql
 Project:     SQL Data Warehouse & Analytics
 Purpose:     Reset and configure the DataWarehouse database and create the
              Medallion architecture schemas (bronze, silver, gold).
===============================================================================
 WARNING:
   - This script can drop the existing DataWarehouse database.
   - Use only in development or other disposable environments.
===============================================================================
*/

USE master;
GO

SET NOCOUNT ON;

DECLARE @DatabaseName SYSNAME = N'DataWarehouse';
DECLARE @DropExisting BIT = 1; -- Set to 0 to keep an existing database.

PRINT REPLICATE('=', 72);
PRINT FORMATMESSAGE(N'Initializing database [%s]', @DatabaseName);
PRINT FORMATMESSAGE(N'Drop existing database: %s',
                    CASE WHEN @DropExisting = 1 THEN N'YES' ELSE N'NO' END);
PRINT REPLICATE('=', 72);

BEGIN TRY
    IF DB_ID(@DatabaseName) IS NOT NULL
    BEGIN
        IF @DropExisting = 1
        BEGIN
            PRINT FORMATMESSAGE(N'Existing database [%s] found. Dropping...', @DatabaseName);

            DECLARE @DropSql NVARCHAR(MAX) =
                N'ALTER DATABASE [' + @DatabaseName + N'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                  DROP DATABASE [' + @DatabaseName + N'];';

            EXEC (@DropSql);
            PRINT FORMATMESSAGE(N'Database [%s] dropped successfully.', @DatabaseName);
        END
        ELSE
        BEGIN
            PRINT FORMATMESSAGE(
                N'Database [%s] already exists and drop is disabled. Initialization aborted.',
                @DatabaseName);
            RETURN;
        END
    END
    ELSE
    BEGIN
        PRINT FORMATMESSAGE(N'No existing database named [%s] found. Proceeding with creation.', @DatabaseName);
    END

    DECLARE @CreateSql NVARCHAR(MAX) = N'CREATE DATABASE [' + @DatabaseName + N'];';
    PRINT FORMATMESSAGE(N'Creating database [%s]...', @DatabaseName);
    EXEC (@CreateSql);
    PRINT FORMATMESSAGE(N'Database [%s] created.', @DatabaseName);

    DECLARE @ConfigSql NVARCHAR(MAX);

    SET @ConfigSql = N'ALTER DATABASE [' + @DatabaseName + N'] SET RECOVERY SIMPLE WITH NO_WAIT;';
    EXEC (@ConfigSql);

    SET @ConfigSql = N'ALTER DATABASE [' + @DatabaseName + N'] SET AUTO_UPDATE_STATISTICS_ASYNC ON;';
    EXEC (@ConfigSql);

    DECLARE @SchemaSql NVARCHAR(MAX) = N'
        USE [' + @DatabaseName + N'];

        IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N''bronze'')
            CREATE SCHEMA bronze AUTHORIZATION dbo;

        IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N''silver'')
            CREATE SCHEMA silver AUTHORIZATION dbo;

        IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N''gold'')
            CREATE SCHEMA gold AUTHORIZATION dbo;
    ';

    PRINT FORMATMESSAGE(N'Creating Medallion schemas in [%s]...', @DatabaseName);
    EXEC (@SchemaSql);
    PRINT N'Schemas [bronze], [silver], and [gold] verified.';

    DECLARE @Completion NVARCHAR(400) =
        FORMATMESSAGE(N'Database [%s] initialized successfully.', @DatabaseName);

    PRINT REPLICATE('=', 72);
    PRINT @Completion;
    PRINT REPLICATE('=', 72);
END TRY
BEGIN CATCH
    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();

    PRINT REPLICATE('!', 72);
    PRINT N'Initialization failed.';
    PRINT FORMATMESSAGE(N'Error %d (state %d): %s', @ErrorNumber, @ErrorState, @ErrorMsg);
    PRINT REPLICATE('!', 72);

    THROW;
END CATCH;
GO

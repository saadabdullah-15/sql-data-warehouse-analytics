/*
===============================================================================
 Script:      init_database.sql
 Project:     SQL Data Warehouse & Analytics
 Purpose:     Reset and configure the DataWarehouse database and create the
              Medallion architecture schemas (bronze, silver, gold).
===============================================================================
 Warnings:
   - The script drops the existing [DataWarehouse] database if it is found.
   - Run only in development/test environments where this is acceptable.
===============================================================================
*/

USE master;
GO

SET NOCOUNT ON;

PRINT REPLICATE('=', 72);
PRINT 'Starting DataWarehouse initialization...';
PRINT REPLICATE('=', 72);

IF DB_ID(N'DataWarehouse') IS NOT NULL
BEGIN
    PRINT 'Existing database [DataWarehouse] detected. Dropping...';
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
    PRINT 'Database [DataWarehouse] dropped.';
END
ELSE
BEGIN
    PRINT 'No existing [DataWarehouse] database found. Continuing with creation.';
END
GO

PRINT 'Creating database [DataWarehouse]...';
CREATE DATABASE DataWarehouse;
GO

PRINT 'Switching context to [DataWarehouse].';
USE DataWarehouse;
GO

SET NOCOUNT ON;

PRINT 'Ensuring Medallion schemas exist: [bronze], [silver], [gold].';

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'bronze')
BEGIN
    EXEC ('CREATE SCHEMA bronze');
    PRINT 'Schema [bronze] created.';
END
ELSE
BEGIN
    PRINT 'Schema [bronze] already exists.';
END

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'silver')
BEGIN
    EXEC ('CREATE SCHEMA silver');
    PRINT 'Schema [silver] created.';
END
ELSE
BEGIN
    PRINT 'Schema [silver] already exists.';
END

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'gold')
BEGIN
    EXEC ('CREATE SCHEMA gold');
    PRINT 'Schema [gold] created.';
END
ELSE
BEGIN
    PRINT 'Schema [gold] already exists.';
END

PRINT REPLICATE('=', 72);
PRINT 'DataWarehouse initialization complete.';
PRINT REPLICATE('=', 72);
GO

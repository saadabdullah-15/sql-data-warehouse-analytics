/* ========================================================================
   Project: SQL Data Warehouse & Analytics
   Script:  01_create_database_and_schemas.sql
   Author:  Saad Abdullah
   Purpose:
       - Create a clean database environment for the project.
       - Recreate the [DataWarehouse] database (drops if exists).
       - Define Medallion architecture schemas: [bronze], [silver], [gold].
   ------------------------------------------------------------------------
   ⚠️ WARNING:
       This script DROPS the existing [DataWarehouse] database.
       All existing objects and data will be permanently deleted.
       Run only in a development or test environment — never in production
       unless you are sure you want to reset the database.
   ======================================================================== */

-- Ensure execution starts from master
USE master;
GO

-- Drop the existing database if it exists
IF DB_ID(N'DataWarehouse') IS NOT NULL
BEGIN
    PRINT 'Database [DataWarehouse] already exists — dropping it now...';
    ALTER DATABASE [DataWarehouse] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DataWarehouse];
    PRINT 'Database [DataWarehouse] dropped successfully.';
END
ELSE
BEGIN
    PRINT 'No existing [DataWarehouse] database found — proceeding with creation.';
END
GO

-- Create a new, clean database
PRINT 'Creating new database [DataWarehouse]...';
CREATE DATABASE [DataWarehouse];
GO

-- Switch context to the new database
USE [DataWarehouse];
GO

-- Create Medallion Architecture Schemas
PRINT 'Creating schemas [bronze], [silver], and [gold]...';

CREATE SCHEMA [bronze] AUTHORIZATION [dbo];
GO

CREATE SCHEMA [silver] AUTHORIZATION [dbo];
GO

CREATE SCHEMA [gold] AUTHORIZATION [dbo];
GO

PRINT '✅ Database [DataWarehouse] and schemas [bronze], [silver], [gold] created successfully.';
GO
-- End of script
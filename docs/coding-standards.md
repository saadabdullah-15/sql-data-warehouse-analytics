# SQL Coding Standards

This project keeps all T-SQL scripts aligned to a single house style so that each
layer of the Medallion pipeline is easy to read, extend, and review. The points
below summarise the conventions reflected in the refreshed scripts.

---

## File Preamble

- Start every script with the shared banner:
  ```sql
  /*
  ===============================================================================
   Script:      <file_name.sql>
   Project:     SQL Data Warehouse & Analytics
   Purpose:     One-line description with an optional wrapped second line.
  ===============================================================================
   Usage:
     <Example invocations. Omit section when not relevant.>
   Notes:
     - Bullet list for caveats or reminders.
  ===============================================================================
  */
  ```
- Keep content ASCII-only and wrap long purpose lines manually so the banner
  remains readable in narrow editors.

---

## General SQL Conventions

- Set the context explicitly with `USE DataWarehouse;` followed by `GO`.
- Enable `SET NOCOUNT ON;` for DDL/data load scripts to avoid extra rowcount
  chatter.
- Guard resource creation with existence checks (`IF SCHEMA_ID(...) IS NULL`,
  `IF OBJECT_ID(...) IS NOT NULL`, etc.) before issuing `BEGIN ... END` blocks.
- Upper-case reserved keywords (`SELECT`, `INSERT`, `BEGIN TRY`, `THROW`) and
  prefer lower_snake_case for object names and columns to match the dataset.
- Capture errors with a `TRY...CATCH` wrapper and re-raise using `THROW` to
  preserve the original error details.
- When printing operational telemetry, keep the message width consistent and use
  bracketed separators (`PRINT '------------------------------------------------';`) for readability.

---

## Stored Procedure Pattern

- Declare parameters first, then immediately validate inputs (throw if required
  values are missing).
- Track runtime metrics with `@batch_start_time`, `@start_time`, and `@end_time`
  (UTC preferred) to make duration logging consistent.
- Truncate target tables before bulk insert/reload steps to guarantee idempotent
  reruns in development.
- Stage complex result sets via common-table expressions (`;WITH ...`) before
  inserting—this keeps transformation logic declarative.
- Surface data quality issues by persisting rejects and printing a short summary
  of row counts and anomaly counts at the end of each load.

---

## Change Management

- Keep layer-specific scripts under their schema folder (`bronze/`, `silver/`,
  `gold/`) and name them with the pattern `<action>_<layer>_data.sql`.
- When adding new scripts, match the banner, guard-rail structure, and logging
  approach from the existing files so reviews can focus on logic, not format.
- Document any deviation from these conventions directly in the script's `Notes`
  section and cross-reference in the repository README when appropriate.

---

Following these standards keeps the data warehouse project approachable for new
contributors and makes future code reviews far more mechanical. Refer back to
this guide before submitting pull requests or updating existing scripts.

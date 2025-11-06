# SQL Data Warehouse & Analytics

A production-style SQL Server data warehouse sandbox built around the Medallion architecture (bronze -> silver -> gold). The project pairs curated CRM and ERP extracts with repeatable SQL assets so you can rebuild the environment end-to-end, validate quality, and demonstrate analytics engineering patterns.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Highlights](#highlights)
- [Source Data](#source-data)
- [SQL Assets](#sql-assets)
- [Repository Layout](#repository-layout)
- [Getting Started](#getting-started)
- [Quickstart](#quickstart)
- [Operational Checks](#operational-checks)
- [Quality & Testing](#quality--testing)
- [Documentation](#documentation)
- [Roadmap](#roadmap)
- [License](#license)
- [Author](#author)

## Overview

The warehouse showcases how to standardise heterogeneous CRM and ERP feeds, land them safely, and publish analytics-friendly views. It is intentionally portable: drop the repo onto a SQL Server host, execute the scripts, and the complete bronze, silver, and gold layers are rebuilt with auditability baked in.

Use it as a reusable sandbox for:
- Practicing ELT patterns with SQL Server tooling.
- Stress-testing data quality checks and operational guard-rails.
- Demonstrating dimensional modelling concepts in a portfolio or interview setting.

## Architecture

The solution follows a layered Medallion topology with clear separation of concerns:
- **Bronze** - Raw landing tables that mirror the source files for traceability.
- **Silver** - Cleansed, conformed entities with surrogate keys, canonical IDs, and enrichment from ERP lookups.
- **Gold** - Presentation-ready dimensional views built on top of the silver entities.

Reference diagrams in `docs/` for a visual walkthrough:
- `docs/data_architecture.png` - Logical architecture at a glance.
- `docs/data_flow.png` - High-level load sequence across layers.
- `docs/data_integration.png` - Integration touchpoints between CRM and ERP domains.

## Highlights

- **Repeatable environment resets** with `scripts/init_database.sql`, including schema provisioning for bronze, silver, and gold.
- **Parameterized bulk ingestion** via `bronze.load_bronze`, supporting alternate dataset roots, delimiter overrides, and per-table telemetry.
- **Curated conformance** inside `silver.load_silver`, covering canonical key generation, ERP enrichment, reject capture, and load metrics.
- **Presentation layer automation** with `scripts/gold/create_gold_views.sql`, publishing `gold.dim_customers`, `gold.dim_products`, and `gold.fact_sales`.
- **Consolidated quality gate** through `scripts/tests/run_quality_checks.sql`, surfacing duplicates, domain violations, and dimensional integrity issues.
- **Documented standards** including naming conventions, coding standards, and a detailed gold-layer data catalog under `docs/`.

## Source Data

Sample extracts are stored within the repository to keep the build reproducible.

| Source | File | Description |
| --- | --- | --- |
| CRM | `datasets/source_crm/cust_info.csv` | Customer master extract with demographic attributes. |
| CRM | `datasets/source_crm/prd_info.csv` | Product master extract with lifecycle metadata. |
| CRM | `datasets/source_crm/sales_details.csv` | Sales order line items with pricing and dates. |
| ERP | `datasets/source_erp/CUST_AZ12.csv` | Demographic lookup used for gender and birthdate enrichment. |
| ERP | `datasets/source_erp/LOC_A101.csv` | Location lookup that resolves canonical customer IDs to countries. |
| ERP | `datasets/source_erp/PX_CAT_G1V2.csv` | Product category lookup that enriches CRM products. |

## SQL Assets

| Layer | Script / Procedure | Purpose |
| --- | --- | --- |
| Reset | `scripts/init_database.sql` | Drops and recreates `DataWarehouse`, ensuring bronze/silver/gold schemas exist. |
| Bronze | `scripts/bronze/create_bronze_tables.sql` | Rebuilds raw landing tables aligned to source file structures. |
| Bronze | `scripts/bronze/load_bronze_data.sql` -> `bronze.load_bronze` | Bulk-loads CRM/ERP CSVs with configurable root path and telemetry. |
| Silver | `scripts/silver/create_silver_tables.sql` | Builds curated tables, surrogate keys, and supporting indexes. |
| Silver | `scripts/silver/load_silver_data.sql` -> `silver.load_silver` | Conforms identifiers, enriches entities, captures rejects, emits summaries. |
| Gold | `scripts/gold/create_gold_views.sql` | Drops/recreates presentation views for dimensions and facts. |
| Tests | `scripts/tests/run_quality_checks.sql` | Executes the consolidated post-load validation suite. |

## Repository Layout

- `datasets/` - Sample CRM and ERP extracts used by the bronze loader.
- `docs/` - Architecture diagrams, coding standards, naming conventions, and the gold-layer data catalog.
- `scripts/` - SQL Server build assets organised by layer plus supporting tests.
- `requirements.txt` - Optional Python stack (pandas, SQLAlchemy, Great Expectations, etc.) for orchestration or validation.
- `LICENSE` - MIT License for reuse.

## Getting Started

Prerequisites:
- SQL Server 2019+ (Express or Developer) or an equivalent instance with `sqlcmd` access.
- `sqlcmd`, Azure Data Studio, or SQL Server Management Studio to run scripts.
- File system access to the repository so the bulk loader can reach `datasets/`.
- Optional: Python 3.9+ with packages from `requirements.txt` for automation, validation, or visualisation.

Configuration tips:
- The bronze loader defaults to the repository `datasets` path. Override it with the `@DataRoot` parameter if you relocate the files.
- Ensure your SQL Server service account can read the CSV directory; UNC paths are supported when properly configured.

## Quickstart

Run the steps below from the repository root, adjusting the server name as needed.

1. **Bootstrap the database**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -i scripts\init_database.sql
   ```
2. **Create bronze tables**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\bronze\create_bronze_tables.sql
   ```
3. **Load bronze data**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -Q "EXEC bronze.load_bronze;"
   ```
   Change the dataset root if required:
   ```sql
   EXEC bronze.load_bronze @DataRoot = N'D:\data\crm-erp';
   ```
4. **Provision silver tables**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\silver\create_silver_tables.sql
   ```
5. **Promote data to silver**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -Q "EXEC silver.load_silver;"
   ```
   Review the printed summaries for row counts, rejects, and enrichment coverage.
6. **Publish gold views**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\gold\create_gold_views.sql
   ```
7. **(Recommended) Run the quality suite**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\tests\run_quality_checks.sql
   ```
   Investigate any returned rows before refreshing downstream analytics.

## Operational Checks

- `bronze.load_bronze` reports per-table durations and row counts; use the output to verify file accessibility and delimiters.
- `silver.load_silver` truncates and reloads curated tables, writes rejects to `silver.crm_sales_details_rejects`, and prints enrichment coverage metrics.
- When automating, wrap the loader calls in SQL Server Agent or orchestration tooling and persist result sets for monitoring dashboards.
- Adjust the loader parameters (`@DataRoot`, `@FieldTerminator`, `@FirstDataRow`) to accommodate new extracts without editing the SQL.

## Quality & Testing

- Execute `scripts/tests/run_quality_checks.sql` after each load. Every result set should return zero rows; anything else signals an issue that needs remediation.
- Extend the quality suite with additional assertions (for example, incremental load watermark checks) by appending to the same script or adding new modules under `scripts/tests/`.
- For Python-based validation, install the dependencies in `requirements.txt` and orchestrate Great Expectations suites alongside the SQL checks.

## Documentation

- `docs/coding-standards.md` - SQL style guide for contributions.
- `docs/naming_conventions.md` - Schema, table, column, and procedure naming patterns.
- `docs/gold_data_catalog.md` - Business-facing documentation for the gold views.
- `docs/quality_checks.md` - Overview of the validation approach and how to interpret failures.

## Roadmap

1. Add aggregate gold views (for example, monthly sales and retention cohorts) and supporting tests.
2. Parameterise quality checks for CI/CD and persist outcomes to a logging table.
3. Layer in orchestration (PowerShell, Azure Data Factory, notebooks) for fully automated refreshes.
4. Introduce incremental loading patterns (watermarks and change tracking) to complement the current full refresh.

## License

Licensed under the [MIT License](LICENSE).

## Author

**Saad Abdullah**  
Master's Student in Data Science  
[LinkedIn](https://linkedin.com/in/saadabdullah-15) | [GitHub](https://github.com/saadabdullah-15)

# SQL Data Warehouse & Analytics

An end-to-end SQL Server warehouse sandbox that follows the Medallion (bronze -> silver -> gold) pattern. The repository bundles source CSV extracts with repeatable SQL scripts so the environment can be rebuilt, audited, and extended for portfolio storytelling or deeper experimentation.

---

## Current Progress

- **Environment reset** – `scripts/init_database.sql` drops and recreates the `DataWarehouse` database, provisions the bronze/silver/gold schemas, and guards against accidental production use.
- **Bronze ingestion** – `scripts/bronze/create_bronze_tables.sql` rebuilds landing tables, while `scripts/bronze/load_bronze_data.sql` bulk-loads CRM and ERP CSVs with configurable file roots, UTF-8 handling, and runtime logging.
- **Silver curation** – `scripts/silver/create_silver_tables.sql` defines analytics-friendly tables (surrogate keys, canonical IDs, helper indexes). `scripts/silver/load_silver_data.sql` standardizes dates and gender values, enriches products with ERP categories, resolves surrogate keys, and tracks rejects in `silver.crm_sales_details_rejects`.
- **Datasets & docs** – `datasets/` includes reproducible CRM/ERP extracts. `docs/` and `tests/` are scaffolded for future documentation, lineage diagrams, and automated quality checks.

---

## Pipeline Status

| Layer | Status | Notes |
| --- | --- | --- |
| Bronze | Complete | Automated bulk load procedure (`bronze.load_bronze`) with parameterized paths and load telemetry. |
| Silver | Complete | Stored procedure (`silver.load_silver`) performs canonicalization, enrichment, rejects capture, and row-count reporting. |
| Gold | Planned | Star-schema models, aggregate views, and KPI reporting still to be designed. |

---

## Repository Layout

- `datasets/source_crm/` – Customer, product, and sales detail extracts (CSV).
- `datasets/source_erp/` – ERP customer, location, and product category reference data (CSV).
- `docs/` – Placeholders for architecture diagrams, data catalog, and naming standards.
- `scripts/` – SQL Server build + load scripts organised by Medallion layer, plus `init_database.sql`.
- `tests/` – Reserved for data quality assertions or integration tests (currently empty).
- `requirements.txt` – Optional Python dependencies for orchestration, validation, or visualization.

---

## Prerequisites

- SQL Server Express/Developer (or compatible) plus SSMS or a `sqlcmd`-capable CLI.
- Local access to the CSV files under `datasets/`.
- Optional: Python 3.9+ with packages from `requirements.txt` if you want to orchestrate or validate outside SQL Server.

---

## Run the Pipeline Locally

1. **Reset the database**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -i scripts\init_database.sql
   ```
   Replace the server name to match your environment. The script recreates the `DataWarehouse` database and its schemas.
2. **Rebuild bronze landing tables**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\bronze\create_bronze_tables.sql
   ```
3. **Load bronze data**
   ```sql
   EXEC bronze.load_bronze;                         -- uses the repo datasets path
   EXEC bronze.load_bronze @DataRoot = N'D:\data';  -- example override
   ```
4. **Provision silver tables**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\silver\create_silver_tables.sql
   ```
5. **Promote data to silver**
   ```sql
   EXEC silver.load_silver;
   ```
   The procedure truncates/reloads the silver tables, enriches the data, surfaces rejects, and prints row-count and quality summaries.

---

## Data Quality & Monitoring

- Bronze loads print per-table timings and row counts, helping diagnose file or schema mismatches quickly.
- Silver loads materialize rejects in `silver.crm_sales_details_rejects`, emit row-count summaries, and highlight missing product/customer mappings to guide data fixes.
- Helper indexes in silver tables support join consistency checks and downstream performance tuning.

---

## Roadmap / Next Steps

1. Design gold-layer dimensional models, aggregate tables, and KPI/reporting views to showcase analytics outputs.
2. Add automated quality tests (e.g., T-SQL assertions or Great Expectations) under `tests/` and wire them into the load workflow.
3. Document business definitions, lineage diagrams, and naming standards inside `docs/`.
4. Introduce orchestration/automation (Python notebook, `.bat`/PowerShell runner, or CI job) to execute the full bronze -> silver pipeline end-to-end.
5. Capture performance metrics and incremental-load strategies (e.g., delta detection or partitioned loads) for production readiness.

---

## License

Licensed under the [MIT License](LICENSE).

---

## Author

**Saad Abdullah**  
Master's Student in Data Science  
[LinkedIn](https://linkedin.com/in/saadabdullah-15) | [GitHub](https://github.com/saadabdullah-15)

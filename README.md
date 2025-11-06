# SQL Data Warehouse & Analytics

An end-to-end SQL Server warehouse sandbox that follows the Medallion (bronze -> silver -> gold) pattern. The repository bundles source CSV extracts with repeatable SQL scripts so the environment can be rebuilt, audited, and extended for portfolio storytelling or deeper experimentation.

---

## Current Progress

- **Environment reset** – `scripts/init_database.sql` drops/rebuilds `DataWarehouse`, provisions the bronze/silver/gold schemas, and is safe to re-run in dev.
- **Bronze ingestion** – `scripts/bronze/create_bronze_tables.sql` recreates staging tables; `scripts/bronze/load_bronze_data.sql` bulk-loads CRM/ERP CSVs with configurable paths, code page handling, and load telemetry.
- **Silver curation** – `scripts/silver/create_silver_tables.sql` defines analytics-friendly structures (surrogate keys, indexes). `scripts/silver/load_silver_data.sql` normalises IDs, enriches products, resolves surrogate keys, and captures rejects/metrics.
- **Gold presentation** – `scripts/gold/create_gold_views.sql` publishes `gold.dim_customers`, `gold.dim_products`, and `gold.fact_sales`, reusing the silver surrogate keys for BI-ready consumption.
- **Operational quality** – `scripts/tests/run_quality_checks.sql` runs a consolidated suite of T-SQL checks covering duplicates, trims, domain validation, category enrichment, and fact/dimension referential integrity.
- **Documentation** – `docs/` now contains a gold data catalog and project naming conventions to keep the warehouse consistent.

---

## Pipeline Status

| Layer | Status | Notes |
| --- | --- | --- |
| Bronze | Complete | Automated bulk load procedure (`bronze.load_bronze`) with parameterized paths and load telemetry. |
| Silver | Complete | Stored procedure (`silver.load_silver`) performs canonicalization, enrichment, rejects capture, and row-count reporting. |
| Gold | Complete | `create_gold_views.sql` rebuilds star-schema views (`dim_customers`, `dim_products`, `fact_sales`) for analytics. |

---

## Repository Layout

- `datasets/source_crm/` – Customer, product, and sales detail extracts (CSV).
- `datasets/source_erp/` – ERP customer, location, and product category reference data (CSV).
- `docs/` - Project documentation: coding standards, naming conventions, gold-layer data catalog, and diagram stubs.
- `scripts/` - SQL Server build + load scripts organised by Medallion layer, plus `init_database.sql`.
- `scripts/tests/` - Quality checks (`run_quality_checks.sql`) that validate silver/gold completeness after a load.
- `requirements.txt` - Optional Python dependencies for orchestration, validation, or visualization.

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
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -Q "EXEC bronze.load_bronze;"
   ```
   Pass a different datasets root when needed:
   ```sql
   EXEC bronze.load_bronze;                         -- uses the repo datasets path
   EXEC bronze.load_bronze @DataRoot = N'D:\data';  -- example override
   ```
4. **Provision silver tables**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\silver\create_silver_tables.sql
   ```
5. **Promote data to silver**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -Q "EXEC silver.load_silver;"
   ```
   ```sql
   EXEC silver.load_silver;
   ```
   The procedure truncates/reloads the silver tables, enriches the data, surfaces rejects, and prints row-count and quality summaries.
6. **Publish gold views**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\gold\create_gold_views.sql
   ```
   Rebuilds `gold.dim_customers`, `gold.dim_products`, and `gold.fact_sales` on top of the refreshed silver layer.
7. **Run quality checks (optional but recommended)**
   ```powershell
   sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\tests\run_quality_checks.sql
   ```
   Review any returned rows to investigate data anomalies before downstream use.

---

## Data Quality & Monitoring

- Bronze loads print per-table timings and row counts, helping diagnose file or schema mismatches quickly.
- Silver loads materialize rejects in `silver.crm_sales_details_rejects`, emit row-count summaries, and highlight missing product/customer mappings to guide data fixes.
- Helper indexes in silver tables support join consistency checks and downstream performance tuning.
- `scripts/tests/run_quality_checks.sql` consolidates trim checks, domain validation, surrogate-key integrity, and fact/dimension referential tests for the current load cycle.

---

## Roadmap / Next Steps

1. Extend the gold layer with aggregates (e.g., monthly sales, customer retention) and additional fact views.
2. Parameterise quality checks for automated CI runs and capture exceptions in a logging table.
3. Expand documentation (lineage diagrams, architecture visuals) and link them from `docs/`.
4. Explore orchestration (PowerShell, Azure Data Factory, or notebooks) to automate the end-to-end load including QA.
5. Prototype incremental loading strategies (watermarks, change detection) to supplement the current full-refresh pattern.

---

## License

Licensed under the [MIT License](LICENSE).

---

## Author

**Saad Abdullah**  
Master's Student in Data Science  
[LinkedIn](https://linkedin.com/in/saadabdullah-15) | [GitHub](https://github.com/saadabdullah-15)

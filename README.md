# SQL Data Warehouse & Analytics

An end-to-end SQL Server data warehouse sandbox that demonstrates the Medallion (bronze -> silver -> gold) pattern, ELT best practices, and portfolio-ready analytics workflows. The repository pairs raw source extracts with reproducible SQL scripts so the environment can be rebuilt from scratch.

---

## Project Highlights

- Resettable SQL Server environment that provisions schemas for each Medallion layer.
- Realistic ERP and CRM extracts under `datasets/` for practicing ingestion patterns.
- Clear separation between raw ingestion, curation, and presentation-ready models.
- Optional Python tooling (`requirements.txt`) for automation, validation, and visualization.

---

## Architecture Overview

- **Bronze**: Land raw CSV files from ERP (`datasets/source_erp`) and CRM (`datasets/source_crm`) systems with zero transformation.
- **Silver**: Prepare conformed, quality-controlled entities. (Scripts planned; checkpoint currently empty.)
- **Gold**: Deliver star-schema style dimensional models and downstream reporting views. (Planned.)

Each layer builds on the previous one, enforcing an auditable flow from ingestion to analytics.

---

## Repository Layout

- `datasets/source_crm/`: Customer, product, and sales detail extracts (CSV).
- `datasets/source_erp/`: ERP master data extracts (CSV).
- `docs/`: Diagram and documentation placeholders ready for Draw.io outputs and Markdown notes.
- `scripts/`: SQL Server build scripts. Includes `init_database.sql` plus layer-specific folders.
- `tests/`: Reserved for data quality checks and regression tests (currently empty).

---

## Prerequisites

- SQL Server (Express or Developer edition) and either SQL Server Management Studio (SSMS) or a `sqlcmd`-compatible CLI.
- Access to the CSV files in `datasets/`.
- Optional: Python 3.9+ with the packages listed in `requirements.txt` for automating loads, validations, or visualization.

---

## Quickstart

1. **Clone**
   ```bash
   git clone https://github.com/saadabdullah-15/sql-data-warehouse-analytics.git
   cd sql-data-warehouse-analytics
   ```
2. **Create or refresh the warehouse**
   - Open `scripts/init_database.sql` in SSMS and execute it, or run:
     ```powershell
     sqlcmd -S .\SQLEXPRESS -i scripts\init_database.sql
     ```
     *(Replace the server with your instance name if different.)*
   - The script drops any existing `DataWarehouse` database, recreates it, and provisions `bronze`, `silver`, and `gold` schemas.
3. **Create landing tables**
   - Run `scripts/bronze/create_bronze_tables.sql` to rebuild the raw staging tables with the latest metadata definitions.
4. **Load raw data**
   - Execute the stored procedure defined in `scripts/bronze/load_bronze_data.sql`:
     ```sql
     EXEC bronze.load_bronze;
     ```
     *(Override `@DataRoot` if your datasets directory lives elsewhere.)*
5. **Iterate on transformations**
   - Build silver and gold transformations in new scripts under `scripts/silver/` and `scripts/gold/`, documenting lineage and business logic in `docs/` as you go.

---

## SQL Scripts

- `scripts/init_database.sql` - Resets the warehouse and establishes schema scaffolding; safe to rerun in dev/test environments only.
- `scripts/bronze/create_bronze_tables.sql` - Drops and recreates raw landing tables in the bronze schema.
- `scripts/bronze/load_bronze_data.sql` - Stored procedure definition for bulk loading CSV files into the bronze schema.

As additional transformations are added, group them by layer to keep the workflow discoverable.

---

## Dataset Notes

- Files are checked in for reproducibility. Treat them as sample data; do not load into production systems.
- CRM extracts include customer attributes (`cust_info.csv`), product dimensions (`prd_info.csv`), and transactional sales (`sales_details.csv`).
- ERP extracts include customer master (`CUST_AZ12.csv`), location dimension (`LOC_A101.csv`), and product category reference data (`PX_CAT_G1V2.csv`).

---

## Documentation & Roadmap

- `docs/` contains empty placeholders for architecture diagrams, data catalogs, and naming conventions. Populate these as the warehouse evolves.
- Planned next steps:
  1. Bronze ingestion stored procedure implemented (`scripts/bronze/load_bronze_data.sql`); extend automation or monitoring as needed.
  2. Add silver cleansing and conformance scripts with automated quality checks.
  3. Publish gold star-schema models and analytical SQL (KPIs, reporting views).
  4. Backfill documentation (data flow diagrams, glossary, and testing strategy).

---

## License

Licensed under the [MIT License](LICENSE).

---

## Author

**Saad Abdullah**  
Master's Student in Data Science  
[LinkedIn](https://linkedin.com/in/saadabdullah-15) | [GitHub](https://github.com/saadabdullah-15)

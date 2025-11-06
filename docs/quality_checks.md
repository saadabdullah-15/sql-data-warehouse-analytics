# Quality Checks Overview

This document summarises the automated data quality checks provided in `scripts/tests/run_quality_checks.sql`. Use it as a quick reference for what is covered and how to interpret the output.

---

## Execution

Run the consolidated checks after the silver and gold loads finish:

```powershell
sqlcmd -S .\SQLEXPRESS -d DataWarehouse -i scripts\tests\run_quality_checks.sql
```

Each `PRINT` block identifies the test being executed. Any returned rows indicate a condition that requires attention.

---

## Silver Layer Checks

| Area | Purpose | Notes |
| --- | --- | --- |
| `crm_cust_info` duplicates | Ensures `cust_sk` is unique/non-null | Confirms customer surrogate key integrity. |
| Trim validation | Flags leading/trailing whitespace in `cst_key` | Helps catch ingestion issues from CSV files. |
| Gender/birthdate domains | Enforces allowed gender values and reasonable birthdate ranges | Birthdates outside 1924-01-01 and today are nulled in the silver load. |
| `crm_prd_info` duplicates | Validates `product_sk` uniqueness | Detects duplicate product rows post-curation. |
| Cost & enrichment checks | Flags NULL/negative costs and missing ERP category enrichment | Category warnings often indicate unmapped SKU patterns. |
| Date range sanity | Highlights `valid_to` earlier than `valid_from` | Helps detect upstream data quality problems. |
| Sales surrogate keys | Ensures each sales row links to customer/product surrogate keys | Missing keys indicate unresolved joins. |
| Sales date ordering | Detects order dates after ship/due dates | Suggests source data errors. |
| Sales amount reconciliation | Verifies `sales_amount = quantity * unit_price` | Uses `decimal(18,2)` casting for comparison. |
| ERP demographics | Checks birthdate range and gender domain in `silver.erp_cust_az12` | Aligns ERP and CRM customer attributes. |
| ERP locations | Flags blank `cntry` values | Ensures downstream geography enrichment. |
| ERP categories | Searches for trailing spaces and unexpected maintenance flags | Keeps enrichment table tidy for joins. |

---

## Gold Layer Checks

| Area | Purpose |
| --- | --- |
| `dim_customers` duplicate keys | Confirms customer dimension surrogate key uniqueness. |
| `dim_products` duplicate keys | Confirms product dimension surrogate key uniqueness. |
| Fact-to-dimension relationships | Left joins `fact_sales` to dimensions and reports missing keys. |
| Metric positivity | Flags sales rows with non-positive `sales_amount`, `quantity`, or `unit_price`. |

---

## When Issues Appear

1. **Review the test heading** to identify the affected domain.
2. **Inspect the returned rows** for repeating values or unexpected nulls.
3. **Trace back to silver transforms** (`scripts/silver/load_silver_data.sql`) or source data to correct the anomaly.
4. Re-run the pipeline and the quality check script to confirm remediation.

Maintaining a clean quality log before publishing reports ensures trustworthy analytics and accelerates debugging when upstream data changes.

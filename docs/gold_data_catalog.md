# Gold Data Catalog

## Overview
The gold layer exposes business-friendly views that power analytics and reporting. Each view is shaped as either a dimension or a fact table and is sourced from the curated silver entities.

---

### 1. `gold.dim_customers`
**Purpose:** Customer dimension enriched with ERP demographics and location context.

| Column Name    | Data Type | Description |
|----------------|-----------|-------------|
| `customer_key` | BIGINT    | Surrogate key inherited from `silver.crm_cust_info.cust_sk`; primary join key for facts. |
| `customer_id`  | INT       | CRM customer identifier (`cst_id`). |
| `customer_number` | NVARCHAR(32) | CRM business key (`cst_key`) used across source systems. |
| `first_name`   | NVARCHAR(50) | Customer given name with whitespace trimmed. |
| `last_name`    | NVARCHAR(50) | Customer family name with whitespace trimmed. |
| `country`      | NVARCHAR(80) | Resolved country from ERP location (`silver.erp_loc_a101`); NULL when unavailable. |
| `marital_status` | NVARCHAR(10) | Standardised marital status (Married, Single, Unknown). |
| `gender`       | NVARCHAR(10) | Normalised gender (Male, Female, Unknown). |
| `birthdate`    | DATE      | Validated date of birth (NULL when outside 1924‑01‑01 to today or missing). |
| `created_date` | DATE      | CRM customer creation date. |

---

### 2. `gold.dim_products`
**Purpose:** Product dimension containing category enrichment and product lifecycle metadata.

| Column Name    | Data Type | Description |
|----------------|-----------|-------------|
| `product_key`  | BIGINT    | Surrogate key inherited from `silver.crm_prd_info.product_sk`. |
| `product_id`   | INT       | CRM product identifier (`prd_id`). |
| `product_number` | NVARCHAR(50) | CRM product key (`prd_key`) upper-cased and trimmed. |
| `product_name` | NVARCHAR(100) | Cleaned product description (`prd_nm`). |
| `category_id`  | NVARCHAR(20) | Identifier derived from CRM key and aligned to ERP category (`erp_px_cat_g1v2.id`). |
| `category_name` | NVARCHAR(50) | ERP category description. |
| `subcategory_name` | NVARCHAR(50) | ERP subcategory description. |
| `is_maintenance` | BIT | 1 when ERP flag is `Yes`; 0 when `No`; NULL when unspecified. |
| `cost`         | DECIMAL(18,2) | Product cost with blanks defaulted to 0.00. |
| `product_line` | NVARCHAR(20) | Normalised product line (Mountain, Road, Other Sales, Touring, n/a). |
| `start_date`   | DATE      | Earliest valid date derived from CRM start/end dates. |
| `end_date`     | DATE      | Latest valid date derived from CRM start/end dates (NULL when open-ended). |

---

### 3. `gold.fact_sales`
**Purpose:** Sales fact view representing CRM order lines with resolved surrogate keys.

| Column Name   | Data Type     | Description |
|---------------|---------------|-------------|
| `order_number` | NVARCHAR(50) | CRM sales order number (`sls_ord_num`). |
| `product_key` | BIGINT        | Foreign key to `gold.dim_products.product_key`. |
| `customer_key` | BIGINT       | Foreign key to `gold.dim_customers.customer_key`. |
| `order_date`  | DATE          | Parsed order date. |
| `shipping_date` | DATE        | Parsed ship date (NULL when not provided). |
| `due_date`    | DATE          | Parsed due date (NULL when not provided). |
| `sales_amount` | DECIMAL(18,2) | Monetary total per line after standardisation. |
| `quantity`    | INT           | Ordered quantity, positive integer. |
| `unit_price`  | DECIMAL(18,2) | Standardised unit price per line. |

---

### Usage Notes
- All gold views are rebuilt by `scripts/gold/create_gold_views.sql`. Re-run after refreshing the silver layer.
- Gold surrogate keys mirror the silver layer surrogate keys to simplify joins and lineage tracking.
- Run the consolidated checks in `scripts/tests/run_quality_checks.sql` after rebuilding the gold views to confirm dimensional integrity before reporting refreshes.

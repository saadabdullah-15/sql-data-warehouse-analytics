# **Naming Conventions**

This document outlines the naming conventions used for schemas, tables, views, columns, stored procedures, and other objects in the SQL Data Warehouse & Analytics project.

## **Table of Contents**

1. [General Principles](#general-principles)
2. [Table Naming Conventions](#table-naming-conventions)
   - [Bronze Rules](#bronze-rules)
   - [Silver Rules](#silver-rules)
   - [Gold Rules](#gold-rules)
3. [Column Naming Conventions](#column-naming-conventions)
   - [Surrogate Keys](#surrogate-keys)
   - [Technical Columns](#technical-columns)
4. [Stored Procedure Naming Conventions](#stored-procedure-naming-conventions)

---

## **General Principles**

- **Style:** Use lower_snake_case for database objects unless dictated otherwise by the source system.
- **Language:** All names are written in English.
- **Clarity:** Choose names that communicate subject matter or business purpose.
- **Reserved Words:** Avoid SQL reserved keywords and special characters.
- **Traceability:** Preserve source-system semantics in the bronze and silver layers to ease lineage tracking.

---

## **Table Naming Conventions**

### **Bronze Rules**
- Schema: `bronze`.
- Tables retain the upstream system name and original entity name; no renaming.
- Pattern: ```bronze.<sourcesystem>_<source_table>```
  - `<sourcesystem>` examples: `crm`, `erp`.
  - `<source_table>` matches the raw file or table name (`cust_info`, `sales_details`).
  - Example: `bronze.crm_cust_info` loads the CRM customer extract.

### **Silver Rules**
- Schema: `silver`.
- Tables continue to reference the originating system for recognisable lineage while reflecting curated content.
- Pattern: ```silver.<sourcesystem>_<entity>```
  - Example: `silver.crm_sales_details` holds cleansed CRM sales lines.
  - ERP lookups keep their delivered identifiers (e.g., `silver.erp_px_cat_g1v2`).

### **Gold Rules**
- Schema: `gold`.
- Views adopt dimensional modelling prefixes that reflect their role in the star schema.
- Pattern: ```gold.<category>_<entity>```
  - `<category>` indicates table type (`dim`, `fact`, `agg`, etc.).
  - `<entity>` describes the business subject (`customers`, `products`, `sales`).
  - Examples: `gold.dim_customers`, `gold.fact_sales`.

#### **Glossary of Category Patterns**

| Pattern  | Meaning             | Example(s)                    |
|----------|---------------------|-------------------------------|
| `dim_`   | Dimension view       | `dim_customers`, `dim_products` |
| `fact_`  | Fact / transaction view | `fact_sales`                |
| `agg_`   | Aggregate or summary | (future) `agg_sales_monthly`  |
| `report_`| Report-ready output  | (future) `report_margin`      |

---

## **Column Naming Conventions**

- Default case is lower_snake_case.
- Business identifiers mirror the source columns (`cst_id`, `prd_key`).
- Boolean flags use the `is_` prefix (`is_maintenance`).
- Date fields end with `_date`; datetime values use `_datetime`.

### **Surrogate Keys**
- Silver layer uses `_sk` for generated surrogate keys (`cust_sk`, `product_sk`).
- Gold views expose the same surrogate keys as `_key` to align with BI tooling (`customer_key`, `product_key`).
- Fact views carry the surrogate key names directly (`product_key`, `customer_key`).

### **Technical Columns**
- System-managed columns use the `dwh_` prefix (`dwh_create_date`).
- Additional audit columns should follow the same pattern (e.g., `dwh_update_user`).

---

## **Stored Procedure Naming Conventions**

- Pattern: ```<schema>.load_<layer>```
  - `bronze.load_bronze`
  - `silver.load_silver`
- Procedures are action-focused, combining the schema with a descriptive verb.
- Parameters use PascalCase for readability (`@DataRoot`, `@FieldTerminator`, etc.).

---

Adhering to these conventions keeps the warehouse consistent, simplifies onboarding, and reduces cognitive load during development and code reviews.

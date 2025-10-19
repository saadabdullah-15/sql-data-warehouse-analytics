# SQL Data Warehouse & Analytics Project 🚀

A personal end-to-end **Data Warehouse and Analytics** implementation using **SQL Server** — built from scratch to demonstrate practical **data engineering**, **ETL**, and **data modeling** skills.

This project is part of my learning journey to design, build, and manage a modern analytical data platform following best practices such as the **Medallion Architecture** (Bronze → Silver → Gold).

---

## 🧠 Project Goals

- Develop a **fully functional SQL-based Data Warehouse**
- Design a clean **data architecture** and **ETL process**
- Create reusable and modular **SQL scripts** for transformations
- Produce **analytical insights** through structured reporting queries
- Showcase **real-world data engineering workflow** for my portfolio

---

## 🧱 Architecture Overview

**Bronze Layer** → Raw data ingestion from CSV sources (ERP & CRM)  
**Silver Layer** → Data cleaning, standardization, and transformation  
**Gold Layer** → Business-ready data modeled in **Star Schema** format  

The project follows the Medallion approach to ensure data quality and analytical readiness at each stage.

---

## 🧰 Tools & Technologies

- **SQL Server & SSMS** – Database and query engine  
- **Draw.io** – Data architecture and flow diagrams  
- **Git & GitHub** – Version control and documentation  
- **Python (optional)** – For additional ETL or validation automation  
---

## 📂 Repository Structure

```
datasets/           # Source data (ERP, CRM)
docs/               # Documentation and diagrams (architecture, flows, models)
scripts/            # SQL scripts (bronze, silver, gold layers)
tests/              # Testing and data validation scripts
```

---

## ⚙️ Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/saadabdullah-15/sql-data-warehouse-analytics.git
   cd sql-data-warehouse-analytics
   ```

2. **Set up your environment**
   - Install SQL Server Express & SSMS
   - Create a new database for this project
   - Import datasets into the **Bronze layer**

3. **Run your ETL scripts**
   - Start from the `scripts/bronze/` folder and progress toward `gold/`

4. **Document your findings**
   - Use Markdown and Draw.io diagrams under `docs/`

---

## 📊 Deliverables

- SQL ETL pipeline scripts
- Data model (star schema)
- Data quality and validation checks
- Analytical SQL reports (KPIs and insights)
- Architecture diagrams and documentation

---

## 🧾 License

This project is licensed under the **MIT License** — you are free to use, modify, and share it with proper attribution.

---

## ✨ Author

**Saad Abdullah**  
📍 Master's Student in Data Science  
🔗 [LinkedIn](https://linkedin.com/in/saadabdullah-15) • [GitHub](https://github.com/saadabdullah-15)

---

### 💡 Note

This project is **self-implemented** for learning and portfolio purposes.  
While inspired by public resources and tutorials, all scripts, documentation, and structures in this repository are written and customized by me to reflect my understanding and workflow.

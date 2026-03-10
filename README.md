# 🎬 Streamify Inc. — Data Warehouse Project

> End-to-end Data Warehouse for a fictional streaming platform, built with Microsoft SQL Server, following the Medallion Architecture (Bronze / Silver / Gold).

---

## 📌 Overview

Welcome to the **Streamify Data Warehouse** project! This repository showcases an end-to-end data warehousing and analytics project simulating a real-world scenario for a fictional streaming company — **Streamify Inc.**

As a data engineering student at **ENSIAS (École Nationale Supérieure d'Informatique et d'Analyse des Systèmes)**, I built this project to:

- Apply data engineering concepts in a realistic, hands-on scenario
- Practice working with **raw, messy data** from multiple source systems (CRM + ERP)
- Build a clean **Star Schema** following the **Medallion Architecture**
- Develop analytical insights through **Power BI** dashboards
- Integrate a **predictive AI component** for revenue forecasting

I hope this project inspires or helps others on their data journey. Feedback and suggestions are always welcome!

---

## 🗂️ Repository Structure

```
streamify-data-warehouse/
│
├── datasets/                          # Raw CSV source files (CRM + ERP exports)
│   ├── crm_customers.csv
│   ├── crm_subscription_history.csv
│   ├── erp_viewing_logs.csv
│   └── erp_content_catalog.csv
│
├── scripts/
│   ├── bronze/                        # Raw data ingestion (DDL + BULK INSERT)
│   ├── silver/                        # Data cleaning & transformation
│   └── gold/                          # Star schema (dimensions + fact table)
│
├── tests/                             # Data quality checks & audit queries
│
├── images/                            # Architecture diagrams & screenshots
│
├── data_catalog.md                    # Column descriptions for the Gold layer
└── README.md
```

---

## 🔧 Technologies & Tools

| Category | Tool |
|---|---|
| Database | Microsoft SQL Server |
| IDE | SQL Server Management Studio (SSMS) |
| Data Ingestion | BULK INSERT |
| Data Modeling | Star Schema |
| Visualization | Power BI |
| AI Component | Python (scikit-learn) |
| Version Control | Git & GitHub |

---

## 🏗️ Data Architecture

![Architecture](images/architecture_high_level_data_warehouse.png)

The project follows the **Medallion Architecture** with 3 layers, all hosted in SQL Server:

### 🥉 Bronze Layer — Raw Data
- Stores data **as-is** from source systems (CRM & ERP CSV exports)
- **No transformations** — all columns stored as `NVARCHAR` to accept any format
- Load strategy: **Truncate & Insert** (full reload)

### 🥈 Silver Layer — Clean Data
- Applies **data cleaning, standardization, and normalization**
- Handles: duplicate removal, date format conversion, invalid values, type casting
- Derived columns added (e.g., `age` from `birth_date`, `is_completed` flag)
- Load strategy: **Truncate & Insert**

### 🥇 Gold Layer — Business-Ready Data
- Structured as a **Star Schema** for reporting and analytics
- Object type: **Views** — no physical storage, always up to date
- Contains: dimensions (`dim_customer`, `dim_content`, `dim_device`, `dim_date`, `dim_subscription_plan`) + fact table (`fact_viewing_sessions`)

---

## 📊 Data Model — Star Schema

```
              dim_date
                 |
dim_device ── fact_viewing_sessions ── dim_content
                 |
           dim_customer
                 |
        dim_subscription_plan
```

The fact table `fact_viewing_sessions` represents one aggregated viewing session per row, joining all 5 dimensions via surrogate keys.

---

## 🗃️ Data Sources

The project simulates receiving raw exports from two internal systems:

| File | Source System | Description |
|---|---|---|
| `crm_customers.csv` | CRM (Salesforce) | Customer accounts and subscription info |
| `crm_subscription_history.csv` | CRM (Finance) | Full history of plan changes |
| `erp_viewing_logs.csv` | ERP (App logs) | Raw viewing events (PLAY/PAUSE/STOP/RATE) |
| `erp_content_catalog.csv` | ERP (Editorial) | Content catalog with genres and metadata |

> ⚠️ The raw data intentionally contains real-world data quality issues: mixed date formats, inconsistent casing, duplicate records, orphan foreign keys, out-of-range values, and null fields — all handled during the Silver layer transformation.

---

## 🤖 AI Component

A **revenue forecasting model** built with Python predicts the next 3 months of subscription revenue using linear regression. Results are stored back in SQL Server and displayed directly in the Power BI dashboard.

```
gold layer (mart_revenue_monthly)
        ↓
  Python / scikit-learn
  (Linear Regression)
        ↓
gold.revenue_predictions
        ↓
   Power BI dashboard
```

---

## 🚀 How to Run the Project

### Prerequisites
- Microsoft SQL Server (Developer Edition — free)
- SQL Server Management Studio (SSMS)
- Python 3.x with `pandas`, `scikit-learn`, `pyodbc`
- Power BI Desktop (free)

### Steps

**1. Initialize the database**
```sql
-- Run in SSMS
scripts/bronze/01_init_database.sql
```

**2. Create Bronze tables and load raw data**
```sql
scripts/bronze/02_bronze_ddl.sql
scripts/bronze/03_bronze_load.sql   -- update CSV file paths before running
```

**3. Clean and transform to Silver**
```sql
scripts/silver/04_silver_ddl.sql
scripts/silver/05_silver_load.sql
```

**4. Build the Gold Star Schema**
```sql
scripts/gold/06_gold_ddl.sql
scripts/gold/07_gold_load.sql
```

**5. Run the AI component**
```bash
python ai/predictions.py
```

**6. Open Power BI**
- Open `powerbi/streamify_dashboard.pbix`
- Connect to your local SQL Server instance
- Refresh data

---

## 📝 Notes

- SQL scripts contain comments written in **French**, as this project was developed during my studies at ENSIAS (Morocco). Translation to English is planned in future revisions.
- The dataset is **fully synthetic** — generated with Python to simulate realistic messy data from a streaming platform.

---

## 👤 Author

**Abdallah** — Data Engineering Student @ ENSIAS, Rabat, Morocco  
🔗 [LinkedIn](https://www.linkedin.com/in/abdallah-assoumanou-354b43286/) • 🐙 [GitHub](https://github.com/gitabdelhub)

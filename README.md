# Streamify Inc. — Data Warehouse

End-to-end Data Warehouse for a fictional streaming platform built with **Microsoft SQL Server**, following the **Medallion Architecture** (Bronze / Silver / Gold), containerized with **Docker**, tested via **GitHub Actions CI**, visualized in **Power BI**, and extended with a Python **churn prediction model**.

---

## Stack

| | |
|---|---|
| Database | Microsoft SQL Server 2022 |
| IDE | SQL Server Management Studio (SSMS) |
| Data Modeling | Constellation Schema |
| Containerization | Docker & Docker Compose |
| CI | GitHub Actions |
| Visualization | Power BI Desktop |
| AI | Python, scikit-learn |

---

## Project Structure

```
streamify-data-warehouse/
├── datasets/                    # Raw CSV exports (CRM + ERP)
├── scripts/
│   ├── ini_database_streamify.sql
│   ├── bronze/                  # Raw ingestion
│   ├── silver/                  # Cleaning & transformation
│   └── gold/                    # Constellation Schema (Views)
├── ai/                          # Churn prediction model
├── tests/                       # Pytest unit tests
├── docker/                      # Dockerfile & docker-compose
├── .github/workflows/           # CI pipeline
├── powerbi/                     # Power BI dashboard (.pbix)
└── data_catalog.md              # Gold layer column descriptions
```

---

## Architecture

The project follows the **Medallion Architecture** with 3 layers running inside a SQL Server Docker container.

**Bronze** ingests the 4 CSV source files as-is into SQL Server. All columns stored as `NVARCHAR`, no transformation applied. Full truncate and reload on every run.

**Silver** handles all data quality issues: mixed date formats (`DD/MM/YYYY` and Unix timestamps), country names normalized to ISO 2-letter codes, `is_active` values standardized across 6 formats (`True/False/1/0/yes/no`), invalid birth dates set to `NULL`, test accounts removed, and orphan foreign keys excluded before reaching the fact tables.

**Gold** exposes business-ready data as a Constellation Schema through SQL Views. No data physically stored here.

---

## Data Model

The Gold layer uses a **Constellation Schema** with 2 fact tables sharing 4 dimensions.

**fact_viewing_sessions** — one row per session. Raw `PLAY/PAUSE/RESUME/STOP/RATE` events are collapsed into a single row per session, keeping only sessions with a valid `STOP` event and at least 2 minutes of watch time.

Key metrics: `watch_time_minutes`, `is_completed` (≥75% of average episode duration watched), `rating`, `had_pause`, `peak_hour`.

**fact_subscriptions** — one row per subscription change event (`NEW`, `UPGRADE`, `DOWNGRADE`, `CANCEL`, `REACTIVATE`) with amount charged and payment status.

### Dimensions

| Table | Description |
|---|---|
| `dim_customer` | Customer profile — shared by both fact tables |
| `dim_subscription_plan` | Plan name, price, tier (FREE / BASIC / STANDARD / PREMIUM) |
| `dim_date` | Date calendar — shared by both fact tables |
| `dim_content` | Title, genre, type, maturity rating |
| `dim_device` | Device category and OS (10 device codes) |

---

## Data Sources

| File | System | Rows | Description |
|---|---|---|---|
| `crm_customers.csv` | CRM | ~2 000 | One row per customer account |
| `crm_subscription_history.csv` | CRM | ~12 000 | Full history of plan changes |
| `erp_viewing_logs.csv` | ERP | ~12 000 | Raw viewing events (PLAY, PAUSE, RESUME, STOP, RATE) |
| `erp_content_catalog.csv` | ERP | — | Content catalog with genres and metadata |

---

## KPIs tracked in Power BI

| KPI | Definition |
|---|---|
| Completion rate | Sessions with `is_completed = 1` / total sessions |
| Monthly retention | Users active in both M and M-1 / users active in M-1 |
| MRR | Sum of `monthly_price` for all active paying subscribers |
| Avg watch time | Sum of `watch_time_minutes` / total valid sessions |
| Churn rate | Paying customers in M-1 with no session in M / total paying customers in M-1 |

---

## Running the Project

Make sure Docker Desktop is installed, then:

```bash
git clone https://github.com/gitabdelhub/streamify-data-warehouse.git
cd streamify-data-warehouse

cp .env.example .env
# Edit .env and set your SA_PASSWORD

docker compose -f docker/docker-compose.yml up --build
```

This starts SQL Server and runs the full Bronze → Silver → Gold pipeline automatically. Connect SSMS to `localhost,1433` to explore the Gold views.

> Power BI requires the Docker stack to be running. Open `powerbi/streamify_dashboard.pbix` and connect to `localhost,1433`.

---

## CI

On every push and pull request to `main`, GitHub Actions installs dependencies and runs `pytest` on the churn model. A model that drops below 50% accuracy fails the build.

---

## AI — Churn Prediction

A scikit-learn `RandomForestClassifier` trained on features aggregated from the Gold layer:

| Feature | Source |
|---|---|
| `total_sessions` | `fact_viewing_sessions` |
| `avg_watch_time` | `fact_viewing_sessions` |
| `completion_rate` | `fact_viewing_sessions` |
| `avg_rating` | `fact_viewing_sessions` |
| `total_pauses` | `fact_viewing_sessions` |
| `had_upgrade` | `fact_subscriptions` |
| `had_downgrade` | `fact_subscriptions` |
| `had_failed_payment` | `fact_subscriptions` |

The training label (`is_churn`) follows the churn KPI definition above.

---

## Notes

- The dataset is fully synthetic, covering January 2021 to December 2024.
- SQL scripts contain comments in French.
- Never commit `.env` — use `.env.example` as a template.

---

## Author

**Abdallah Assoumanou**  
4th-year student at ENSIAS, Rabat — Data Engineering

[![GitHub](https://img.shields.io/badge/GitHub-gitabdelhub-181717?logo=github)](https://github.com/gitabdelhub)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Abdallah%20Assoumanou-0077B5?logo=linkedin)](https://www.linkedin.com/in/abdallah-assoumanou-354b43286)

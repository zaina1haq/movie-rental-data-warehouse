
#  Movie Rental Data Warehouse
### Sakila OLTP → `sakila_dw` — Dimensional Model, ETL Pipeline & Business Analytics

> **Course:** Data Warehousing / Data Architecture  
> **Dataset:** [Sakila Sample Database](https://dev.mysql.com/doc/sakila/en/) (MySQL)

---

##  Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Data Warehouse Architecture](#data-warehouse-architecture)
- [Schema Design](#schema-design)
- [ETL Pipeline](#etl-pipeline)
- [Business Questions Answered](#business-questions-answered)
- [Key Findings & Visualizations](#key-findings--visualizations)
- [Data Quality Checks](#data-quality-checks)
- [Setup & How to Run](#setup--how-to-run)
- [Technologies Used](#technologies-used)

---

## Project Overview

This project transforms an OLTP movie rental database (Sakila) into a fully functional **data warehouse** optimized for analytical reporting and business decision-making.

The OLTP schema is designed for fast transactional operations — recording rentals, processing payments, managing inventory. It is **not** optimized for answering questions like *"Which film category generates the highest revenue?"* or *"Which customers are most valuable?"*. The data warehouse reorganizes this data into a **star schema** that makes such queries fast, intuitive, and flexible.

**What was built:**
- A `sakila_dw` MySQL database with 5 dimension tables and 2 fact tables
- A full Python ETL pipeline (Jupyter Notebook) to extract, transform, and load data
- 11 analytical business questions with SQL queries and verified results
- Data quality checks across all tables

---

## Repository Structure

```
movie-rental-dw/
│
├── step1_create_dw_schema.sql      # DDL: creates sakila_dw database & all tables
├── movie_rental_dw.ipynb           # ETL pipeline + business analytics (Jupyter)
├── query_results.txt               # Output of all 11 business question queries
├── fileDB.sql                    # Source OLTP schema reference
├── fMovieRental_DW_Final_Report.pdf  # Full project report
│
└── Results/
    └── query_ressults
    └──star_schema
    └── 6 pictures of Visualization  
```

---

## Data Warehouse Architecture

The warehouse uses a **star schema** with two central fact tables sharing five conformed dimensions.

```
                    ┌─────────────┐
                    │  dim_date   │
                    └──────┬──────┘
                           │
┌──────────────┐    ┌──────┴──────┐    ┌─────────────┐
│  dim_staff   ├────┤ fact_rental ├────┤ dim_customer │
└──────────────┘    └──────┬──────┘    └─────────────┘
                           │
┌──────────────┐    ┌──────┴──────┐    ┌─────────────┐
│  dim_store   ├────┤ fact_payment├────┤  dim_film   │
└──────────────┘    └─────────────┘    └─────────────┘
```

### Why Star Schema?
- Fewer joins = faster analytical queries
- Flattened dimensions make reporting tools intuitive
- Conformed dimensions (date, customer, film, store, staff) allow cross-fact analysis

---

## Schema Design

### Dimension Tables

| Table | Rows | Source OLTP Tables | Key Attributes |
|---|---|---|---|
| `dim_date` | 1,095 | *(generated)* | date_key, day_name, month_name, quarter, year, is_weekend |
| `dim_customer` | 599 | customer, address, city, country | full_name, email, city, country, is_active |
| `dim_film` | 1,000 | film, language, film_category, category | title, category, rental_rate, rental_duration, rating |
| `dim_store` | 2 | store, staff, address, city, country | store_id, manager_full_name, city, country |
| `dim_staff` | 2 | staff | full_name, email, store_id, is_active |

### Fact Tables

| Table | Rows | Grain | Key Measures |
|---|---|---|---|
| `fact_rental` | 16,044 | One row per rental transaction | rental_duration_days, expected_duration_days, is_late_return, days_late |
| `fact_payment` | 16,044 | One row per payment transaction | payment_amount, payment_count |

---

## ETL Pipeline

The ETL pipeline is implemented in `movie_rental_dw.ipynb` using Python (`mysql-connector-python`, `pandas`).

### Extract
Data is pulled from 11 OLTP tables: `rental`, `payment`, `customer`, `film`, `inventory`, `store`, `staff`, `address`, `city`, `country`, `category`, `film_category`, `language`.

### Transform
Key transformations applied:

- **Name concatenation** — `first_name + last_name → full_name` for customers, staff, and store managers
- **Address flattening** — joins `address → city → country` into a single dimension row
- **Date key generation** — converts `DATE` values to integer keys (`YYYYMMDD` format); generates the full `dim_date` calendar programmatically
- **Film category resolution** — resolves the many-to-many `film ↔ category` relationship using `ROW_NUMBER()` to assign one primary category per film
- **Late return detection** — computes `is_late_return` and `days_late` by comparing `rental_duration_days` against the film's `rental_duration` policy
- **Surrogate key mapping** — builds in-memory dictionaries to map OLTP natural IDs to warehouse surrogate keys
- **Null handling** — open rentals (no return date yet) store `NULL` in `return_date_key` and `is_late_return`
- **Special features normalization** — MySQL `SET` type converted to comma-separated strings

### Load

Loading order respects foreign key dependencies:

```
dim_date → dim_customer → dim_film → dim_store → dim_staff
         → fact_rental → fact_payment
```

All inserts use `INSERT IGNORE` for idempotency — the pipeline can be re-run safely without duplicating data.

---

## Business Questions Answered

| # | Business Question | Key Result |
|---|---|---|
| BQ-1 | Top 10 most rented films | BUCKET BROTHERHOOD leads with 34 rentals |
| BQ-2 | Top 10 films by revenue | TELEGRAPH VOYAGE tops at $231.73 |
| BQ-3 | Film categories by popularity & revenue | Sports #1 in rentals (1,179); Sci-Fi #1 in revenue ($4,756.98) |
| BQ-4 | Store performance | Store 2 (Woodridge, AU): 8,121 rentals / $33,726.77 |
| BQ-5 | Top 10 customers | ELEANOR HUNT: 46 rentals; KARL SEAL: $221.55 revenue |
| BQ-6 | Monthly rental activity | Peak: July 2005 — 6,709 rentals / $28,368.91 |
| BQ-7 | Staff performance | Mike Hillyer: 8,040 rentals; Jon Stephens: $33,881.94 collected |
| BQ-8 | Top cities by customer activity | Aurora, US (2 customers, 50 rentals); London, UK (2 customers, 48 rentals) |
| BQ-9 | Avg rental duration by category | Sports & Games avg 5.20 days actual (above allowed) |
| BQ-10 | Films returned late most often | TELEGRAPH VOYAGE: 88.9% late return rate |
| BQ-11 | Quarterly revenue trend | Q3 2005 dominates: $52,439.05 |

---

## Key Findings & Visualizations

###  Category Performance
Sports leads in total rentals (1,179) but Sci-Fi delivers stronger revenue efficiency. Children lags in both metrics, suggesting underperformance relative to catalog size.

###  Store Comparison
Store 2 (Woodridge, Australia) outperforms Store 1 (Lethbridge, Canada) on both rentals and revenue, despite similar staff counts. Both stores show near-identical revenue per transaction (~$4.15).

###  Seasonal Trends
Rental activity peaks sharply in **July 2005** (6,709 rentals) — over 2.5× June's volume — then drops in August before nearly disappearing in 2006. This suggests the dataset captures a seasonal spike rather than steady-state operations.

###  Late Returns
**TELEGRAPH VOYAGE** has the highest late return rate at 88.9% across 27 rentals. 7 of the top 10 most-rented films also appear in late return analysis, suggesting popular films may need stricter return policies or revised rental durations.

###  Customer Value
Top customers by rental count (ELEANOR HUNT, 46) and by revenue (KARL SEAL, $221.55) are different people — indicating that high-frequency renters do not always translate to highest-value customers.

---

## Data Quality Checks

The following checks are run post-load inside the notebook:

| Check | Description |
|---|---|
| Orphan fact rows | Verify all FK references in fact tables resolve to valid dimension rows |
| Null surrogate keys | Flag any `customer_key`, `film_key`, `store_key`, or `staff_key` that is NULL |
| Rental duration sanity | Confirm `rental_duration_days` is non-negative where return date is present |
| Row count validation | Compare source OLTP row counts against loaded DW row counts |
| Late return flag consistency | Confirm `is_late_return` aligns with `days_late > 0` |

---

## Setup & How to Run

### Prerequisites
- [XAMPP](https://www.apachefriends.org/) (MySQL + phpMyAdmin)
- Python 3.8+
- Jupyter Notebook
- Sakila database installed in MySQL

### Python Dependencies
```bash
pip install mysql-connector-python pandas jupyter
```

### Steps

**1. Create the data warehouse schema**

Open phpMyAdmin → select the SQL tab → paste and run `step1_create_dw_schema.sql`.

This creates the `sakila_dw` database with all 7 tables.

**2. Run the ETL pipeline**

```bash
jupyter notebook movie_rental_dw.ipynb
```

Run all cells top to bottom. The notebook will:
- Connect to both `sakila` (source) and `sakila_dw` (target)
- Load all dimension tables in order
- Load both fact tables
- Run data quality checks
- Execute and display all 11 business question queries

**3. Verify in phpMyAdmin**

Navigate to `sakila_dw` — you should see 7 tables with a total of ~34,786 rows and 6.4 MiB of data.

---

## Technologies Used

| Tool | Purpose |
|---|---|
| MySQL 8 / XAMPP | Database engine (OLTP source + DW target) |
| phpMyAdmin | Schema inspection and SQL execution |
| Python 3 | ETL pipeline scripting |
| `mysql-connector-python` | Python ↔ MySQL connectivity |
| `pandas` | Data inspection and display |
| Jupyter Notebook | Interactive ETL + analytics environment |
| SQL (analytical) | Business question queries against `sakila_dw` |

---

> **Note:** The Sakila database is a sample dataset provided by MySQL for educational use. All business insights derived from it are for academic purposes only.

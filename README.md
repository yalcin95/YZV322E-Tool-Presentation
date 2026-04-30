# DuckDB Tool Presentation Demo

Student: Hasan Yalçın Arıkanoğlu  
Student ID: 150220341  
Course: YZV 322E - Applied Data Engineering  
Topic: DuckDB

## 1. What is this tool?

DuckDB is an open-source, in-process analytical database management system for running fast SQL queries directly inside an application, notebook, or command-line workflow. It is often described as "SQLite for analytics" because it requires no separate database server, but it is optimized for OLAP workloads such as file scanning, joins, aggregations, and local ETL.

DuckDB was introduced in 2019 by Hannes Mühleisen and Mark Raasveldt at CWI. The project is maintained by the DuckDB Foundation and DuckDB Labs, and it is released under the MIT License.

## 2. Course connection

DuckDB connects directly to the course's focus on practical data engineering pipelines:

- In the assignment list, DuckDB is placed under Python ETL because it integrates well with Pandas, Polars, Arrow, and Python-based data workflows.
- Like PostgreSQL, it supports SQL queries, joins, aggregations, views, and persistent database files.
- Unlike PostgreSQL, DuckDB runs embedded and does not require a database server.
- In an ETL pipeline, DuckDB is useful for local transformation, data profiling, CSV/Parquet conversion, and quick analytical checks before loading data into a downstream system.
- It can complement Airflow by running SQL transformation scripts as scheduled tasks.
- It fits naturally between ingestion and downstream tools such as PostgreSQL, Elasticsearch, Kibana, or dashboards.

This repository uses DuckDB's SQL interface through the official Docker image because the assignment recommends Docker when an official image exists. The same SQL workflow could also be called from a Python ETL script.

## 3. Prerequisites

This demo was verified on macOS with Docker Desktop. It should also work on Linux or Windows with WSL/Git Bash, as long as Docker is running.

You need:

- Docker / Docker Desktop with Docker Compose v2 (bundled with modern Docker Desktop; provides the `docker compose` and `docker-compose` commands)
- A Unix-like shell for the commands below, such as macOS Terminal, Linux shell, WSL, or Git Bash
- Internet connection for the one-time dataset download (and for the remote-Parquet demo in Section 7.1)

The demos use the official DuckDB image (`duckdb/duckdb`) and a small in-repo `Dockerfile` (Python + DuckDB + Pandas) for the benchmark. Both are wired together in `docker-compose.yml`.

## 4. Installation

Clone the repository and enter the project folder:

```bash
git clone https://github.com/yalcin95/YZV322E-Tool-Presentation.git
cd YZV322E-Tool-Presentation
```

Download the NYC TLC dataset files locally:

```bash
mkdir -p data
curl -L -o data/yellow_tripdata_2024-01.parquet \
  https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet
curl -L -o data/taxi_zone_lookup.csv \
  https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv
```

The downloaded files are ignored by Git because they are data artifacts, not source code.

The `d37ci6vzurychx.cloudfront.net` links look unusual, but they are the download links used by the official NYC TLC Trip Record Data page. NYC serves these files through AWS CloudFront.

Official dataset landing page:

- https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

## 5. Running the example with Docker Compose

This repo uses `docker-compose.yml` as a **task runner**, not as a service orchestrator. Each demo is a `docker-compose run --rm <service>` invocation: the container starts, executes, and exits. DuckDB itself is still embedded — nothing stays running.

Three demo services are defined:

| Service | Image | What it does |
| --- | --- | --- |
| `main-demo` | `duckdb/duckdb` (official) | Runs the local Parquet + CSV pipeline |
| `remote-demo` | `duckdb/duckdb` (official) | Queries a remote Parquet file over HTTPS, no download |
| `pandas-bench` | local `Dockerfile` | Pandas vs DuckDB benchmark on the same DataFrame |

Run the main demo:

```bash
docker-compose run --rm main-demo
```

The SQL demo will:

1. Read the official NYC TLC January 2024 yellow taxi Parquet file from `data/`.
2. Print a raw data quality profile showing how many rows are removed by the cleaning rules.
3. Join taxi trips with the official TLC taxi zone lookup CSV from `data/`.
4. Create a persistent database file at `outputs/nyc_taxi_demo.duckdb`.
5. Run analytical SQL queries for payment methods, pickup hours, and pickup zones.
6. Export a transformed result to `outputs/top_pickup_zones.parquet`.
7. Print sample query results to the terminal.

## 6. Expected output

The exact formatting may differ slightly by terminal, but the output should include these sections:

```text
DuckDB NYC Taxi Demo
Dataset: NYC TLC Yellow Taxi Trip Records - January 2024
Trip data source: data/yellow_tripdata_2024-01.parquet
Zone lookup source: data/taxi_zone_lookup.csv

Raw data quality profile
raw_rows  valid_rows  removed_rows  removed_pct  outside_january_rows  non_positive_distance_rows  non_positive_fare_rows  non_positive_total_rows
2964624   2869697     94927         3.20         18                    60371                       38341                   35920

Dataset profile
total_rows  avg_trip_miles  total_amount_usd
2869697     3.73            78481619.24

Payment summary
payment_method  trips    total_amount_usd  avg_amount_usd
Credit card     2298380  64528576.59       28.08
Cash            422747   10088948.58       23.87
Other           115249   3056745.60        26.52
Dispute         22759    571936.35         25.13
No charge       10562    235412.12         22.29

Created outputs/nyc_taxi_demo.duckdb
Created outputs/top_pickup_zones.parquet
```

A full sample terminal output is available in `expected_output/main_demo.txt`.

## 7. Extra demos

Two short demos go beyond the main pipeline to show DuckDB features that distinguish it from a generic SQL engine. Both run via the same `docker-compose.yml`.

### 7.1. Remote Parquet over HTTPS (no download)

DuckDB's `httpfs` extension can read Parquet files over HTTPS directly. The query only fetches the byte ranges it needs, so a multi-million-row file can be summarized without ever landing on disk.

```bash
docker-compose run --rm remote-demo
```

This queries the official NYC TLC **February 2024** Parquet file (different from the local January file used in the main demo) and prints schema, row count, and busiest pickup hours. Captured output: `expected_output/remote_query.txt`.

### 7.2. Pandas zero-copy interop and benchmark

DuckDB can run SQL directly against an existing Pandas DataFrame without copying it. The same aggregation is timed in both engines on identical in-memory data, so the comparison is fair.

```bash
docker-compose run --rm pandas-bench
```

The first run automatically builds the small Python image defined by the `Dockerfile` at the repo root (Python + `duckdb` + `pandas` + `pyarrow`). Subsequent runs reuse the cached image.

The local NYC TLC January 2024 Parquet file (`data/yellow_tripdata_2024-01.parquet`) must be present — see Section 4 for the download command.

Sample timing on the captured run (2.96M rows, identical GROUP BY in both engines):

```text
Pandas:  0.37 s
DuckDB:  0.10 s
Speedup: ~3.7x
```

Numbers vary per machine and per run; the speedup is consistently in the 3–6× range on this dataset. Captured output: `expected_output/benchmark.txt`.

## 8. Repository structure

```text
duckdb-tool-presentation/
├── README.md
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── .gitignore
├── expected_output/
│   ├── main_demo.txt
│   ├── remote_query.txt
│   └── benchmark.txt
├── scripts/
│   ├── download_data.sh
│   ├── run_demo.sql
│   ├── remote_query.sql
│   └── pandas_interop.py
└── outputs/
    └── .gitkeep
```

## 9. Optional local DuckDB CLI run

If DuckDB is installed locally, you can run the same SQL script without Docker:

```bash
duckdb outputs/nyc_taxi_demo.duckdb < scripts/run_demo.sql
```

## 10. Compose teardown

The demos are one-shot, so there is nothing to "stop." If a `--rm` was forgotten and stopped containers accumulate, clean them up with:

```bash
docker-compose down
```

## 11. AI usage disclosure

AI assistance was used to draft the repository structure, README text, demo SQL, and presentation outline. The generated content was reviewed and adapted for the YZV 322E assignment requirements.

## 12. References

- DuckDB official website: https://duckdb.org/
- DuckDB Docker documentation: https://duckdb.org/docs/current/operations_manual/duckdb_docker
- DuckDB installation documentation: https://duckdb.org/install/
- DuckDB FAQ and license information: https://duckdb.org/faq.html
- DuckDB paper: https://duckdb.org/library/duckdb/
- NYC TLC Trip Record Data: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- NYC TLC January 2024 Yellow Taxi Parquet: https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet
- NYC TLC Taxi Zone Lookup CSV: https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv

# DuckDB: Local Analytical SQL over Files

This repository demonstrates DuckDB for the YZV 322E Applied Data Engineering tool presentation.

Student: Hasan Yalçın Arıkanoğlu  
Student ID: 150220341  
Course: YZV 322E - Applied Data Engineering  
Topic: DuckDB

## Introduction

DuckDB is an open-source, in-process analytical database. It runs inside an application, notebook, CLI process, or Docker container instead of requiring a separate database server. It is often described as "SQLite for analytics": embedded like SQLite, but optimized for OLAP workloads such as scans, joins, aggregations, and SQL over files.

DuckDB was introduced in 2019 by Hannes Mühleisen and Mark Raasveldt at CWI. It is maintained by the DuckDB Foundation and DuckDB Labs and released under the MIT License.

For this course, DuckDB is relevant because it fits the transformation/profiling layer of data engineering pipelines. It can inspect, clean, join, aggregate, and export CSV/Parquet data before the result is sent to systems such as PostgreSQL, Elasticsearch, dashboards, or scheduled Airflow jobs. It is also listed under Python ETL in the assignment because it integrates well with Pandas, Polars, Arrow, and Python workflows.

## Prerequisites

You need:

- Docker / Docker Desktop
- Docker Compose, available as either `docker-compose` or `docker compose`
- A Unix-like shell such as macOS Terminal, Linux shell, WSL, or Git Bash
- Internet connection for the dataset download and the remote-Parquet feature check

This demo was verified on macOS with Docker Desktop. The commands are prepared for bash/zsh. It should also work on Linux or Windows with WSL/Git Bash if Docker is running, or the commands can be adapted for PowerShell.

The demo uses the official DuckDB image (`duckdb/duckdb`). The Pandas comparison uses the small in-repo `Dockerfile`, which installs `duckdb`, `pandas`, and `pyarrow` from `requirements.txt`.

## Installation

Clone the repository and enter the project folder:

```bash
git clone https://github.com/yalcin95/YZV322E-Tool-Presentation.git
cd YZV322E-Tool-Presentation
```

Download the NYC TLC dataset files:

```bash
bash scripts/download_data.sh
```

That script is only a convenience wrapper around the official NYC TLC download links. It creates `data/` and downloads the two files used by the demo.

Equivalent manual commands:

```bash
mkdir -p data
curl -L -o data/yellow_tripdata_2024-01.parquet \
  https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet
curl -L -o data/taxi_zone_lookup.csv \
  https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv
```

The downloaded data files are ignored by Git. The `d37ci6vzurychx.cloudfront.net` URLs are the AWS CloudFront download links used by the official NYC TLC Trip Record Data page:

https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page

## Running

This repo uses `docker-compose.yml` as a task runner. Each command starts a container, runs the demo, and exits. DuckDB itself is still embedded; there is no long-running database server.

### Main demo

Run:

```bash
docker-compose run --rm main-demo
```

This is the main required demo. It uses the official DuckDB Docker image and runs `scripts/run_demo.sql`.

The main demo:

1. Reads NYC TLC January 2024 yellow taxi trips from Parquet.
2. Reads the taxi zone lookup from CSV.
3. Profiles raw data quality.
4. Creates a cleaned DuckDB table.
5. Runs analytical SQL summaries.
6. Writes `outputs/nyc_taxi_demo.duckdb`.
7. Writes `outputs/top_pickup_zones.parquet`.

### Additional feature checks

These are short supporting checks that highlight extra DuckDB features.

Remote Parquet over HTTPS:

```bash
docker-compose run --rm remote-demo
```

This uses DuckDB's `httpfs` extension to query the official NYC TLC February 2024 Parquet file directly over HTTPS, without downloading it into `data/`.

Pandas interop and benchmark:

```bash
docker-compose run --rm pandas-bench
```

This loads the January taxi Parquet file into a Pandas DataFrame, then runs the same GROUP BY aggregation in Pandas and DuckDB. DuckDB queries the existing DataFrame directly from SQL.

The first run may build the Python image. Later runs reuse the cached image.

## Example output

The main demo should include output similar to:

```text
DuckDB NYC Taxi Demo
Dataset: NYC TLC Yellow Taxi Trip Records - January 2024

Raw data quality profile
raw_rows  valid_rows  removed_rows  removed_pct
2964624   2869697     94927         3.20

Dataset profile
total_rows  avg_trip_miles  total_amount_usd
2869697     3.73            78481619.24

Created outputs/nyc_taxi_demo.duckdb
Created outputs/top_pickup_zones.parquet
```

Captured outputs from real runs are included in:

```text
expected_output/main_demo.txt
expected_output/remote_query.txt
expected_output/benchmark.txt
```

## Repository structure

```text
YZV322E-Tool-Presentation/
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

## Compose cleanup

The demos are one-shot commands, so there is normally nothing to stop. If stopped containers accumulate, run:

```bash
docker-compose down
```

## AI usage

AI assistance was used to draft the repository structure, README text, demo SQL, and presentation outline. The generated content was reviewed and adapted for the YZV 322E assignment requirements.

## References

- DuckDB official website: https://duckdb.org/
- DuckDB Docker documentation: https://duckdb.org/docs/current/operations_manual/duckdb_docker
- DuckDB installation documentation: https://duckdb.org/install/
- DuckDB FAQ and license information: https://duckdb.org/faq.html
- DuckDB paper: https://duckdb.org/library/duckdb/
- NYC TLC Trip Record Data: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- NYC TLC Yellow Taxi Trip Records Data Dictionary: https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf
- NYC TLC January 2024 Yellow Taxi Parquet: https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet
- NYC TLC Taxi Zone Lookup CSV: https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv

-- scripts/remote_query.sql
-- Demonstrates a feature unique to DuckDB among the course tools:
-- query a remote Parquet file directly over HTTPS without downloading it first.
--
-- The httpfs extension lets DuckDB read files served over HTTP/S3 as if they
-- were local. Combined with Parquet's columnar layout, DuckDB only fetches
-- the byte ranges needed for the query.
--
-- Run with the official Docker image:
--   docker run --rm -i -v "$(pwd):/workspace" -w /workspace \
--     duckdb/duckdb /duckdb < scripts/remote_query.sql

INSTALL httpfs;
LOAD httpfs;

.print Schema of remote Parquet file (no download)
DESCRIBE
SELECT *
FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-02.parquet'
LIMIT 0;

.print Row count and average trip distance for February 2024
SELECT
    COUNT(*) AS rows,
    ROUND(AVG(trip_distance), 2) AS avg_trip_miles,
    ROUND(SUM(total_amount), 2) AS total_amount_usd
FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-02.parquet'
WHERE trip_distance > 0
    AND fare_amount > 0
    AND total_amount > 0;

.print Top 5 pickup hours in February 2024 (queried remotely)
SELECT
    EXTRACT(hour FROM tpep_pickup_datetime) AS pickup_hour,
    COUNT(*) AS trips
FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-02.parquet'
GROUP BY pickup_hour
ORDER BY trips DESC
LIMIT 5;

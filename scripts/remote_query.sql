-- scripts/remote_query.sql
-- Uses httpfs so DuckDB can query a remote Parquet file without downloading it first.
--
-- Run:
--   docker-compose run --rm remote-demo

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

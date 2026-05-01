.echo on
.timer on

.print DuckDB NYC Taxi Demo
.print Dataset: NYC TLC Yellow Taxi Trip Records - January 2024
.print Trip data source: data/yellow_tripdata_2024-01.parquet
.print Zone lookup source: data/taxi_zone_lookup.csv

.print Raw data quality profile
WITH raw_trips AS (
    SELECT
        tpep_pickup_datetime,
        trip_distance,
        fare_amount,
        total_amount
    FROM read_parquet('data/yellow_tripdata_2024-01.parquet')
),
quality_flags AS (
    SELECT
        tpep_pickup_datetime < TIMESTAMP '2024-01-01'
            OR tpep_pickup_datetime >= TIMESTAMP '2024-02-01' AS outside_january,
        trip_distance <= 0 AS non_positive_distance,
        fare_amount <= 0 AS non_positive_fare,
        total_amount <= 0 AS non_positive_total
    FROM raw_trips
)
SELECT
    COUNT(*) AS raw_rows,
    COUNT(*) FILTER (
        WHERE NOT outside_january
            AND NOT non_positive_distance
            AND NOT non_positive_fare
            AND NOT non_positive_total
    ) AS valid_rows,
    COUNT(*) FILTER (
        WHERE outside_january
            OR non_positive_distance
            OR non_positive_fare
            OR non_positive_total
    ) AS removed_rows,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE outside_january
                OR non_positive_distance
                OR non_positive_fare
                OR non_positive_total
        ) / COUNT(*),
        2
    ) AS removed_pct,
    COUNT(*) FILTER (WHERE outside_january) AS outside_january_rows,
    COUNT(*) FILTER (WHERE non_positive_distance) AS non_positive_distance_rows,
    COUNT(*) FILTER (WHERE non_positive_fare) AS non_positive_fare_rows,
    COUNT(*) FILTER (WHERE non_positive_total) AS non_positive_total_rows
FROM quality_flags;

CREATE OR REPLACE TABLE clean_trips AS
SELECT
    tpep_pickup_datetime,
    PULocationID,
    payment_type,
    trip_distance,
    fare_amount,
    total_amount
FROM read_parquet('data/yellow_tripdata_2024-01.parquet')
WHERE
    tpep_pickup_datetime >= TIMESTAMP '2024-01-01'
    AND tpep_pickup_datetime < TIMESTAMP '2024-02-01'
    AND trip_distance > 0
    AND fare_amount > 0
    AND total_amount > 0;

.print Dataset profile
SELECT
    COUNT(*) AS total_rows,
    ROUND(AVG(trip_distance), 2) AS avg_trip_miles,
    ROUND(SUM(total_amount), 2) AS total_amount_usd
FROM clean_trips;

CREATE OR REPLACE TABLE payment_summary AS
SELECT
    -- payment_type labels come from the NYC TLC yellow taxi data dictionary.
    CASE payment_type
        WHEN 0 THEN 'Flex Fare trip'
        WHEN 1 THEN 'Credit card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        WHEN 6 THEN 'Voided trip'
        ELSE 'Other'
    END AS payment_method,
    COUNT(*) AS trips,
    ROUND(SUM(total_amount), 2) AS total_amount_usd,
    ROUND(AVG(total_amount), 2) AS avg_amount_usd
FROM clean_trips
GROUP BY payment_method
ORDER BY trips DESC;

.print Payment summary
SELECT * FROM payment_summary;

CREATE OR REPLACE TABLE busiest_pickup_hours AS
SELECT
    EXTRACT(hour FROM tpep_pickup_datetime) AS pickup_hour,
    COUNT(*) AS trips,
    ROUND(AVG(trip_distance), 2) AS avg_trip_miles,
    ROUND(SUM(total_amount), 2) AS total_amount_usd
FROM clean_trips
GROUP BY pickup_hour
ORDER BY trips DESC
LIMIT 8;

.print Busiest pickup hours
SELECT * FROM busiest_pickup_hours;

CREATE OR REPLACE TABLE top_pickup_zones AS
WITH trips AS (
    SELECT
        PULocationID,
        trip_distance,
        total_amount
    FROM clean_trips
),
zones AS (
    SELECT
        LocationID,
        Borough,
        Zone
    FROM read_csv_auto('data/taxi_zone_lookup.csv')
)
SELECT
    zones.Borough AS borough,
    zones.Zone AS pickup_zone,
    COUNT(*) AS trips,
    ROUND(SUM(trips.total_amount), 2) AS total_amount_usd,
    ROUND(AVG(trips.trip_distance), 2) AS avg_trip_miles
FROM trips
JOIN zones ON trips.PULocationID = zones.LocationID
GROUP BY zones.Borough, zones.Zone
ORDER BY total_amount_usd DESC
LIMIT 8;

.print Top pickup zones by total amount
SELECT * FROM top_pickup_zones;

COPY top_pickup_zones TO 'outputs/top_pickup_zones.parquet' (FORMAT PARQUET);

.print Created outputs/nyc_taxi_demo.duckdb
.print Created outputs/top_pickup_zones.parquet

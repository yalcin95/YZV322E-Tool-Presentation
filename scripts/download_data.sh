#!/usr/bin/env bash
set -euo pipefail

mkdir -p data

curl -L \
  -o data/yellow_tripdata_2024-01.parquet \
  https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet

curl -L \
  -o data/taxi_zone_lookup.csv \
  https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv

echo "Downloaded NYC TLC sample data into data/"

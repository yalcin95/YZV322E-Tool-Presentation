"""Compare a Pandas GROUP BY with DuckDB SQL on the same DataFrame.

Run:
    docker-compose run --rm pandas-bench
"""

from __future__ import annotations

import time
from pathlib import Path

import duckdb
import pandas as pd

PARQUET_PATH = Path(__file__).resolve().parent.parent / "data" / "yellow_tripdata_2024-01.parquet"


def time_pandas(df: pd.DataFrame) -> tuple[pd.DataFrame, float]:
    start = time.perf_counter()
    result = (
        df[df.trip_distance > 0]
        .groupby("payment_type", as_index=False)
        .agg(
            trips=("total_amount", "size"),
            total_usd=("total_amount", "sum"),
            avg_usd=("total_amount", "mean"),
        )
        .sort_values("trips", ascending=False)
        .reset_index(drop=True)
    )
    elapsed = time.perf_counter() - start
    return result, elapsed


def time_duckdb(df: pd.DataFrame) -> tuple[pd.DataFrame, float]:
    # DuckDB can query the DataFrame variable directly.
    start = time.perf_counter()
    result = duckdb.sql(
        """
        SELECT
            payment_type,
            COUNT(*)            AS trips,
            SUM(total_amount)   AS total_usd,
            AVG(total_amount)   AS avg_usd
        FROM df
        WHERE trip_distance > 0
        GROUP BY payment_type
        ORDER BY trips DESC
        """
    ).df()
    elapsed = time.perf_counter() - start
    return result, elapsed


def main() -> None:
    print(f"DuckDB version: {duckdb.__version__}")
    print(f"Pandas version: {pd.__version__}")
    print(f"Loading {PARQUET_PATH.name} into a Pandas DataFrame...")

    df = pd.read_parquet(PARQUET_PATH)
    print(f"DataFrame shape: {df.shape[0]:,} rows x {df.shape[1]} columns\n")

    print("Running same GROUP BY aggregation in both engines...\n")

    pandas_result, pandas_secs = time_pandas(df)
    duckdb_result, duckdb_secs = time_duckdb(df)

    print("Pandas result:")
    print(pandas_result.to_string(index=False))
    print()
    print("DuckDB result (queried directly against the Pandas DataFrame):")
    print(duckdb_result.to_string(index=False))
    print()
    print("Timing on identical data:")
    print(f"  Pandas: {pandas_secs:.3f} s")
    print(f"  DuckDB: {duckdb_secs:.3f} s")
    if duckdb_secs > 0:
        print(f"  Speedup: {pandas_secs / duckdb_secs:.1f}x")


if __name__ == "__main__":
    main()

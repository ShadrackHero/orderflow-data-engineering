
import time
from pathlib import Path
from datetime import datetime, timezone

from db_connection import get_connection

PROJECT_ROOT = Path(__file__).resolve().parents[1]

SQL_FILE = (
    PROJECT_ROOT
    / "sql"
    / "04_staging_transformations.sql"
)

TABLES = [
    "customers",
    "orders",
    "products",
    "sellers",
    "order_items",
    "order_payments",
    "order_reviews",
    "geolocation",
    "product_category_name_translation",
]


def run_staging():
    print("Starting OrderFlow staging pipeline...\n")

    started_at = datetime.now(timezone.utc)
    start_time = time.perf_counter()

    sql_script = SQL_FILE.read_text(encoding="utf-8")

    with get_connection() as conn:
        with conn.cursor() as cursor:

            # Execute all transformations in one transaction.
            cursor.execute(sql_script)

            print("Validating staging row counts...\n")

            for table in TABLES:
                cursor.execute(
                    f"""
                    SELECT
                        (SELECT COUNT(*) FROM raw.{table}),
                        (SELECT COUNT(*) FROM staging.{table})
                    """
                )

                raw_count, staging_count = cursor.fetchone()

                if raw_count != staging_count:
                    raise ValueError(
                        f"{table}: row count mismatch "
                        f"(raw={raw_count}, staging={staging_count})"
                    )

                print(
                    f"[PASS] {table}: "
                    f"{staging_count:,} rows"
                )

        # Commit only if every transformation and validation succeeds.
        conn.commit()

    duration = time.perf_counter() - start_time

    print(
        f"\nStaging completed successfully "
        f"in {duration:.2f} seconds."
    )

    print(f"Started at: {started_at.isoformat()}")


def log_staging_run(
    status, started_at, duration,
    source_rows=None, loaded_rows=None,
    error_message=None
):
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO audit.pipeline_runs (
                    pipeline_name,
                    table_name,
                    source_rows,
                    loaded_rows,
                    status,
                    started_at,
                    completed_at,
                    duration_seconds,
                    error_message
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    "olist_staging_transformation",
                    "all_staging_tables",
                    source_rows,
                    loaded_rows,
                    status,
                    started_at,
                    datetime.now(timezone.utc),
                    duration,
                    error_message
                )
            )

if __name__ == "__main__":
    run_staging()

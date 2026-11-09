
import csv
import time
from datetime import datetime, timezone
from pathlib import Path

from psycopg import sql
from db_connection import get_connection

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data" / "raw"


def get_table_name(file):
    return (
        file.stem
        .removeprefix("olist_")
        .removesuffix("_dataset")
    )


def get_source_rows(file):
    with file.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f)
        next(reader)
        return sum(1 for _ in reader)


def write_audit(
    table_name, source_rows, loaded_rows,
    status, started_at, duration, error=None
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
                VALUES (
                    'olist_raw_ingestion',
                    %s, %s, %s, %s, %s, %s, %s, %s
                )
                """,
                (
                    table_name,
                    source_rows,
                    loaded_rows,
                    status,
                    started_at,
                    datetime.now(timezone.utc),
                    duration,
                    error
                )
            )


def ingest_file(file):
    table_name = get_table_name(file)
    started_at = datetime.now(timezone.utc)
    start_time = time.perf_counter()

    source_rows = None
    loaded_rows = None

    try:
        source_rows = get_source_rows(file)

        with file.open("r", encoding="utf-8-sig", newline="") as f:
            columns = next(csv.reader(f))

        with get_connection() as conn:
            with conn.cursor() as cursor:

                cursor.execute(
                    sql.SQL("TRUNCATE TABLE {}.{}").format(
                        sql.Identifier("raw"),
                        sql.Identifier(table_name)
                    )
                )

                copy_query = sql.SQL(
                    "COPY {}.{} ({}) "
                    "FROM STDIN WITH (FORMAT CSV, HEADER TRUE)"
                ).format(
                    sql.Identifier("raw"),
                    sql.Identifier(table_name),
                    sql.SQL(", ").join(
                        sql.Identifier(col) for col in columns
                    )
                )

                with cursor.copy(copy_query) as copy:
                    with file.open("rb") as source:
                        while chunk := source.read(1024 * 1024):
                            copy.write(chunk)

                cursor.execute(
                    sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
                        sql.Identifier("raw"),
                        sql.Identifier(table_name)
                    )
                )

                loaded_rows = cursor.fetchone()[0]

                if source_rows != loaded_rows:
                    raise ValueError(
                        f"Row count mismatch: "
                        f"CSV={source_rows}, DB={loaded_rows}"
                    )

            # Commit the data only after validation passes.
            conn.commit()

        duration = time.perf_counter() - start_time

        write_audit(
            table_name, source_rows, loaded_rows,
            "SUCCESS", started_at, duration
        )

        print(
            f"[SUCCESS] raw.{table_name}: "
            f"{loaded_rows:,} rows ({duration:.2f}s)"
        )

    except Exception as error:
        duration = time.perf_counter() - start_time

        try:
            write_audit(
                table_name, source_rows, loaded_rows,
                "FAILED", started_at, duration,
                str(error)
            )
        except Exception as audit_error:
            print(f"[AUDIT ERROR] {audit_error}")

        print(f"[FAILED] raw.{table_name}: {error}")
        raise


def run_ingestion():
    files = sorted(DATA_DIR.glob("*.csv"))

    if len(files) != 9:
        raise ValueError(
            f"Expected 9 CSV files, found {len(files)}"
        )

    print("Starting OrderFlow ingestion...\n")

    for file in files:
        ingest_file(file)

    print("\nAll 9 datasets loaded and validated.")


if __name__ == "__main__":
    run_ingestion()

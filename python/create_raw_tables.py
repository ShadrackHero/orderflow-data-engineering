
import csv
from pathlib import Path

from psycopg import sql
from db_connection import get_connection

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data" / "raw"


def create_raw_tables():
    csv_files = sorted(DATA_DIR.glob("*.csv"))

    if len(csv_files) != 9:
        raise ValueError(
            f"Expected 9 CSV files, found {len(csv_files)}"
        )

    with get_connection() as conn:
        with conn.cursor() as cursor:

            for file in csv_files:
                table_name = (
                    file.stem
                    .removeprefix("olist_")
                    .removesuffix("_dataset")
                )

                with file.open(
                    "r", encoding="utf-8-sig", newline=""
                ) as f:
                    columns = next(csv.reader(f))

                column_definitions = sql.SQL(", ").join(
                    sql.SQL("{} TEXT").format(
                        sql.Identifier(column)
                    )
                    for column in columns
                )

                query = sql.SQL(
                    "CREATE TABLE IF NOT EXISTS {}.{} ({})"
                ).format(
                    sql.Identifier("raw"),
                    sql.Identifier(table_name),
                    column_definitions
                )

                cursor.execute(query)
                print(f"Created or verified raw.{table_name}")

        conn.commit()

    print("\nRaw table creation completed.")


if __name__ == "__main__":
    create_raw_tables()
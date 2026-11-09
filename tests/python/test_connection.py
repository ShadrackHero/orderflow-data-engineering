
import sys
from pathlib import Path

# Locate project root
PROJECT_ROOT = Path(__file__).resolve().parents[2]

# Allow imports from the python folder
sys.path.insert(0, str(PROJECT_ROOT / "python"))

from db_connection import get_connection


try:
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT current_database(), current_user;
            """)

            result = cursor.fetchone()

            print("Connection successful!")
            print("Database:", result[0])
            print("User:", result[1])

except Exception as error:
    print("Connection failed:")
    print(error)
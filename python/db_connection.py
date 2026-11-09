
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv

# Locate the project root
PROJECT_ROOT = Path(__file__).resolve().parents[1]

# Load credentials
load_dotenv(PROJECT_ROOT / ".env")


def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )
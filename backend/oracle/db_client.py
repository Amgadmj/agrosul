import os
import psycopg2
from psycopg2 import pool
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/agrosul_db")

try:
    # Use a connection pool for safe multi-threaded background workers
    threaded_postgis_pool = psycopg2.pool.ThreadedConnectionPool(
        1, 10, dsn=DATABASE_URL
    )
    if threaded_postgis_pool:
        print("[Oracle DB] Connection pool created successfully")
except Exception as e:
    print(f"[Oracle DB Error] Failed to connect to database: {e}")
    threaded_postgis_pool = None

def get_connection():
    if threaded_postgis_pool:
        return threaded_postgis_pool.getconn()
    return None

def release_connection(conn):
    if threaded_postgis_pool and conn:
        threaded_postgis_pool.putconn(conn)

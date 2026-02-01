"""Shared configuration for SQLite vector database scripts."""

import os
import sqlite3
from pathlib import Path

# Database configuration
PROJECT_ROOT = Path(os.getcwd())
DB_DIR = PROJECT_ROOT / "private-docs" / "work-logs" / ".vector-db"
DB_PATH = DB_DIR / "work-logs.db"

# Embedding configuration
EMBEDDING_MODEL = "all-MiniLM-L6-v2"
EMBEDDING_DIM = 384

# Environment variable overrides
if env_db_path := os.getenv("VECTORDB_PATH"):
    DB_PATH = Path(env_db_path)
    DB_DIR = DB_PATH.parent


def ensure_db_dir() -> None:
    """Ensure database directory exists."""
    DB_DIR.mkdir(parents=True, exist_ok=True)


def _init_schema() -> None:
    """Create database schema (internal helper)."""
    import sqlite_vec

    conn = sqlite3.connect(str(DB_PATH))
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    cursor = conn.cursor()

    # Work logs metadata table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS work_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_path TEXT UNIQUE NOT NULL,
            summary TEXT NOT NULL,
            tags TEXT,
            log_date DATE,
            log_type TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Chunks table for granular retrieval
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS chunks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            work_log_id INTEGER NOT NULL,
            chunk_type TEXT NOT NULL,
            content TEXT NOT NULL,
            FOREIGN KEY (work_log_id) REFERENCES work_logs(id) ON DELETE CASCADE
        )
    """)

    # Vector table for embeddings
    cursor.execute(f"""
        CREATE VIRTUAL TABLE IF NOT EXISTS chunk_embeddings USING vec0(
            chunk_id INTEGER PRIMARY KEY,
            embedding FLOAT[{EMBEDDING_DIM}]
        )
    """)

    # Indexes
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_work_logs_date ON work_logs(log_date)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_work_logs_type ON work_logs(log_type)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_chunks_work_log ON chunks(work_log_id)")

    conn.commit()
    conn.close()
    print(f"Database auto-initialized at: {DB_PATH}")


def ensure_db_initialized() -> None:
    """Ensure database is initialized with schema.

    Automatically creates the database and schema if they don't exist.
    Safe to call multiple times - will only initialize if needed.
    """
    ensure_db_dir()

    if not DB_PATH.exists():
        _init_schema()
        return

    # DB file exists but check if tables are present
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='work_logs'")
    has_tables = cursor.fetchone() is not None
    conn.close()

    if not has_tables:
        _init_schema()

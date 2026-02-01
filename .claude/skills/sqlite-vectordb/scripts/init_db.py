#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "sqlite-vec>=0.1.1",
# ]
# ///
"""Initialize the SQLite vector database for work logs."""

import sqlite3
import sys
from pathlib import Path

# Enable local imports when run via uv
sys.path.insert(0, str(Path(__file__).parent))

import sqlite_vec

from config import DB_PATH, EMBEDDING_DIM, ensure_db_dir


def init_database() -> None:
    """Create database schema with vector support."""
    ensure_db_dir()

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

    print(f"Database initialized at: {DB_PATH}")


if __name__ == "__main__":
    try:
        init_database()
    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "sqlite-vec>=0.1.1",
# ]
# ///
"""Delete a work log entry from the vector database."""

import argparse
import sqlite3
import sys
from pathlib import Path

# Enable local imports when run via uv
sys.path.insert(0, str(Path(__file__).parent))

import sqlite_vec

from config import DB_PATH, ensure_db_initialized


def delete_entry(file_path: str) -> bool:
    """Delete work log entry and its embeddings."""
    ensure_db_initialized()

    conn = sqlite3.connect(str(DB_PATH))
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    cursor = conn.cursor()

    # Find work log
    cursor.execute("SELECT id FROM work_logs WHERE file_path = ?", (file_path,))
    result = cursor.fetchone()

    if not result:
        conn.close()
        return False

    work_log_id = result[0]

    # Delete embeddings first (foreign key constraint)
    cursor.execute("""
        DELETE FROM chunk_embeddings
        WHERE chunk_id IN (SELECT id FROM chunks WHERE work_log_id = ?)
    """, (work_log_id,))

    # Delete chunks
    cursor.execute("DELETE FROM chunks WHERE work_log_id = ?", (work_log_id,))

    # Delete work log
    cursor.execute("DELETE FROM work_logs WHERE id = ?", (work_log_id,))

    conn.commit()
    conn.close()
    return True


def main():
    parser = argparse.ArgumentParser(description="Delete work log from vector database")
    parser.add_argument("--file", "-f", required=True, help="Path to work log file")
    args = parser.parse_args()

    try:
        if delete_entry(args.file):
            print(f"Deleted: {args.file}")
        else:
            print(f"Not found: {args.file}", file=sys.stderr)
            sys.exit(1)
    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

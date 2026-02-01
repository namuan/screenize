#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "sqlite-vec>=0.1.1",
#     "sentence-transformers>=2.2.0",
#     "numpy>=1.24.0",
# ]
# ///
"""Semantic search in the work logs vector database."""

import argparse
import json
import sqlite3
import sys
from pathlib import Path

# Enable local imports when run via uv
sys.path.insert(0, str(Path(__file__).parent))

import sqlite_vec

from config import DB_PATH, ensure_db_initialized
from embeddings import generate_embedding


def search(query: str, limit: int = 5, tag_filter: str = "", type_filter: str = "") -> list[dict]:
    """Search work logs by semantic similarity."""
    ensure_db_initialized()

    query_embedding = generate_embedding(query)

    conn = sqlite3.connect(str(DB_PATH))
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    cursor = conn.cursor()

    # Vector similarity search
    cursor.execute("""
        SELECT
            ce.chunk_id,
            ce.distance,
            c.chunk_type,
            c.content,
            w.file_path,
            w.summary,
            w.tags,
            w.log_date,
            w.log_type
        FROM chunk_embeddings ce
        JOIN chunks c ON ce.chunk_id = c.id
        JOIN work_logs w ON c.work_log_id = w.id
        WHERE ce.embedding MATCH ?
          AND k = ?
        ORDER BY ce.distance
    """, (query_embedding.tobytes(), limit * 3))  # Get more for filtering

    results = []
    seen_files = set()

    for row in cursor.fetchall():
        _chunk_id, distance, chunk_type, content, file_path, summary, tags, log_date, log_type = row

        # Apply filters
        if tag_filter and tag_filter.lower() not in (tags or "").lower():
            continue
        if type_filter and type_filter.lower() != (log_type or "").lower():
            continue

        # Dedupe by file (keep best match per file)
        if file_path in seen_files:
            continue
        seen_files.add(file_path)

        results.append({
            "file_path": file_path,
            "summary": summary,
            "relevance": round(1 - distance, 4),  # Convert distance to similarity
            "matched_section": chunk_type,
            "matched_content": content[:200] + "..." if len(content) > 200 else content,
            "tags": tags,
            "date": log_date,
            "type": log_type
        })

        if len(results) >= limit:
            break

    conn.close()
    return results


def main():
    parser = argparse.ArgumentParser(description="Search work logs by semantic similarity")
    parser.add_argument("--query", "-q", required=True, help="Search query")
    parser.add_argument("--limit", "-l", type=int, default=5, help="Max results (default: 5)")
    parser.add_argument("--tag", "-t", default="", help="Filter by tag")
    parser.add_argument("--type", "-T", default="", help="Filter by log type")
    parser.add_argument("--json", "-j", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    try:
        results = search(args.query, args.limit, args.tag, args.type)

        if args.json:
            print(json.dumps(results, indent=2))
        else:
            if not results:
                print("No matching work logs found.")
                return

            for i, r in enumerate(results, 1):
                print(f"\n[{i}] {r['file_path']}")
                print(f"    Summary: {r['summary']}")
                print(f"    Relevance: {r['relevance']:.2%}")
                print(f"    Date: {r['date'] or 'N/A'} | Type: {r['type'] or 'N/A'}")
                if r['tags']:
                    print(f"    Tags: {r['tags']}")

    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

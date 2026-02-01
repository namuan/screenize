#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "sqlite-vec>=0.1.1",
#     "sentence-transformers>=2.2.0",
#     "numpy>=1.24.0",
#     "pyyaml>=6.0",
# ]
# ///
"""Add a work log entry to the vector database."""

import argparse
import re
import sqlite3
import sys
from pathlib import Path

# Enable local imports when run via uv
sys.path.insert(0, str(Path(__file__).parent))

import sqlite_vec
import yaml

from config import DB_PATH, ensure_db_initialized
from embeddings import generate_embeddings


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML frontmatter and body from markdown."""
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", content, re.DOTALL)
    if match:
        try:
            metadata = yaml.safe_load(match.group(1)) or {}
            return metadata, match.group(2)
        except yaml.YAMLError:
            return {}, content
    return {}, content


def extract_chunks(body: str, summary: str) -> list[tuple[str, str]]:
    """Extract semantic chunks from work log body."""
    chunks = [("summary", summary)]

    # Extract sections
    sections = re.split(r"\n##\s+", body)
    for section in sections[1:]:  # Skip content before first ##
        lines = section.strip().split("\n")
        if lines:
            section_name = lines[0].lower().strip()
            section_content = "\n".join(lines[1:]).strip()
            if section_content:
                chunk_type = "details" if "detail" in section_name else \
                             "challenges" if "challenge" in section_name or "solution" in section_name else \
                             "other"
                chunks.append((chunk_type, section_content[:2000]))  # Limit chunk size

    return chunks


def add_entry(file_path: str, summary: str, tags: str = "") -> None:
    """Add work log entry with embeddings."""
    path = Path(file_path)
    if not path.exists():
        print(f"Error: File not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    ensure_db_initialized()
    content = path.read_text(encoding="utf-8")
    metadata, body = parse_frontmatter(content)

    conn = sqlite3.connect(str(DB_PATH))
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    cursor = conn.cursor()

    # Delete existing entry if exists
    cursor.execute("SELECT id FROM work_logs WHERE file_path = ?", (file_path,))
    existing = cursor.fetchone()
    if existing:
        work_log_id = existing[0]
        cursor.execute("DELETE FROM chunk_embeddings WHERE chunk_id IN (SELECT id FROM chunks WHERE work_log_id = ?)", (work_log_id,))
        cursor.execute("DELETE FROM chunks WHERE work_log_id = ?", (work_log_id,))
        cursor.execute("DELETE FROM work_logs WHERE id = ?", (work_log_id,))

    # Insert work log
    cursor.execute("""
        INSERT INTO work_logs (file_path, summary, tags, log_date, log_type)
        VALUES (?, ?, ?, ?, ?)
    """, (
        file_path,
        summary,
        tags,
        metadata.get("date"),
        metadata.get("type")
    ))
    work_log_id = cursor.lastrowid

    # Extract and embed chunks
    chunks = extract_chunks(body, summary)
    chunk_texts = [text for _, text in chunks]
    embeddings = generate_embeddings(chunk_texts)

    for (chunk_type, chunk_text), embedding in zip(chunks, embeddings):
        cursor.execute(
            "INSERT INTO chunks (work_log_id, chunk_type, content) VALUES (?, ?, ?)",
            (work_log_id, chunk_type, chunk_text)
        )
        chunk_id = cursor.lastrowid
        cursor.execute(
            "INSERT INTO chunk_embeddings (chunk_id, embedding) VALUES (?, ?)",
            (chunk_id, embedding.tobytes())
        )

    conn.commit()
    conn.close()
    print(f"Added: {file_path} ({len(chunks)} chunks)")


def main():
    parser = argparse.ArgumentParser(description="Add work log to vector database")
    parser.add_argument("--file", "-f", required=True, help="Path to work log markdown file")
    parser.add_argument("--summary", "-s", required=True, help="One-line summary")
    parser.add_argument("--tags", "-t", default="", help="Comma-separated tags")
    args = parser.parse_args()

    try:
        add_entry(args.file, args.summary, args.tags)
    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()

---
name: sqlite-vectordb
description: SQLite vector DB for work log storage and semantic search. Use for indexing work logs, generating embeddings, semantic search, and DB maintenance.
---

# SQLITE VECTOR DB SKILL

<objective>

Store work logs in a searchable vector database and provide semantic search infrastructure.

**When to use**:
- **Add entry**: After `/log-work` execution (integrated with work-logger)
- **Search**: When previous work context is needed (called by work-context-finder)
- **Delete**: To clean up incorrect/outdated logs

**Note**: DB initializes automatically. No need to run `init_db.py` manually.

</objective>

<commands>

## Add Entry

Index a markdown log into the vector DB.

```bash
uv run .claude/skills/sqlite-vectordb/scripts/add_entry.py \
  --file "private-docs/work-logs/YYYY-MM-DD-slug.md" \
  --summary "One-line summary" \
  --tags "tag1,tag2"
```

- `--file`, `-f` (required): Work log file path
- `--summary`, `-s` (required): One-line summary for search indexing
- `--tags`, `-t` (required): Comma-separated tags

## Search

Semantic similarity search in work logs.

```bash
uv run .claude/skills/sqlite-vectordb/scripts/search.py \
  --query "search terms" \
  --limit 5
```

- `--query`, `-q` (required): Search query
- `--limit`, `-l`: Max results (default: 5)
- `--tag`, `-t`: Filter by tag
- `--type`, `-T`: Filter by log type
- `--json`, `-j`: JSON output

## Delete Entry

Remove a work log entry from the database.

```bash
uv run .claude/skills/sqlite-vectordb/scripts/delete_entry.py \
  --file "private-docs/work-logs/YYYY-MM-DD-slug.md"
```

## Initialize DB (Optional)

Manual schema creation. Usually not needed - other scripts auto-initialize.

```bash
uv run .claude/skills/sqlite-vectordb/scripts/init_db.py
```

</commands>

<technical_specs>

- **DB location**: `private-docs/work-logs/.vector-db/work-logs.db`
- **Engine**: SQLite + `sqlite-vec` extension
- **Embedding model**: `all-MiniLM-L6-v2` (384-dim)
- **Chunk types**: summary, details, challenges, other
- **Execution**: `uv run` with PEP 723 inline deps
- **Schema reference**: [references/schema.md](references/schema.md)

</technical_specs>

<standards>

**Language requirement**: All data stored in the vector DB MUST be written in English.

- **Summary**: English only (for consistent embedding quality)
- **Tags**: English only (e.g., `auth`, `refactor`, not `인증`, `리팩토링`)
- **Query**: English preferred for optimal search accuracy
- **Rationale**: Embedding model (`all-MiniLM-L6-v2`) performs best with English text

</standards>

<troubleshooting>

**Exit codes**:
- 0: Success
- 1: File not found
- 2: DB error

**Common fixes**:
- DB corrupted: Delete `private-docs/work-logs/.vector-db/work-logs.db` and re-run (auto-recreates)
- Missing deps: Run `uv sync`

</troubleshooting>

<examples>

**Valid usage**:

```bash
# Add entry (auto-initializes DB if missing)
uv run .claude/skills/sqlite-vectordb/scripts/add_entry.py \
  --file "private-docs/work-logs/2026-01-16-auth-feature.md" \
  --summary "Implement OAuth2 authentication" \
  --tags "auth,oauth,security"

# Search with filters
uv run .claude/skills/sqlite-vectordb/scripts/search.py \
  --query "authentication login" --limit 3 --tag auth
```

**Invalid usage**:

```bash
# WRONG: Non-existent file → Exit code 1
uv run .../add_entry.py --file "missing.md" ...

# WRONG: Empty summary → Poor search quality
uv run .../add_entry.py --file "..." --summary "" --tags "..."
```

</examples>

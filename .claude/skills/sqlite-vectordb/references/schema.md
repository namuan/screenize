# SQLITE VECTOR DB SCHEMA

## 1. Tables

- **`work_logs`**: Metadata (`id`, `file_path`, `summary`, `tags`, `log_date`, `log_type`, `timestamps`).
- **`chunks`**: Text parts linked to `work_logs` (`id`, `work_log_id`, `chunk_type`, `content`).
- **`chunk_embeddings`** (Virtual): Vector storage.
  - `chunk_id` (FK -> `chunks.id`)
  - `embedding` (FLOAT[384])

## 2. Embeddings & Chunking

- **Model**: `all-MiniLM-L6-v2` (384-dim, via `sentence-transformers`).
- **Chunks**:
  1. **summary**: User-provided one-liner.
  2. **details**: From "Details" section.
  3. **challenges**: From "Challenges" section.
  4. **other**: All other content.

## 3. Query Examples

### Similarity Search

```sql
SELECT w.file_path, w.summary, ce.distance
FROM chunk_embeddings ce
JOIN chunks c ON ce.chunk_id = c.id
JOIN work_logs w ON c.work_log_id = w.id
WHERE ce.embedding MATCH ? AND k = 5
ORDER BY ce.distance;
```

### Filtering

```sql
SELECT * FROM work_logs WHERE log_type = 'bugfix' AND log_date >= '2024-01-01' ORDER BY log_date DESC;
```

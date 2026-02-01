---
name: work-logger
description: Document completed work with vector database indexing. Use `/log-work` after completing any significant task (feature, bug fix, refactoring, configuration change) to record what was done, decisions made, and files changed.
user_invocable: true
---

# WORK LOGGING PROTOCOL

<objective>

Index completed work for future context retrieval via semantic search.

**When to use**: Execute `/log-work` after every meaningful work unit (features, bugs, refactors, config changes).

</objective>

<workflow>

## Step 1: Generate Template

```bash
uv run .claude/skills/work-logger/scripts/create_template.py \
  --description "short-description" \
  --type feature|bugfix|refactor|docs|config
```

Output: `private-docs/work-logs/YYYY-MM-DD-short-description.md`

## Step 2: Populate Log

Edit the generated file:

- **Metadata**: Fill `tags` (YAML array) and `files_changed`
- **Content**: Complete `summary`, Title, and all sections
- **Quality**: Ensure self-contained, searchable text

## Step 3: Index to Vector DB

```bash
uv run .claude/skills/sqlite-vectordb/scripts/add_entry.py \
  --file "private-docs/work-logs/YYYY-MM-DD-short-description.md" \
  --summary "One-line summary" \
  --tags "tag1,tag2"
```

</workflow>

<standards>

- **Language**: All indexed data (summary, tags) MUST be in English for vector DB compatibility
- **Integrity**: Logs must be understandable in isolation with verified filenames/paths
- **Context**: Use project conventions from `CLAUDE.md`
- **Completeness**: Include decisions made and rationale

</standards>

<examples>

**Valid usage**:

```bash
# Step 1: Generate
uv run .claude/skills/work-logger/scripts/create_template.py \
  --description "add-user-auth" --type feature

# Step 2: Edit private-docs/work-logs/2026-01-16-add-user-auth.md

# Step 3: Index
uv run .claude/skills/sqlite-vectordb/scripts/add_entry.py \
  --file "private-docs/work-logs/2026-01-16-add-user-auth.md" \
  --summary "Implemented OAuth2 user authentication" \
  --tags "auth,oauth,security"
```

</examples>

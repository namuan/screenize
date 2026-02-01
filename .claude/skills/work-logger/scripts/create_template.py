#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
Create a work log template file with accurate date and time.
"""

import argparse
import re
from datetime import datetime
from pathlib import Path


def slugify(text: str) -> str:
    """Convert text to URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[-\s]+", "-", text)
    return text[:50].rstrip("-")


def create_template(description: str, work_type: str = "other") -> str:
    """Create work log template and return the file path."""
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H:%M")

    slug = slugify(description) if description else "work-log"
    filename = f"{date_str}-{slug}.md"

    work_logs_dir = Path("private-docs/work-logs")
    work_logs_dir.mkdir(parents=True, exist_ok=True)

    filepath = work_logs_dir / filename

    # Check if file already exists
    if filepath.exists():
        counter = 1
        while True:
            new_filename = f"{date_str}-{slug}-{counter}.md"
            filepath = work_logs_dir / new_filename
            if not filepath.exists():
                filename = new_filename
                break
            counter += 1

    template = f"""---
date: {date_str}
time: {time_str}
type: {work_type}
tags: []
files_changed: []
summary:
---

# {{Title}}

## Summary
Brief overview of what was accomplished.

## Details
- Specific changes made
- Technical decisions and rationale
- Code patterns used

## Challenges & Solutions
Any obstacles encountered and how they were resolved.

## Related Work
References to related previous work logs or issues.

## Next Steps
Any follow-up tasks or considerations.
"""

    filepath.write_text(template)
    print(filepath)
    return str(filepath)


def main():
    parser = argparse.ArgumentParser(description="Create work log template")
    parser.add_argument(
        "--description", "-d",
        type=str,
        default="",
        help="Brief description for filename (will be slugified)"
    )
    parser.add_argument(
        "--type", "-t",
        type=str,
        choices=["feature", "bugfix", "refactor", "docs", "config", "other"],
        default="other",
        help="Type of work"
    )

    args = parser.parse_args()
    create_template(args.description, args.type)


if __name__ == "__main__":
    main()

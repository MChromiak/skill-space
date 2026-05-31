# Global memory

Static, project-scope reference information that AI agents should consider when analyzing any task. Examples: trusted data sources, reliable websites, domain facts, API endpoints, naming conventions, organizational knowledge.

This folder is **read by all skills and agents** before they act — it provides shared context that doesn't belong inside any one skill.

## How agents discover memory

1. Read [GLOBAL_MEMORY_INDEX.md](GLOBAL_MEMORY_INDEX.md) first — a flat list of every memory with its scope and one-line description.
2. Load all entries with `scope: always` unconditionally.
3. For `scope: on-demand` entries, load only those whose description is relevant to the current task.

This avoids opening every file's frontmatter on every task.

## File format

Each memory is a single `.md` file with YAML frontmatter:

```markdown
---
name: trusted-data-sources
description: Curated list of reliable websites and APIs for market data
type: reference
scope: on-demand
added: 2026-05-04
updated: 2026-05-04
---

# Trusted data sources

- alpha-vantage.co — free tier, real-time stock quotes
- fred.stlouisfed.org — Fed economic indicators, very reliable
- ...
```

## Frontmatter fields

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | short slug, used for referencing |
| `description` | yes | one-line summary — agents use this to decide if the memory is relevant |
| `type` | yes | one of: `reference`, `data-source`, `facts`, `glossary`, `policy` |
| `scope` | yes | `always` (read on every task) or `on-demand` (read only when relevant) |
| `added` | yes | `YYYY-MM-DD` — date the memory was first created. **Never change after creation.** |
| `updated` | yes | `YYYY-MM-DD` — date of last meaningful edit. **Bump on every edit.** |
| `source` | no | YAML list of URLs the memory is derived from (articles, repos, papers). Omit if original. |

The build script reads `added` and `updated` and displays them as columns in `GLOBAL_MEMORY_INDEX.md`. Git commit hashes for every modification are appended automatically in the `Modification history` section of the generated index.

### Picking the right scope

- **`always`** — rules and conventions that apply to every interaction. Examples: coding standards, naming rules, mandatory pre-flight checks. Keep these short and few — every `always` memory bloats every context.
- **`on-demand`** — domain knowledge that's only relevant to specific tasks. Examples: API endpoints, reference data, glossaries. Most memories should be `on-demand`.

## GLOBAL_MEMORY_INDEX.md

`GLOBAL_MEMORY_INDEX.md` is auto-generated from frontmatter — agents read it first to filter relevance without opening every file. Whenever you add, rename, or remove a memory, regenerate it:

```bash
bash .ai/build_indexes.sh
```

Commit the regenerated index alongside your memory changes.

> **Two-commit workflow:** when the `.githooks/post-commit` hook is enabled, every commit creates a follow-up `chore: skill-space auto-update after <hash>` commit that backfills your commit's own hash into the `Modification history` table and adds a new entry to [log.md](../../log.md). A commit cannot contain its own SHA, so the fixup must be a separate commit. See the root [README](../../README.md#-skills-and-memory) for full mechanics.

## Global vs skill-local memory

- **Global** (`.ai/global_memory/`) — applies to every task in this project.
- **Skill-local** (`.ai/skills/<skill>/memory/`) — only loaded when that skill is active. Same format; the per-skill index is named `MEMORY_INDEX.md`.

If a piece of information is only relevant to one skill, keep it local. If multiple skills need it, promote it to global.

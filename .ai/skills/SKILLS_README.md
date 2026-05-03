# Skills

Reusable AI capabilities — prompts, workflows, or domain-specific behaviors agents can apply to tasks.

## How agents discover skills

1. Read [SKILLS_INDEX.md](SKILLS_INDEX.md) — auto-generated list of every skill with scope and description.
2. Load every skill marked `scope: always` unconditionally.
3. For `scope: on-demand` skills, load only those whose description is relevant to the current task.

A skill is **active** for a task when it has been loaded via this process. Skill-local memory at `.ai/skills/<active-skill>/memory/` is then consulted using the same index-driven flow (see `MEMORY_INDEX.md` in each skill's memory folder).

## Skill formats

A skill can be either:

- **Single file** — `<skill-name>.md`
- **Bundle folder** — `<skill-name>/<skill-name>.md` with optional `memory/` and `scripts/` subfolders

```
skills/
├── code-review.md                ← single-file skill
└── data-pipeline/                ← bundle skill
    ├── data-pipeline.md          ← main file (must match folder name)
    ├── memory/                   ← optional skill-local memory
    │   ├── MEMORY_INDEX.md
    │   └── *.md
    └── scripts/                  ← optional helper scripts
        └── *.sh
```

## Frontmatter

Each skill's main `.md` file starts with YAML frontmatter:

```markdown
---
name: code-review
description: Review pull requests for security, correctness, and conventions
scope: on-demand
---

# code-review

...skill body here...
```

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | short slug |
| `description` | yes | one-line summary used by agents to filter relevance |
| `scope` | yes | `always` (load on every task) or `on-demand` |

### Picking the right scope

- **`always`** — skills that should run on every interaction (e.g., `clarifying-questions`, `code-style-enforcer`). Keep this short — every `always` skill bloats every context.
- **`on-demand`** — skills tied to specific tasks (e.g., `code-review`, `migration-planner`). Most skills should be `on-demand`.

## Optional subfolders (bundle skills only)

| Subfolder | Purpose | Format |
|---|---|---|
| `memory/` | skill-local reference data | same as `.ai/global_memory/`, with its own `MEMORY_INDEX.md` |
| `scripts/` | helper executables the skill may invoke | any shell/Python/Node scripts |

## Regenerating index files

Index files are auto-generated from frontmatter. After adding, renaming, or removing skills (or skill memory):

```bash
bash .ai/build_indexes.sh
```

Commit the regenerated index files alongside your changes.

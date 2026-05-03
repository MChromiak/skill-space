# Agents

## Before starting any task

Before acting on any request, identify missing or vague information and ask clarifying questions first. Do not begin the actual task until ambiguities are resolved.

Ask only about what is genuinely unclear and would change your approach — do not ask for information you can reasonably infer from context.

## Discovery: skills and memory

Before doing the task, consult these layers in order. Each layer uses the same INDEX-driven flow.

| # | Layer | Index file |
|---|---|---|
| 1 | Skills | `.ai/skills/SKILLS_INDEX.md` |
| 2 | Global memory | `.ai/global_memory/GLOBAL_MEMORY_INDEX.md` |
| 3 | Skill-local memory *(per active skill)* | `.ai/skills/<active-skill>/memory/MEMORY_INDEX.md` |

**For each layer that exists:**

1. Read its index file — a flat list grouped into `Always` and `On-demand` sections.
2. Load every entry under `Always` unconditionally.
3. Under `On-demand`, load only entries whose description is relevant to the current task.

A skill becomes **active** when loaded in step 1 of layer 1. Layer 3 then runs once per active skill.

If a layer's index file is missing or has no relevant entries, skip that layer. All layers are optional.

## Skill structure (optional subfolders)

A skill in `.ai/skills/<skill>/` may optionally contain:

- `memory/` — skill-local reference files with their own `MEMORY_INDEX.md`
- `scripts/` — helper scripts the skill can invoke

Neither is mandatory. Many skills are a single `<skill>.md` file with no folder.

---

> Add project-specific guidance below this line.

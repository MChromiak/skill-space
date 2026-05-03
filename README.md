# skill-space 🧠
> TODO: REplace with a dedicated plugin for ClaudeCode

> A portable preset of AI agent skills, prompts, and configuration — installs into any project in seconds with zero git footprint.

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Shell](https://img.shields.io/badge/shell-bash_4%2B-4EAA25?logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![AI Tools](https://img.shields.io/badge/works%20with-Claude%20%7C%20Copilot%20%7C%20Agents-blue)

---

## What it is

skill-space is a personal toolbox for AI-assisted development. It stores shared skills and agent definitions for Claude Code, GitHub Copilot, and other AI coding assistants in one versioned place.

When starting a new project: clone this repo and run the onboard script. It copies the relevant files into the standard locations each tool expects, adds them to `.gitignore`, and optionally removes itself — leaving **no trace in your project's git history**.

---

## 📁 Structure

```
skill-space/
└── .ai/
    ├── agents/                  # agent definition files
    ├── skills/                  # shared skills (single-file or bundle)
    │   ├── SKILLS_README.md     # skill format & frontmatter spec
    │   ├── SKILLS_INDEX.md      # auto-generated skill index
    │   └── <skill-name>/        # bundle skills (folder)
    │       ├── <skill-name>.md  # skill definition (must match folder name)
    │       ├── memory/          # (optional) skill-local memory + MEMORY_INDEX.md
    │       └── scripts/         # (optional) skill helper scripts
    ├── global_memory/           # project-scope reference memory
    │   ├── GLOBAL_MEMORY.md            # memory format & frontmatter spec
    │   └── GLOBAL_MEMORY_INDEX.md      # auto-generated memory index
    ├── .claude/                 # Claude Code specific config
    ├── .copilot/                # GitHub Copilot specific config
    ├── AGENTS.md                # base agent instructions template
    ├── CLAUDE.md                # base Claude Code instructions template
    ├── DESIGN.md                # base design system template (Google DESIGN.md spec)
    ├── build_indexes.sh         # regenerates all index files from frontmatter
    └── onboard_to_project.sh   # interactive install / uninstall script
```

---

## 🚀 Getting started

Clone skill-space into your project directory and run the script:

```bash
cd my-project
git clone https://github.com/MChromiak/skill-space.git
bash skill-space/.ai/onboard_to_project.sh
```

The interactive script guides you through three steps:

1. **Mode** — Setup or Clear
2. **Checklist** — pick exactly which items to install
3. **Cleanup** — optionally remove skill-space from the project when done

---

## 📦 What gets installed

| Item | Installed to | Purpose |
|---|---|---|
| `agents/` + `skills/` | `.github/` | GitHub Copilot discovery |
| `skills/` | `.agents/` | generic agent skill path |
| `agents/` + `skills/` | `.copilot/` | Copilot workspace config |
| `AGENTS.md` | project root | base agent instructions |
| `CLAUDE.md` | project root | Claude Code instructions |
| `DESIGN.md` | project root | brand & design system (Google DESIGN.md spec) |

> All installed items are automatically added to `.gitignore` — invisible to your project's git and your teammates.

---

## 🧠 Skills and memory

skill-space uses three discovery layers, all driven by auto-generated index files:

| # | Layer | Index | Active when |
|---|---|---|---|
| 1 | Skills | `.ai/skills/SKILLS_INDEX.md` | every task — agents pick relevant skills here |
| 2 | Global memory | `.ai/global_memory/GLOBAL_MEMORY_INDEX.md` | every task |
| 3 | Skill-local memory | `.ai/skills/<active-skill>/memory/MEMORY_INDEX.md` | active skill has memory |

Each entry has `scope: always` (loaded unconditionally) or `scope: on-demand` (loaded only if its description matches the task). The frontmatter-based filter is cheap, and the index keeps agents from opening every file.

Format references:
- Skills — [.ai/skills/SKILLS_README.md](.ai/skills/SKILLS_README.md)
- Memory — [.ai/global_memory/GLOBAL_MEMORY.md](.ai/global_memory/GLOBAL_MEMORY.md)

### Regenerating indexes

After adding, renaming, or removing any skill or memory file:

```bash
bash .ai/build_indexes.sh
```

This rewrites every index file (`SKILLS_INDEX.md`, `GLOBAL_MEMORY_INDEX.md`, and any per-skill `MEMORY_INDEX.md`) from frontmatter, so they can't drift out of sync.

A pre-commit hook ([.githooks/pre-commit](.githooks/pre-commit)) does this automatically — enable it once after cloning skill-space:

```bash
git config core.hooksPath .githooks
```

After that, any commit that touches `.ai/global_memory/` or `.ai/skills/` regenerates the affected index files and stages them into the same commit.

---

## 🧹 Clearing installed files

Re-clone skill-space and run the script in Clear mode:

```bash
bash skill-space/.ai/onboard_to_project.sh
# → select: Clear
```

The script removes only what it installed and strips the corresponding `.gitignore` entries.

---

## ⚙️ Requirements

- bash 4+
- macOS or Linux
- Any modern terminal with `tput` support

---

## License

MIT © [Michał Chromiak](https://github.com/MChromiak)

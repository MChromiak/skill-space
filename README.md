# skill-space 🧠

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
    ├── skills/                  # shared skill & prompt files
    ├── .claude/                 # Claude Code specific config
    ├── .copilot/                # GitHub Copilot specific config
    ├── AGENTS.md                # base agent instructions template
    ├── CLAUDE.md                # base Claude Code instructions template
    ├── DESIGN.md                # base design system template (Google DESIGN.md spec)
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

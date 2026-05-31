#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Auto-detect install target:
#   - parent project, if skill-space is nested inside another git repo
#   - skill-space itself, otherwise (self-onboard)
PARENT="$(cd "$SKILL_SPACE_DIR/.." 2>/dev/null && pwd || echo "")"
PARENT_GIT=""
if [ -n "$PARENT" ]; then
  PARENT_GIT=$(git -C "$PARENT" rev-parse --show-toplevel 2>/dev/null || echo "")
fi
if [ -n "$PARENT_GIT" ] && [ "$PARENT_GIT" != "$SKILL_SPACE_DIR" ]; then
  REPO_ROOT="$PARENT"
  INSTALL_MODE_LABEL="consumer install — target: $(basename "$REPO_ROOT")/"
else
  REPO_ROOT="$SKILL_SPACE_DIR"
  INSTALL_MODE_LABEL="self-install — target: skill-space itself"
fi

# ---------------------------------------------------------------------------
# Terminal helpers
# ---------------------------------------------------------------------------
read_key() {
  local key
  IFS= read -rsn1 key
  if [[ "$key" == $'\x1b' ]]; then
    IFS= read -rsn2 -t 0.05 key
    echo "esc$key"
  else
    echo "$key"
  fi
}

# ---------------------------------------------------------------------------
# Mode picker
# ---------------------------------------------------------------------------
MODE_LABELS=(
  "Setup    — create .skill-space/ + symlinks at standard tool paths"
  "Refresh  — sync .skill-space/ from .ai/ (preserves local additions)"
  "Clear    — remove .skill-space/ and symlinks"
)
MODE_SEL=0

pick_mode() {
  local count=${#MODE_LABELS[@]}
  draw() {
    tput clear
    echo "skill-space: $INSTALL_MODE_LABEL"
    echo ""
    echo "  What do you want to do?"
    echo "  [↑↓ move · Enter confirm]"
    echo ""
    for i in "${!MODE_LABELS[@]}"; do
      if [ "$i" -eq "$MODE_SEL" ]; then
        echo "  > ${MODE_LABELS[$i]}"
      else
        echo "    ${MODE_LABELS[$i]}"
      fi
    done
    echo ""
  }
  tput smcup 2>/dev/null || true
  while true; do
    draw
    key=$(read_key)
    case "$key" in
      "esc[A"|"esc0A") MODE_SEL=$(( (MODE_SEL - 1 + count) % count )) ;;
      "esc[B"|"esc0B") MODE_SEL=$(( (MODE_SEL + 1) % count )) ;;
      "") break ;;
    esac
  done
  tput rmcup 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Checklist (multi-select)
# ---------------------------------------------------------------------------
LABELS=()
SELECTED=()

run_checklist() {
  local title="$1"; shift
  local defaults="$1"; shift  # e.g. "110000" — 1=on, 0=off per position
  LABELS=("$@")
  SELECTED=()
  local count=${#LABELS[@]}
  for (( i=0; i<count; i++ )); do
    local d="${defaults:$i:1}"
    SELECTED+=( "${d:-1}" )
  done
  local cursor=0

  draw() {
    tput clear
    echo "skill-space: $INSTALL_MODE_LABEL"
    echo ""
    echo "  $title"
    echo "  [↑↓ move · Space toggle · Enter confirm]"
    echo ""
    for i in "${!LABELS[@]}"; do
      local box="[ ]"
      [ "${SELECTED[$i]}" -eq 1 ] && box="[x]"
      if [ "$i" -eq "$cursor" ]; then
        echo "  > $box  ${LABELS[$i]}"
      else
        echo "    $box  ${LABELS[$i]}"
      fi
    done
    echo ""
  }
  tput smcup 2>/dev/null || true
  while true; do
    draw
    key=$(read_key)
    case "$key" in
      "esc[A"|"esc0A") cursor=$(( (cursor - 1 + count) % count )) ;;
      "esc[B"|"esc0B") cursor=$(( (cursor + 1) % count )) ;;
      " ") SELECTED[$cursor]=$(( 1 - SELECTED[$cursor] )) ;;
      "") break ;;
    esac
  done
  tput rmcup 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Filesystem helpers
# ---------------------------------------------------------------------------
gitignore_add() {
  local entry="$1"
  local gi="$REPO_ROOT/.gitignore"
  touch "$gi"
  if ! grep -qxF "$entry" "$gi"; then
    echo "$entry" >> "$gi"
    echo "  .gitignore: + $entry"
  fi
}

gitignore_remove() {
  local entry="$1"
  local gi="$REPO_ROOT/.gitignore"
  if [ -f "$gi" ] && grep -qxF "$entry" "$gi"; then
    grep -vxF "$entry" "$gi" > "$gi.tmp" && mv "$gi.tmp" "$gi"
    echo "  .gitignore: - $entry"
  fi
}

make_symlink() {
  local target="$1" link="$2"
  if [ -L "$link" ]; then
    local current; current=$(readlink "$link")
    if [ "$current" = "$target" ]; then
      echo "  ok      : $link → $target"
    else
      ln -sfn "$target" "$link"
      echo "  updated : $link → $target"
    fi
  elif [ -e "$link" ]; then
    echo "  skip    : $link (exists and is not a symlink)"
  else
    mkdir -p "$(dirname "$link")"
    ln -s "$target" "$link"
    echo "  created : $link → $target"
  fi
}

remove_symlink() {
  local link="$1"
  if [ -L "$link" ]; then
    rm "$link"
    echo "  removed : $link"
  elif [ -e "$link" ]; then
    echo "  skip    : $link (not a symlink, won't touch)"
  fi
}

rmdir_if_empty() {
  local dir="$1"
  if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
    rmdir "$dir"
  fi
}

# Install root-level instruction files + sync content folders to .skill-space/.
#
# Root files (real files at REPO_ROOT, gitignored):
#   - AGENTS.md   = copy of .ai/AGENTS.md (canonical instructions)
#   - CLAUDE.md   = symlink → AGENTS.md   (so reading CLAUDE.md = reading AGENTS.md)
#   - DESIGN.md   = installed only if user opted in (handled separately in Setup)
#
# .skill-space/ contains ONLY content folders (skills/, global_memory/, agents/,
# .claude/, .copilot/). The root MD files don't go inside .skill-space/ — that
# would duplicate instructions in two places.
#
# Framework scripts (build_indexes.sh, onboard_to_project.sh) are skipped — they
# operate on .ai/ in the skill-space repo and aren't agent-consumable content.
#
# Refresh-safe: does NOT delete files or dirs in .skill-space/ that don't exist
# in .ai/. Those are the user's local additions.
sync_from_ai() {
  local src="$SCRIPT_DIR"
  local dst="$REPO_ROOT/.skill-space"

  # === Root instructions ===
  cp "$src/AGENTS.md" "$REPO_ROOT/AGENTS.md"
  ln -sfn AGENTS.md "$REPO_ROOT/CLAUDE.md"
  echo "  installed: AGENTS.md (real file, gitignored)"
  echo "  installed: CLAUDE.md → AGENTS.md (symlink, gitignored)"

  # === Content folders to .skill-space/ ===
  mkdir -p "$dst"
  # Pass 1: replicate directory structure
  (cd "$src" && find . -type d) | while IFS= read -r rel; do
    [ "$rel" = "." ] && continue
    mkdir -p "$dst/${rel#./}"
  done
  # Pass 2: copy files, excluding scripts AND root-MD files (the latter go to REPO_ROOT)
  (cd "$src" && find . -type f) | while IFS= read -r rel; do
    case "$rel" in
      ./build_indexes.sh|./onboard_to_project.sh) continue ;;
      ./AGENTS.md|./CLAUDE.md|./DESIGN.md) continue ;;
    esac
    local rel_clean="${rel#./}"
    cp "$src/$rel_clean" "$dst/$rel_clean"
  done
  echo "  synced   : .skill-space/ ← .ai/  (content folders only; local additions preserved)"
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
pick_mode

case "$MODE_SEL" in
  # ===== Setup =============================================================
  0)
    run_checklist "Optional additions (CLAUDE.md + AGENTS.md at root are always installed):" \
      "0000" \
      "root: DESIGN.md (Google design system spec)" \
      ".github/  symlinks (Copilot / GitHub agents)" \
      ".copilot/ symlinks (Copilot workspace)" \
      ".agents/  symlinks (generic agent tools)"

    echo ""
    echo "Target: $REPO_ROOT"
    echo ""

    sync_from_ai
    gitignore_add ".skill-space/"
    gitignore_add "CLAUDE.md"
    gitignore_add "AGENTS.md"

    if [ "${SELECTED[0]}" -eq 1 ]; then
      cp "$SCRIPT_DIR/DESIGN.md" "$REPO_ROOT/DESIGN.md"
      echo "  installed: DESIGN.md (real file, gitignored)"
      gitignore_add "DESIGN.md"
    fi
    if [ "${SELECTED[1]}" -eq 1 ]; then
      mkdir -p "$REPO_ROOT/.github"
      make_symlink "../.skill-space/agents" "$REPO_ROOT/.github/agents"
      make_symlink "../.skill-space/skills" "$REPO_ROOT/.github/skills"
      gitignore_add ".github/agents"
      gitignore_add ".github/skills"
    fi
    if [ "${SELECTED[2]}" -eq 1 ]; then
      mkdir -p "$REPO_ROOT/.copilot"
      make_symlink "../.skill-space/agents" "$REPO_ROOT/.copilot/agents"
      make_symlink "../.skill-space/skills" "$REPO_ROOT/.copilot/skills"
      gitignore_add ".copilot/agents"
      gitignore_add ".copilot/skills"
    fi
    if [ "${SELECTED[3]}" -eq 1 ]; then
      mkdir -p "$REPO_ROOT/.agents"
      make_symlink "../.skill-space/skills" "$REPO_ROOT/.agents/skills"
      gitignore_add ".agents/skills"
    fi

    echo ""
    echo "Setup complete."
    ;;

  # ===== Refresh ===========================================================
  1)
    if [ ! -d "$REPO_ROOT/.skill-space" ] && [ ! -e "$REPO_ROOT/AGENTS.md" ]; then
      echo ""
      echo "  Nothing to refresh — neither .skill-space/ nor AGENTS.md exists."
      echo "  Run Setup first."
      exit 0
    fi
    echo ""
    echo "Target: $REPO_ROOT"
    echo ""
    sync_from_ai
    # If DESIGN.md exists at root, refresh it too
    if [ -f "$REPO_ROOT/DESIGN.md" ] || [ -L "$REPO_ROOT/DESIGN.md" ]; then
      cp "$SCRIPT_DIR/DESIGN.md" "$REPO_ROOT/DESIGN.md"
      echo "  refreshed: DESIGN.md"
    fi
    echo ""
    echo "Refresh complete. Local additions in .skill-space/ were not touched."
    ;;

  # ===== Clear =============================================================
  2)
    run_checklist "Select what to remove:" \
      "111111" \
      ".skill-space/  (the central content folder)" \
      "root: CLAUDE.md (symlink) + AGENTS.md (real file)" \
      "root: DESIGN.md" \
      ".github/  symlinks" \
      ".copilot/ symlinks" \
      ".agents/  symlinks"

    echo ""
    printf "  Remove selected items from $(basename "$REPO_ROOT")/? Type 'yes' to confirm: "
    IFS= read -r confirm </dev/tty
    if [[ "$confirm" != "yes" ]]; then
      echo "  Cancelled."
      exit 0
    fi

    echo ""
    if [ "${SELECTED[0]}" -eq 1 ] && [ -d "$REPO_ROOT/.skill-space" ]; then
      rm -rf "$REPO_ROOT/.skill-space"
      echo "  removed : $REPO_ROOT/.skill-space/"
      gitignore_remove ".skill-space/"
    fi
    if [ "${SELECTED[1]}" -eq 1 ]; then
      # CLAUDE.md is a symlink, AGENTS.md is a real file
      remove_symlink "$REPO_ROOT/CLAUDE.md"
      gitignore_remove "CLAUDE.md"
      if [ -f "$REPO_ROOT/AGENTS.md" ] && [ ! -L "$REPO_ROOT/AGENTS.md" ]; then
        rm "$REPO_ROOT/AGENTS.md"
        echo "  removed : $REPO_ROOT/AGENTS.md"
      else
        remove_symlink "$REPO_ROOT/AGENTS.md"
      fi
      gitignore_remove "AGENTS.md"
    fi
    if [ "${SELECTED[2]}" -eq 1 ]; then
      if [ -f "$REPO_ROOT/DESIGN.md" ] && [ ! -L "$REPO_ROOT/DESIGN.md" ]; then
        rm "$REPO_ROOT/DESIGN.md"
        echo "  removed : $REPO_ROOT/DESIGN.md"
      else
        remove_symlink "$REPO_ROOT/DESIGN.md"
      fi
      gitignore_remove "DESIGN.md"
    fi
    if [ "${SELECTED[3]}" -eq 1 ]; then
      remove_symlink "$REPO_ROOT/.github/agents"; gitignore_remove ".github/agents"
      remove_symlink "$REPO_ROOT/.github/skills"; gitignore_remove ".github/skills"
      rmdir_if_empty "$REPO_ROOT/.github"
    fi
    if [ "${SELECTED[4]}" -eq 1 ]; then
      remove_symlink "$REPO_ROOT/.copilot/agents"; gitignore_remove ".copilot/agents"
      remove_symlink "$REPO_ROOT/.copilot/skills"; gitignore_remove ".copilot/skills"
      rmdir_if_empty "$REPO_ROOT/.copilot"
    fi
    if [ "${SELECTED[5]}" -eq 1 ]; then
      remove_symlink "$REPO_ROOT/.agents/skills"; gitignore_remove ".agents/skills"
      rmdir_if_empty "$REPO_ROOT/.agents"
    fi
    echo ""
    echo "Clear complete."
    ;;
esac

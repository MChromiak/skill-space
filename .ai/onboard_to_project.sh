#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SKILL_SPACE_DIR/.." && pwd)"

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
# Mode picker  (single-select, no toggle)
# Sets global MODE_SEL
# ---------------------------------------------------------------------------
MODE_LABELS=("Setup  — copy files & add to .gitignore" "Clear  — remove copied files")
MODE_SEL=0

pick_mode() {
  local count=${#MODE_LABELS[@]}

  draw() {
    tput clear
    echo "Repo: $REPO_ROOT"
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
# Checklist  (multi-select)
# Populates global LABELS and SELECTED arrays
# ---------------------------------------------------------------------------
LABELS=()
SELECTED=()

run_checklist() {
  local title="$1"; shift
  LABELS=("$@")
  SELECTED=()
  local count=${#LABELS[@]}
  for (( i=0; i<count; i++ )); do SELECTED+=( 1 ); done
  local cursor=0

  draw() {
    tput clear
    echo "Repo: $REPO_ROOT"
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
# Helpers
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

copy_item() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    echo "  exists : $dst"
  else
    cp -r "$src" "$dst"
    echo "  copied : $dst"
  fi
}

remove_item() {
  local path="$1"
  if [ -e "$path" ]; then
    rm -rf "$path"
    echo "  removed: $path"
  else
    echo "  absent : $path"
  fi
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
pick_mode

if [ "$MODE_SEL" -eq 0 ]; then
  # ----- Setup ---------------------------------------------------------------
  run_checklist "Select items to install:" \
    ".github/agents + .github/skills" \
    ".agents/skills" \
    ".copilot/agents + .copilot/skills" \
    "AGENTS.md" \
    "CLAUDE.md"

  echo ""
  echo "Repo: $REPO_ROOT"
  echo ""

  if [ "${SELECTED[0]}" -eq 1 ]; then
    echo ".github/"
    mkdir -p "$REPO_ROOT/.github"
    copy_item "$SCRIPT_DIR/agents" "$REPO_ROOT/.github/agents"
    copy_item "$SCRIPT_DIR/skills" "$REPO_ROOT/.github/skills"
    gitignore_add ".github/agents"
    gitignore_add ".github/skills"
  fi

  if [ "${SELECTED[1]}" -eq 1 ]; then
    echo ".agents/"
    mkdir -p "$REPO_ROOT/.agents"
    copy_item "$SCRIPT_DIR/skills" "$REPO_ROOT/.agents/skills"
    gitignore_add ".agents/"
  fi

  if [ "${SELECTED[2]}" -eq 1 ]; then
    echo ".copilot/"
    mkdir -p "$REPO_ROOT/.copilot"
    copy_item "$SCRIPT_DIR/agents" "$REPO_ROOT/.copilot/agents"
    copy_item "$SCRIPT_DIR/skills" "$REPO_ROOT/.copilot/skills"
    gitignore_add ".copilot/"
  fi

  if [ "${SELECTED[3]}" -eq 1 ]; then
    echo "AGENTS.md"
    copy_item "$SCRIPT_DIR/AGENTS.md" "$REPO_ROOT/AGENTS.md"
    gitignore_add "AGENTS.md"
  fi

  if [ "${SELECTED[4]}" -eq 1 ]; then
    echo "CLAUDE.md"
    copy_item "$SCRIPT_DIR/CLAUDE.md" "$REPO_ROOT/CLAUDE.md"
    gitignore_add "CLAUDE.md"
  fi

  echo ""
  printf "  Remove skill-space from this repo? [y/N] "
  IFS= read -r answer </dev/tty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    printf "  Are you sure? Type 'yes' to confirm: "
    IFS= read -r confirm </dev/tty
    if [[ "$confirm" == "yes" ]]; then
      echo "  Removing $(basename "$SKILL_SPACE_DIR")/ ..."
      rm -rf "$SKILL_SPACE_DIR"
    else
      echo "  Cancelled — keeping skill-space"
    fi
  else
    echo "  Keeping skill-space"
  fi

else
  # ----- Clear ---------------------------------------------------------------
  run_checklist "Select items to remove:" \
    ".github/agents + .github/skills" \
    ".agents/skills" \
    ".copilot/agents + .copilot/skills" \
    "AGENTS.md" \
    "CLAUDE.md"

  echo ""
  printf "  Remove selected files from $(basename "$REPO_ROOT")/ ? Type 'yes' to confirm: "
  IFS= read -r confirm </dev/tty
  if [[ "$confirm" != "yes" ]]; then
    echo "  Cancelled."
    exit 0
  fi

  echo ""
  echo "Repo: $REPO_ROOT"
  echo ""

  if [ "${SELECTED[0]}" -eq 1 ]; then
    echo ".github/"
    remove_item "$REPO_ROOT/.github/agents"
    remove_item "$REPO_ROOT/.github/skills"
    gitignore_remove ".github/agents"
    gitignore_remove ".github/skills"
  fi

  if [ "${SELECTED[1]}" -eq 1 ]; then
    echo ".agents/"
    remove_item "$REPO_ROOT/.agents"
    gitignore_remove ".agents/"
  fi

  if [ "${SELECTED[2]}" -eq 1 ]; then
    echo ".copilot/"
    remove_item "$REPO_ROOT/.copilot"
    gitignore_remove ".copilot/"
  fi

  if [ "${SELECTED[3]}" -eq 1 ]; then
    echo "AGENTS.md"
    remove_item "$REPO_ROOT/AGENTS.md"
    gitignore_remove "AGENTS.md"
  fi

  if [ "${SELECTED[4]}" -eq 1 ]; then
    echo "CLAUDE.md"
    remove_item "$REPO_ROOT/CLAUDE.md"
    gitignore_remove "CLAUDE.md"
  fi
fi

echo ""
echo "done."

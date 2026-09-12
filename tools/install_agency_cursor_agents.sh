#!/usr/bin/env bash
#
# install_agency_cursor_agents.sh
#
# Convert msitarzewski/agency-agents definitions into Cursor-native subagents
# (YAML frontmatter with name + description) and install them for immediate use.
# Project core voices are Cason's personal Grok fleet (PERSONAL_FLEET_MAP.md).
# New slugs not in upstream agency-agents are generated from fleet profiles.
#
# Default:
#   - Full roster  → ~/.cursor/agents/          (user-wide Subagents UI)
#   - Core team    → <repo>/.cursor/agents/     (project-scoped, personal fleet)
#   - Manifest     → <repo>/agency-team/
#
# Usage:
#   ./tools/install_agency_cursor_agents.sh
#   AGENCY_AGENTS_ROOT=~/Development/agency-agents ./tools/install_agency_cursor_agents.sh
#   ./tools/install_agency_cursor_agents.sh --dry-run
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENCY_ROOT="${AGENCY_AGENTS_ROOT:-$HOME/Development/agency-agents}"
USER_AGENTS_DIR="${CURSOR_AGENTS_DIR:-$HOME/.cursor/agents}"
PROJECT_AGENTS_DIR="${PROJECT_AGENTS_DIR:-$REPO_ROOT/.cursor/agents}"
TEAM_DIR="${TEAM_DIR:-$REPO_ROOT/agency-team}"
DRY_RUN=0

DIVISIONS=(
  academic design engineering finance game-development gis marketing paid-media
  product project-management sales security spatial-computing specialized support testing
)

# High-value ChatDev / DevAll core roster (entry = agents-orchestrator)
# Voices are Cason's personal Grok fleet — see agency-team/PERSONAL_FLEET_MAP.md
CORE_SLUGS=(
  agents-orchestrator
  product-manager
  senior-project-manager
  project-shepherd
  software-architect
  ux-architect
  frontend-developer
  backend-architect
  prompt-engineer
  workflow-architect
  api-tester
  reality-checker
  devops-automator
  code-reviewer
  multi-agent-systems-architect
  ai-engineer
  technical-writer
  evidence-collector
  accessibility-auditor
  git-workflow-master
  tradbot
  home-assistant-master
  credit-card-max
  signal
)

# Not in upstream agency-agents; generated from fleet profiles if source missing
PERSONAL_FLEET_ONLY_SLUGS=(
  tradbot
  home-assistant-master
  credit-card-max
  signal
)

usage() {
  sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -d "$AGENCY_ROOT" ]]; then
  echo "ERROR: agency-agents not found at $AGENCY_ROOT" >&2
  echo "Clone https://github.com/msitarzewski/agency-agents or set AGENCY_AGENTS_ROOT." >&2
  exit 1
fi

# shellcheck source=/dev/null
. "$AGENCY_ROOT/scripts/lib.sh"

write_cursor_agent() {
  local src="$1" dest_dir="$2"
  local name description slug body outfile

  is_agent_file "$src" || return 1
  name="$(get_field name "$src")"
  description="$(get_field description "$src")"
  [[ -n "$name" && -n "$description" ]] || return 1
  slug="$(slugify "$name")"
  body="$(get_body "$src")"
  outfile="$dest_dir/${slug}.md"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'DRY would write %s\n' "$outfile"
    return 0
  fi

  mkdir -p "$dest_dir"
  # Cursor native subagent: name must be lowercase-hyphen slug
  cat > "$outfile" <<EOF
---
name: ${slug}
description: ${description}
---

${body}
EOF
  printf '%s\t%s\t%s\n' "$slug" "$name" "$(basename "$(dirname "$src")")"
}

is_personal_fleet_only() {
  local slug="$1" s
  for s in "${PERSONAL_FLEET_ONLY_SLUGS[@]}"; do
    [[ "$s" == "$slug" ]] && return 0
  done
  return 1
}

write_personal_fleet_agent() {
  local slug="$1" dest="$2"
  local profile="$TEAM_DIR/personal-fleet/${slug}.md"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$profile" ]]; then
    cp "$profile" "$dest"
    return 0
  fi
  cat > "$dest" <<EOF
---
name: ${slug}
description: Personal Grok fleet specialist (${slug}).
---

You are ${slug} on Cason Clark's personal Grok fleet.
Prefer Signal for non-urgent noise. Never empty status theater.
See agency-team/PERSONAL_FLEET_MAP.md.
EOF
}

header() { printf '\n==> %s\n' "$*"; }

header "Installing full Agency roster → $USER_AGENTS_DIR"
mkdir -p "$USER_AGENTS_DIR" "$TEAM_DIR"
CATALOG="$TEAM_DIR/CATALOG.tsv"
: > "$CATALOG"
printf 'slug\tdisplay_name\tdivision\n' > "$CATALOG"

total=0
for div in "${DIVISIONS[@]}"; do
  dir="$AGENCY_ROOT/$div"
  [[ -d "$dir" ]] || continue
  while IFS= read -r -d '' file; do
    line="$(write_cursor_agent "$file" "$USER_AGENTS_DIR" || true)"
    if [[ -n "${line:-}" && "$DRY_RUN" -eq 0 ]]; then
      printf '%s\n' "$line" >> "$CATALOG"
      incr total
    elif [[ "$DRY_RUN" -eq 1 && -n "${line:-}" ]]; then
      incr total
    fi
  done < <(find "$dir" -type f -name '*.md' -print0 | sort -z)
done

header "Installed $total user-level agents"

header "Activating core team → $PROJECT_AGENTS_DIR"
mkdir -p "$PROJECT_AGENTS_DIR"
core_ok=0
core_missing=()
for slug in "${CORE_SLUGS[@]}"; do
  src="$USER_AGENTS_DIR/${slug}.md"
  dest="$PROJECT_AGENTS_DIR/${slug}.md"
  # Keep committed personal-fleet remaps; do not overwrite with stock agency-agents.
  if [[ -f "$dest" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'DRY would keep existing core %s\n' "$slug"
    fi
    incr core_ok
    continue
  fi
  if [[ -f "$src" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'DRY would copy core %s\n' "$slug"
    else
      cp "$src" "$dest"
    fi
    incr core_ok
    continue
  fi
  if is_personal_fleet_only "$slug"; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'DRY would generate personal-fleet core %s\n' "$slug"
    else
      write_personal_fleet_agent "$slug" "$dest"
      printf 'generated personal-fleet core %s\n' "$slug"
    fi
    incr core_ok
    continue
  fi
  core_missing+=("$slug")
done

header "Writing team manifest + topology → $TEAM_DIR"
if [[ "$DRY_RUN" -eq 0 ]]; then
  {
    echo "# ChatDev / DevAll core Agency team (Cursor subagents)"
    echo "# Entry / orchestrator: agents-orchestrator"
    echo "# Names match .cursor/agents/<slug>.md and ~/.cursor/agents/<slug>.md"
    echo "# Personal Grok fleet remap — see agency-team/PERSONAL_FLEET_MAP.md"
    echo
    for slug in "${CORE_SLUGS[@]}"; do
      printf '%s\n' "$slug"
    done
  } > "$TEAM_DIR/CORE_TEAM.txt"

  # TEAM.md / HANDOFFS.md / PERSONAL_FLEET_MAP.md are committed fleet docs — do not overwrite.

  for slug in "${PERSONAL_FLEET_ONLY_SLUGS[@]}"; do
    if ! grep -q "^${slug}"$'\t' "$CATALOG" 2>/dev/null; then
      printf '%s\t%s\t%s\n' "$slug" "$slug" "personal-fleet" >> "$CATALOG"
    fi
  done

  # Available-but-not-core listing
  {
    echo "# Full catalog (available in ~/.cursor/agents)"
    echo "# Core team marked with [CORE]"
    echo
    while IFS=$'\t' read -r slug display division; do
      [[ "$slug" == "slug" ]] && continue
      mark=""
      for c in "${CORE_SLUGS[@]}"; do
        [[ "$c" == "$slug" ]] && mark=" [CORE]" && break
      done
      printf -- '- %s (%s / %s)%s\n' "$slug" "$display" "$division" "$mark"
    done < "$CATALOG"
  } > "$TEAM_DIR/AVAILABLE_AGENTS.md"

  overlay="$TEAM_DIR/ORCHESTRATOR_OVERLAY.md"
  orch="$PROJECT_AGENTS_DIR/agents-orchestrator.md"
  if [[ -f "$overlay" && -f "$orch" ]]; then
    python3 - "$orch" "$overlay" <<'PY'
from pathlib import Path
import sys

orch = Path(sys.argv[1])
overlay = Path(sys.argv[2]).read_text()
text = orch.read_text()
start = "<!-- CHATDEV_CORE_TEAM_OVERLAY -->"
end = "<!-- /CHATDEV_CORE_TEAM_OVERLAY -->"
if start in text:
    text = text.split(start)[0].rstrip() + "\n"
orch.write_text(text.rstrip() + "\n\n" + overlay.lstrip())
PY
  fi
fi

header "Validation"
user_count="$(find "$USER_AGENTS_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
proj_count="$(find "$PROJECT_AGENTS_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
echo "User agents:    $user_count  ($USER_AGENTS_DIR)"
echo "Project core:   $proj_count  ($PROJECT_AGENTS_DIR)"
echo "Core installed: $core_ok / ${#CORE_SLUGS[@]}"
if [[ ${#core_missing[@]} -gt 0 ]]; then
  echo "MISSING core slugs: ${core_missing[*]}" >&2
  exit 1
fi

# Smoke-check frontmatter on a few files
for slug in agents-orchestrator frontend-developer api-tester evidence-collector tradbot signal; do
  f="$PROJECT_AGENTS_DIR/${slug}.md"
  head -1 "$f" | grep -q '^---$' || { echo "bad frontmatter: $f" >&2; exit 1; }
  grep -q "^name: ${slug}$" "$f" || { echo "bad name field: $f" >&2; exit 1; }
  grep -q '^description: ' "$f" || { echo "bad description: $f" >&2; exit 1; }
done

echo "OK — Agency Cursor team ready."

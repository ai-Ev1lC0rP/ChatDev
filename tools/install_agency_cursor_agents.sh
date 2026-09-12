#!/usr/bin/env bash
#
# install_agency_cursor_agents.sh
#
# Convert msitarzewski/agency-agents definitions into Cursor-native subagents
# (YAML frontmatter with name + description) and install them for immediate use.
#
# Default:
#   - Full roster  → ~/.cursor/agents/          (user-wide Subagents UI)
#   - Core team    → <repo>/.cursor/agents/     (project-scoped, higher priority)
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
  if [[ ! -f "$src" ]]; then
    core_missing+=("$slug")
    continue
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'DRY would copy core %s\n' "$slug"
  else
    cp "$src" "$dest"
  fi
  incr core_ok
done

header "Writing team manifest + topology → $TEAM_DIR"
if [[ "$DRY_RUN" -eq 0 ]]; then
  {
    echo "# ChatDev / DevAll core Agency team (Cursor subagents)"
    echo "# Entry / orchestrator: agents-orchestrator"
    echo "# Names match .cursor/agents/<slug>.md and ~/.cursor/agents/<slug>.md"
    echo
    for slug in "${CORE_SLUGS[@]}"; do
      printf '%s\n' "$slug"
    done
  } > "$TEAM_DIR/CORE_TEAM.txt"

  cat > "$TEAM_DIR/TEAM.md" <<'EOF'
# Agency Team (Cursor-native)

Primary deliverable: **Cursor subagents** sourced from
[`agency-agents`](https://github.com/msitarzewski/agency-agents)
(`/Users/ev1lc0rp/Development/agency-agents` on this machine).

## Why Cursor-native (not Agency Swarm first)

Agency definitions are already Cursor-oriented (rules + personality markdown).
Cursor subagents (`.cursor/agents/*.md` / `~/.cursor/agents/*.md`) show up in
the Subagents UI and can be delegated via Task / `@agent` flows immediately.
Agency Swarm remains a follow-up if you want a Python runtime agency with tools.

## Install layout

| Location | Purpose |
|----------|---------|
| `~/.cursor/agents/*.md` | Full roster (~232 agents), user-wide |
| `.cursor/agents/*.md` | Core team (project, higher priority) |
| `agency-team/` | Topology, catalog, reinstall script docs |
| `yaml_instance/agency_core_team.yaml` | Web Console twin of the core pipeline |

Reinstall / refresh from source:

```bash
make install-agency-agents
```

## Team topology (CEO / orchestrator pattern)

```text
                    ┌─────────────────────────┐
                    │   agents-orchestrator   │  ← entry / pipeline lead
                    └───────────┬─────────────┘
            ┌───────────────────┼───────────────────┐
            ▼                   ▼                   ▼
   senior-project-manager   product-manager   project-shepherd
            │                   │                   │
            └─────────┬─────────┴─────────┬─────────┘
                      ▼                   ▼
              software-architect     ux-architect
                      │                   │
         ┌────────────┼────────────┐      │
         ▼            ▼            ▼      ▼
 frontend-dev   backend-arch   prompt-eng  workflow-architect
         │            │            │              │
         └────────────┴─────┬──────┴──────────────┘
                            ▼
         devops-automator / ai-engineer / git-workflow-master
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
         api-tester   evidence-collector  code-reviewer
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
     accessibility-auditor  technical-writer  reality-checker
```

Handoff table: `agency-team/HANDOFFS.md`. Orchestrator slug map is appended
from `agency-team/ORCHESTRATOR_OVERLAY.md` on each install.

### Communication flows (directional)

- **agents-orchestrator** → all core roles (can spawn / hand off)
- **senior-project-manager** → product-manager, project-shepherd, software-architect
- **product-manager** → software-architect, ux-architect, prompt-engineer, workflow-architect
- **software-architect** → frontend-developer, backend-architect, devops-automator, ai-engineer
- **frontend-developer / backend-architect** → api-tester, evidence-collector, code-reviewer
- **api-tester / evidence-collector / code-reviewer** → reality-checker (final gate)
- **multi-agent-systems-architect** — consult when the pipeline itself is the product
- Specialists report findings back to **agents-orchestrator**

## How to use

1. Open Cursor → Subagents (or Agent / Task picker).
2. Select a core agent (e.g. `agents-orchestrator`) or ask the main agent to
   delegate: “Use the agents-orchestrator subagent to run the pipeline for …”
3. Web Console: run workflow `agency_core_team` (`yaml_instance/agency_core_team.yaml`).
4. For one-off specialists outside the core set, pick from the full user-level
   roster in `~/.cursor/agents/` (see `CATALOG.tsv`).

## Official agency-agents Cursor rules (optional)

Upstream also installs `.mdc` rules via:

```bash
cd /path/to/ChatDev
~/Development/agency-agents/scripts/install.sh --tool cursor --no-interactive
```

Prefer native subagents for team orchestration; use rules only if you want
`@slug` rule mentions without Subagents isolation.

## Follow-up: Agency Swarm

Mirror roles under an `agency_swarm` agency folder later if you need tool-backed
Python agents (`BaseTool`, `agency.py`). Source lives at
`~/Development/agency-swarm`. Not required for IDE team use.

## What’s left / next enablements

- No API keys required for Cursor subagent prompts themselves.
- Web Console workflow needs onboarded `${BASE_URL}` / `${API_KEY}` / `${DEFAULT_MODEL}`.
- Optional: run upstream rules install if you want `@slug` rule mentions:
  `~/Development/agency-agents/scripts/install.sh --tool cursor --no-interactive`
- Refresh after upstream agency-agents pulls:
  `make install-agency-agents`
EOF

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
for slug in agents-orchestrator frontend-developer api-tester evidence-collector; do
  f="$PROJECT_AGENTS_DIR/${slug}.md"
  head -1 "$f" | grep -q '^---$' || { echo "bad frontmatter: $f" >&2; exit 1; }
  grep -q "^name: ${slug}$" "$f" || { echo "bad name field: $f" >&2; exit 1; }
  grep -q '^description: ' "$f" || { echo "bad description: $f" >&2; exit 1; }
done

echo "OK — Agency Cursor team ready."

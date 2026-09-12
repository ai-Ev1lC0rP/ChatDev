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

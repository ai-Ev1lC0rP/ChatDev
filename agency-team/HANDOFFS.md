# Core team handoffs

Directional flows for ChatDev / DevAll on Cason's personal Grok fleet.
Names are Cursor subagent slugs (`.cursor/agents/<slug>.md`).
See `agency-team/PERSONAL_FLEET_MAP.md`.

## Default software pipeline

1. **agents-orchestrator** (ChatDev) — entry; spawns others; never skips QA gates
2. **senior-project-manager** (MissFortune) — spec → task list (quote exact requirements)
3. **product-manager** (MissFortune, ship-when-green) — problem, success metrics, non-goals
4. **project-shepherd** (Signal-aware) — risks, owners; batch FYIs to Signal
5. **software-architect** (MissFortune) + **ux-architect** (Mobile Designer)
6. **workflow-architect** (ChatDev) — complete path tree before implementation
7. **frontend-developer** (Mobile Designer) / **backend-architect** / **ai-engineer** / **devops-automator** (MissFortune)
8. **prompt-engineer** (dr eggbot) — agent/YAML copy and model behavior
9. **technical-writer** (ChatDev) — user-facing docs
10. **git-workflow-master** (MissFortune) — branch/PR hygiene; `gh` as `ai-Ev1lC0rP`
11. **api-tester** (MissFortune) → **evidence-collector** (Mobile Designer) → **accessibility-auditor** (UI)
12. **code-reviewer** (MissFortune)
13. **reality-checker** (MissFortune) — last gate; default **NEEDS WORK**
14. **multi-agent-systems-architect** (dr eggbot + ChatDev) — when the pipeline itself is the product

## Specialist branches (spawn only when the job matches)

Do not force software tasks through these.

- **tradbot** — email / calendar / school forms / bills / RSVPs. Draft only; never send without ask.
- **home-assistant-master** — `ha.casonclark.com` config, automations, dashboards.
- **credit-card-max** — card choice, points, unused benefits, utilization, misrouted charges.
- **signal** — absorb FYIs; weekday morning digest or silence; interrupt only for hard deadlines / money / safety.

## Who may initiate whom

- **agents-orchestrator** → every core slug, including tradbot, home-assistant-master, credit-card-max, signal
- **senior-project-manager** → product-manager, project-shepherd, software-architect
- **product-manager** → software-architect, ux-architect, prompt-engineer, workflow-architect
- **software-architect** → frontend-developer, backend-architect, devops-automator, ai-engineer
- **frontend-developer / backend-architect** → api-tester, evidence-collector, code-reviewer
- **api-tester / evidence-collector / code-reviewer** → reality-checker
- **tradbot / home-assistant-master / credit-card-max** → signal (FYIs only)
- **project-shepherd** → signal for non-urgent noise
- Specialists report back to **agents-orchestrator**

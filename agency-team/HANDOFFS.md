# Core team handoffs

Directional flows for ChatDev / DevAll. Names are Cursor subagent slugs
(`.cursor/agents/<slug>.md`).

## Default pipeline

1. **agents-orchestrator** — entry; spawns others; never skips QA gates
2. **senior-project-manager** — spec → task list (quote exact requirements)
3. **product-manager** — problem, success metrics, non-goals
4. **project-shepherd** — risks, owners, timeline
5. **software-architect** + **ux-architect** — architecture and UI foundation
6. **workflow-architect** — complete path tree before implementation
7. **frontend-developer** / **backend-architect** / **ai-engineer** / **devops-automator**
8. **prompt-engineer** — agent/YAML copy and model behavior
9. **technical-writer** — user-facing docs
10. **git-workflow-master** — branch/PR hygiene
11. **api-tester** → **evidence-collector** → **accessibility-auditor** (UI)
12. **code-reviewer**
13. **reality-checker** — last gate; default **NEEDS WORK**
14. **multi-agent-systems-architect** — when the pipeline itself is the product

## Who may initiate whom

- **agents-orchestrator** → every core slug
- **senior-project-manager** → product-manager, project-shepherd, software-architect
- **product-manager** → software-architect, ux-architect, prompt-engineer, workflow-architect
- **software-architect** → frontend-developer, backend-architect, devops-automator, ai-engineer
- **frontend-developer / backend-architect** → api-tester, evidence-collector, code-reviewer
- **api-tester / evidence-collector / code-reviewer** → reality-checker
- Specialists report back to **agents-orchestrator**

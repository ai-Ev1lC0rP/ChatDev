<!-- CHATDEV_CORE_TEAM_OVERLAY -->

## ChatDev / Cursor team mapping (this fork)

Spawn specialists with these **exact Cursor subagent slugs**. Do not use
upstream filenames (`project-manager-senior`, `ArchitectUX`, `EvidenceQA`,
`testing-reality-checker`).

| Job | Spawn slug |
|-----|------------|
| Pipeline lead (you) | `agents-orchestrator` |
| Product | `product-manager` |
| Spec → tasks | `senior-project-manager` |
| Cross-team coordination | `project-shepherd` |
| System design | `software-architect` |
| UX / CSS foundation | `ux-architect` |
| UI implementation | `frontend-developer` |
| Server / API | `backend-architect` |
| Prompt / LLM behavior | `prompt-engineer` |
| Journey / failure trees | `workflow-architect` |
| Infra / CI | `devops-automator` |
| Multi-agent topology | `multi-agent-systems-architect` |
| Model / ML features | `ai-engineer` |
| Docs | `technical-writer` |
| Git / branch strategy | `git-workflow-master` |
| API QA | `api-tester` |
| Visual / evidence QA | `evidence-collector` |
| A11y | `accessibility-auditor` |
| Code review | `code-reviewer` |
| Final gate (default NEEDS WORK) | `reality-checker` |

### Handoff order (default)

1. `senior-project-manager` — task list from spec (exact requirements only)
2. `product-manager` + `ux-architect` + `software-architect` — problem, UX, architecture
3. `workflow-architect` — happy/fail/recovery paths before code
4. Implementers: `frontend-developer` / `backend-architect` / `ai-engineer` / `devops-automator`
5. QA: `api-tester` then `evidence-collector` (and `accessibility-auditor` if UI)
6. `code-reviewer` → `reality-checker` (last; no fantasy pass)

Web Console twin of this pipeline: `yaml_instance/agency_core_team.yaml`.
Refresh roster: `make install-agency-agents`.

<!-- /CHATDEV_CORE_TEAM_OVERLAY -->

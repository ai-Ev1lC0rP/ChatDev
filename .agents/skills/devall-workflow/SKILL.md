---
name: devall-workflow
description: Build, validate, and run ChatDev 2.0 (DevAll) YAML multi-agent workflows using project make targets and schema checks.
---

# DevAll Workflow Skill

Use this skill when creating or changing DevAll workflows, agents, or local run setup.

## Process

1. Prefer editing/creating YAML under `yaml_instance/` over custom Python when possible.
2. Use `${BASE_URL}` and `${API_KEY}` for model auth; never embed secrets.
3. After YAML changes, run `make validate-yamls`.
4. After upload/session/path changes, run `make check`.
5. For local runs: `make setup`, then `make onboard-models` (Ollama or OmniRoute), then `make dev`.
6. Sync upstream with `make sync-upstream` before large fork customizations.

## Constraints

- Do not resurrect ChatDev 1.0 `CompanyConfig` as the primary surface.
- Do not commit `.env`, `WareHouse/`, or IDE state.
- Keep security sanitization for filenames and session IDs intact.

# OmniRoute Model Onboarding — Design

**Date:** 2026-07-24  
**Status:** Approved for implementation (parent mission preferences)

## Problem

ChatDev configures LLMs only via manual `.env` edits (`BASE_URL` / `API_KEY`). New users have no guided “set up models” step. OmniRoute is an OpenAI-compatible local gateway that aggregates many providers behind one endpoint — a natural fit for ChatDev’s existing env-based provider pattern.

## What OmniRoute Is

[OmniRoute](https://github.com/diegosouzapw/OmniRoute) is a local-first AI gateway (npm / Docker). Default API: `http://localhost:20128/v1`. Dashboard for API keys and providers: `http://localhost:20128`. Clients point any OpenAI-compatible stack at `/v1` and use model `auto` (or a specific routed model).

## Fit Into ChatDev

```
ChatDev agents (YAML: base_url ${BASE_URL}, api_key ${API_KEY})
        │
        ▼
   OmniRoute :20128/v1   ← onboarding writes these env vars
        │
        ▼
   250 providers / free tiers / fallbacks
```

No rewrite of agent providers: ChatDev already speaks OpenAI-compatible HTTP via `BASE_URL` + `API_KEY`.

## Approach (chosen)

**Env + CLI onboarding step** (minimal, fits Makefile/`setup` flow):

1. `make setup` ensures deps + `.env`, then points users at model onboarding.
2. `make onboard-models` runs `tools/onboard_models.py` — interactive or `--provider omniroute --yes`.
3. Optional `make omniroute-up` / `omniroute-status` for Docker gateway lifecycle.
4. Optional Compose profile `omniroute` so Docker users can start the gateway with ChatDev.

### Alternatives considered

| Option | Pros | Cons |
|--------|------|------|
| A. Env + CLI onboarding (chosen) | Small diff; matches existing setup | No GUI wizard |
| B. Frontend Settings wizard | Visible in UI | Larger Vue surface; secrets still live in server `.env` |
| C. Vendor OmniRoute into repo | Always available | Heavy; Node 22+; maintenance burden |

## Components

| Piece | Role |
|-------|------|
| `tools/onboard_models.py` | Write/update `.env` model vars; probe OmniRoute; print next steps |
| `tools/omniroute_gateway.py` | Status / start helpers (Docker preferred) |
| Makefile targets | `onboard-models`, `omniroute-up`, `omniroute-down`, `omniroute-status` |
| `.env.example` | Document OmniRoute as recommended model path |
| `compose.yml` profile `omniroute` | Optional sidecar |

## Data / config

- `BASE_URL=http://localhost:20128/v1` (or host.docker.internal when ChatDev runs in Compose)
- `API_KEY=<OmniRoute dashboard key>` — placeholder until user pastes key
- Optional `DEFAULT_MODEL=auto` for documentation; YAML agent `model` fields remain authoritative

## Error handling

- Gateway down: print how to start (`make omniroute-up` or `npx -y omniroute`); still allow writing env
- Missing API key: write placeholder + dashboard URL; verify step skipped or reports unauthorized clearly
- Non-interactive without `--provider`: exit with usage

## Testing

- Unit tests for `.env` upsert and provider preset resolution (no live secrets)
- Optional live probe marked skip-unless OmniRoute reachable

## Out of scope

- Embedding OmniRoute source into ChatDev
- Changing every YAML demo to `model: auto`
- Committing real API keys

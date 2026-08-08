# OmniRoute Onboarding — Levels

**Date:** 2026-08-08  
**Status:** Spec (pacing over [2026-07-24 design](2026-07-24-omniroute-onboarding-design.md))  
**Fantasy:** Zero → gateway up → first agent call → multi-provider confidence.

## Arc

Tutorial → First success → Mastery: `[L1 Setup] → [L2 Gateway] → [L3 Key+Env] → [L4 First run] → [L5 Mastery]`

## Levels

### L1 — Tutorial: Boot the fork
**Feel:** Safe entry; no LLM yet.  
**Actions:** `make setup` → confirm `.env` from `.env.example`.  
**Exit:** Deps OK; `make onboard-models` / `make omniroute-*` runnable.  
**Fail soft:** Missing Docker/Node blocks L2 only.

### L2 — Gateway alive
**Feel:** “Something is listening.”  
**Actions:** `make omniroute-up` (alt: `docker compose --profile omniroute up -d` / `npx -y omniroute`).  
**Verify:** `make omniroute-status`; open `http://localhost:20128`.  
**Exit:** Health/models probe succeeds. Dashboard = landmark.

### L3 — First success: Key + env
**Feel:** ChatDev points at OmniRoute.  
**Actions:** Dashboard → **Endpoints** → create API key → `make onboard-models` (OmniRoute), or  
`make onboard-models ONBOARD_ARGS='--provider omniroute --api-key <key> --yes'`.  
**Verify:** `.env` has `BASE_URL=http://localhost:20128/v1`, real `API_KEY`, `MODEL_PROVIDER=omniroute`; re-status.  
**Exit:** Probe authorized (not placeholder). Never commit keys; YAML keeps `${BASE_URL}` / `${API_KEY}`.

### L4 — Apply: First agent run
**Feel:** End-to-end win.  
**Actions:** `make dev` → Web Console → small YAML using `${BASE_URL}` / `${API_KEY}` (`auto` or routed id).  
**Side path:** Ollama via `make onboard-models` if gateway blocked.  
**Exit:** One successful agent response in Console.

### L5 — Mastery (optional)
**Feel:** Operator, not tourist.  
**Actions:** Add providers in dashboard; `model: auto` or named routes; Compose sidecar (`BASE_URL=http://omniroute:20128/v1` when backend in Compose); `make omniroute-down`/`up`; `make check`.  
**Exit:** Restart gateway, add/swap provider, re-verify without re-reading L1–L3.

## Encounter beats

| ID | Level | Tension | Primary | Fallback |
|----|-------|---------|---------|----------|
| E1 | L1 | Low | `make setup` | Fix uv/Python |
| E2 | L2 | Med | `omniroute-up` + status | npx / Compose |
| E3 | L3 | Med | Dashboard key + onboard | Placeholder; retry `--api-key` |
| E4 | L4 | High | `make dev` + workflow | Ollama preset |
| E5 | L5 | High | Multi-provider + Compose | Stay on L4 |

## Readability

- Critical path: OmniRoute at every fork; Ollama is the labeled side path.
- CLI writes `.env`; each level ends with one verify (command or dashboard landmark).
- Proxied Console hosts are dress, not a new level — same L4 win.

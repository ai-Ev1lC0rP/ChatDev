# Product Brief: OmniRoute Onboarding “Works Well”

**Date:** 2026-08-08 · **Author:** PM (Alex) · **Status:** Definition of done  
**Branch context:** ChatDev 2.0 DevAll on `upstream-sync`; fork PRs #1–#3 vs `pr-base/devall-pre-omniroute`  
**Related:** [design](./2026-07-24-omniroute-onboarding-design.md) · [levels](./2026-08-08-omniroute-onboarding-levels.md) · [loop](./2026-08-08-omniroute-onboarding-loop.md)

## What “works well” means

A developer new to this fork reaches a **first successful Web Console agent reply** via OmniRoute without hand-editing YAML providers or committing secrets. One recommended path (`make onboard-models` + `omniroute-*`), honest probe feedback, and a clear next verb on every failure.

**One-liner:** Point ChatDev at OmniRoute in minutes — multi-provider routing behind the env vars agents already use.

## Primary user & journey

**Persona:** Local DevAll operator bootstrapping this fork (macOS/Linux, Docker available).

| Step | Intent | Exit signal |
|------|--------|-------------|
| 1. `make setup` | Boot fork | Deps + `.env`; onboard targets runnable |
| 2. `make omniroute-up` | Gateway alive | Status/dashboard on port 20128 |
| 3. Dashboard key → `make onboard-models` | ChatDev wired | OmniRoute `BASE_URL`, real key, `MODEL_PROVIDER=omniroute` |
| 4. Status / onboard probe | Trust the link | Reachable + authorized models (not placeholder “success”) |
| 5. `make dev` → YAML with `${BASE_URL}` / `${API_KEY}` | First win | One agent reply in Console (incl. proxied hosts) |

**Side path (labeled):** Ollama/other presets when gateway blocked.  
**Mastery (optional):** Swap providers in OmniRoute; Compose sidecar; restart without re-reading L1–L3.

## Success metrics

| Goal | Metric | Target | Window |
|------|--------|--------|--------|
| Time-to-wired | Setup → authorized OmniRoute probe | ≤ 5 min (Docker-ready) | Per session |
| First value | Setup → first Console agent reply | ≤ 15 min | Same session |
| Path clarity | OmniRoute is the default recommendation | 100% setup/docs/Make hooks | Ongoing |
| Honesty | No false “ready” on placeholder/unauthorized | Zero | Gate for “works well” |
| Recoverability | Failure prints one forward verb | 100% documented fail paths | Ongoing |
| Safety | No real keys in git / status pretty-print | Zero leaks | Continuous |
| Quality bar | Onboarding tests + `make check` | Green | Per change |

**North star:** first agent reply via OmniRoute — not green probe alone.

## Non-goals

- Frontend Settings wizard; vendoring OmniRoute; mass-rewriting YAML `model` fields  
- Dropping Ollama/direct presets; committing keys; treating stale `main` / ChatDev 1.0 as base  
- Unrelated fork DX unless it blocks the journey above  

## Priority gaps

### P0 — before claiming “works well”

1. **Single gateway identity** — Make helpers and Compose profile `omniroute` must observe the same instance (naming drift today).  
2. **Honest success signal** — Placeholder/unauthorized must not read ready; authorized models required.  
3. **Journey completeness** — Docs/Make path ends at first Console reply, not env write alone.  
4. **Secret hygiene** — No keys in commits, status output, or dirty pretty-print leftovers on `upstream-sync`.

### P1 — next

1. Optional hard-fail when a real key is set but probe still fails.  
2. Compose/backend-in-Docker `BASE_URL` guidance stays one-step discoverable.  
3. Align open PR #2 (onboarding) / #1 (path-safety) with merged #3; dirty TODOs ≠ done.  
4. Docker-missing path: clear Ollama/npx fallback without abandoning OmniRoute as default.

## Decision

**Ship bar:** P0 closed + metrics met on a clean machine.  
**Confidence:** High on framing; medium on gap severity until P0 #1–#2 verified in one clean run.  
**Owner:** Fork DevAll maintainer · **Revisit:** After P0 closed or when PR #2 merges.

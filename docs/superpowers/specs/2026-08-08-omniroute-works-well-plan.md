# OmniRoute Onboarding — Works-Well Delivery Plan

**Date:** 2026-08-08  
**Role:** Delivery lead synthesis  
**Host:** `tsmbp64`  
**Sources:** [design](./2026-07-24-omniroute-onboarding-design.md) · [PM brief](./2026-08-08-omniroute-works-well-pm.md) · [loop](./2026-08-08-omniroute-onboarding-loop.md) · [levels](./2026-08-08-omniroute-onboarding-levels.md) · [integration status](./2026-08-08-omniroute-integration-status.md) · [API test report](./2026-08-08-omniroute-api-test-report.md)

## One-liner

Ship a fail-forward OmniRoute path so a new fork operator gets one successful Web Console agent reply without hand-editing YAML providers or committing secrets.

## Definition of done (from PM + loop)

| Gate | Signal |
|------|--------|
| Path | OmniRoute is the recommended default; Ollama labeled side path |
| Identity | Make + Compose profile observe the same gateway (`chatdev_omniroute` / `chatdev_omniroute_data`) |
| Honesty | Placeholder / unauthorized never reads “ready” |
| Reward | First Console agent reply via `${BASE_URL}` / `${API_KEY}` (probe alone is not enough) |
| Safety | No real keys in git, status pretty-print, or docs |
| Quality | `make check` green (YAML + path-safety + onboard-models) |

## Player journey → engineering map

| Level | Player beat | Primary surfaces | PR ownership |
|-------|-------------|------------------|--------------|
| L1 Setup | `make setup` | Makefile, `.env.example` | #2 onboarding (+ #3 DX merged) |
| L2 Gateway | `make omniroute-up` / status | Makefile, `compose.yml`, `tools/omniroute_gateway.py` | #2 |
| L3 Key + env | `make onboard-models` | `tools/onboard_models.py`, user guides EN/ZH | #2 |
| L4 First run | `make dev` + Console | Vite proxy/HMR for `*.casonclark.com` | #3 (merged) + follow-up DX |
| Safety gate | Upload / session paths | `AttachmentService`, uploads routes, tests | #1 |

## PR coherence (review base)

**Base:** `pr-base/devall-pre-omniroute` (remote includes merged #3).

| PR | Branch | State | Delivery action |
|----|--------|-------|-----------------|
| [#1](https://github.com/ai-Ev1lC0rP/ChatDev/pull/1) | `pr/session-id-path-safety` | OPEN | Keep path-safety tip current; merge first |
| [#2](https://github.com/ai-Ev1lC0rP/ChatDev/pull/2) | `pr/omniroute-model-onboarding` | OPEN | Land compose/Make/CLI/docs improvements; merge after #1 |
| [#3](https://github.com/ai-Ev1lC0rP/ChatDev/pull/3) | `pr/fork-dx-vite-proxy` | MERGED | Follow-up DX PR only if Vite/HMR/AGENTS deltas remain |

**Merge order:** refresh local base → **#1** → **#2** → reconcile `upstream-sync`.

Do not treat squash commits on `upstream-sync` (`e82f030`, `860b0f3`) as substitutes for review-base merges; dual history is expected until reconcile.

## P0 work packages (actionable)

### WP1 — Single gateway identity
- Compose SoT: `container_name: chatdev_omniroute`, volume `chatdev_omniroute_data`
- Make `omniroute-up/down/status` prefer compose profile; Python helper probe/status aligned
- Acceptance: `make omniroute-up` then `make omniroute-status` sees the same container Compose started

### WP2 — Honest onboarding copy + probe
- Interactive steps match loop (choose → confirm → optional start → save → next verb)
- Docs EN/ZH journey ends at `make dev`, not env write alone
- Acceptance: placeholder key path prints dashboard/key next step; authorized path states agents can use env placeholders

### WP3 — Fail-forward Make UX
- Setup hooks point at OmniRoute path; Docker-missing / auth / port conflict each print one recover verb
- Acceptance: `make help` shows onboarding tree + recovery notes

### WP4 — Path-safety unchanged as hard gate
- Opaque `session_id` + basename filename sanitization remain; CI runs focused tests
- Acceptance: session/upload tests green in `make check`

### WP5 — Fork DX follow-through (post-#3)
- Document `VITE_HMR_CLIENT_PORT=443` for HTTPS reverse proxies; keep `allowedHosts` behavior
- Acceptance: proxied Console hosts are dress on L4, not a new level

## Out of scope (explicit)

Frontend settings wizard; vendoring OmniRoute; mass YAML `model: auto` rewrites; ChatDev 1.0 / stale `main` as base; inventing API keys in tests.

## Validation plan

1. `make check` (YAML + attachment filename + session_id + onboard_models)
2. Non-destructive CLI: `onboard_models.py --list` / `--help`
3. Live (operator): `make omniroute-up` → status reachable → dashboard key → onboard with key → `make dev` → one agent reply
4. Do not invent keys; live auth remains operator-owned

## Open questions for owner

1. Confirm review base stays `pr-base/devall-pre-omniroute` (not `upstream-sync` / `main`).
2. Approve merge order **#1 → #2** after base refresh.
3. How to track remaining TODOs: GitHub issues vs inline `TODO(area):` vs delivery summary only?
4. After merges: reset/merge `upstream-sync` to review base, or keep `upstream-sync` as live integration line with backup refs retained?

## Status snapshot (this delivery pass)

- Specs (loop/levels/PM/status/API report) exist; this file is the integrated plan.
- Sibling WIP on disk may advance #2 surfaces (Make/compose/CLI/docs) ahead of remote tip — fold via named-file commits on `pr/*` only.
- Live OmniRoute was previously unreachable in API test report; unit gates can still be green.

---
**Delivery lead** · 2026-08-08

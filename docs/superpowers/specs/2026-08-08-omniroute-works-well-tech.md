# OmniRoute Onboarding + Path-Safety + Vite Proxy — Gap Analysis

**Date:** 2026-08-08  
**Host:** `tsmbp64.taileb7e4.ts.net` (matches expected device `TSMBP64`)  
**Workspace:** `/Users/ev1lc0rp/Development/ChatDev`  
**Branch baseline:** `upstream-sync` @ `860b0f3` (committed) + dirty WIP (not treated as shipped)  
**Role:** Technical Consultant — advise only; no application code changes in this deliverable  
**Secrets:** None inspected or recorded

## Purpose

Rank what still blocks “OmniRoute works well” on this fork across three surfaces:

1. **OmniRoute model onboarding** (`tools/onboard_models.py`, `tools/omniroute_gateway.py`, Makefile, `compose.yml`, `.env.example`)
2. **Upload / `session_id` path-safety** (`AttachmentService`, upload routes, regression tests)
3. **Vite reverse-proxy DX** (`frontend/vite.config.js`, HMR env, proxy hosts)

Related coordination notes (not duplicated here as authority):  
`2026-08-08-omniroute-integration-status.md`, `2026-08-08-omniroute-api-test-report.md`,  
`2026-08-08-omniroute-onboarding-levels.md`, `2026-08-08-omniroute-onboarding-loop.md`,  
`2026-07-24-omniroute-onboarding-design.md`.

## Current-state snapshot

| Surface | Committed `upstream-sync` | Split PR tip | Working tree WIP |
|--------|---------------------------|--------------|------------------|
| OmniRoute onboarding | Landed combined in `e82f030` | `pr/omniroute-model-onboarding` (`2ca10db`) | Makefile → **compose** lifecycle; gateway/helpers still dual-path |
| Path-safety | Landed combined in `e82f030` | `pr/session-id-path-safety` (`09c9e70`) | Minor upload-route / filename TODO polish |
| Vite proxy / HMR | Landed in `860b0f3` | `pr/fork-dx-vite-proxy` (`14ab3b8`; review-base #3 merged) | Docs / comment clarity; `.env.example` HMR block |
| Container name SoT | **Mismatch:** Python `chatdev-omniroute` vs compose `chatdev_omniroute` | PR tip documents `TODO(omniroute)` mismatch | Aligning toward `chatdev_omniroute`; volume naming still inconsistent |

**PR topology risk:** Split branches target `pr-base/devall-pre-omniroute`. Local `upstream-sync` already carries squash/combined commits. Dual history is a process risk, not a product feature.

**Live gateway (from API test report):** unit/path-safety suites green; OmniRoute on `:20128` was unreachable at test time — L2 “gateway alive” not yet proven on this host.

---

## Ranked gaps

Priority: **P0** = breaks trust / security / dual-instance confusion now; **P1** = onboarding reliability or incomplete harding; **P2** = polish, governance, nice-to-have.

### P0 — Must close before calling OmniRoute “works well”

| ID | Gap | Risk | Recommended fix owner area |
|----|-----|------|----------------------------|
| **P0-1** | **Docker name mismatch (documented `TODO(omniroute)`).** Committed helper uses `DOCKER_CONTAINER=chatdev-omniroute` / `chatdev-omniroute-data`; `compose.yml` uses `container_name: chatdev_omniroute` and volume key `omniroute-data`. `make omniroute-status` / `docker_container_running()` can report “not running” while Compose instance is healthy (or the reverse). | Dual gateway instances; lost API keys/config across volumes; false-negative status; operators “fix” by starting a second container on the same port. | **DevOps / tools** — single SoT: `compose.yml` `container_name` + pinned volume `name`; Makefile lifecycle; `tools/omniroute_gateway.py` inspect/start/stop constants. Retire or strictly deprecate legacy `docker run` name. |
| **P0-2** | **Dual lifecycle paths still coexist.** WIP Makefile correctly prefers `docker compose --profile omniroute`, but `onboard_models --start` still calls `start_gateway_docker()` (`docker run`). Two entrypoints → two naming/volume policies. | Same as P0-1, triggered by “helpful” `--start` during onboarding. | **Tools / onboarding CLI** — `--start` should invoke the same compose path as `make omniroute-up`, or be removed in favor of Makefile-only lifecycle. |
| **P0-3** | **WIP volume pin inconsistency (if landing WIP as-is).** Compose WIP pins `volumes.omniroute-data.name: chatdev_omniroute_data`; Python WIP still references `chatdev_omniroute-data` (hyphen vs underscore) and a TODO that does not match the compose pin. | Silent data-dir split after “alignment” PR; keys in one volume, runtime in another. | **DevOps** — pick one literal name, pin it in compose, mirror in any remaining docker-run helper, add a one-line assert/test or `make omniroute-status` name check. |
| **P0-4** | **Path-safety incomplete outside AttachmentService.** Upload/session attachment paths use `_safe_session_id`; `server/routes/sessions.py` download validates similarly; `batch_run_service` / `workflow_run_service` still interpolate `session_{session_id}` into `WareHouse` without the shared sanitizer. | Residual traversal / unexpected directory creation if a hostile or malformed `session_id` reaches those services. | **Backend security** — centralize opaque-id validation (shared helper); apply at WareHouse path construction sites; extend regression tests beyond AttachmentService. |

### P1 — Reliability and verification gaps

| ID | Gap | Risk | Recommended fix owner area |
|----|-----|------|----------------------------|
| **P1-1** | **Advisory-only OmniRoute verify.** `verify_provider()` always returns `0` even when a real key fails `/models` (`TODO(onboarding)`). | CI/scripts report success while agents will fail at first LLM call; false “green” onboarding. | **Tools / onboarding** — opt-in `--strict` / exit non-zero when key is non-placeholder and probe fails; keep default soft for interactive first-run. |
| **P1-2** | **No ready-wait after gateway start.** `TODO(omniroute)`: after start, no retry until `/v1/models` answers (or auth challenge). Makefile compose `up -d` returns before process is ready. | Race: immediate `onboard-models` / status fails; users conclude OmniRoute is broken. | **DevOps / tools** — poll probe (bounded retries) in `omniroute-up` / status path. |
| **P1-3** | **CI vs local `make check` drift.** GitHub `validate-yamls` runs attachment + session_id tests only; local `make check` also runs `tests/test_onboard_models.py`. | Onboarding regressions merge without CI signal. | **CI / Makefile owners** — add onboard-models tests to the workflow job that already runs path-safety. |
| **P1-4** | **Live L2 not proven on this host.** API test report: Docker present, `:20128` connection refused, `docker_running=false`. | “Works well” cannot be claimed for the happy path until one green `omniroute-up` → key → `omniroute-status` → agent call. | **Ops / local host** — start via compose SoT; create dashboard key; re-run status + one Console workflow (no secrets in git). |
| **P1-5** | **Vite `allowedHosts: true` is maximally permissive.** Needed for `*.casonclark.com` reverse proxies; also accepts any Host header to the Vite dev server. | Host-header / DNS-rebinding style abuse against a reachable dev server (local/tailnet exposure). | **Frontend DX / security** — prefer explicit allowlist (`chatdev`, `chat-dev`, `bit`, `*.casonclark.com`, localhost) unless true wildcards are required; document threat model in `.env.example`. |
| **P1-6** | **`make client` hardcodes `VITE_API_BASE_URL=http://localhost:$(BACKEND_PORT)`.** Overrides env that Compose / reverse-proxy setups may need. | Proxied or containerized frontend talks to wrong API origin; “UI up, API dead” reports. | **Frontend DX / Makefile** — only set default when unset; document proxy vs localhost matrix in `.env.example`. |
| **P1-7** | **Upload route error semantics.** Path-safety `ValueError` maps to HTTP 400 (good); some ValidationError paths still surface as generic “Session not connected,” which can mask sanitizer failures depending on call order. | Harder incident triage; false ops signals. | **Backend API** — distinct 400 details for unknown session vs invalid `session_id` / filename (no stack traces/secrets). |

### P2 — Polish, governance, secondary hardening

| ID | Gap | Risk | Recommended fix owner area |
|----|-----|------|----------------------------|
| **P2-1** | **Filename hardening incomplete.** `TODO(security)`: after basename + null-strip, still accept control chars / extreme lengths. | Low residual DoS / log noise; traversal already mitigated. | **Backend security** — reject control chars + max length; unit tests. |
| **P2-2** | **Legacy container orphan.** Makefile notes `chatdev-omniroute` is unmanaged after compose migration. | Port conflicts; confusion in `docker ps`. | **Ops docs / Makefile help** — one-time cleanup command in help text (manual remove). |
| **P2-3** | **Compose DNS vs host BASE_URL.** Docs correctly say in-compose backend needs `http://omniroute:20128/v1`; default onboarding writes `localhost`. | Easy misconfig when running full stack in Compose. | **Docs / onboarding** — detect or warn when `MODEL_PROVIDER=omniroute` and backend is compose-networked. |
| **P2-4** | **PR / branch governance debt.** Design follow-up (`TODO(fork-dx)`) + integration status: split PRs vs combined `upstream-sync` landing; dirty tree overlaps all three scopes. | Double-apply, review confusion, accidental commit of WIP. | **Release / Project Shepherd** — finish review-base merge order (#1 → #2), then reconcile `upstream-sync`; park WIP on a follow-up branch. |
| **P2-5** | **HMR documentation lag.** `pr/fork-dx-vite-proxy` carried `TODO(proxy)` for `.env.example` / user guide; WIP adds `.env.example` HMR block — user guides may still lag. | Reverse-proxy Console “works once” tribal knowledge. | **Docs / frontend DX** — EN/ZH user guide note: `VITE_HMR_CLIENT_PORT=443` for HTTPS proxies. |
| **P2-6** | **Non-OmniRoute providers skip live probe.** By design today. | Weaker confidence for Ollama/OpenAI presets. | **Tools** — optional lightweight probe per provider later; not blocking OmniRoute path. |
| **P2-7** | **Image tag `:latest`.** Compose + helper pull floating OmniRoute image. | Non-reproducible breaks after upstream image move. | **DevOps** — pin digest/tag once a known-good OmniRoute version is chosen. |

---

## Cross-cutting architecture (target state)

```
make setup
   → make omniroute-up          # ONLY compose profile; container_name chatdev_omniroute
   → Dashboard → API key        # never commit
   → make onboard-models        # writes BASE_URL/API_KEY/MODEL_PROVIDER only
   → make omniroute-status      # HTTP /v1/models + same container name SoT
   → make dev                   # Vite: localhost OR VITE_HMR_CLIENT_PORT=443 behind proxy
```

**SoT rules**

1. **Container name:** `compose.yml` `container_name: chatdev_omniroute` wins; Python/Makefile must match.
2. **Volume name:** explicit compose `name:` wins; any helper volume string must be identical.
3. **Path safety:** one opaque-id validator for every `WareHouse/session_*` construction.
4. **Proxy DX:** HMR client port + Host allowlist documented; `make client` must not clobber intentional env.

---

## Suggested remediation tiers

| Tier | Outcome | Scope |
|------|---------|--------|
| **Tier 1 — Quick win (≤1–2 days)** | One gateway instance, truthful status | Close P0-1/P0-2/P0-3; pin volume; Makefile compose-only; align or gate `--start`; live `omniroute-up` smoke on TSMBP64 |
| **Tier 2 — Full local solution** | Trustworthy onboarding + hardened uploads | P0-4 shared session sanitizer; P1-1 strict verify; P1-2 ready-wait; P1-3 CI parity; P1-5/P1-6 proxy hardening |
| **Tier 3 — Enterprise / fork hygiene** | Sustainable ops | P2 governance reconciliation; pin OmniRoute image; compose-network BASE_URL warn; filename control-char policy |

---

## Explicit non-gaps (already in good shape)

- OmniRoute-first presets and `${BASE_URL}` / `${API_KEY}` placeholder pattern (no hardcoding in YAML).
- Attachment **filename** basename sanitization + `tests/test_attachment_upload_filename.py`.
- Attachment **session_id** opaque validation + `tests/test_session_id_safety.py` (AttachmentService path).
- Vite HMR `clientPort` / `wss` when `VITE_HMR_CLIENT_PORT` is set (committed `860b0f3`).
- Local `make check` includes onboarding + path-safety unit tests.
- Design/levels/loop specs exist to pace UX; product surface remains env + CLI (no CompanyConfig 1.0 revival).

---

## Decision asks (for owners)

1. **Confirm SoT:** Compose-only lifecycle for OmniRoute (retire `docker run` helper for day-to-day), yes/no?
2. **Confirm volume literal:** `chatdev_omniroute_data` vs `chatdev_omniroute-data` — one string forever.
3. **Confirm verify policy:** soft default + `--strict` for scripts, or hard-fail when key present?
4. **Confirm Host policy:** keep `allowedHosts: true` or tighten to `*.casonclark.com` + localhost?
5. **Confirm branch strategy:** review-base merge of split PRs vs continue landing only on `upstream-sync`.

---

## Evidence anchors (no secrets)

| Artifact | Relevance |
|----------|-----------|
| `tools/omniroute_gateway.py` | Container/volume constants; probe; docker-run start; TODOs |
| `tools/onboard_models.py` | Presets; `--start`; advisory verify TODO |
| `Makefile` | WIP compose SoT vs committed docker-run helpers |
| `compose.yml` | `chatdev_omniroute`; volume pin WIP |
| `.env.example` | OmniRoute + HMR documentation |
| `server/services/attachment_service.py` | `_safe_session_id` / `_safe_upload_filename` |
| `server/services/batch_run_service.py` / `workflow_run_service.py` | Unshared `session_{id}` paths |
| `frontend/vite.config.js` | `allowedHosts`, HMR clientPort |
| PR tips `pr/session-id-path-safety`, `pr/omniroute-model-onboarding`, `pr/fork-dx-vite-proxy` | Split review artifacts vs combined `upstream-sync` |

---

**Technical Consultant** · Gap analysis only · 2026-08-08  
**Verdict:** Yellow — unit/defensive tests are in place, but OmniRoute cannot be called “works well” until container/volume SoT and lifecycle duality (P0-1…P0-3) are closed and a live L2→L4 path is proven on this host.

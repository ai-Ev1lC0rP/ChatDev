# OmniRoute / Onboarding API Test Report

**Date**: 2026-08-08  
**Hostname**: `tsmbp64.taileb7e4.ts.net` (matches expected device `TSMBP64`)  
**Workspace**: `/Users/ev1lc0rp/Development/ChatDev`  
**Tester**: API Tester agent  
**Product code modified**: No  
**Overall quality status**: **CONDITIONAL PASS** (unit/CLI green; live OmniRoute unreachable)

---

## Pass / Fail Summary

| Area | Result | Notes |
|------|--------|-------|
| Hostname verification | **PASS** | `tsmbp64.taileb7e4.ts.net` |
| Pytest suite (33 tests) | **PASS** | Exit 0, ~4.5s |
| OmniRoute live gateway | **FAIL** | Connection refused on `:20128`; Docker container not running |
| `onboard_models.py --list` | **PASS** | Exit 0 |
| `onboard_models.py --help` | **PASS** | Exit 0, non-destructive |
| API keys invented | **N/A** | None created or fabricated |

**Release readiness for local OmniRoute path**: **No-Go** until gateway is up and `/v1/models` responds successfully (with a real key if the endpoint requires auth).

**Release readiness for defensive onboarding + upload/session safety**: **Go** (all automated tests passed).

---

## 1. Pytest / Functional Validation

**Command**:

```bash
uv run pytest -v tests/test_onboard_models.py tests/test_session_id_safety.py tests/test_attachment_upload_filename.py
```

**Environment**: Python 3.12.11, pytest 9.0.2, project `.venv`

**Result**: **33 passed in 4.54s** (`PYTEST_EXIT=0`)

### Coverage breakdown

| File | Tests | Status |
|------|------:|--------|
| `tests/test_onboard_models.py` | 7 | PASS |
| `tests/test_session_id_safety.py` | 13 | PASS |
| `tests/test_attachment_upload_filename.py` | 13 | PASS |

### Functional highlights validated

- Env upsert create/update and `export` prefix preservation
- OmniRoute provider preset wiring
- Provider apply writes `.env` safely (test-scoped)
- Gateway probe behavior when unreachable
- CLI `--list` and non-interactive onboarding paths
- Opaque `session_id` accept/reject + warehouse containment / traversal rejection
- Upload filename basename sanitization (path traversal, null bytes, empty names)
- Round-trip normal upload; traversal cannot escape temp dir

`make check` was not required after targeted suite success; targeted suite is the scoped gate for this report.

---

## 2. OmniRoute Reachability

**Docker**: Available (`/usr/local/bin/docker`, `DOCKER_AVAILABLE=yes`)

**Command**: `make omniroute-status`

**Status JSON**:

```json
{
  "reachable": false,
  "models_ok": false,
  "model_count": null,
  "detail": "unreachable: <urlopen error [Errno 61] Connection refused>",
  "docker_running": false,
  "base_url": "http://localhost:20128/v1"
}
```

**Direct probe**: `curl http://localhost:20128/v1/models`

| Metric | Value |
|--------|-------|
| HTTP code | `000` |
| Curl exit | `7` (failed to connect) |
| Connect error | Connection refused |
| Time | ~3 ms |

**Reachability verdict**: **UNREACHABLE** — OmniRoute gateway process/container is not listening on `localhost:20128`.

**Security note**: No API keys were invented, written, or assumed. Live authenticated model listing was not attempted.

---

## 3. CLI Smoke Tests (Non-Destructive)

### `uv run python tools/onboard_models.py --list`

**Exit**: 0  

Presets reported:

| Provider | BASE_URL | DEFAULT_MODEL |
|----------|----------|---------------|
| omniroute (recommended) | `http://localhost:20128/v1` | `auto` |
| ollama | `http://localhost:11434/v1` | `gpt-oss:20b` |
| openai | `https://api.openai.com/v1` | `gpt-4o` |
| gemini | `https://generativelanguage.googleapis.com` | `gemini-2.0-flash` |
| lmstudio | `http://localhost:1234/v1` | `local-model` |
| custom | `http://localhost:8000/v1` | `default` |

OmniRoute list output correctly points operators to `make omniroute-up`, dashboard `http://localhost:20128`, and creating an API key under Endpoints before re-running with `--api-key`.

### `uv run python tools/onboard_models.py --help`

**Exit**: 0  

Help documents flags including `--provider`, `--base-url`, `--api-key`, `--model`, `--env-file`, `--port`, `--start`, `--yes`, `--skip-verify`, `--list`. No state changes performed.

---

## Security Assessment (Scoped)

| Check | Result |
|-------|--------|
| Session ID path safety (unit) | PASS |
| Upload filename sanitization (unit) | PASS |
| No secrets invented during testing | PASS |
| Live auth/rate-limit against OmniRoute | SKIPPED (gateway down) |

---

## Performance Notes (Scoped)

| Check | Result |
|-------|--------|
| Pytest suite duration | 4.54s (well under 15m suite budget) |
| OmniRoute `/v1/models` latency / p95 | N/A (unreachable) |
| Concurrent load against gateway | N/A (unreachable) |

---

## Issues and Blockers

### Blockers (live OmniRoute path)

1. **OmniRoute container/process not running** (`docker_running: false`, connection refused on port `20128`).
2. **Cannot validate `/v1/models` contract, model count, or auth behavior** until the gateway is started.
3. **API key still required for authenticated onboarding** after start — must be created by the operator in the OmniRoute dashboard (Endpoints); tests must not invent keys.

### Non-blockers

- Unit/regression suite for onboarding + attachment/session safety is green.
- CLI discovery/help paths work without side effects.
- Docker binary is present; starting the stack should be possible via `make omniroute-up` when the operator chooses.

### Recommended next steps (operator)

1. `make omniroute-up`
2. `make omniroute-status` until `reachable: true`
3. Create a real API key in the OmniRoute UI (Endpoints)
4. Re-probe `/v1/models` (with auth if required)
5. Optionally: `uv run python tools/onboard_models.py --provider omniroute --api-key <real-key> --yes` (destructive to `.env` — out of scope for this report)

---

## Evidence Index

| Artifact | Location / value |
|----------|------------------|
| Hostname | `tsmbp64.taileb7e4.ts.net` |
| Pytest | 33 passed, exit 0 |
| OmniRoute status | unreachable; docker_running false |
| curl `/v1/models` | exit 7, HTTP 000 |
| CLI `--list` / `--help` | exit 0 each |

---

**API Tester**: API Tester agent  
**Testing Date**: 2026-08-08  
**Quality Status**: CONDITIONAL PASS  
**Release Readiness**: Go for safety/onboarding unit gates; No-Go for live OmniRoute integration until gateway is reachable

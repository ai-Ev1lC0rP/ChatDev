# OmniRoute Integration — Coordination Status

**Date:** 2026-08-08  
**Host:** `tsmbp64` (verified)  
**Scope:** Coordinate view only — no application code changes in this pass  
**Working branch:** `upstream-sync` @ `860b0f3` (tracks `origin/upstream-sync`)

## Executive summary

**Overall:** Yellow — fork review PRs are split and reviewable; local `upstream-sync` already carries a combined landing plus a large dirty tree that must not be confused with the review-base merges.

Review base: `pr-base/devall-pre-omniroute`  
- Remote tip: `d90180b` (#3 squash-merged)  
- Local tip: `4fd4da6` (**stale** — fetch/reset before merging)

## PR status (`ai-Ev1lC0rP/ChatDev`)

| PR | Branch | State | Into review base | Notes |
|----|--------|-------|------------------|-------|
| [#1](https://github.com/ai-Ev1lC0rP/ChatDev/pull/1) | `pr/session-id-path-safety` | OPEN / MERGEABLE | Pending | Session_id + filename path safety + CI tests |
| [#2](https://github.com/ai-Ev1lC0rP/ChatDev/pull/2) | `pr/omniroute-model-onboarding` | OPEN / MERGEABLE | Pending | `onboard-models`, gateway helpers, docs |
| [#3](https://github.com/ai-Ev1lC0rP/ChatDev/pull/3) | `pr/fork-dx-vite-proxy` | MERGED | Done (`d90180b`) | Fork DX, `AGENTS.md`, Vite proxy/HMR |

All three target `pr-base/devall-pre-omniroute`. Heads are **not** ancestors of `upstream-sync`; that branch used squash/combined commits instead (`e82f030`, `860b0f3`).

## Recommended merge order (into review base)

1. **Refresh local base** from `origin/pr-base/devall-pre-omniroute` (includes #3).
2. **Merge #1** (security) — smallest blast radius; path-safety is a hard gate.
3. **Merge #2** (OmniRoute onboarding) — depends on clean CI on the post-#1 base.
4. **Reconcile to `upstream-sync`** only after review-base green: either FF/merge review base, or document that `upstream-sync` remains the “already landed” integration line and PRs stay review artifacts.

Do **not** merge dirty working-tree deltas into the PRs without an explicit change request.

## Dirty on `upstream-sync` (uncommitted)

**Modified (overlap PR scopes):**  
`.env.example`, design spec, EN/ZH model onboarding docs, `frontend/vite.config.js`, `server/routes/uploads.py`, `server/services/attachment_service.py`, `tools/omniroute_gateway.py`, `tools/onboard_models.py`

**Untracked:** `AGENTS.md`, `docs/superpowers/specs/2026-08-08-omniroute-onboarding-loop.md`, `docs/superpowers/specs/2026-08-08-omniroute-onboarding-levels.md`  
(+ this status file once written)

Treat as **WIP beyond** the open PR tips — park or branch before merging #1/#2.

## Backup refs (recovery)

| Ref | Role |
|-----|------|
| `backup/pre-split-full` / `refs/backup/pre-split-full-*` | Pre-split snapshot (`15a2e01`) |
| `refs/backup/pre-split-1785695386` | Earlier pre-split marker |
| `refs/backup/omniroute-pretty-head-20260802125317` | Points at `860b0f3` (current upstream-sync tip family) |

Safe rollback anchors; do not delete until review-base ↔ `upstream-sync` reconciliation is done.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Dual history: combined commits on `upstream-sync` vs split PRs on review base | Review confusion / double-apply | Land via review base; reconcile once; avoid cherry-picking both ways |
| Stale local `pr-base` | Wrong merge parent | Always use `origin/pr-base/devall-pre-omniroute` |
| Dirty tree overlaps #1/#2/#3 files | Accidental commit into wrong branch | Stash/branch WIP before any merge work |
| Security (#1) vs upload dirty deltas | Path-safety regressions | Merge #1 first; re-run path-safety tests after any WIP fold-in |
| Secrets in onboarding WIP | Key leak | Keep `${BASE_URL}` / `${API_KEY}`; never commit `.env` |

## Stakeholder asks

1. **Owner:** Confirm review base remains `pr-base/devall-pre-omniroute` (not `upstream-sync` / `main`).
2. **Owner:** Approve merge order **#1 → #2** after local base refresh.
3. **Owner:** Decide fate of dirty `upstream-sync` WIP — new follow-up PR(s) vs discard vs fold into #2 only.
4. **Reviewer:** Run path-safety + onboard-models tests on #1 then #2 before merge.
5. **Ops:** After merges, decide whether `upstream-sync` should reset/merge to match review base or stay as the live integration line with backups retained.

## Related specs

- `2026-07-24-omniroute-onboarding-design.md`
- `2026-08-08-omniroute-onboarding-loop.md` / `…-levels.md` (untracked design layers)

---
**Project Shepherd** · Coordinate-only · 2026-08-08

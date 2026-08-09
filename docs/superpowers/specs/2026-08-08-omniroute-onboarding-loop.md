# OmniRoute Onboarding as a Player Loop

**Date:** 2026-08-08 · **Status:** Design lens (no code)  
**Aligns with:** `make onboard-models`, `make omniroute-*`, [2026-07-24 design](./2026-07-24-omniroute-onboarding-design.md)

## Fun hypothesis

The player (developer) feels *capable in under five minutes*: one goal, few verbs, honest feedback, first agent reply without hand-editing YAML providers.

## Pillars

1. **One recommended path** — OmniRoute (`localhost:20128/v1`); Ollama/etc. are side routes.
2. **Fail forward** — Down gateway or missing key never traps; always leave a next verb.
3. **No secret theater** — Never print/commit real keys; placeholders + dashboard URL only.
4. **Reward is runtime** — Win = `make dev` + working chat, not probe-green alone.

## Core loop

### Moment-to-moment (0–30s)

- **Goal:** Point ChatDev at a live OpenAI-compatible endpoint.
- **Verbs:** Choose provider → (optional) start gateway → write `.env` → probe.
- **Feedback:** Preset summary; probe OK / unauthorized / unreachable + one-line fix.
- **Reward:** Env written; printed next step.

### Session (5–15 min)

1. `make setup` → hook: `make onboard-models`
2. Onboard (default OmniRoute) → optional `make omniroute-up`
3. Dashboard: create Endpoints key → re-run with key (env only)
4. `make omniroute-status` / onboard probe → `/v1` healthy
5. `make dev` → first Web Console message succeeds

**Tension:** Gateway down, placeholder key, Docker missing.  
**Resolution:** Env still written; recover via `omniroute-up`, paste key, retry probe.

### Long-term

Swap providers without rewriting agent YAML (`${BASE_URL}` / `${API_KEY}`). Add models in OmniRoute; keep `model: auto` (or agent-local). Retention: second YAML workflow after first chat works.

## Fail-forward map

| Failure | Forward verb |
|---------|----------------|
| Gateway down | `make omniroute-up`; env still writable |
| Placeholder / bad key | Dashboard → re-run onboard with key |
| Probe unauthorized | Same; do not claim success |
| Non-interactive, no `--provider` | Usage + OmniRoute example; exit non-zero |
| Docker unavailable | Ollama / direct provider presets |

## Onboarding checklist

- [ ] Core verb within one step of `make setup`
- [ ] First success possible without a cloud key (local OmniRoute/Ollama)
- [ ] Gateway → key → probe → dev in low-stakes order
- [ ] Discover health via status/probe, not a docs wall
- [ ] Session ends on a hook: open console / run a demo workflow

## Tuning levers `[PLACEHOLDER]`

Time-to-first-probe (&lt;3 min Docker-ready); default preset = OmniRoute (Ollama zero-key alt); probe warns ≠ blocks env write; one next action per failure.

## Out of scope

Frontend settings wizard, vendoring OmniRoute, committing keys, mass-rewriting YAML `model` fields.

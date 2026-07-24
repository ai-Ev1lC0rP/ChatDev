# Model onboarding (OmniRoute)

ChatDev agents call LLMs through OpenAI-compatible `BASE_URL` + `API_KEY` env vars. Model onboarding writes those values into `.env`.

## Recommended: OmniRoute

[OmniRoute](https://github.com/diegosouzapw/OmniRoute) is a local AI gateway. ChatDev points at its `/v1` API; OmniRoute handles provider routing, free tiers, and fallbacks.

| Item | Value |
|------|--------|
| Dashboard | http://localhost:20128 |
| API base | http://localhost:20128/v1 |
| Suggested model | `auto` |

### Steps

1. Install project deps: `make setup`
2. Start OmniRoute: `make omniroute-up`  
   (or `docker compose --profile omniroute up -d`, or `npx -y omniroute`)
3. Run onboarding: `make onboard-models` (choose OmniRoute)  
   Non-interactive: `make onboard-models ONBOARD_ARGS='--provider omniroute --yes'`
4. Open the dashboard → **Endpoints** → create an API key
5. Save the key:  
   `make onboard-models ONBOARD_ARGS='--provider omniroute --api-key YOUR_KEY --yes'`
6. Verify: `make omniroute-status`
7. Start ChatDev: `make dev`

### Docker Compose

```bash
docker compose --profile omniroute up -d
```

If ChatDev backend also runs in Compose, set `BASE_URL=http://omniroute:20128/v1` in `.env`.

## Other providers

`make onboard-models` also offers Ollama, OpenAI, Gemini, LM Studio, and custom OpenAI-compatible endpoints.

## Env vars written

| Variable | Purpose |
|----------|---------|
| `BASE_URL` | Provider API root (used as `${BASE_URL}` in YAML) |
| `API_KEY` | Auth token (`${API_KEY}`) |
| `DEFAULT_MODEL` | Reference default (YAML `model` still wins) |
| `MODEL_PROVIDER` | Which preset was applied (`omniroute`, `ollama`, …) |

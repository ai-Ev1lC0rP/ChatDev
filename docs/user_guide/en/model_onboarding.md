# Model onboarding

Agents talk to LLMs through OpenAI-compatible `BASE_URL` + `API_KEY`.  
Onboarding writes those into `.env` so YAML can use `${BASE_URL}` / `${API_KEY}`.

---

## Path: OmniRoute first

[OmniRoute](https://github.com/diegosouzapw/OmniRoute) is the recommended local gateway: one `/v1` endpoint, multi-provider routing, free tiers, and fallbacks.

| | |
|---|---|
| Dashboard | http://localhost:20128 |
| API | http://localhost:20128/v1 |
| Model | `auto` |

---

## Journey

### 1 · Prepare

```bash
make setup
```

### 2 · Start the gateway

```bash
make omniroute-up
```

Alternates: `docker compose --profile omniroute up -d` · `npx -y omniroute`

### 3 · Connect ChatDev

Interactive:

```bash
make onboard-models
```

Choose **OmniRoute**. Non-interactive:

```bash
make onboard-models ONBOARD_ARGS='--provider omniroute --yes'
```

### 4 · Unlock with a key

1. Open the dashboard → **Endpoints** → create an API key  
2. Save it (replace the placeholder; never commit real keys):

```bash
make onboard-models ONBOARD_ARGS='--provider omniroute --api-key YOUR_KEY --yes'
```

### 5 · Verify

```bash
make omniroute-status
```

### 6 · Run

```bash
make dev
```

---

## Compose note

If ChatDev’s backend also runs in Docker Compose, point at the service name:

`BASE_URL=http://omniroute:20128/v1`

---

## Other paths

Same command, different presets: Ollama · OpenAI · Gemini · LM Studio · custom OpenAI-compatible.

```bash
make onboard-models
```

---

## What gets written

| Variable | Role |
|----------|------|
| `BASE_URL` | Provider API root (`${BASE_URL}` in YAML) |
| `API_KEY` | Auth (`${API_KEY}`) |
| `DEFAULT_MODEL` | Reference default (YAML `model` still wins) |
| `MODEL_PROVIDER` | Preset applied (`omniroute`, `ollama`, …) |

# 模型接入引导（OmniRoute）

ChatDev Agent 通过 OpenAI 兼容的 `BASE_URL` + `API_KEY` 环境变量调用大模型。模型接入引导会将这些值写入 `.env`。

## 推荐：OmniRoute

[OmniRoute](https://github.com/diegosouzapw/OmniRoute) 是本地 AI 网关。ChatDev 指向其 `/v1` API，由 OmniRoute 负责多厂商路由、免费额度与回退。

| 项 | 值 |
|------|--------|
| 控制台 | http://localhost:20128 |
| API | http://localhost:20128/v1 |
| 建议模型名 | `auto` |

### 步骤

1. `make setup`
2. `make omniroute-up`（或 `docker compose --profile omniroute up -d` / `npx -y omniroute`）
3. `make onboard-models`（选择 OmniRoute）  
   非交互：`make onboard-models ONBOARD_ARGS='--provider omniroute --yes'`
4. 打开控制台 → **Endpoints** → 创建 API Key
5. `make onboard-models ONBOARD_ARGS='--provider omniroute --api-key YOUR_KEY --yes'`
6. `make omniroute-status`
7. `make dev`

### Compose

```bash
docker compose --profile omniroute up -d
```

若后端也在 Compose 内运行，请将 `.env` 中 `BASE_URL` 设为 `http://omniroute:20128/v1`。

## 其他厂商

`make onboard-models` 亦支持 Ollama、OpenAI、Gemini、LM Studio 与自定义 OpenAI 兼容端点。

## 写入的环境变量

| 变量 | 用途 |
|----------|---------|
| `BASE_URL` | Provider API 根地址（YAML 中 `${BASE_URL}`） |
| `API_KEY` | 鉴权（`${API_KEY}`） |
| `DEFAULT_MODEL` | 参考默认模型（YAML `model` 仍优先生效） |
| `MODEL_PROVIDER` | 所选预设（`omniroute`、`ollama` 等） |

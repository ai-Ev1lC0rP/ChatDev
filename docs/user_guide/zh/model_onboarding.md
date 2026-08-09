# 模型接入引导

Agent 通过 OpenAI 兼容的 `BASE_URL` + `API_KEY` 调用大模型。  
接入引导将这些值写入 `.env`，供 YAML 使用 `${BASE_URL}` / `${API_KEY}`。

---

## 路径：优先 OmniRoute

[OmniRoute](https://github.com/diegosouzapw/OmniRoute) 是推荐的本地网关：统一 `/v1` 端点，多厂商路由、免费额度与回退。

| | |
|---|---|
| 控制台 | http://localhost:20128 |
| API | http://localhost:20128/v1 |
| 模型 | `auto` |

---

## 旅程

### 1 · 准备

```bash
make setup
```

### 2 · 启动网关

```bash
make omniroute-up
```

备选：`docker compose --profile omniroute up -d` · `npx -y omniroute`

### 3 · 连接 ChatDev

交互：

```bash
make onboard-models
```

选择 **OmniRoute**。非交互：

```bash
make onboard-models ONBOARD_ARGS='--provider omniroute --yes'
```

### 4 · 用密钥解锁

1. 打开控制台 → **Endpoints** → 创建 API Key  
2. 写入（替换占位符；切勿提交真实密钥）：

```bash
make onboard-models ONBOARD_ARGS='--provider omniroute --api-key YOUR_KEY --yes'
```

### 5 · 验证

```bash
make omniroute-status
```

### 6 · 运行

```bash
make dev
```

---

## Compose 说明

若后端也在 Docker Compose 内运行，请指向服务名：

`BASE_URL=http://omniroute:20128/v1`

---

## 其他路径

同一命令，不同预设：Ollama · OpenAI · Gemini · LM Studio · 自定义 OpenAI 兼容端点。

```bash
make onboard-models
```

---

## 写入内容

| 变量 | 作用 |
|------|------|
| `BASE_URL` | Provider API 根地址（YAML 中 `${BASE_URL}`） |
| `API_KEY` | 鉴权（`${API_KEY}`） |
| `DEFAULT_MODEL` | 参考默认模型（YAML `model` 仍优先生效） |
| `MODEL_PROVIDER` | 所选预设（`omniroute`、`ollama` 等） |

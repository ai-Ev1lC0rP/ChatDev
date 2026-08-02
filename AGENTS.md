## Learned User Preferences

- Prefer working and opening PRs on `upstream-sync` (ChatDev 2.0 / DevAll); do not treat `main` as the PR base for current work.
- Prefer GitHub HTTPS / `gh` auth for push and remote ops when SSH keys are unavailable.
- Do not show code snippets in chat responses; validate changes and finish through testing before claiming done.
- Prefer OmniRoute as the recommended model-onboarding / multi-provider path; keep model setup as an explicit onboarding step (`make onboard-models`).
- When using local Ollama directly, prefer the model already installed on this machine (e.g. `gpt-oss:20b`).
- Expect the Web Console to be reached via reverse-proxy hostnames under `*.casonclark.com` (e.g. chatdev / chat-dev / bit) as well as localhost.

## Learned Workspace Facts

- This fork tracks OpenBMB ChatDev 2.0 (DevAll) on `upstream-sync`; `origin/main` is stale ChatDev 1.0 and is not a useful merge-base for current work.
- Local default ports: frontend Vite `5173`, backend API `6400`.
- OmniRoute local gateway is `http://localhost:20128` (OpenAI-compatible `/v1`); use `make omniroute-up` / `omniroute-status` / `omniroute-down` alongside onboarding.
- Agent YAML must keep `${BASE_URL}` / `${API_KEY}` placeholders — never hardcode provider keys in workflows.
- Behind HTTPS reverse proxies, Vite HMR needs `VITE_HMR_CLIENT_PORT=443` (and allowed proxy hosts) so the browser stays on `wss` to the public host.
- Upload filename and `session_id` path segments are security-sensitive; keep basename-only sanitization and opaque session-id validation in `AttachmentService`.

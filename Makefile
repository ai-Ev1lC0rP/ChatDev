# ==============================================================================
# ChatDev / DevAll — local development
# ==============================================================================
#
# Onboarding tree (recommended):
#   setup → omniroute-up → onboard-models → omniroute-status → dev
# Teardown gateway: omniroute-down  (data volume kept)
#
# OmniRoute container_name SoT: compose.yml → chatdev_omniroute
# ==============================================================================

.DEFAULT_GOAL := help

BACKEND_PORT ?= 6400
FRONTEND_PORT ?= 5173
OMNIROUTE_PORT ?= 20128
UPSTREAM_REMOTE ?= upstream
UPSTREAM_BRANCH ?= main

COMPOSE ?= docker compose
COMPOSE_FILE ?= compose.yml
# Must match compose.yml: service name + profiles + container_name
OMNIROUTE_SERVICE := omniroute
OMNIROUTE_PROFILE := omniroute
OMNIROUTE_CONTAINER := chatdev_omniroute

# ==============================================================================
# Onboarding path
# ==============================================================================

.PHONY: setup
setup: setup-env ## L1: install backend + frontend deps; ensure .env exists
	@uv sync
	@cd frontend && npm install
	@echo "Setup complete."
	@echo "Next (OmniRoute path): make omniroute-up"
	@echo "Then: make onboard-models"
	@echo "Verify: make omniroute-status → make dev"
	@echo "Alt (no Docker): make onboard-models  # choose Ollama / other provider"

.PHONY: setup-env
setup-env: ## Create .env from .env.example if missing
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env from .env.example"; \
	else \
		echo ".env already exists"; \
	fi

.PHONY: omniroute-up
omniroute-up: ## L2: start OmniRoute via compose profile (port OMNIROUTE_PORT)
	@command -v docker >/dev/null 2>&1 || { \
		echo "FAIL: Docker not found."; \
		echo "Recover: install Docker, or run: npx -y omniroute"; \
		echo "Then: make onboard-models ONBOARD_ARGS='--provider omniroute --yes'"; \
		exit 1; \
	}
	@$(COMPOSE) -f $(COMPOSE_FILE) --profile $(OMNIROUTE_PROFILE) up -d $(OMNIROUTE_SERVICE)
	@echo "OmniRoute up → dashboard http://localhost:$(OMNIROUTE_PORT)  API /v1"
	@echo "Container: $(OMNIROUTE_CONTAINER)  (compose SoT)"
	@echo "Next: open Dashboard → Endpoints (API key), then: make onboard-models"
	@echo "If port busy: OMNIROUTE_PORT=<free> make omniroute-up  (match .env BASE_URL port)"

.PHONY: onboard-models
onboard-models: setup-env ## L3: interactive model setup (OmniRoute / Ollama / OpenAI / …)
	@uv run python tools/onboard_models.py $(ONBOARD_ARGS)
	@echo "Next: make omniroute-status  (OmniRoute)  then  make dev"
	@echo "Recover auth: Dashboard key → make onboard-models ONBOARD_ARGS='--provider omniroute --api-key <KEY> --yes'"

.PHONY: omniroute-status
omniroute-status: ## L3/L4 verify: probe /v1/models + compose container state
	@uv run python tools/omniroute_gateway.py
	@if command -v docker >/dev/null 2>&1; then \
		echo "--- compose ($(OMNIROUTE_CONTAINER)) ---"; \
		$(COMPOSE) -f $(COMPOSE_FILE) --profile $(OMNIROUTE_PROFILE) ps $(OMNIROUTE_SERVICE) || true; \
	else \
		echo "Docker not available; HTTP probe above is authoritative."; \
	fi
	@echo "Recover: unreachable → make omniroute-up | auth fail → paste Dashboard API key via onboard-models"

.PHONY: omniroute-down
omniroute-down: ## Stop OmniRoute compose service (volume kept; restart with omniroute-up)
	@command -v docker >/dev/null 2>&1 || { \
		echo "FAIL: Docker not found (nothing to stop via compose)."; \
		exit 1; \
	}
	@$(COMPOSE) -f $(COMPOSE_FILE) --profile $(OMNIROUTE_PROFILE) stop $(OMNIROUTE_SERVICE)
	@echo "OmniRoute stopped ($(OMNIROUTE_CONTAINER); volume kept)."
	@echo "Restart: make omniroute-up"
	@echo "Note: legacy docker-run name 'chatdev-omniroute' is not managed here — remove manually if present."

.PHONY: dev
dev: ## L4: run backend + frontend (needs models configured)
	@$(MAKE) -j2 server client

.PHONY: server
server: ## Start the backend server with reload
	@echo "Starting server on port $(BACKEND_PORT)..."
	@uv run python server_main.py --port $(BACKEND_PORT) --reload

.PHONY: client
client: ## Start the frontend development server
	@cd frontend && npx cross-env VITE_API_BASE_URL=http://localhost:$(BACKEND_PORT) npm run dev -- --port $(FRONTEND_PORT)

.PHONY: stop
stop: ## Stop backend and frontend servers cross-platform
	@echo "Stopping backend server (port $(BACKEND_PORT))..."
	@npx kill-port $(BACKEND_PORT) || true
	@echo "Stopping frontend server (port $(FRONTEND_PORT))..."
	@npx kill-port $(FRONTEND_PORT) || true

# ==============================================================================
# Tools & Maintenance
# ==============================================================================

.PHONY: sync
sync: ## Sync Vue graphs to the server database
	@uv run python tools/sync_vuegraphs.py

.PHONY: validate-yamls
validate-yamls: ## Validate all YAML configuration files
	@uv run python tools/validate_all_yamls.py

.PHONY: sync-upstream
sync-upstream: ## Fetch and merge latest upstream/main into the current branch
	@git remote get-url $(UPSTREAM_REMOTE) >/dev/null 2>&1 || \
		git remote add $(UPSTREAM_REMOTE) https://github.com/OpenBMB/ChatDev.git
	@git fetch $(UPSTREAM_REMOTE)
	@git merge $(UPSTREAM_REMOTE)/$(UPSTREAM_BRANCH)
	@echo "Merged $(UPSTREAM_REMOTE)/$(UPSTREAM_BRANCH) into $$(git branch --show-current)"

.PHONY: check
check: ## Run YAML validation + focused security/unit tests
	@$(MAKE) validate-yamls
	@tests=""; \
	for t in \
		tests/test_attachment_upload_filename.py \
		tests/test_session_id_safety.py \
		tests/test_onboard_models.py; do \
		if [ -f "$$t" ]; then tests="$$tests $$t"; fi; \
	done; \
	if [ -z "$$tests" ]; then \
		echo "FAIL: no focused check tests found"; \
		exit 1; \
	fi; \
	uv run pytest -v $$tests

# ==============================================================================
# Quality Checks
# ==============================================================================

.PHONY: check-backend
check-backend: ## Run backend quality checks (tests + linting)
	@$(MAKE) backend-tests
	@$(MAKE) backend-lint

.PHONY: backend-tests
backend-tests: ## Run backend tests
	@uv run pytest -v

.PHONY: backend-lint
backend-lint: ## Run backend linting
	@uvx ruff check .

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help: ## Display onboarding path, recovery notes, and all targets
	@echo "ChatDev / DevAll — make targets"
	@echo ""
	@echo "Onboarding path (recommended):"
	@echo "  1. make setup                 # deps + .env"
	@echo "  2. make omniroute-up          # gateway :$(OMNIROUTE_PORT) (compose → $(OMNIROUTE_CONTAINER))"
	@echo "  3. make onboard-models        # write BASE_URL / API_KEY (OmniRoute recommended)"
	@echo "  4. make omniroute-status      # probe /v1 + container"
	@echo "  5. make dev                   # API :$(BACKEND_PORT) + UI :$(FRONTEND_PORT)"
	@echo "     make omniroute-down        # stop gateway (volume kept)"
	@echo ""
	@echo "Failure / recovery:"
	@echo "  Docker missing     → npx -y omniroute  OR  onboard-models with Ollama preset"
	@echo "  Gateway down       → make omniroute-up ; make omniroute-status"
	@echo "  Auth / bad key     → Dashboard → Endpoints → onboard with --api-key"
	@echo "  Port conflict      → OMNIROUTE_PORT=<free> make omniroute-up"
	@echo "  Compose DNS        → backend in compose: BASE_URL=http://omniroute:20128/v1"
	@echo ""
	@echo "Dry-run examples:"
	@echo "  make -n setup omniroute-up onboard-models omniroute-status omniroute-down"
	@echo ""
	@echo "All targets:"
	@uv run python -c "import re; \
	p=r'$(firstword $(MAKEFILE_LIST))'.strip(); \
	[print(f'  {m[0]:<20} {m[1]}') for m in re.findall(r'^([a-zA-Z_-]+):.*?## (.*)$$', open(p, encoding='utf-8').read(), re.M)]"

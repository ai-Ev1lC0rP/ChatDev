# ==============================================================================
# Development Commands
# ==============================================================================

.DEFAULT_GOAL := help

BACKEND_PORT ?= 6400
FRONTEND_PORT ?= 5173
UPSTREAM_REMOTE ?= upstream
UPSTREAM_BRANCH ?= main

.PHONY: setup
setup: setup-env ## Install backend + frontend deps and ensure .env exists
	@uv sync
	@cd frontend && npm install
	@echo "Setup complete."
	@echo "Next: configure models (OmniRoute recommended): make onboard-models"
	@echo "Then run: make dev"

.PHONY: onboard-models
onboard-models: setup-env ## Interactive model setup (OmniRoute / Ollama / OpenAI / …)
	@uv run python tools/onboard_models.py $(ONBOARD_ARGS)

.PHONY: omniroute-up
omniroute-up: ## Start OmniRoute gateway via Docker (port 20128)
	@uv run python -c "from tools.omniroute_gateway import start_gateway_docker; print(start_gateway_docker())"

.PHONY: omniroute-down
omniroute-down: ## Stop OmniRoute Docker container
	@uv run python -c "from tools.omniroute_gateway import stop_gateway_docker; print(stop_gateway_docker())"

.PHONY: omniroute-status
omniroute-status: ## Probe OmniRoute gateway health / models
	@uv run python tools/omniroute_gateway.py

.PHONY: setup-env
setup-env: ## Create .env from .env.example if missing
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env from .env.example"; \
	else \
		echo ".env already exists"; \
	fi

.PHONY: dev
dev: ## Run both backend and frontend development servers
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
	@uv run pytest -v tests/test_attachment_upload_filename.py tests/test_session_id_safety.py tests/test_onboard_models.py

# ==============================================================================
# Help
# ==============================================================================

.PHONY: help
help: ## Display this help message
	@uv run python -c "import re; \
	p=r'$(firstword $(MAKEFILE_LIST))'.strip(); \
	[print(f'{m[0]:<20} {m[1]}') for m in re.findall(r'^([a-zA-Z_-]+):.*?## (.*)$$', open(p, encoding='utf-8').read(), re.M)]" | sort

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

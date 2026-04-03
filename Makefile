# =============================================================================
# my-business — service management
# /home/ubuntu/my-business/Makefile
#
# Usage:
#   make up              # start everything
#   make down            # stop everything
#   make restart         # stop then start everything
#   make build           # rebuild all docker images
#   make deploy          # rebuild + restart everything + deploy scout
#
#   make up-agent        # start agentic system only
#   make up-gateway      # start gateway only
#   make down-agent      # stop agentic system only
#   make down-gateway    # stop gateway only
#   make restart-agent   # restart agentic system only
#   make restart-gateway # restart gateway only
#   make build-agent     # rebuild agentic system image
#   make build-gateway   # rebuild gateway image
#
#   make deploy-scout    # copy scout files to ~/Documents/scout
#   make logs-agent      # tail agentic system logs
#   make logs-gateway    # tail gateway logs
#   make status          # show running containers
#   make health          # check gateway + agent health endpoints
# =============================================================================

ROOT        := /home/ubuntu/my-business
AGENT_DIR   := $(ROOT)/ai-assistant
GATEWAY_DIR := $(ROOT)/api
SCOUT_SRC   := $(ROOT)/scout
SCOUT_DEST  := $(HOME)/Documents/scout

# ── All services ──────────────────────────────────────────────────────────────

.PHONY: up
up: up-agent up-gateway
	@echo "✓ All services started"

.PHONY: down
down: down-gateway down-agent
	@echo "✓ All services stopped"

.PHONY: restart
restart: down up
	@echo "✓ All services restarted"

.PHONY: build
build: build-agent build-gateway
	@echo "✓ All images rebuilt"

.PHONY: deploy
deploy: build down up deploy-scout
	@echo "✓ Full deploy complete"

# ── Agentic system ────────────────────────────────────────────────────────────

.PHONY: up-agent
up-agent:
	@echo "→ Starting agentic system..."
	cd $(AGENT_DIR) && docker compose up -d
	@echo "✓ Agent up on :5002"

.PHONY: down-agent
down-agent:
	@echo "→ Stopping agentic system..."
	cd $(AGENT_DIR) && docker compose down
	@echo "✓ Agent stopped"

.PHONY: restart-agent
restart-agent: down-agent up-agent
	@echo "✓ Agent restarted"

.PHONY: build-agent
build-agent:
	@echo "→ Rebuilding agentic system..."
	cd $(AGENT_DIR) && docker compose build
	@echo "✓ Agent image rebuilt"

.PHONY: logs-agent
logs-agent:
	cd $(AGENT_DIR) && docker compose logs -f

# ── Gateway ───────────────────────────────────────────────────────────────────

.PHONY: up-gateway
up-gateway:
	@echo "→ Starting gateway..."
	cd $(GATEWAY_DIR) && docker compose up -d
	@echo "✓ Gateway up on :5001"

.PHONY: down-gateway
down-gateway:
	@echo "→ Stopping gateway..."
	cd $(GATEWAY_DIR) && docker compose down
	@echo "✓ Gateway stopped"

.PHONY: restart-gateway
restart-gateway: down-gateway up-gateway
	@echo "✓ Gateway restarted"

.PHONY: build-gateway
build-gateway:
	@echo "→ Rebuilding gateway..."
	cd $(GATEWAY_DIR) && docker compose build
	@echo "✓ Gateway image rebuilt"

.PHONY: logs-gateway
logs-gateway:
	cd $(GATEWAY_DIR) && docker compose logs -f

# ── Scout ─────────────────────────────────────────────────────────────────────

.PHONY: deploy-scout
deploy-scout:
	@echo "→ Deploying Scout to $(SCOUT_DEST)..."
	@mkdir -p $(SCOUT_DEST)
	@rsync -av --delete \
		--exclude='.git' \
		--exclude='*.py' \
		$(SCOUT_SRC)/ $(SCOUT_DEST)/
	@echo "✓ Scout deployed to $(SCOUT_DEST)"
	@echo "  → Reload the extension in Chrome: chrome://extensions (click refresh)"

# ── Utilities ─────────────────────────────────────────────────────────────────

.PHONY: status
status:
	@echo "=== Running containers ==="
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

.PHONY: health
health:
	@echo "=== Gateway health ==="
	@curl -sf http://localhost:5001/health | python3 -m json.tool || echo "✗ Gateway unreachable"
	@echo ""
	@echo "=== Agent health ==="
	@curl -sf http://localhost:5002/health | python3 -m json.tool || echo "✗ Agent unreachable"

.PHONY: logs
logs:
	@echo "Tailing all logs (Ctrl+C to stop)..."
	@docker compose \
		-f $(AGENT_DIR)/docker-compose.yml \
		-f $(GATEWAY_DIR)/docker-compose.yml \
		logs -f 2>/dev/null || \
	(cd $(AGENT_DIR) && docker compose logs -f &) && \
	(cd $(GATEWAY_DIR) && docker compose logs -f)

# ── Help ──────────────────────────────────────────────────────────────────────

.PHONY: help
help:
	@echo ""
	@echo "my-business service management"
	@echo ""
	@echo "  make up              Start everything"
	@echo "  make down            Stop everything"
	@echo "  make restart         Restart everything"
	@echo "  make build           Rebuild all images"
	@echo "  make deploy          Full rebuild + restart + scout deploy"
	@echo ""
	@echo "  make up-agent        Start agentic system"
	@echo "  make up-gateway      Start gateway"
	@echo "  make down-agent      Stop agentic system"
	@echo "  make down-gateway    Stop gateway"
	@echo "  make restart-agent   Restart agentic system"
	@echo "  make restart-gateway Restart gateway"
	@echo "  make build-agent     Rebuild agentic system image"
	@echo "  make build-gateway   Rebuild gateway image"
	@echo ""
	@echo "  make deploy-scout    Copy scout to ~/Documents/scout"
	@echo "  make logs-agent      Tail agentic system logs"
	@echo "  make logs-gateway    Tail gateway logs"
	@echo "  make status          Show running containers"
	@echo "  make health          Check health endpoints"
	@echo ""
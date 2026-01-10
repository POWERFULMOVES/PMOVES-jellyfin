# PMOVES-Jellyfin Makefile - Hardened Architecture
# Dual-mode operation: standalone or docked to PMOVES.AI

SHELL := /bin/bash
.SHELLFLAGS := -ec

# Docker compose command
COMPOSE ?= $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

# Image names
DOCKERHUB_IMAGE := powerfulmoves/pmoves-jellyfin
GHCR_IMAGE := ghcr.io/powerfulmoves/pmoves-jellyfin
VERSION ?= pmoves-latest

# Build platforms
PLATFORMS := linux/amd64,linux/arm64

.PHONY: help up down restart logs build push status clean install check test

help:
	@echo "PMOVES-Jellyfin Commands"
	@echo "========================"
	@echo "  make up          - Start Jellyfin (standalone mode)"
	@echo "  make down        - Stop Jellyfin"
	@echo "  make restart     - Restart Jellyfin"
	@echo "  make logs        - View logs"
	@echo "  make status      - Check service status"
	@echo "  make build       - Build Docker image"
	@echo "  make push        - Build and push multi-arch image"
	@echo "  make clean       - Remove containers and volumes"
	@echo "  make install     - Setup environment"
	@echo "  make check       - Verify configuration"

# Check environment
check:
	@echo "Checking environment..."
	@docker --version > /dev/null 2>&1 || { echo "✗ Docker not found"; exit 1; }
	@$(COMPOSE) version > /dev/null 2>&1 || { echo "✗ Docker Compose not found"; exit 1; }
	@echo "✓ Environment OK"

# Install/setup
install: check
	@echo "Setting up PMOVES-Jellyfin..."
	@test -f .env || cp .env.example .env
	@echo "✓ Configuration created (.env)"
	@mkdir -p media
	@echo "✓ Media directory created (media/)"
	@echo "Edit .env file to configure your settings"

# Start service
up: check
	@echo "Starting PMOVES-Jellyfin..."
	@$(COMPOSE) up -d
	@echo "✓ Jellyfin started"
	@echo "  Web UI: http://localhost:8096"

# Stop service
down:
	@echo "Stopping PMOVES-Jellyfin..."
	@$(COMPOSE) down
	@echo "✓ Jellyfin stopped"

# Restart service
restart: down up

# View logs
logs:
	@$(COMPOSE) logs -f jellyfin

# Check status
status:
	@echo "PMOVES-Jellyfin Status:"
	@$(COMPOSE) ps jellyfin

# Build image
build:
	@echo "Building PMOVES-Jellyfin image..."
	@docker build \
		--build-arg JELLYFIN_UPSTREAM=${JELLYFIN_UPSTREAM:-ghcr.io/jellyfin/jellyfin:latest} \
		-t $(DOCKERHUB_IMAGE):$(VERSION) \
		-t $(GHCR_IMAGE):$(VERSION) \
		.
	@echo "✓ Build complete"
	@echo "  Images tagged:"
	@echo "    - $(DOCKERHUB_IMAGE):$(VERSION)"
	@echo "    - $(GHCR_IMAGE):$(VERSION)"

# Build and push multi-arch
push: buildx-prepare
	@echo "Building and pushing multi-arch image..."
	@docker buildx build \
		--platform $(PLATFORMS) \
		--build-arg JELLYFIN_UPSTREAM=${JELLYFIN_UPSTREAM:-ghcr.io/jellyfin/jellyfin:latest} \
		--progress=plain \
		-t $(DOCKERHUB_IMAGE):$(VERSION) \
		-t $(GHCR_IMAGE):$(VERSION) \
		--push \
		.
	@echo "✓ Multi-arch push complete"

# Buildx helpers
buildx-prepare:
	@docker buildx inspect multi-platform-builder >/dev/null 2>&1 || \
		docker buildx create --use --name multi-platform-builder --driver docker-container
	@docker buildx use multi-platform-builder

# Clean up
clean:
	@echo "Cleaning up PMOVES-Jellyfin..."
	@$(COMPOSE) down -v
	@docker volume rm ${VOLUME_PREFIX:-jellyfin}_config ${VOLUME_PREFIX:-jellyfin}_cache 2>/dev/null || true
	@echo "✓ Cleanup complete"

# Health check
test:
	@echo "Testing PMOVES-Jellyfin..."
	@curl -fSs http://localhost:8096/health > /dev/null && echo "✓ Health check passed" || echo "✗ Health check failed"

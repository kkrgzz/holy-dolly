include .env
export

CORE_SERVICES     := paperless-ngx miniflux syncthing filebrowser firefly
OPTIONAL_SERVICES := immich uptime-kuma n8n

.PHONY: all init up up-all down down-all restart status logs help

all: init up

# =============================================================================
# INITIALIZATION (run once after cloning)
# =============================================================================
init:
	@echo "==> Creating directories..."
	@# SSD — fast storage for databases and app state
	@sudo mkdir -p \
		$(DATA_ROOT)/paperless/redis \
		$(DATA_ROOT)/paperless/pgdata \
		$(DATA_ROOT)/paperless/data \
		$(DATA_ROOT)/miniflux/db \
		$(DATA_ROOT)/syncthing/config \
		$(DATA_ROOT)/filebrowser \
		$(DATA_ROOT)/firefly/db \
		$(DATA_ROOT)/firefly/upload \
		$(DATA_ROOT)/immich/pgdata \
		$(DATA_ROOT)/immich/model-cache \
		$(DATA_ROOT)/uptime-kuma \
		$(DATA_ROOT)/n8n/pgdata \
		$(DATA_ROOT)/n8n/data
	@# HDD — bulk storage for documents, media, photos
	@sudo mkdir -p \
		$(HDD_ROOT)/paperless/consume \
		$(HDD_ROOT)/paperless/media \
		$(HDD_ROOT)/paperless/export \
		$(HDD_ROOT)/immich/upload
	@sudo touch $(DATA_ROOT)/filebrowser/filebrowser.db
	@sudo touch $(DATA_ROOT)/filebrowser/settings.json
	@sudo chown -R $(PUID):$(PGID) \
		$(DATA_ROOT) \
		$(HDD_ROOT)/paperless \
		$(HDD_ROOT)/immich
	@sudo chmod -R 755 \
		$(DATA_ROOT) \
		$(HDD_ROOT)/paperless \
		$(HDD_ROOT)/immich
	@echo "==> Done. Copy .env.template to .env and fill in your values."

# =============================================================================
# CORE SERVICES
# =============================================================================
up:
	@echo "==> Starting core services..."
	@for svc in $(CORE_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml up -d; \
	done

down:
	@echo "==> Stopping core services..."
	@for svc in $(CORE_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml down; \
	done

restart:
	@echo "==> Restarting core services..."
	@for svc in $(CORE_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml restart; \
	done

# =============================================================================
# ALL SERVICES (core + optional)
# =============================================================================
up-all:
	@echo "==> Starting all services..."
	@for svc in $(CORE_SERVICES) $(OPTIONAL_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml up -d; \
	done

down-all:
	@echo "==> Stopping all services..."
	@for svc in $(CORE_SERVICES) $(OPTIONAL_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml down; \
	done

# =============================================================================
# INDIVIDUAL SERVICE CONTROLS
# =============================================================================
up-%:
	@docker compose -f $*/docker-compose.yml up -d

down-%:
	@docker compose -f $*/docker-compose.yml down

restart-%:
	@docker compose -f $*/docker-compose.yml restart

logs-%:
	@docker compose -f $*/docker-compose.yml logs -f

update-%:
	@echo "==> Updating $*..."
	@docker compose -f $*/docker-compose.yml pull
	@docker compose -f $*/docker-compose.yml up -d
	@echo "==> $* updated."

reset-%:
	@echo "==> WARNING: This will destroy all data for $*. Press Ctrl+C to cancel, Enter to continue."
	@read _
	@docker compose -f $*/docker-compose.yml down -v
	@docker compose -f $*/docker-compose.yml up -d
	@echo "==> $* has been reset."

# =============================================================================
# UTILITIES
# =============================================================================
status:
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs:
	@for svc in $(CORE_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml logs --tail=20 2>/dev/null; \
	done

# =============================================================================
# HELP
# =============================================================================
help:
	@echo "Holy Dolly — Homelab Docker Stack"
	@echo ""
	@echo "SETUP:"
	@echo "  make init              Create all required directories on SSD and HDD"
	@echo ""
	@echo "CORE COMMANDS:"
	@echo "  make up                Start core services"
	@echo "  make down              Stop core services"
	@echo "  make restart           Restart core services"
	@echo "  make up-all            Start everything (core + optional)"
	@echo "  make down-all          Stop everything"
	@echo "  make status            Show running containers and ports"
	@echo "  make logs              Print recent logs from all core services"
	@echo ""
	@echo "SINGLE SERVICE:"
	@echo "  make up-<name>         Start one service"
	@echo "  make down-<name>       Stop one service"
	@echo "  make restart-<name>    Restart one service"
	@echo "  make logs-<name>       Follow logs live"
	@echo "  make update-<name>     Pull latest image and restart"
	@echo "  make reset-<name>      Wipe and restart (WARNING: deletes data!)"
	@echo ""
	@echo "CORE SERVICES:     $(CORE_SERVICES)"
	@echo "OPTIONAL SERVICES: $(OPTIONAL_SERVICES)"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make restart-miniflux"
	@echo "  make update-paperless-ngx"
	@echo "  make logs-firefly"
	@echo "  make up-immich"

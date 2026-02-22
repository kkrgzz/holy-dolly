# Load environment variables
include .env
export

# Default target
.PHONY: all
all: init up

# =============================================================================
# INITIALIZATION (Run once)
# =============================================================================
init:
	@echo "--- Initializing Directories & Permissions ---"
	@sudo mkdir -p $(DATA_ROOT)/filebrowser
	@sudo mkdir -p $(DATA_ROOT)/paperless/redis
	@sudo mkdir -p $(DATA_ROOT)/paperless/pgdata
	@sudo mkdir -p $(DATA_ROOT)/paperless/data
	@sudo mkdir -p $(DATA_ROOT)/paperless/media
	@sudo mkdir -p $(DATA_ROOT)/paperless/export
	@sudo mkdir -p $(DATA_ROOT)/miniflux/db
	@sudo mkdir -p $(DATA_ROOT)/syncthing/config
	@sudo mkdir -p $(DATA_ROOT)/jellyfin/config
	@sudo mkdir -p $(DATA_ROOT)/jellyfin/cache
	@sudo mkdir -p $(DATA_ROOT)/pihole/config
	@sudo mkdir -p $(DATA_ROOT)/pihole/dnsmasq
	@sudo mkdir -p $(MEDIA_ROOT)
	@sudo mkdir -p $(DOCS_ROOT)
	@sudo touch $(DATA_ROOT)/filebrowser/filebrowser.db
	@sudo touch $(DATA_ROOT)/filebrowser/settings.json
	@sudo chown -R $(PUID):$(PGID) $(DATA_ROOT) $(MEDIA_ROOT) $(DOCS_ROOT)
	@sudo chmod -R 755 $(DATA_ROOT) $(MEDIA_ROOT) $(DOCS_ROOT)
	@echo "--- Done ---"

network:
	@docker network inspect web_network >/dev/null 2>&1 || docker network create web_network

# =============================================================================
# ALL SERVICES
# =============================================================================
up: network
	@echo "--- Starting All Services ---"
	@docker compose -f paperless-ngx/docker-compose.yml up -d
	@docker compose -f miniflux/docker-compose.yml up -d
	@docker compose -f syncthing/docker-compose.yml up -d
	@docker compose -f filebrowser/docker-compose.yml up -d
	@docker compose -f jellyfin/docker-compose.yml up -d
	@docker compose -f pihole/docker-compose.yml up -d

down:
	@echo "--- Stopping All Services ---"
	@docker compose -f paperless-ngx/docker-compose.yml down
	@docker compose -f miniflux/docker-compose.yml down
	@docker compose -f syncthing/docker-compose.yml down
	@docker compose -f filebrowser/docker-compose.yml down
	@docker compose -f jellyfin/docker-compose.yml down
	@docker compose -f pihole/docker-compose.yml down

restart:
	@echo "--- Restarting All Services ---"
	@docker compose -f paperless-ngx/docker-compose.yml restart
	@docker compose -f miniflux/docker-compose.yml restart
	@docker compose -f syncthing/docker-compose.yml restart
	@docker compose -f filebrowser/docker-compose.yml restart
	@docker compose -f jellyfin/docker-compose.yml restart
	@docker compose -f pihole/docker-compose.yml restart

logs:
	@docker compose -f paperless-ngx/docker-compose.yml logs -f &
	@docker compose -f miniflux/docker-compose.yml logs -f &
	@docker compose -f syncthing/docker-compose.yml logs -f &
	@docker compose -f filebrowser/docker-compose.yml logs -f &
	@docker compose -f jellyfin/docker-compose.yml logs -f &
	@docker compose -f pihole/docker-compose.yml logs -f

reset:
	@echo "--- Resetting All Services (removing all volumes/data) ---"
	@docker compose -f paperless-ngx/docker-compose.yml down -v
	@docker compose -f miniflux/docker-compose.yml down -v
	@docker compose -f syncthing/docker-compose.yml down -v
	@docker compose -f filebrowser/docker-compose.yml down -v
	@docker compose -f jellyfin/docker-compose.yml down -v
	@docker compose -f pihole/docker-compose.yml down -v
	@make up
	@echo "--- All services have been reset with fresh data ---"

status:
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# =============================================================================
# INDIVIDUAL SERVICE CONTROLS
# =============================================================================
up-%: network
	@docker compose -f $*/docker-compose.yml up -d

down-%:
	@docker compose -f $*/docker-compose.yml down

restart-%:
	@docker compose -f $*/docker-compose.yml restart

logs-%:
	@docker compose -f $*/docker-compose.yml logs -f

reset-%:
	@echo "--- Resetting $* (removing all volumes/data) ---"
	@docker compose -f $*/docker-compose.yml down -v
	@if [ "$*" = "miniflux" ]; then \
		sudo rm -rf $(DATA_ROOT)/miniflux/db; \
		sudo mkdir -p $(DATA_ROOT)/miniflux/db; \
		sudo chown 999:$(PGID) $(DATA_ROOT)/miniflux/db; \
	fi
	@if [ "$*" = "paperless-ngx" ]; then \
		sudo rm -rf $(DATA_ROOT)/paperless/{redis,pgdata,data,media}; \
		sudo mkdir -p $(DATA_ROOT)/paperless/{redis,pgdata,data,media,export}; \
		sudo chown -R $(PUID):$(PGID) $(DATA_ROOT)/paperless; \
	fi
	@docker compose -f $*/docker-compose.yml up -d
	@echo "--- $* has been reset with fresh data ---"

# =============================================================================
# HELP
# =============================================================================
help:
	@echo "Holy Dolly - Simple Docker Stack Manager"
	@echo ""
	@echo "COMMON COMMANDS:"
	@echo "  make up                  - Start all services"
	@echo "  make down                - Stop all services"
	@echo "  make restart             - Restart all services"
	@echo "  make reset               - Reset ALL services (delete all data!)"
	@echo "  make status              - Show running containers"
	@echo "  make logs                - View all logs"
	@echo ""
	@echo "SINGLE SERVICE (replace % with service name):"
	@echo "  make up-%                - Start one service"
	@echo "  make down-%              - Stop one service"
	@echo "  make restart-%           - Restart one service"
	@echo "  make reset-%             - Reset service (delete all data and restart fresh)"
	@echo "  make logs-%              - View service logs"
	@echo ""
	@echo "Services: paperless-ngx, miniflux, syncthing, filebrowser, jellyfin, pihole"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make restart-syncthing   - Restart only Syncthing"
	@echo "  make reset-miniflux      - Fresh install of Miniflux (deletes data!)"
	@echo "  make logs-miniflux       - View Miniflux logs"
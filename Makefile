include .env
export

# =============================================================================
# SERVICE GROUPS
# Private machine: personal data — documents, finance, photos, files
# Public machine:  productivity tools — RSS, automation, notes
# =============================================================================
PRIVATE_SERVICES := paperless-ngx firefly filebrowser syncthing immich uptime-kuma kavita
PUBLIC_SERVICES  := miniflux n8n trilium
ALL_SERVICES     := $(PRIVATE_SERVICES) $(PUBLIC_SERVICES)

.PHONY: all setup \
        init-private init-public \
        up-private up-public up-all \
        down-private down-public down-all \
        restart-private restart-public \
        status logs help

# =============================================================================
# FIRST-TIME SETUP (run once after cloning)
# =============================================================================
setup:
	@bash setup.sh

# =============================================================================
# INITIALIZATION
# Run once per machine before starting services for the first time.
# init-private: private machine (creates SSD + HDD directories)
# init-public:  public machine  (creates SSD directories only)
# =============================================================================
init-private:
	@echo "==> Initializing private machine directories..."
	@sudo mkdir -p \
		$(DATA_ROOT)/paperless/redis \
		$(DATA_ROOT)/paperless/pgdata \
		$(DATA_ROOT)/paperless/data \
		$(DATA_ROOT)/syncthing/config \
		$(DATA_ROOT)/filebrowser \
		$(DATA_ROOT)/firefly/db \
		$(DATA_ROOT)/firefly/upload \
		$(DATA_ROOT)/immich/pgdata \
		$(DATA_ROOT)/immich/model-cache \
		$(DATA_ROOT)/uptime-kuma \
		$(DATA_ROOT)/kavita/config
	@sudo mkdir -p \
		$(HDD_ROOT)/paperless/consume \
		$(HDD_ROOT)/paperless/media \
		$(HDD_ROOT)/paperless/export \
		$(HDD_ROOT)/immich/upload \
		$(HDD_ROOT)/kavita/library
	@sudo touch $(DATA_ROOT)/filebrowser/filebrowser.db
	@sudo touch $(DATA_ROOT)/filebrowser/settings.json
	@sudo chown -R $(PUID):$(PGID) \
		$(DATA_ROOT) \
		$(HDD_ROOT)/paperless \
		$(HDD_ROOT)/immich \
		$(HDD_ROOT)/kavita
	@sudo chmod -R 755 \
		$(DATA_ROOT) \
		$(HDD_ROOT)/paperless \
		$(HDD_ROOT)/immich \
		$(HDD_ROOT)/kavita
	@echo "==> Done."

init-public:
	@echo "==> Initializing public machine directories..."
	@sudo mkdir -p \
		$(DATA_ROOT)/miniflux/db \
		$(DATA_ROOT)/n8n/pgdata \
		$(DATA_ROOT)/n8n/data \
		$(DATA_ROOT)/trilium
	@sudo chown -R $(PUID):$(PGID) $(DATA_ROOT)
	@sudo chmod -R 755 $(DATA_ROOT)
	@echo "==> Done."

# =============================================================================
# PRIVATE SERVICES
# =============================================================================
up-private:
	@echo "==> Starting private services..."
	@for svc in $(PRIVATE_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml up -d; \
	done

down-private:
	@echo "==> Stopping private services..."
	@for svc in $(PRIVATE_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml down; \
	done

restart-private:
	@echo "==> Restarting private services..."
	@for svc in $(PRIVATE_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml restart; \
	done

# =============================================================================
# PUBLIC SERVICES
# =============================================================================
up-public:
	@echo "==> Starting public services..."
	@for svc in $(PUBLIC_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml up -d; \
	done

down-public:
	@echo "==> Stopping public services..."
	@for svc in $(PUBLIC_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml down; \
	done

restart-public:
	@echo "==> Restarting public services..."
	@for svc in $(PUBLIC_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml restart; \
	done

# =============================================================================
# ALL SERVICES
# =============================================================================
up-all:
	@echo "==> Starting all services..."
	@for svc in $(ALL_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml up -d; \
	done

down-all:
	@echo "==> Stopping all services..."
	@for svc in $(ALL_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml down; \
	done

# =============================================================================
# INDIVIDUAL SERVICE CONTROLS
# Works with any service name, e.g: make logs-paperless-ngx
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
	@echo "==> WARNING: This will destroy all data for $*."
	@echo "==> Press Ctrl+C to cancel, or Enter to continue."
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
	@for svc in $(ALL_SERVICES); do \
		docker compose -f $$svc/docker-compose.yml logs --tail=20 2>/dev/null; \
	done

# =============================================================================
# HELP
# =============================================================================
help:
	@echo "Holy Dolly — Homelab Docker Stack"
	@echo ""
	@echo "FIRST TIME (run in order):"
	@echo "  make setup              Generate .env from template with random secrets"
	@echo "  make init-private       Create directories for the private machine"
	@echo "  make init-public        Create directories for the public machine"
	@echo ""
	@echo "PRIVATE MACHINE:"
	@echo "  make up-private         Start private services"
	@echo "  make down-private       Stop private services"
	@echo "  make restart-private    Restart private services"
	@echo ""
	@echo "PUBLIC MACHINE:"
	@echo "  make up-public          Start public services"
	@echo "  make down-public        Stop public services"
	@echo "  make restart-public     Restart public services"
	@echo ""
	@echo "ALL SERVICES:"
	@echo "  make up-all             Start everything"
	@echo "  make down-all           Stop everything"
	@echo "  make status             Show running containers and ports"
	@echo "  make logs               Print recent logs from all services"
	@echo ""
	@echo "SINGLE SERVICE:"
	@echo "  make up-<name>          Start one service"
	@echo "  make down-<name>        Stop one service"
	@echo "  make restart-<name>     Restart one service"
	@echo "  make logs-<name>        Follow logs live"
	@echo "  make update-<name>      Pull latest image and restart"
	@echo "  make reset-<name>       Wipe and restart (WARNING: deletes data!)"
	@echo ""
	@echo "PRIVATE:  $(PRIVATE_SERVICES)"
	@echo "PUBLIC:   $(PUBLIC_SERVICES)"
	@echo ""
	@echo "EXAMPLES:"
	@echo "  make restart-miniflux"
	@echo "  make update-paperless-ngx"
	@echo "  make logs-n8n"
	@echo "  make up-trilium"

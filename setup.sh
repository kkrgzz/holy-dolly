#!/usr/bin/env bash
# =============================================================================
# Holy Dolly — Setup Script
# Copies .env.template to .env and auto-generates all secrets.
# Run this once from the repo root before starting any services.
# =============================================================================

set -euo pipefail

TEMPLATE=".env.template"
ENV_FILE=".env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# Helpers
# =============================================================================

# Generate a 32-character alphanumeric string (safe in sed, safe in any config)
gen_secret() {
    openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32
}

# Replace a key's value in the .env file
set_env() {
    local key="$1"
    local value="$2"
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
}

# =============================================================================
# Checks
# =============================================================================

if ! command -v openssl &>/dev/null; then
    echo -e "${RED}Error: openssl is required but not installed.${NC}"
    echo "Install it with: sudo apt install openssl"
    exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
    echo -e "${RED}Error: $TEMPLATE not found.${NC}"
    echo "Run this script from the repository root."
    exit 1
fi

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Warning: $ENV_FILE already exists.${NC}"
    read -r -p "Overwrite it? All existing values will be lost. [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted. Your existing .env was not modified."
        exit 0
    fi
fi

# =============================================================================
# Copy template
# =============================================================================

cp "$TEMPLATE" "$ENV_FILE"
echo -e "${GREEN}✓ Copied $TEMPLATE → $ENV_FILE${NC}"

# =============================================================================
# Generate secrets
# =============================================================================

echo ""
echo -e "${BOLD}Generating secrets...${NC}"

set_env "PAPERLESS_DB_PASS"    "$(gen_secret)"
set_env "MINIFLUX_DB_PASS"     "$(gen_secret)"
set_env "MINIFLUX_ADMIN_PASS"  "$(gen_secret)"
set_env "FIREFLY_DB_PASS"      "$(gen_secret)"
set_env "FIREFLY_APP_KEY"      "$(gen_secret)"
set_env "IMMICH_DB_PASS"       "$(gen_secret)"
set_env "N8N_DB_PASS"          "$(gen_secret)"
set_env "N8N_ENCRYPTION_KEY"   "$(gen_secret)"
set_env "WALLABAG_DB_PASS"     "$(gen_secret)"
set_env "WALLABAG_SECRET"      "$(gen_secret)"

echo -e "${GREEN}✓ All secrets generated${NC}"

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  Setup complete!${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""
echo -e "Auto-generated (${GREEN}done${NC}):"
echo "  PAPERLESS_DB_PASS"
echo "  MINIFLUX_DB_PASS"
echo "  MINIFLUX_ADMIN_PASS"
echo "  FIREFLY_DB_PASS"
echo "  FIREFLY_APP_KEY"
echo "  IMMICH_DB_PASS"
echo "  N8N_DB_PASS"
echo "  N8N_ENCRYPTION_KEY"
echo "  WALLABAG_DB_PASS"
echo "  WALLABAG_SECRET"
echo ""
echo -e "Needs your input (${YELLOW}open .env and fill these in${NC}):"
echo "  PUID / PGID            → run: id"
echo "  TZ                     → e.g. Europe/Berlin"
echo "  DOMAIN                 → e.g. example.com"
echo "  HDD_ROOT               → e.g. /mnt/hdd"
echo "  SYNCTHING_HOSTNAME     → a recognizable name for this device"
echo "  FIREFLY_IMPORTER_TOKEN → generate after first Firefly III login"
echo ""
echo -e "${YELLOW}Important:${NC} Keep your .env file safe and backed up."
echo -e "           ${BOLD}N8N_ENCRYPTION_KEY${NC} is especially critical —"
echo -e "           losing it makes all n8n credentials permanently unreadable."
echo ""
echo -e "Next steps:"
echo "  1. nano .env          # fill in the fields listed above"
echo "  2. make init          # create data directories"
echo "  3. make up            # start core services"
echo ""

# Holy Dolly - Docker Stack

Self-hosted media and document management stack.

## Services

- **Paperless-NGX** - Document management (port 8000)
- **Miniflux** - RSS reader (port 9090)
- **Syncthing** - File synchronization (port 8384)
- **Filebrowser** - Web file manager (port 8081)
- **Jellyfin** - Media server (port 8096)

## Quick Start

### First Time Setup
```bash
make init    # Create directories and set permissions
make up      # Start all services
```

### Daily Usage
```bash
make status           # Check what's running
make logs             # View all logs (Ctrl+C to exit)
make restart          # Restart everything
make reset            # Fresh install (deletes ALL data!)
```

### Working with Individual Services

Start/stop/restart a single service:
```bash
make up-syncthing
make down-syncthing
make restart-syncthing
make reset-syncthing      # Fresh install (deletes data!)
make logs-syncthing
```

Works with: `paperless-ngx`, `miniflux`, `syncthing`, `filebrowser`, `jellyfin`

## Common Tasks

**Restart after config change:**
```bash
make restart-syncthing
```

**Fresh install after password change or corruption:**
```bash
make reset-miniflux      # Just Miniflux
make reset               # All services (nuclear option!)
```

**Check service status:**
```bash
make status
```

**View specific service logs:**
```bash
make logs-miniflux
```

**Stop everything:**
```bash
make down
```

## Troubleshooting

**Service won't start or keeps restarting?**
```bash
make logs-[service-name]    # Check logs for errors
docker ps -a                # See all containers including stopped ones
```

**Password authentication errors or corrupted database?**
```bash
make reset-miniflux         # Fresh install (deletes data!)
```

**Port conflicts?**
Edit the `docker-compose.yml` file in the service folder and change the port mapping.

**Need to completely reset everything?**
```bash
make reset                  # Nuclear option - fresh install of all services!
```

## File Locations

All data is stored in directories defined in `.env`:
- `DATA_ROOT` - Service configs and databases
- `MEDIA_ROOT` - Media files
- `DOCS_ROOT` - Documents

## Notes

- **Syncthing ports**: TCP 22002, UDP 22001 (modified for WSL2 compatibility)
- All services connect via `web_network` Docker network
- Services restart automatically on system reboot (`restart: unless-stopped`)

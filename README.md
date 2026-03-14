# Holy Dolly — Homelab Docker Stack

Personal self-hosted services running inside a Proxmox VM, accessed via Nginx Proxy Manager (NPM) on a gateway VM, secured with Tailscale.

## Architecture

```
Internet / Tailscale
        │
   Gateway VM
   ├── Nginx Proxy Manager  (reverse proxy + SSL)
   └── Tailscale            (secure remote access)
        │
   Docker VM  (this stack)
   ├── Paperless-NGX  :8000
   ├── Miniflux       :9090
   ├── Syncthing      :8384
   ├── Filebrowser    :8081
   ├── Firefly III    :8082
   └── Firefly Import :8083

   Proxmox LXC containers (not in this stack)
   ├── Pi-hole        (DNS ad blocking)
   └── Jellyfin       (media server)
```

## Services & Ports

Configure these in NPM as proxy hosts pointing to `<docker-vm-ip>:<port>`.

### Core Services

| Service | Port | Suggested Subdomain |
|---|---|---|
| Paperless-NGX | `8000` | `paperless.yourdomain.com` |
| Miniflux | `9090` | `miniflux.yourdomain.com` |
| Syncthing | `8384` | `syncthing.yourdomain.com` |
| Filebrowser | `8081` | `files.yourdomain.com` |
| Firefly III | `8082` | `firefly.yourdomain.com` |
| Firefly Importer | `8083` | `firefly-importer.yourdomain.com` |

### Optional Services

| Service | Port | Suggested Subdomain |
|---|---|---|
| Immich | `2283` | `photos.yourdomain.com` |
| Uptime Kuma | `3001` | `status.yourdomain.com` |

> Syncthing also needs ports **22000/tcp**, **22000/udp**, and **21027/udp** open on your firewall for device-to-device sync.

## Storage Layout

```
SSD (DATA_ROOT)                    — fast I/O, backed up by Proxmox PBS
├── paperless/
│   ├── pgdata/                    database
│   ├── redis/                     cache
│   └── data/                      full-text search index
├── miniflux/db/                   database
├── syncthing/config/              sync config
├── filebrowser/                   filebrowser database + settings
├── firefly/
│   ├── db/                        database
│   └── upload/                    attachments (small, financial — keep on SSD)
├── immich/
│   ├── pgdata/                    database
│   └── model-cache/               ML models for face detection
└── uptime-kuma/                   monitoring data

HDD (HDD_ROOT)                     — bulk storage, USB connected
├── paperless/
│   ├── consume/                   ← drop files here to import into Paperless
│   │                                (Syncthing can sync directly to this folder)
│   ├── media/                     processed documents
│   └── export/                    manual exports
└── immich/upload/                 photo and video library
```

## Setup

### 1. Clone and configure

```bash
git clone <repo-url> holy-dolly
cd holy-dolly
cp .env.template .env
nano .env   # fill in all values
```

### 2. HDD — ensure nofail in fstab

If your HDD is not listed in `/etc/fstab` or is missing `nofail`, the VM can
stall at boot if the USB drive is disconnected. Find your HDD UUID and add it:

```bash
# Find your HDD UUID
blkid

# Edit fstab
sudo nano /etc/fstab

# Add a line like this (replace UUID and /mnt/hdd with yours):
UUID=xxxx-xxxx  /mnt/hdd  ext4  defaults,nofail,x-systemd.device-timeout=5  0  2
```

### 3. Create directories

```bash
make init
```

### 4. Start services

```bash
make up          # core services only
make up-all      # core + optional (Immich, Uptime Kuma)
```

### 5. First-time service setup

**Firefly III** — generate the importer token:
1. Open Firefly III in browser
2. Go to Options → Profile → Personal Access Tokens → Create
3. Copy the token into `.env` as `FIREFLY_IMPORTER_TOKEN`
4. Restart: `make restart-firefly`

**Syncthing** — configure sync folders:
1. Open Syncthing web UI
2. Add a folder pointing to `/data/paperless/consume` — sync this from your phone/laptop to auto-import documents into Paperless
3. Add any other folders you want to sync under `/data/`

**Immich** — open `http://<host>:2283` and create your admin account on first boot.

**Uptime Kuma** — open `http://<host>:3001`, create your admin account, then add monitors for each service URL.

## Daily Commands

```bash
make status              # show running containers and ports
make up                  # start core services
make down                # stop core services
make up-all              # start everything
make down-all            # stop everything
make restart             # restart core services
make logs                # recent logs from all core services
```

## Single Service Commands

```bash
make up-<name>           # start
make down-<name>         # stop
make restart-<name>      # restart
make logs-<name>         # follow logs live (Ctrl+C to exit)
make update-<name>       # pull latest image and restart
make reset-<name>        # wipe data and restart (destructive!)
```

**Core:** `paperless-ngx` `miniflux` `syncthing` `filebrowser` `firefly`
**Optional:** `immich` `uptime-kuma`

```bash
# Examples
make restart-miniflux
make update-paperless-ngx
make logs-firefly
make up-immich
```

## Updating Services

Images are pinned to major versions (e.g. `postgres:16`, `fireflyiii/core:6`).
This prevents surprise breaking changes from auto-updates.

To update a single service to the latest version within its pinned major:

```bash
make update-paperless-ngx
```

To intentionally upgrade to a new major version, edit the `image:` tag in the
service's `docker-compose.yml`, then run `make update-<name>`.

> **Immich** is an exception — it updates frequently and recommends staying
> on the latest release. Pin `IMMICH_VERSION` in `.env` to a specific tag
> (e.g. `v1.130.0`) when you want to control when you upgrade.

## Troubleshooting

**Service won't start or keeps restarting**
```bash
make logs-<name>         # read the error message
docker ps -a             # check exit codes
```

**Database authentication error after changing a password in .env**
```bash
make reset-<name>        # wipe and recreate (loses data in that service!)
```

**Port already in use**
```bash
sudo ss -tlnp | grep <port>   # find what's using the port
# Then edit the port mapping in <service>/docker-compose.yml
```

**Paperless not importing files**
```bash
# Check that the consume directory is writable
ls -la $(HDD_ROOT)/paperless/consume
make logs-paperless-ngx
```

**Syncthing not syncing**
- Ensure ports 22000/tcp, 22000/udp, 21027/udp are open on your VM firewall
- Check the Syncthing web UI for connection errors

**HDD not mounted after reboot**
```bash
sudo mount -a            # attempt to mount all fstab entries
dmesg | tail -20         # check for USB/mount errors
```

**Immich ML is slow or spiking CPU**
- This is normal on first run — it indexes all your photos
- It is limited to 1 worker (`MACHINE_LEARNING_WORKERS=1`) to protect the mini PC
- Indexing runs in the background; the app remains usable during it

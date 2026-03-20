# Holy Dolly — Homelab Docker Stack

Personal self-hosted services running inside Proxmox VMs, accessed via Nginx Proxy Manager (NPM) and secured with Tailscale.

---

## Architecture

```
Internet / Tailscale
        │
        ├── Private Gateway VM          ├── Public Gateway VM
        │   └── NPM + Tailscale         │   └── NPM + Tailscale
        │           │                   │           │
        │   Private Docker VM           │   Public Docker VM
        │   (personal data)             │   (productivity tools)
        │   ├── Paperless-NGX  :8000    │   ├── Miniflux       :9090
        │   ├── Firefly III    :8082    │   ├── n8n            :5678
        │   ├── Firefly Import :8083    │   └── Trilium Notes  :8085
        │   ├── Filebrowser    :8081    │
        │   ├── Syncthing      :8384    │
        │   ├── Immich         :2283    │
        │   ├── Kavita         :5000    │
        │   └── Uptime Kuma    :3001    │
        │           │
        │   External USB HDD
        │   ├── paperless/consume/      ← drop zone for document import
        │   ├── paperless/media/        ← processed documents
        │   └── immich/upload/          ← photo and video library

Proxmox LXC containers (not in this stack)
├── Pi-hole    (DNS ad blocking)
└── Jellyfin   (media server)
```

---

## NPM Proxy Table

Configure each entry in NPM as a proxy host pointing to `<docker-vm-ip>:<port>`.

### Private Machine

| Service | Port | Suggested Subdomain |
|---------|------|---------------------|
| Paperless-NGX | `8000` | `paperless.yourdomain.com` |
| Firefly III | `8082` | `firefly.yourdomain.com` |
| Firefly Importer | `8083` | `firefly-importer.yourdomain.com` |
| Filebrowser | `8081` | `files.yourdomain.com` |
| Syncthing | `8384` | `syncthing.yourdomain.com` |
| Immich | `2283` | `photos.yourdomain.com` |
| Kavita | `5000` | `library.yourdomain.com` |
| Uptime Kuma | `3001` | `status.yourdomain.com` |

### Public Machine

| Service | Port | Suggested Subdomain |
|---------|------|---------------------|
| Miniflux | `9090` | `miniflux.yourdomain.com` |
| n8n | `5678` | `n8n.yourdomain.com` |
| Trilium Notes | `8085` | `notes.yourdomain.com` |
| Wallabag | `9091` | `read.yourdomain.com` |

> Syncthing also needs ports **22000/tcp**, **22000/udp**, and **21027/udp** open on your VM firewall for device-to-device sync.

---

## Storage Layout

```
VM disk  (DATA_ROOT=/opt/docker-data)
│  Regular directory on the VM filesystem — no mount needed.
│  Backed up automatically by Proxmox PBS with the VM snapshot.
│
├── paperless/pgdata/          PostgreSQL database
├── paperless/redis/           Redis cache
├── paperless/data/            Full-text search index
├── miniflux/db/               PostgreSQL database
├── syncthing/config/          Syncthing config
├── filebrowser/               Filebrowser database + settings
├── firefly/db/                MariaDB database
├── firefly/upload/            Financial attachments (small, critical — SSD)
├── immich/pgdata/             PostgreSQL database
├── immich/model-cache/        ML models for face/object detection
├── kavita/config/             SQLite DB, app config, JWT key
├── n8n/pgdata/                PostgreSQL database
├── n8n/data/                  Encryption keys, workflow files
├── trilium/                   Notes database
├── uptime-kuma/               Monitoring data
├── wallabag/db/               MariaDB database
└── wallabag/images/           Article thumbnails and cached images

External HDD  (HDD_ROOT=/mnt/hdd)
│  USB-connected bulk storage — private machine only.
│  Not covered by PBS. Back up critical data with rclone to cloud storage.
│
├── paperless/consume/         ← Drop files here to auto-import into Paperless
│                                (Syncthing on your phone syncs directly here)
├── paperless/media/           Processed document files
├── paperless/export/          Manual exports
├── immich/upload/             Photo and video library
└── kavita/library/            Manga, ebooks, and comics
    ├── manga/                 → Kavita library type: Manga
    ├── comics/                → Kavita library type: Comics
    ├── novels/                → Kavita library type: Book
    ├── textbooks/             → Kavita library type: Book
    └── manuals/               → Kavita library type: Book
```

---

## First Time Setup

### 1. Clone the repo

```bash
git clone <repo-url> holy-dolly
cd holy-dolly
```

### 2. Generate secrets

```bash
make setup
```

This copies `.env.template` → `.env` and generates all passwords and keys automatically.

Then open `.env` and fill in the fields the script lists as needing manual input:

```bash
nano .env
```

| Variable | What to set |
|----------|-------------|
| `PUID` / `PGID` | Run `id` — use your user's uid and gid |
| `TZ` | Your timezone, e.g. `Europe/Istanbul` |
| `DOMAIN` | Your domain, e.g. `example.com` |
| `HDD_ROOT` | Your HDD mount path, e.g. `/mnt/hdd` *(private machine only)* |
| `SYNCTHING_HOSTNAME` | A recognizable name for this device *(private machine only)* |
| `FIREFLY_IMPORTER_TOKEN` | Fill in after first Firefly login *(see below)* |

### 3. HDD fstab entry *(private machine only)*

Add `nofail` to your HDD's fstab entry so the VM boots normally even if the USB drive is disconnected:

```bash
# Find your HDD UUID
blkid

# Edit fstab
sudo nano /etc/fstab

# Add this line (replace UUID and path with yours):
UUID=xxxx-xxxx  /mnt/hdd  ext4  defaults,nofail,x-systemd.device-timeout=5  0  2

# Verify without rebooting
sudo mount -a
```

### 4. Create directories

```bash
# Private machine
make init-private

# Public machine
make init-public
```

### 5. Start services

```bash
# Private machine
make up-private

# Public machine
make up-public

# Everything (if running both on one machine)
make up-all
```

### 6. Post-start service setup

**Firefly III** — generate the importer token:
1. Open Firefly III in your browser
2. Options → Profile → Personal Access Tokens → Create new token
3. Copy the token into `.env` as `FIREFLY_IMPORTER_TOKEN`
4. `make restart-firefly`

**Syncthing** — configure sync folders:
1. Open the Syncthing web UI
2. Add a folder pointing to `/data/paperless/consume` and sync it from your phone/laptop
3. Files synced here are automatically picked up and imported by Paperless

**n8n** — open `http://<host>:5678` and create your owner account on first boot.
`N8N_ENCRYPTION_KEY` in `.env` encrypts all saved credentials — back it up. If lost, all stored credentials become unreadable.

**Trilium Notes** — open `http://<host>:8085` and create your account on first boot.

**Immich** — open `http://<host>:2283` and create your admin account on first boot.

**Kavita** — open `http://<host>:5000/registration` to create your admin account on first boot.
Go to **Settings → Libraries** and add one library per subdirectory, selecting the correct type:
- `/books/manga` → type **Manga**, `/books/comics` → type **Comics**
- `/books/novels`, `/books/textbooks`, `/books/manuals` → type **Book**

**Wallabag** — open `http://<host>:9091` and log in with `wallabag` / `wallabag`. **Change the password immediately.**
Once the app loads successfully, set `POPULATE_DATABASE: "false"` in [wallabag/docker-compose.yml](wallabag/docker-compose.yml) and run `make restart-wallabag`.
To connect Miniflux: open Miniflux → **Settings → Integrations → Wallabag** and enter your Wallabag URL and credentials.

**Uptime Kuma** — open `http://<host>:3001`, create your admin account, add monitors for each service. See [docs/uptime-kuma.md](docs/uptime-kuma.md) for the full guide.

---

## Daily Commands

```bash
make status              # show all running containers and ports

# Private machine
make up-private
make down-private
make restart-private

# Public machine
make up-public
make down-public
make restart-public

# Everything
make up-all
make down-all
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

**Private:** `paperless-ngx` `firefly` `filebrowser` `syncthing` `immich` `kavita` `uptime-kuma`
**Public:** `miniflux` `n8n` `trilium` `wallabag`

```bash
# Examples
make restart-miniflux
make update-paperless-ngx
make logs-n8n
make reset-trilium
```

---

## Updating Services

All images are pinned to specific versions. To update a service:

```bash
# 1. Check the project's releases page for the new version
# 2. Edit the image tag in the service's docker-compose.yml
# 3. Apply the update
make update-<name>
```

To find the currently running version:
```bash
docker inspect <container-name> | grep '"Image"'
```

> **Immich** updates very frequently. Pin `IMMICH_VERSION` in `.env` to a specific
> tag (e.g. `v1.130.0`) and update it intentionally rather than following `release`.

---

## Troubleshooting

**Service won't start or keeps restarting**
```bash
make logs-<name>         # read the error
docker ps -a             # check exit codes
```

**Database authentication error after changing a password in .env**
```bash
# The database still has the old password — wipe and recreate
make reset-<name>        # WARNING: deletes all data for that service
```

**Port already in use**
```bash
sudo ss -tlnp | grep <port>
# Edit the port in <service>/docker-compose.yml
```

**Filebrowser shows 403 / cannot create folders or upload**
```bash
# The HDD directories are owned by root — fix ownership for the whole HDD
sudo chown -R $PUID:$PGID $HDD_ROOT
sudo chmod -R 755 $HDD_ROOT
```
For new installs, `make init-private` handles this automatically.

**Paperless not importing files**
```bash
ls -la $HDD_ROOT/paperless/consume   # check permissions
make logs-paperless-ngx
```

**Syncthing not syncing**
- Ensure ports `22000/tcp`, `22000/udp`, `21027/udp` are open on the VM firewall
- Check the Syncthing web UI for connection errors

**HDD not mounted after reboot**
```bash
sudo mount -a            # mount all fstab entries
dmesg | tail -20         # check for USB/mount errors
```

**Uptime Kuma shows service as down**
- Use `http://host.docker.internal:<port>` as the monitor URL, not `localhost`
- Requires `extra_hosts: host.docker.internal:host-gateway` in the compose file (already set)

**Immich ML slow or spiking CPU on first run**
- Normal — it is indexing all photos for face/object detection
- Limited to 1 worker (`MACHINE_LEARNING_WORKERS=1`) to protect the mini PC
- Runs in the background; the app stays usable during indexing

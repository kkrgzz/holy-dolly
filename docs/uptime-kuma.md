# Uptime Kuma — Setup & Configuration Guide

Uptime Kuma monitors your services and sends you a notification when something
goes down (or comes back up). This guide covers everything specific to this stack.

---

## 1. First Boot

Start the service if you haven't already:

```bash
make up-uptime-kuma
```

Open `http://<docker-vm-ip>:3001` in your browser.

On first visit you will be prompted to create an **admin account**. Pick a strong
password — this is your only account. There is no "forgot password" flow without
CLI access.

---

## 2. Adding Monitors

Go to **Dashboard → Add New Monitor**.

### Monitor type

For web services, always use **HTTP(s)** — it checks the actual HTTP response
code, not just whether the port is open. Use **TCP Port** only for non-HTTP
services (e.g. database ports if you ever expose them).

### Heartbeat interval

**60 seconds** is a good default for a homelab. 30 seconds is fine too but
generates more log entries.

---

## 3. Monitors for This Stack

> **Important — do not use `localhost`**
> Uptime Kuma runs inside a Docker container. `localhost` inside that container
> refers to the container itself, not your VM. Use `host.docker.internal`
> instead — this resolves to the Docker host (your VM) from within any container.
> The `docker-compose.yml` for Uptime Kuma already configures this for you.

| Service | Type | URL | Expected Status |
|---|---|---|---|
| Paperless-NGX | HTTP(s) | `http://host.docker.internal:8000` | 200 |
| Miniflux | HTTP(s) | `http://host.docker.internal:9090` | 200 |
| Syncthing | HTTP(s) | `http://host.docker.internal:8384` | 200 |
| Filebrowser | HTTP(s) | `http://host.docker.internal:8081` | 200 |
| Firefly III | HTTP(s) | `http://host.docker.internal:8082` | 200 |
| Firefly Importer | HTTP(s) | `http://host.docker.internal:8083` | 200 |
| n8n | HTTP(s) | `http://host.docker.internal:5678` | 200 |
| Immich | HTTP(s) | `http://host.docker.internal:2283` | 200 |

**Friendly name** — use whatever you want, e.g. `Paperless`, `Firefly III`.

**Tags** — optional but useful. Create a `homelab` tag and assign it to all
monitors so you can filter them easily.

---

## 4. Notifications

Go to **Settings → Notifications → Setup Notification**.

Uptime Kuma supports many channels. The most useful ones for a homelab:

### Telegram (recommended)

1. Open Telegram and search for **@BotFather**
2. Send `/newbot` and follow the prompts — you'll receive a **Bot Token**
3. Start a chat with your new bot (send it any message)
4. Get your **Chat ID** by visiting:
   `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
   Look for `"chat":{"id":...}` in the response
5. In Uptime Kuma:
   - **Notification Type:** Telegram
   - **Bot Token:** paste your token
   - **Chat ID:** paste your chat ID
6. Click **Test** to confirm it works, then **Save**

### Email (SMTP)

- **Notification Type:** SMTP
- Fill in your mail server details (Gmail, Fastmail, your own server, etc.)
- Use an **app password** if using Gmail (not your main account password)

### After setting up a notification

Go back to each monitor, edit it, and assign the notification channel under
**Notifications**. By default new monitors have no notification assigned.

---

## 5. Status Page (optional)

A status page is a public (or private) page that shows all your monitors at a
glance — useful for checking at a glance from your phone.

1. Go to **Status Page → New Status Page**
2. Give it a name, e.g. `Homelab`
3. Add your monitors to it
4. Set it to **Private** if you don't want it publicly accessible
5. The status page is available at `http://<docker-vm-ip>:3001/status/<slug>`

You can proxy this through NPM with its own subdomain if you want to access it
via `https://status.yourdomain.com`.

---

## 6. Maintenance Windows

If you're doing planned maintenance (e.g. updating services, rebooting the VM),
create a maintenance window so you don't get flooded with false alerts.

Go to **Maintenance → Schedule Maintenance**:
- Set the time window
- Select the affected monitors
- Uptime Kuma will suppress alerts during this window

---

## 7. Troubleshooting

**Monitor shows "down" immediately after adding it**
- Make sure the service is actually running: `make status`
- Check that the port is correct and the service is responding:
  ```bash
  curl -I http://host.docker.internal:8000
  # or from the VM directly:
  curl -I http://localhost:8000
  ```
- Some services take 30–60 seconds to fully start after `make up`

**Not receiving notifications**
- Go to the monitor, click **Edit**, confirm a notification channel is assigned
- Use the **Test** button on the notification settings to verify the channel works
- Check that your bot token / chat ID are correct (Telegram)

**Uptime Kuma itself is down**
```bash
make logs-uptime-kuma    # check for errors
make restart-uptime-kuma
```

**Reset admin password** (if locked out)
```bash
docker exec -it uptime-kuma node extra/reset-password.js
```

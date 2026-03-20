# Wallabag — Setup Guide

Wallabag is a self-hosted read-it-later service. Save articles from the web,
strip the clutter, and read them cleanly — on any device. Integrates natively
with Miniflux so you can save feed articles with one click.

---

## 1. First Boot

Start the service:

```bash
make up-wallabag
```

Wait until the container is ready (watch for `wallabag is ready!` in the logs):

```bash
make logs-wallabag
```

---

## 2. Initialize the Database

The Docker image's automatic DB population is unreliable with MariaDB — the
schema must be created manually on the first install.

Run the installer inside the container:

```bash
docker exec -it wallabag php bin/console wallabag:install --env=prod -n
```

Fix file ownership (the installer runs as root — skipping this causes session errors):

```bash
docker exec -it wallabag chown -R nobody:nobody /var/www/wallabag
```

Restart to pick up the clean state:

```bash
make restart-wallabag
```

---

## 3. First Login

Open `http://<docker-vm-ip>:9091` in your browser.

Default credentials: `wallabag` / `wallabag`

**Change the password immediately** — go to the top-right menu → **Config → Change
your password**.

---

## 4. Miniflux Integration

Wallabag and Miniflux can be linked so you can save any article from your RSS
feed directly to Wallabag.

**In Wallabag** — create a dedicated API client:
1. Go to top-right menu → **API clients management → Create a new client**
2. Give it a name (e.g. `miniflux`) and save
3. Note the **Client ID** and **Client secret**

**In Miniflux** — go to **Settings → Integrations → Wallabag** and fill in:

| Field | Value |
|-------|-------|
| Wallabag URL | `https://wallabag.yourdomain.com` (or `http://<ip>:9091` locally) |
| Client ID | from the API client you created above |
| Client secret | from the API client you created above |
| Username | your Wallabag username |
| Password | your Wallabag password |

Click **Save** — you'll now see a **Save to Wallabag** option on every article.

---

## 5. Browser Extension & Mobile

- **Browser:** install the [wallabag companion](https://github.com/nicowillis/wallabag-companion) or the official [wallabagger](https://github.com/wallabag/wallabagger) extension
- **Android:** [wallabag for Android](https://play.google.com/store/apps/details?id=fr.ghostsector.wallabag.android) (official) or [Read You](https://github.com/Ashinch/ReadYou)
- **iOS:** [Silencia](https://apps.apple.com/app/silencia/id1544926073) or [Fiery Feeds](https://apps.apple.com/app/fiery-feeds-rss-reader/id1158763303)

Configure them to point to your Wallabag URL and log in with your credentials.

---

## 6. Upgrading

Wallabag is pinned to a specific version in `wallabag/docker-compose.yml`.
To upgrade:

1. Check the [Wallabag releases page](https://github.com/wallabag/wallabag/releases) for the new version
2. Update the image tag in `wallabag/docker-compose.yml`
3. Run:

```bash
make update-wallabag
docker exec -it wallabag php bin/console doctrine:migrations:migrate --env=prod --no-interaction
docker exec -it wallabag chown -R nobody:nobody /var/www/wallabag
make restart-wallabag
```

> The migration step applies any schema changes introduced by the new version.
> Always run it after an upgrade even if the release notes don't mention DB changes.

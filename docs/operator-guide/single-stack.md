---
title: "Single Stack"
sidebar_position: 10
kind: how-to
status: drafted
verified_against: null
lede: "Running one stack on one machine beyond the quickstart: its ports and keys, its backups, and upgrades."
---

The deployment option: [a single stack on one machine](../../deployment-options/one-machine/). Start it with the [quickstart](../quickstart/).

## Ports and keys

| Port | Service | Bound to |
|---|---|---|
| 8765 | API service (MCP and REST) | 127.0.0.1 |
| 8766 | Console | 127.0.0.1 |

To let other machines reach the API service:

1. Set `AUTH_ENABLED=true` and put at least one client key hash in `API_KEY_HASH_LIST` (see [client keys](../connecting-clients-and-operating/#client-keys)).
2. Add the overlay that publishes 8765 on every interface, in `.env`:

   ```bash
   COMPOSE_FILE=docker-compose.yml:docker-compose.open.yml
   ```

3. `docker compose up -d`. The overlay forces authentication on; the engine refuses to start without a key.

Rotate a key by adding the new hash, moving the client to the new key, then removing the old hash and restarting.

## Backups

Three things, kept apart from one another:

| Backup | What it is | Without it |
|---|---|---|
| The archive | The `ARCHIVE_DIR` folder, or the external bucket | No rebuild after the database is lost |
| The database's key volume (`ememory_tde_keys`) | The key that encrypts the database at rest | The database's files cannot be read |
| The archive encryption key | `ARCHIVE_KEY` in `local.env` | The archive's objects cannot be read |

Volume names carry the compose project's prefix; list them with `docker volume ls`. One way to copy a volume to a file:

```bash
docker run --rm -v <project>_ememory_tde_keys:/v:ro -v "$PWD":/b alpine tar czf /b/tde_keys.tgz -C /v .
```

Keep `local.env` (and `gateway.env`, if used) with the backups: they hold the database password, the client key hashes and the archive keys.

The database itself is rebuilt from the archive: an engine started on an empty database with the same archive settings restores it. See [archive and restore](../../durability/archive-and-restore/).

## Upgrades

1. Read the release notes for settings that changed.
2. Get the new compose files: download the new release of [everythingmemory/home](https://github.com/everythingmemory/home/releases), unpack it beside the old one, and copy across your `local.env` and any file you changed in `conf/`. Then `docker compose pull` fetches the images it pins.
3. `docker compose up -d`. The API service runs the database migrations when it starts.
4. Check `curl -s http://localhost:8765/health`.

Changing `EMBEDDING_MODEL` is not an upgrade but a new [embedding space](../../architecture/embedding-spaces/): every record is re-embedded in the background.

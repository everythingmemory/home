# Single Stack

Running one stack on one machine beyond the quickstart: its ports and keys, its backups, and upgrades.

The deployment option: [a single stack on one machine](../deployment-options/one-machine.md). Start it with the [quickstart](quickstart.md).

## Ports and keys

| Port | Service | Bound to |
|---|---|---|
| 8765 | API service (MCP and REST) | 127.0.0.1 |
| 8766 | Console | 127.0.0.1 |

To let other machines reach the API service:

1. Set `AUTH_ENABLED=true` in `.env` and create at least one client key with `./e.sh client-key create --label <name>`, which adds it to `conf/keys.yaml` (see [client keys](../configuration/authentication.md#client-keys)).
2. Add the overlay that publishes 8765 on every interface, in `.env`:

   ```bash
   COMPOSE_FILE=docker-compose.yml:docker-compose.open.yml
   ```

3. `docker compose up -d`. The overlay forces authentication on; the engine refuses to start without a key.

Rotate a key by creating a new one under a new label, restarting, moving the client to the new key, then deleting the old entry from `conf/keys.yaml` and restarting.

## Backups

Three things, kept apart from one another:

| Backup | What it is | Without it |
|---|---|---|
| The archive | The `ARCHIVE_DIR` folder, or the external bucket | No rebuild after the database is lost |
| The database's key volume (`ememory_tde_keys`) | The key that encrypts the database at rest | The database's files cannot be read |
| The archive encryption key | `ARCHIVE_KEY` in `.env` | The archive's objects cannot be read |

Volume names carry the compose project's prefix; list them with `docker volume ls`. One way to copy a volume to a file:

```bash
docker run --rm -v <project>_ememory_tde_keys:/v:ro -v "$PWD":/b alpine tar czf /b/tde_keys.tgz -C /v .
```

Keep `.env` and `conf/keys.yaml` (and `gateway.env`, if used) with the backups: they hold the database password, the archive keys and the client key hashes.

The database itself is rebuilt from the archive: an engine started on an empty database with the same archive settings restores it. See [archive and restore](../durability/archive-and-restore.md).

## Upgrades

1. Read the release notes for settings that changed.
2. Get the new compose files: download the new release of [everythingmemory/home](https://github.com/everythingmemory/home/releases), unpack it beside the old one, and copy across your `.env`, `conf/keys.yaml` and any other file you changed in `conf/`. From before 1.2.14, move these first: an old `S3_*` name or a non-empty `API_KEY_HASH_LIST` stops the engine starting, naming the replacement. Put the hashes into `conf/keys.yaml` and rename each `S3_*` setting to its `ARCHIVE_*` name (`S3_ACCESS_KEY` → `ARCHIVE_ACCESS_KEY`, `S3_SECRET_KEY` → `ARCHIVE_SECRET_KEY`, `S3_BUCKET` → `ARCHIVE_BUCKET`, `S3_ENDPOINT_URL` → `ARCHIVE_ENDPOINT_URL`, `S3_REGION` → `ARCHIVE_REGION`, `S3_KEY_PREFIX` → `ARCHIVE_PREFIX`); the engine names each one it finds. Then `docker compose pull` fetches the images it pins.
3. `docker compose up -d`. The API service runs the database migrations when it starts.
4. Check `curl -s http://localhost:8765/health`.

Changing `EMBEDDING_MODEL` is not an upgrade but a new [embedding space](../architecture/embedding-spaces.md): every record is re-embedded in the background.

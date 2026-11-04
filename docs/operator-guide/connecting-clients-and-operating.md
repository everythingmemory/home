---
title: "Connecting Clients and Operating the Stack"
sidebar_position: 9
kind: how-to
status: drafted
verified_against: null
lede: "Start the stack, know its ports, turn on client keys, connect agents and programs, open the console, and check health and logs."
---

## Start the stack

Fill in `local.env` from the settings template — at least `POSTGRES_PASSWORD`, `REDIS_PASSWORD`, `AUTH_ENABLED`, `ARCHIVE_DIR`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `ARCHIVE_KEY` and the `EMBEDDING_*` settings (the template pre-fills `POSTGRES_DB`, `POSTGRES_USER` and `S3_BUCKET`) — link it as `.env`, and start the stack with Docker Compose.

```bash
ln -s local.env .env
docker compose up -d
```

`docker compose up` refuses to start while a required setting is missing, and names it. Every setting: [configuration options](../../configuration/).

## Ports

| Port | Service | Bound to |
|---|---|---|
| 8765 | API service (MCP and REST) | 127.0.0.1 |
| 8766 | Console | 127.0.0.1 |

To try it, no key is needed: the template ships `AUTH_ENABLED=false`, and port 8765 — the only engine port published — binds 127.0.0.1, so only this machine reaches it. The database, the queue and the plugins are reachable only inside the stack. To reach the API service from other machines, add the overlay `docker-compose.open.yml`, which publishes 8765 on every interface and turns authentication on.

## Client keys

With `AUTH_ENABLED=false` (the template's value) every caller on this machine is accepted without a key. With `AUTH_ENABLED=true`, every caller except `/health` sends `Authorization: Bearer <key>`, and the engine holds only each key's SHA-256 hash, in `API_KEY_HASH_LIST`.

Mint one key per client, put its hash in `API_KEY_HASH_LIST` (comma-separated), and give the key to that client:

```bash
python3 -c "import hashlib,secrets; k='emem_'+secrets.token_urlsafe(32); print('key: ', k); print('hash:', hashlib.sha256(k.encode()).hexdigest())"
```

Every key is equal. Removing a hash revokes that key. With authentication on and no hash, the engine refuses to start. With authentication on, the [audit log](../../durability/the-audit-log/) records which key made each write.

## Connect clients

| Client | Where | Credential |
|---|---|---|
| An agent's MCP client | `http://localhost:8765/mcp` (streamable HTTP), or `/mcp/sse` | `Authorization: Bearer <key>` header, with authentication on |
| A program | `http://localhost:8765/api/v2/` (REST) | The same header |
| A change-feed subscriber | `http://localhost:8765/api/v1/feed` | The same header |
| `e.sh`, the command-line script | The REST API | `--api-key` or `EMEMORY_API_KEY` |

What an agent does once connected: [a walkthrough](../../agents-how-to/walkthrough/).

## The console

Open `http://127.0.0.1:8766/`. The console passes `/api` to the API service. With authentication on, you sign in once with a client key; the console's server holds it and sends it with each request, and the browser keeps only a session cookie.

## Health

```bash
curl http://localhost:8765/health
```

The reply's `status` is `healthy`, or `degraded` when the database is unreachable or the embedding width is not declared, cannot be read, or differs from what the endpoint returned (the reason under `embedding.state`). It names the pipeline and temporal profiles in force. `/health` needs no key.

## Logs

Every service logs to standard error.

```bash
docker compose logs -f ememory-api
```

The engine's log format is set in `conf/logging.yaml`.

---
title: "Quickstart"
sidebar_position: 1
kind: tutorial
status: drafted
verified_against: "core 1.2.8; the release download from everythingmemory/home arrives with the first release"
lede: "From nothing to an agent storing and finding a record, on one machine, in ten steps."
---

## Before you start

- **A container engine with Docker Compose 2.24.4 or later** (`docker compose version`): Docker Engine on Linux, or Docker Desktop or Colima on macOS. It is the only thing to install; the stack and its tools all run as containers.
- **Resources given to the container engine** (on macOS, the Docker Desktop or Colima VM settings): enough for the stack — [sizing](../sizing/) gives the memory each service is allowed and what the stack uses.
- `openssl` and `python3` for minting keys.

## Steps

1. **Get the stack files.** Download the latest release of [everythingmemory/home](https://github.com/everythingmemory/home/releases) and unpack it, or clone the repository, and run every step from its folder. It holds the compose files and `local.env.template`. Nothing is built: the compose file pulls the eMemory images from `ghcr.io/everythingmemory`, each pinned to the release by digest, and the third-party images (Postgres, the archive store, the job queue, the model gateway) from their own publishers, pinned the same way.

2. **Create the settings file.**

   ```bash
   cp local.env.template local.env
   ln -s local.env .env
   ```

3. **Set the database password.** Put the output in `local.env` as `POSTGRES_PASSWORD=`.

   ```bash
   openssl rand -hex 24
   ```

4. **Set the job queue password and the archive settings.** The archive is on by default, in the stack's own store on this machine, written to a folder you name. Make the folder, set `ARCHIVE_DIR` in `local.env` to its absolute path, then mint the queue password, the archive store's key pair and the archive's encryption key, and put each in `local.env`:

   ```bash
   mkdir -p "$HOME/ememory-data/archive"   # ARCHIVE_DIR (an absolute path)
   openssl rand -hex 24      # REDIS_PASSWORD
   openssl rand -hex 20      # S3_ACCESS_KEY
   openssl rand -hex 32      # S3_SECRET_KEY
   openssl rand -base64 32   # ARCHIVE_KEY
   ```

   The folder must exist before the stack starts; a missing one is refused, never created empty. On macOS with Docker Desktop, keep it under your home folder, which Docker Desktop shares by default. The folder survives `docker compose down -v`, and you back it up and move it with your own tools.

   Keep a copy of `ARCHIVE_KEY` in your password manager, never beside the archive folder: every archive object is encrypted with it, a lost key is an unreadable archive, and a key stored with the archive protects nothing. The S3 pair only lets the engine reach the store; `ARCHIVE_KEY` is what reads what is in it.

5. **Start the stack.**

   ```bash
   docker compose up -d
   ```

   The first start pulls the images, which takes a few minutes; later starts take seconds.

   A required setting that is missing stops the start and is named. Most are named by `docker compose up` itself. The archive settings are checked when the stack starts: `up` reports that `archive-store` or `archive-bucket` did not start or complete, the engine does not start, and `docker compose logs archive-store archive-bucket` names the missing key.

   Another eMemory stack already running on this machine? Give this one its own project name and ports: set `EMEMORY_PORT`, `CONSOLE_PORT` and `EMEMORY_NETWORK` in `local.env` (see the template) and start it with `docker compose -p <name> up -d`.

6. **Check health.**

   ```bash
   curl -s http://localhost:8765/health
   ```

   Expect `"status":"healthy"`, with `"embedding":{"model":"nomic-embed-text","width":768,"state":"ok"}`. Until every service is up it can answer `degraded`; give it a minute.

7. **Mint a client key** (needed once authentication is on; the template starts with it off, which is safe because the stack answers on this machine only). Put the hash in `API_KEY_HASH_LIST`, keep the key for the client. To turn authentication on, also set `AUTH_ENABLED=true`, then run `docker compose up -d` again so the stack picks up the change; a call without the key then gets `401`.

   ```bash
   python3 -c "import hashlib,secrets; k='emem_'+secrets.token_urlsafe(32); print('key: ', k); print('hash:', hashlib.sha256(k.encode()).hexdigest())"
   ```

8. **Connect an MCP client** to `http://localhost:8765/mcp` (streamable HTTP). With authentication on, add the header `Authorization: Bearer <key>`. In Claude Code, for example (other clients: [Claude integration](../claude-integration/), [ChatGPT and OpenAI](../chatgpt-openai-integration/), [OpenClaw](../openclaw-integration/), [other MCP clients](../other-mcp-clients/)):

   ```bash
   claude mcp add --transport http everythingmemory http://localhost:8765/mcp
   ```

9. **Store a record.** From the agent:

   ```text
   e_ingest {"content": "Acme's renewal is due on 1 March 2027. Sarah owns it.", "properties": ["org:Acme", "topic:renewal"]}
   ```

   Or over REST:

   ```bash
   curl -s -X POST http://localhost:8765/api/v2/ingest -H "Content-Type: application/json" \
     -d '{"content": "Acme'"'"'s renewal is due on 1 March 2027. Sarah owns it.", "properties": ["org:Acme", "topic:renewal"]}'
   ```

10. **Find it.**

    ```text
    e_gather {"action": "find", "query": "when is the Acme renewal due"}
    ```

    ```bash
    curl -s -X POST http://localhost:8765/api/v2/gather -H "Content-Type: application/json" \
      -d '{"action": "find", "query": "when is the Acme renewal due"}'
    ```

## Next

- What an agent does from here: [a walkthrough](../../agents-how-to/walkthrough/).
- Running it beyond a first try: [single stack](../single-stack/).
- Every setting: [configuration options](../../configuration/).
- Backing up or moving a memory to another machine: [bundles](../../governance/engine-identity-and-bundles/).
- The source code is available on request, under the Business Source License 1.1: [licence](../../reference/licence/).

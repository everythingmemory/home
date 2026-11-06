# Quickstart

From nothing to an agent storing and finding a record, on one machine, in nine steps.

## Before you start

- **A container engine with Docker Compose 2.24.4 or later** (`docker compose version`): Docker Engine on Linux, or Docker Desktop or Colima on macOS. It is the only thing to install besides `openssl` or `python3`; the stack runs as containers.
- **Resources given to the container engine** (on macOS, the Docker Desktop or Colima VM settings): enough for the stack — [sizing](sizing.md) gives the memory each service is allowed and what the stack uses.
- `openssl` or `python3`, for `./e.sh init`, and `python3`, for `./e.sh client-key create`.

### Colima on macOS

- On an Intel Mac with macOS 26, Homebrew needs the Command Line Tools first: `xcode-select --install`.
- Install with `brew install colima docker docker-compose`. Point Docker at Homebrew's Compose plugin in `~/.docker/config.json`; this is needed when Docker Desktop's link to the plugin is also present, or when brew cannot link the plugin:

  ```bash
  mkdir -p ~/.docker
  printf '{ "cliPluginsExtraDirs": ["%s/opt/docker-compose/lib/docker/cli-plugins"] }\n' "$(brew --prefix)" > ~/.docker/config.json
  ```

- Start the VM with room for the stack:

  ```bash
  colima start --vm-type vz --mount-type virtiofs --cpu 4 --memory 8 --disk 60
  ```

## Steps

1. **Get the stack files.** Download the latest release of [everythingmemory/home](https://github.com/everythingmemory/home/releases) and unpack it, or clone the repository, and run every step from its folder. It holds the compose files, the settings template `.env.example`, `conf/` and `e.sh`. Nothing is built: the compose file pulls the eMemory images from `ghcr.io/everythingmemory`, each pinned to the release by digest, and the third-party images (Postgres, the archive store, the job queue, the model gateway) from their own publishers, pinned the same way.

2. **Write the settings file.**

   ```bash
   ./e.sh init
   ```

   This writes `.env`, the stack's one settings file, from `.env.example`, with every password and key generated (see [the settings it writes](#the-settings-init-writes)). It makes the archive folder, `$HOME/ememory-data/archive`, and names it as `ARCHIVE_DIR`; to put the archive elsewhere, pass `--archive-dir` with an absolute path. It also starts `conf/keys.yaml`, the client-key registry, with no keys yet. It never overwrites an existing `.env`.

   The archive folder survives `docker compose down -v`, and you back it up and move it with your own tools. On macOS with Docker Desktop, keep it under your home folder, which Docker Desktop shares by default.

3. **Save `ARCHIVE_KEY`.** `init` prints it once. Put it in your password manager, never beside the archive folder: every archive object is encrypted with it, a lost key is an unreadable archive, and a key stored with the archive protects nothing.

4. **Start the stack.**

   ```bash
   docker compose up -d
   ```

   The first start pulls the images, which takes a few minutes; later starts take seconds.

   A required setting that is missing stops the start and is named. Most are named by `docker compose up` itself. The archive settings are checked when the stack starts: `up` reports that `archive-store` or `archive-bucket` did not start or complete, the engine does not start, and `docker compose logs archive-store archive-bucket` names the missing setting.

   Another eMemory stack already running on this machine? Give this one its own project name and ports: set `EMEMORY_PORT`, `CONSOLE_PORT` and `EMEMORY_NETWORK` in `.env` (see the template) and start it with `docker compose -p <name> up -d`.

5. **Check health.**

   ```bash
   curl -s http://localhost:8765/health
   ```

   Expect `"status":"healthy"`, with `"embedding":{"model":"nomic-embed-text","width":768,"state":"ok"}`. Until every service is up it can answer `degraded`; give it a minute.

6. **Create a client key** (needed once authentication is on; `.env` starts with it off, which is safe because the stack answers on this machine only).

   ```bash
   ./e.sh client-key create --label me
   ```

   It prints the key (`emem_…`) once and adds its entry — the label and the key's hash — to `conf/keys.yaml`. Keep the key for the client. To turn authentication on, set `AUTH_ENABLED=true` in `.env` and run `docker compose up -d` again so the stack picks up the change; a call without a key then gets `401`. A key with no scope opens everything; to confine one, see [client keys](../configuration/authentication.md#client-keys).

7. **Connect an MCP client** to `http://localhost:8765/mcp` (streamable HTTP). With authentication on, add the header `Authorization: Bearer <key>`. In Claude Code, for example (other clients: [Claude integration](claude-integration.md), [ChatGPT and OpenAI](chatgpt-openai-integration.md), [OpenClaw](openclaw-integration.md), [other MCP clients](other-mcp-clients.md)):

   ```bash
   claude mcp add --transport http everythingmemory http://localhost:8765/mcp
   ```

8. **Store a record.** (With authentication on, add `-H "Authorization: Bearer $EMEMORY_API_KEY"` to each REST example in steps 8 and 9, with your key in that variable.) From the agent:

   ```text
   e_ingest {"content": "Acme's renewal is due on 1 March 2027. Sarah owns it.", "properties": ["org:Acme", "topic:renewal"]}
   ```

   Or over REST:

   ```bash
   curl -s -X POST http://localhost:8765/api/v2/ingest -H "Content-Type: application/json" \
     -d '{"content": "Acme'"'"'s renewal is due on 1 March 2027. Sarah owns it.", "properties": ["org:Acme", "topic:renewal"]}'
   ```

9. **Find it.**

   ```text
   e_gather {"action": "find", "query": "when is the Acme renewal due"}
   ```

   ```bash
   curl -s -X POST http://localhost:8765/api/v2/gather -H "Content-Type: application/json" \
     -d '{"action": "find", "query": "when is the Acme renewal due"}'
   ```

## The settings init writes

`./e.sh init` fills these in `.env`; every other value comes from `.env.example` as it ships. To write `.env` by hand instead, copy `.env.example` to `.env` and set each one — the template has a one-line recipe beside it.

| Setting | What it is | Format |
|---|---|---|
| `POSTGRES_PASSWORD` | The database's password. Fixed into the database volume the first time the stack starts | Letters and digits; `init` writes 48 hex characters |
| `REDIS_PASSWORD` | The job queue's password, carried by the engine and every worker | Letters and digits; `init` writes 48 hex characters. A quote or backslash breaks the queue password, so do not add one by hand |
| `ARCHIVE_ACCESS_KEY`, `ARCHIVE_SECRET_KEY` | The login for the stack's own archive store, the `archive-store` service on this machine — not an Amazon account. Any pair becomes that store's one identity at start | Letters and digits; `init` writes 40 and 64 hex characters. A quote or backslash breaks the archive login, so do not add one by hand |
| `ARCHIVE_KEY` | The key every archive object is encrypted with (AES-256-GCM). Keep it in a password manager, apart from the archive | **Required:** 32 random bytes, base64-encoded |
| `ARCHIVE_DIR` | The host folder that holds the encrypted archive. It must exist before the stack starts; a missing one is refused, never created empty | An absolute path with no `.` or `..` in it |

## Reading the docs

- Online: [everythingmemory.ai/docs](https://everythingmemory.ai/docs/).
- In the release: the Markdown in `docs/`.
- Offline: each release carries the site as `site-html.tar.gz`. Unpack it and serve it on this machine, then open `http://localhost:8080/`:

  ```bash
  mkdir ememory-site && tar xzf site-html.tar.gz -C ememory-site && python3 -m http.server 8080 -d ememory-site
  ```

## Next

- What an agent does from here: [a walkthrough](../agents-how-to/walkthrough.md).
- Running it beyond a first try: [single stack](single-stack.md).
- Every setting: [configuration options](../configuration/index.md).
- Backing up or moving a memory to another machine: [bundles](../governance/engine-identity-and-bundles.md).
- The source code is available on request, under the Business Source License 1.1: [licence](../reference/licence.md).

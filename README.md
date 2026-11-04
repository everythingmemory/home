# Everything Memory

A store of facts that AI agents write and read. This repository holds the
quickstart — the compose file, its configuration and the env template — and
the documentation.

## Run it

Needs Docker with Docker Compose 2.24 or later. The images are public on the
GitHub Container Registry, for `linux/amd64` and `linux/arm64`.

```bash
git clone https://github.com/everythingmemory/home.git
cd home
cp local.env.template local.env     # then edit: the recipes are inside
mkdir -p /srv/ememory/archive       # the folder local.env names as ARCHIVE_DIR
docker compose --env-file local.env up -d
curl http://localhost:8765/health
```

The full install guide starts at [docs/operator-guide/quickstart.md](docs/operator-guide/quickstart.md).

Optional overlays: `docker-compose.folder.yml` (Folder Intake, which ingests a
folder you name) and `docker-compose.qdrant.yml` (Qdrant as the vector store).

## Agent plugin (Claude Code)

`plugins/ememory/` is the stock eMemory plugin for Claude Code: skills, an
orientation agent and session hooks for storing, finding and correcting
knowledge in a stack. This repository is its marketplace:

```bash
claude plugin marketplace add everythingmemory/home
claude plugin install ememory@everythingmemory
```

Or, inside Claude Code, run `/plugin` and pick it from the everythingmemory
marketplace.

## Licence

The files in this repository are licensed under the Apache License 2.0
([LICENSE](LICENSE)); the documentation in `docs/` under CC BY 4.0
([LICENSE-docs](LICENSE-docs)). The images they run are built from the
eMemory source, available on request. The engine, console, local-embed,
plugin-wordnet, plugin-chrono and chrono-engine images are under the Business
Source License 1.1; the command-line (cli) and Folder Intake images under the
Apache License 2.0. Each image's licence is in its
`org.opencontainers.image.licenses` label and inside the image at
`/licenses/LICENSE`.

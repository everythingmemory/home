# Everything Memory

A system of record for AI agents. Agents store what they learn as records and find it again by meaning, by property and by time — across sessions, agents and models. Every version is kept, every record carries where it came from, and it runs on your own infrastructure.

**Install:** follow the [quickstart](docs/operator-guide/quickstart.md) — it needs one container engine. **Docs:** [everythingmemory.ai/docs](https://everythingmemory.ai/docs/) (also in [`docs/`](docs/)). **Trial, source or a conversation:** [register](https://everythingmemory.ai/ememory/register/).

This repository holds what the quickstart runs — the compose files, their configuration, the settings template and `e.sh` — with the documentation and the agent plugin.

## Reading the docs

- Online: [everythingmemory.ai/docs](https://everythingmemory.ai/docs/).
- Here: the Markdown in [`docs/`](docs/).
- Offline: each release carries the site as `site-html.tar.gz`. Unpack it and serve it on this machine:

  ```bash
  mkdir ememory-site && tar xzf site-html.tar.gz -C ememory-site && python3 -m http.server 8080 -d ememory-site
  ```

  then open `http://localhost:8080/`.

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
eMemory source, which is available on request: [register](https://everythingmemory.ai/ememory/register/)
and choose "Source code". The engine, console, local-embed,
plugin-wordnet, plugin-chrono and chrono-engine images are under the Business
Source License 1.1; the command-line (cli) and Folder Intake images under the
Apache License 2.0. Each image's licence is in its
`org.opencontainers.image.licenses` label and inside the image at
`/licenses/LICENSE`.

# ememory — setup

Claude Code plugin for Everything Memory (eMemory). It assumes an eMemory stack is already running — for example one started with the quickstart, answering on `http://localhost:8765/mcp`.

## What's in it

```
ememory/
├── .claude-plugin/plugin.json   plugin manifest
├── CLAUDE.md                    standing instructions (printed at session start by the hooks)
├── hooks/hooks.json             session start / resume / compact: CLAUDE.md plus a reminder
├── agents/e-orient.md           orientation agent
├── skills/
│   ├── e-orient                 session-start survey
│   ├── e-store                  storing facts, adjustments, updates
│   ├── e-retrieve               finding and reading, past states, provenance
│   ├── e-correct                corrections and deletion
│   ├── e-properties             labels, relations, property hygiene
│   └── e-doctor                 connection troubleshooting
├── .mcp.json.example            connection template
└── marketplace.example.json     copy of the marketplace manifest (the live one is .claude-plugin/marketplace.json at the repository root)
```

## 1. Install the plugin

In Claude Code:

```
/plugin marketplace add everythingmemory/home
/plugin install ememory@everythingmemory
```

## 2. Connect to your stack

The connection is yours to configure; the plugin does not ship one. The URL is your engine's address (`http://localhost:8765/mcp` for the quickstart on this machine).

Copy `.mcp.json.example` from this plugin to `.mcp.json` in your project. When the engine has authentication on, set `EMEMORY_API_KEY` in your environment to your client key; when it is off, delete the `headers` block.

Or add the server with `claude mcp add`. Authentication off (the quickstart default):

```bash
claude mcp add --transport http everythingmemory http://localhost:8765/mcp
```

Authentication on — send your client key:

```bash
claude mcp add --transport http everythingmemory http://localhost:8765/mcp \
  --header "Authorization: Bearer <client key>"
```

Restart Claude Code after connecting; MCP servers are read at session start.

## 3. Standing instructions

Claude Code does not load a plugin's `CLAUDE.md` by itself, so this plugin's session hooks print it at startup, on resume and after compaction. Nothing to copy.

## 4. Check it

Start a session and ask: "What does eMemory know?" Claude should call `e_property(action="list")` and answer from eMemory. Then:

- Tell it a fact → it stores it with `e_ingest` and properties.
- Ask about that fact → it searches eMemory before answering.
- Say "no, that's wrong" → it records a correction with `e_correct`.

Anything failing: ask Claude to run `e-doctor`.

To stop permission prompts on every call, allow `mcp__everythingmemory__*` in your Claude Code settings.

## Licence

Apache-2.0.

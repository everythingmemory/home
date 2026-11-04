# ememory-core — setup

Claude Code plugin for Everything Memory (eMemory). It assumes an eMemory stack is already running — for example one started with the quickstart, answering on `http://localhost:8765/mcp`.

## What's in it

```
ememory-core/
├── .claude-plugin/plugin.json   plugin manifest
├── CLAUDE.md                    standing instructions (see step 3)
├── hooks/hooks.json             session start / resume / compact reminders
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
/plugin install ememory-core@everythingmemory
```

## 2. Connect to your stack

The connection is yours to configure; the plugin does not ship one.

Authentication off (the quickstart default):

```bash
claude mcp add --transport http everythingmemory http://localhost:8765/mcp
```

Authentication on — send your client key:

```bash
claude mcp add --transport http everythingmemory http://localhost:8765/mcp \
  --header "Authorization: Bearer <client key>"
```

Or copy `.mcp.json.example` to `.mcp.json` in your project and set `EMEMORY_API_KEY` in your environment (drop the `headers` block when authentication is off). Use your stack's URL if it isn't on this machine.

Restart Claude Code after connecting; MCP servers are read at session start.

## 3. Load the standing instructions

Claude Code does not load a plugin's `CLAUDE.md` by itself. Copy the contents of this plugin's `CLAUDE.md` into your project's `CLAUDE.md` (or `~/.claude/CLAUDE.md` for every project).

## 4. Check it

Start a session and ask: "What does eMemory know?" Claude should call `e_property(action="list")` and answer from eMemory. Then:

- Tell it a fact → it stores it with `e_ingest` and properties.
- Ask about that fact → it searches eMemory before answering.
- Say "no, that's wrong" → it records a correction with `e_correct`.

Anything failing: ask Claude to run `e-doctor`.

To stop permission prompts on every call, allow `mcp__everythingmemory__*` in your Claude Code settings.

## Licence

Apache-2.0.

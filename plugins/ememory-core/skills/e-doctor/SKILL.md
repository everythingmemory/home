---
name: e-doctor
description: Diagnose and fix the connection between Claude Code and an eMemory stack — first-time setup and tools that stop responding.
when_to_use: When eMemory tools are missing, return connection errors, 401s or timeouts, or when the user asks for help connecting eMemory.
---

## Gate: call the tool, twice

```
e_property(action="list")
```

Returns (even empty) → connected; say so and stop. Fails → call it once more; one failure (cold start) is not a diagnosis. Re-test every time doctor runs.

## Tools missing entirely

The MCP server isn't configured, or the session started before it was.

- `claude mcp list` — is `everythingmemory` there, and connected?
- Add it: `claude mcp add --transport http everythingmemory http://localhost:8765/mcp`
  - With authentication on, add `--header "Authorization: Bearer <client key>"`.
- MCP config is read at session start: restart the session after any change.

## Tools present but failing

Walk in order; one fix at a time, re-test after each.

1. Engine running? `docker compose ps` in the stack's folder.
2. Health: `curl -s http://localhost:8765/health` → expect `"status":"healthy"`. `degraded` right after a start: wait a minute.
3. Logs: `docker compose logs --tail=50`

| Symptom | Likely cause | Fix |
|---|---|---|
| Connection refused | Stack down, or another port | `docker compose up -d`; check `EMEMORY_PORT` in `local.env` |
| 401 Unauthorized | Authentication on, key missing or wrong | Send `Authorization: Bearer <client key>`; its hash must be in `API_KEY_HASH_LIST` |
| `up` stops naming a setting | A required setting is unset | Set it in `local.env`, `docker compose up -d` |
| `archive-bucket didn't complete` | Archive setting missing, or `ARCHIVE_DIR` folder absent | `docker compose logs archive-bucket`; create the folder |
| Embedding not `ok` in health | Model still loading | Wait; check the logs |
| Restart loop / OOM | Too little memory for the container engine | Give it at least 4 GB |
| Permission prompt on every call | No allow rule | Allow `mcp__<server name>__*` (name from the tool prefix) |

A stack on another machine: same steps, with its URL and key; ask its operator about anything server-side.

## Rules

- Never read, print or store secrets (`local.env`, keys). The user edits them.
- Read the server name from the tool prefix (`mcp__<name>__e_gather`); don't assume it.
- Don't disable the built-in memory; the two coexist.
- Two failed diagnostic steps with no progress → stop, report the exact error text, hand back to the user.

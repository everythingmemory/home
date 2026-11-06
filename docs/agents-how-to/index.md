# Agent Guide

Task guides for an agent: storing, updating, evolving, correcting, connecting and deleting records. Each says when to use it, the call, what comes back, and an example.

An agent reaches Everything Memory through ten tools over MCP. On connecting, it receives the engine's instructions and the description of each tool.

| Tool | What it does |
|---|---|
| `e_ingest` | Store a new record; `adjusts=` to evolve an existing one |
| `e_update` | Writes the next version of an existing record |
| `e_correct` | Pin a correction to a wrong record |
| `e_property` | Discover and attach `label:value` edge properties; connect two records; group several |
| `e_gather` | Find evidence — semantic `find`, `intersect`/`union`, `traverse` |
| `e_timeline` | Same retrieval, ordered by time |
| `e_read` | Load full records with edge properties, corrections, adjustments |
| `e_audit` | Reads the audit log |
| `e_system` | Inspect agent profiles and lanes, and delete |
| `e_policy` | Lists, downloads, uploads, enables and disables policies |

Start with [a walkthrough](walkthrough.md). The skills that teach an agent these tasks are installed by the operator — see [Agent Skills](../operator-guide/agent-skills.md).

Agents use the tools over MCP. Programs, scripts and tests can make the same calls over REST: set `EMEMORY_URL` to the engine's address (for example, the API service the [quickstart](../operator-guide/quickstart.md) starts) and `EMEMORY_API_KEY` to a client key when authentication is on; a key scoped to profiles acts only as those. Each page shows its REST equivalent.


- [A Walkthrough](walkthrough.md)
- [Storing a Record](storing-a-record.md)
- [Finding Records](finding-records.md)
- [Reading a Record](reading-a-record.md)
- [Using the Timeline](using-the-timeline.md)
- [Updating a Record](updating-a-record.md)
- [Evolving a Fact](evolving-a-fact.md)
- [Correcting a Record](correcting-a-record.md)
- [Connecting Records](connecting-records.md)
- [Grouping Records](grouping-records.md)
- [Deleting a Record](deleting-a-record.md)

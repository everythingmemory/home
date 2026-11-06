# Agent Skills

The stock skills teach an agent to use the tools well: when to store, how to choose edge properties, when to correct and when to adjust, and how to orient at the start of a session. They ship as a Claude Code plugin, and their text can be given to any agent.

## What the skills are

The tools say what an agent can do; the skills say how to do it well. Each skill is a page of guidance an agent reads when the task calls for it: how to decompose what it learned into records, which edge properties to reuse, how to search and read before relying on what it was trained on, and how to tell a correction from an adjustment.

The engine does not need the skills to run. Without them an agent still has the instructions and tool descriptions the engine hands it over MCP.

## The core skills

| Skill | Teaches the agent to |
|---|---|
| `e-orient` | Check its lanes and write schema *before* storing — so facts land in the right place; survey recent activity, active corrections and project context at session start |
| `e-store` | Split a thought into standalone records and tag them with reusable edge properties |
| `e-retrieve` | Gather → read before reasoning, and trust quartiles over raw distance |
| `e-correct` | Make the wrong/evolved call — `correct` vs. `adjust` — instead of duplicating |
| `e-properties` | Reuse the existing vocabulary instead of inventing a new label every time |
| `e-doctor` | Diagnose connection, auth, and profile issues on its own |
| `e-file-upload` | Store a file verbatim, so it can be retrieved later as the same file, possibly by another agent |
| `e-file-download` | Reassemble a stored file from its parts and deliver it back |

Toolkit alone: a database. Toolkit plus skills: an agent that knows how to remember, and a structure that builds itself. Start with the tools to see it work; add the skills to watch it cohere.

The plugin also carries:

- **An orientation agent**, `e-orient`, which surveys memory to restore situational awareness at session start or after the context is compacted.
- **Session-start hooks**, which, when a session starts, resumes or is compacted, remind the agent to load the edge-property vocabulary, its standing directives and its session context from memory.

## Installing them

In Claude Code, install the skills as a plugin from the eMemory repository:

```bash
claude plugin marketplace add everythingmemory/home
claude plugin install ememory@everythingmemory
```

Or, inside Claude Code, run `/plugin` and pick `ememory` from the `everythingmemory` marketplace. Installing eMemory never installs the plugin; it is your choice.

Then connect the agent to the API service; see [connecting clients](connecting-clients-and-operating.md).

## Other agents and harnesses

Every agent that connects over MCP receives the engine's instructions and the description of each tool, whatever its harness. For a harness without plugins, give the agent the skills' text as part of its instructions.

## Licence

The skills, the orientation agent and the hooks are licensed under the Apache License 2.0. See [licence](../reference/licence.md).

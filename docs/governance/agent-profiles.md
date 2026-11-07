# Agent Profiles

An owner running many agents on one engine needs to say, in one place, where each agent writes and what it reads, rather than telling every agent separately. An agent profile, declared in a policy, gives an agent a home lane and read and write grants on other lanes; the engine holds every call to the lanes of the profile it names, and to those lanes' source types; an agent can ask for its own map of writable lanes, source types and labels; and two profiles, open and restricted, ship ready on a new engine.

Challenges addressed: [Auditable Decision-Making](../use-cases/auditing-agentic-decisions.md), [Multi-Agent Coordination](../use-cases/agent-swarm-coordination.md).

## Concepts

An agent's **agent profile** is its map of the workspace. It names a `home_lane` plus per-lane read and write grants — which lanes it may work within, and what it may do in each; each lane in turn declares the [source types](source-types.md), and label vocabulary, it can hold. Together they hand the agent a clear picture: which lanes it can reach, and what kinds of source records each one contains and accepts. The engine enforces that agent profile's lanes on every call: reads and writes land only where it grants them, and only as the lane's source types allow. One eMemory, many agents — each with its own map. Agent profiles are declared in a [policy](policies.md).

| Setting | Effect |
|---|---|
| `home_lane` | Readable and writable. Records go here unless the call names another lane |
| `can_read_other_lanes` | More lanes the agent may read |
| `can_write_other_lanes` | More lanes the agent may write |
| `can_read_any_lane`, `can_write_any_lane` | Every lane a policy declares |

In a policy, the grants and the home lane name lanes as written in the document — a name, a qualified label or a UUID. The engine resolves each to one lane UUID: first among the lanes this policy declares, then among every lane the engine holds. A name that matches more than one is refused; name it with its qualified label or its UUID. See [lane labels](lanes.md#lane-labels).

`e_read`, `e_gather`, `e_timeline` and `e_audit` return only records in lanes the agent profile can read. Ingesting, updating, adding an edge property, correcting and deleting each need write access to the record's lane.

A new engine has two agent profiles: `open` reads and writes every lane; `restricted` reads every lane and writes only `default`. A call that names no agent profile runs as the engine's default, `restricted` as shipped, and is refused if no default is set. `e_system` always requires one.

- A new engine's first policy, and its default, come from `conf/agents.yaml`, read on the first start of an engine that holds no policy.
- After that, policies change lanes and profiles, and `PUT /api/v2/agent-profiles/default` changes the default; a policy cannot set it.
- A member marked `builtin: true` is the floor: added back on every start if no policy declares it. The shipped floor is the lane `default` and the profile `restricted`; `open` is not in it.

## Naming the agent profile

The agent profile is given to the agent by the deployment — in its system prompt or a skill — and the agent passes it as `agent_profile` on each call. `e_system` `get_profile` returns the agent profile's writable lanes, their source types and the labels each allows.

:::warning
The caller chooses its agent profile. The engine does not tie an agent profile to a credential, so any caller that can reach the engine can name any enabled agent profile. Lanes and agent profiles keep cooperating agents in their own work areas; they are not an access control against a caller that names a different agent profile. With authentication on, the audit log records which credential made each call.
:::

Some results are not limited by lane:

- `e_correct` with `list` or `inspect` returns corrections for records in any lane.
- The per-term counts `e_gather` reports for `intersect`, the edge properties of a `traverse` starting record with their counts, and search page totals cover all lanes.
- `e_policy` with `list` or `download` returns every policy to any caller.
- Some refusals name the lane of a record the agent profile cannot read.
- The REST route that lists source records returns all lanes.

## Reference

[`e_system`](../reference/tools/e_system.md).

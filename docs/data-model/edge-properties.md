---
title: "Edge Properties"
sidebar_position: 2
kind: concept
status: drafted
verified_against: null
lede: "Agents need to ask memory exact questions — every record about Acme, how many records mention the renewal — that meaning alone cannot answer. Edge properties put label:value pairs on records; every record sharing a value is joined by one edge, with no graph database to run; records are gathered by intersecting or uniting those edges, or walked from one to the next; a lane's source types can hold agents to one vocabulary; and every change to a record's edge properties is kept as a new version."
---

Challenges addressed: [Auditable Decision-Making](../../use-cases/auditing-agentic-decisions/), [Context Window Limits and Lossy Compaction](../../use-cases/beyond-the-context-window/), [Tracking Changes Through Time](../../use-cases/data-evolution/), [Point-in-Time Recall](../../use-cases/what-was-true-when/), [Multi-Agent Coordination](../../use-cases/agent-swarm-coordination/).

## Concepts

When two or more records share the same label:value, an edge is imputed: one N-ary edge that touches every record carrying it. The records and their edge properties form the Edge Property Graph.

Every source record carries **edge properties**: `label:value` pairs like `person:Sarah` or `topic:database`. When two or more records share an edge property, an edge — a grouping — is imputed.

In an ordinary graph an edge joins exactly two nodes. Here a single label like `person:Sarah` is **one N-ary edge that touches every record about Sarah at once** — five records, five hundred, it does not matter. One label, one edge, N members.

There is no separate edge table. The shared value is the edge. The records are the vertices and the edge properties are the edges of the **Edge Property Graph (EPG)**. It is a **hypergraph**: each edge property is a hyperedge joining every record that carries it, held in PostgreSQL without a graph database. See [the EPG](../../architecture/edge-property-graph/).

![Four records of different source types linked by the shared edge properties org:Acme, person:Sarah and topic:renewal](/img/shared-property.svg)

Notice the records in the figure are different source types — a contact, a meeting, a deal, a report — and on their own they're inert. It's the shared labels (`person:Sarah`, `org:Acme`, `topic:renewal`) that weave them into one fabric: each common label is an N-ary edge touching every record that carries it. **Common labels connect records across types, sources, and sessions.** Stack a second label and you've walked from one set into its intersection.

## Two kinds of edge property

| Kind | What it says | Written by | Governed by |
|---|---|---|---|
| **Agent-specified** — any `label:value`, such as `org:Acme` | the records that share it have something in common: an **imputed** edge | the agent, with `e_ingest`, `e_update` and `e_property` `add` / `remove` | the [policy](../../governance/policies/): which labels a [lane](../../governance/lanes/) allows, through its [source types](../../governance/source-types/), and which lanes the [agent profile](../../governance/agent-profiles/) may write |
| **Built-in** — the reserved labels `e_connect`, `e_group`, `e_adjustment` | someone declared a relation, a membership or an evolution: an **asserted** edge | the engine, which mints each value: [connections](../connections/) (`connect` / `disconnect`), [groups](../groups/) (`group` / `ungroup`), [adjustments](../adjustments/) (`adjusts` / `unadjust`) | the engine: these labels cannot be written or removed any other way |

An imputed edge is an inference: it says records have something in common, not what passed between them. A built-in edge is an assertion. The agent instructions the engine ships keep the two apart: `person:John` written on Sarah's record reads exactly like a record about John, so a relation between them belongs in a connection.

## Idioms

Several idioms are built on that one mechanism.

| Idiom | How it is written | Members | See |
|---|---|---|---|
| Agentic annotation | The caller's edge properties, on `e_ingest`, `e_update` or `e_property` `add` | Every record that carries the value | This page |
| Adjustment (linked list) | `e_ingest` with `adjusts`: the engine mints `e_adjustment:<label>_<32 hex>` and writes it on the new record and on each record it adjusts. Adjusting the newer record again adds the next link | The new record and the records it adjusts; a chain of links over time | [Updates and adjustments](../../agents-how-to/evolving-a-fact/) |
| Connection (1-to-1) | `e_property` `connect`: `e_connect:<hint>_<32 hex>` | Exactly two | [Connections](../connections/) |
| Group (membership) | `e_property` `group`: `e_group:<hint>_<32 hex>` | Two or more | [Groups](../groups/) |
| File hierarchy | Folder Intake writes `folder_id` on the folder's record and each file's record, and `file_id` on a file's record and each of its parts | A folder's records; a file's record and its parts | [Documents and files](../../use-cases/beyond-the-context-window/#documents-and-files) |

`e_adjustment` values do not appear in `e_property` listings or in `intersect` and `union`; `e_read` shows them under `adjustments`, and `traverse` walks them. A [correction](../../agents-how-to/correcting-a-record/) is not an edge property: it is a separate object attached to its record.

## Hygiene, and source types

Edge properties are the connection construct, so their hygiene matters: it is what lets agents curate, connect and manage records predictably. `org:Acme` and `company:Acme` are different edge properties and form no edge.

The optional **source type** exists for that reason. A lane that declares source types is closed: each source type names the labels a record of that type may carry, and a write with any other label is refused. That keeps the labels from sprawling. Source types and their labels are declared in the [policy](../../governance/policies/), not in code.

## Queries are set operations

Each edge property is a set of records. A query can **intersect** sets (records that carry every one), **union** them (any one), or run them as a **timeline** (the same sets, ordered by time). **Traverse** starts at one record and walks its edges to the records that share them. See [the EPG](../../architecture/edge-property-graph/) and [temporal retrieval](../../agents-how-to/using-the-timeline/).

## Where edge properties come from

| Source | How | Shown by `e_read` and `e_property` | Crosses to peers, kept in the archive |
|---|---|---|---|
| The caller | `e_ingest` `properties`, `e_update`, `e_property` `add` | Yes | Yes |
| The engine | Reserved labels: `e_connect` and `e_group` from `connect` and `group`; `e_adjustment` from `e_ingest` `adjusts` | `e_connect` and `e_group` yes; `e_adjustment` under `adjustments` | Yes |

An edge property is written as one string. The engine splits it at the first colon. Spaces in the label become underscores. The value is trimmed and otherwise kept as written. A string with no colon is given the label `general`. Labels that begin with `e_` are reserved: `e_ingest` and `e_update` refuse a call that passes one, and `e_property` `add` skips it and reports it under `rejected`.

## Edge Property Lifecycle

Declared edge properties — the caller's, and the reserved values for connections, groups and adjustments — are part of each entry in the record's [ledger](../source-records/#a-record-is-a-ledger). The edge-property table that retrieval reads is a cache of the latest entry. A declared edge property's id is derived from the fact it states: `ep_` and the first 32 hexadecimal characters of a SHA-256 over the record id, schema, label and value, so every engine projecting the same entry gives it the same id. Tags are not in the ledger; they are an index over the content.

A record's edge properties are part of its whole state. Every change to them writes a new version of the record, and every earlier version is kept in the record's history.

| Change | Call | What it does | Audit |
|---|---|---|---|
| Add, when written | `e_ingest` `properties` | The first version carries them | `sr_ingested` |
| Add later | `e_property` `add` | A new version with the added values. Add-only: values already held are reported, not repeated | `property_added`, one per value |
| Change | `e_update` `properties` | A new version. Merged by label: each label named has all its values replaced; labels not named stay as they were | `sr_updated` |
| Remove a label | `e_property` `remove` with `labels` | A new version without that label and its values | `property_removed`, one per value |
| Remove values | `e_property` `remove` with `properties` | A new version without the matching values | `property_removed`, one per value |

An update that changes nothing writes nothing. Earlier versions are read with `e_audit` `inspect` on the update's event.

**Reserved labels.** The `e_*` labels are written only by the engine: `connect`, `group` and `e_ingest` `adjusts` write them, and `disconnect`, `ungroup` and `unadjust` remove them. `e_ingest`, `e_update`, `e_property` `add` and `e_property` `remove` refuse them. See [connections](../connections/#writing-and-removing-a-connection) and [groups](../groups/#writing-and-removing-a-group).


## Example
See which labels exist before inventing one.

```text
e_property {"action": "list"}
```

```json
{"labels": [{"label": "org", "sr_count": 14}, {"label": "topic", "sr_count": 9}, {"label": "person", "sr_count": 6}]}
```

Write a record that reuses them, then gather every record on both edges.

```text
e_ingest {"content": "Sarah is the account owner for Acme.", "properties": ["org:Acme", "person:Sarah", "topic:renewal"]}
e_gather {"action": "intersect", "match": ["org:Acme", "topic:renewal"]}
```

## Implications
**`add` only adds.** It never removes an edge property. To replace the values of a label, use `e_update`; to remove particular values or a whole label, use `e_property` `remove`. See the lifecycle above.

**A closed lane checks labels at write time.** `e_ingest` and `e_update` refuse a label or value the record's source type does not allow. `e_property` `add` checks only the combined label list of the lane's source types, and does not check values.

**Adding an edge property needs write access** to the record's lane.

## Reference

The tools, their arguments and their refusals: [`e_ingest`](../../reference/tools/e_ingest/), [`e_property`](../../reference/tools/e_property/) and [`e_gather`](../../reference/tools/e_gather/).

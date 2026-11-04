---
title: "Source Records"
sidebar_position: 1
kind: concept
status: drafted
verified_against: null
lede: "Agents need somewhere to keep what they learn that outlives the context window and still says where it came from, so it can later be found, corrected, linked and audited. A source record stores any content an agent sends, exactly as sent; stamps it with its lane, source type, authority, source system and time; keeps every change as a new whole version, readable as it stood at any time; and is the one unit that edge properties, corrections and deletions act on."
---

Challenges addressed: [Auditable Decision-Making](../../use-cases/auditing-agentic-decisions/), [Context Window Limits and Lossy Compaction](../../use-cases/beyond-the-context-window/), [Tracking Changes Through Time](../../use-cases/data-evolution/), [Point-in-Time Recall](../../use-cases/what-was-true-when/), [Vendor-Independent Memory](../../use-cases/vendor-independent-memory/), [Enterprise Distributed Memory Requirements](../../use-cases/enterprise-memory-mesh/), [Multi-Agent Coordination](../../use-cases/agent-swarm-coordination/).

## Concepts

A source record is data: whatever content an agent or a program stores, with its edge properties, lane, source type, authority and provenance.

A **source record** (SR) is stored with full provenance: who said it, when, where it came from, how authoritative it is. It always traces back to its origin. Its content can be free-form text, JSON, and so on; skills or prompts control what goes in it. The content is whatever the caller sends: a sentence, a paragraph of reasoning, a whole document, a large JSON object, or one part of a file. The [Folder Intake](../../use-cases/beyond-the-context-window/#documents-and-files) writes a record for the folder, one per file and one per part of its text.

A record has one `sr_id` and lives in one lane. Every other operation names a record: an [edge property](../edge-properties/) sits on a record, a [correction](../../agents-how-to/correcting-a-record/) is pinned to a record, a [tombstone](../../agents-how-to/deleting-a-record/) removes a record.

## You curate the memory

Everything in eMemory — each source record, the `label:value` edge properties on it, the source type it fits — is authored by you and your agent, not by a hidden model deciding what's worth keeping. Your agent has the full context of the conversation and the task, so it knows which detail actually matters and labels it precisely; the store keeps that verbatim and never reinterprets it. The payoff is memory that says what you meant — and that gets sharper as your agent gets smarter, with nothing to re-tune.

## What the engine requires of the content

| Check | What happens |
|---|---|
| Content is a string | Required. JSON is sent as its text |
| Size | No limit on what is stored. Vectors cover at most `EMBED_MAX_CHUNKS` chunks (default 64); text past that is stored but has no vector |
| JSON content | Stored as sent. For embedding, the engine turns it into plain sentences first |
| A batch over REST | At most 200 records per `POST /api/v2/ingest/batch` |

The engine stores content as it is given. Content ingested twice is two records with two ids, and content changes only through an update, which keeps the earlier version.

The agent instructions the engine ships recommend one fact per record for conversational memory, written to stand alone, because a small record can be found, linked and corrected without touching anything else. That is guidance to the agent, not a rule of the data model.

## A record is a ledger

A record is a ledger of whole-state versions. Every change — the first write, an update, an added or removed edge property, a connection, a deletion — appends one entry holding the record's whole state: its content, its lane, its declared edge properties and its fields. The latest entry is the record's state; nothing is merged across entries, and earlier entries are never changed.

The latest entry is the one with the highest version. When two engines write the same version while apart, the entry from the engine whose identity sorts later wins, and then the later event id, so every engine settles on the same one. The other entry is kept.

### Updating a record

An update appends the next entry: the next version of a record — a plan, a status, a document — under the same `sr_id`, so every link, edge property, connection and audit trail that points at the record still points at it. Use it when the record *is* the artifact and the artifact moved on; when a fact was right and the world changed, write an [adjustment](../adjustments/); when it was wrong, a [correction](../../agents-how-to/correcting-a-record/).

`e_update` takes the whole new content (never a difference), edge properties merged by label (each label named has its values replaced; labels not named stay), or both, and a `note` saying why this version exists. Connections, groups and adjustment links are left alone, and the record's tags are derived again from the new content. An update that changes nothing writes nothing. To remove an edge property, use `e_property` `remove`. How-to: [updating a record](../../agents-how-to/updating-a-record/).

### Reading the versions

- **Now:** `e_read`, `e_gather` and `e_timeline` return the latest entry.
- **As of a time:** `e_read` with `as_of` returns the record as it stood then.
- **Every version:** `e_audit` `history` lists each version with when it was written, what changed and its note.

Retrieval reads two tables, the record table and the edge-property table, plus the tag index and vectors derived from the content. The two tables are a cache of each record's latest entry, written in the same transaction as the entry, and they exist for speed and simplicity in the query logic. The ledger is the record; all of these can be rebuilt from it.

## What a record carries

`e_read` returns these with every record.

| Field | What it is |
|---|---|
| `sr_id` | The id: `sr_` and 32 hexadecimal characters |
| `content` | The content as it was written, or as the latest update left it |
| `lane` | The one lane the record lives in, shown by its label; see [lanes](../../governance/lanes/) |
| `lane_uuid` | That lane's UUID |
| `source_type` | The declared kind of the record within that lane |
| `authority_level` | The [authority](../authority/), set from the source type |
| `source_system` | The name the calling client reported, or the engine's host name when it reported none (over REST: the request's `source_system`, else its User-Agent) |
| `ingested_at` | When the engine accepted the record |
| `version` | Which entry of the ledger this is; `0` for the first |
| `properties` | Its [edge properties](../edge-properties/); left out when it has none |

A record also keeps fields that `e_read` does not return, among them a SHA-256 hash of the content and the id of the engine that first wrote it.

## Example
```text
e_ingest {
  "content": "{\"account\": \"Acme\", \"renewal\": \"2027-03-01\", \"owner\": \"Sarah\", \"seats\": 240}",
  "source_type": "documentary",
  "properties": ["org:Acme", "topic:renewal"]
}
```

The reply carries the new `sr_id`, the `content_hash` and `ingested_at`. `e_read` returns the JSON text exactly as sent.

## Implications
**The caller decides the unit.** A record is as large or as small as the caller makes it. Edge properties, corrections and deletions act on the whole record.

**The edge properties you pass are on the record when `e_ingest` returns.** Tags the extractors derive and the embedding are added afterwards by a background worker, unless the call sets `sync`.

**The lane is chosen at ingest.** It is the agent profile's home lane unless the call names another with `assign_lane`. See [lanes](../../governance/lanes/).

## Reference

The tools, their arguments and their refusals: [`e_ingest`](../../reference/tools/e_ingest/) and [`e_read`](../../reference/tools/e_read/).

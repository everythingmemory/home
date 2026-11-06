# Audit Log

Anyone who must account for what agents did — an auditor, an operator, a reviewer — needs more than what the memory says now: who wrote each record, who corrected it, who deleted the one beside it, and when. The audit log writes an event for each change a tool makes to a record, in the same transaction as the change, naming the record, lane, agent profile and engine; keeps every event, even after the record is deleted; traces any record's history, with its content before and after each update; and carries each engine's events to its peers under their origin.

Challenges addressed: [Auditable Decision-Making](../use-cases/auditing-agentic-decisions.md), [Tracking Changes Through Time](../use-cases/data-evolution.md), [Point-in-Time Recall](../use-cases/what-was-true-when.md), [Multi-Agent Coordination](../use-cases/agent-swarm-coordination.md).

## Concepts

A change a tool makes to a record on this engine writes an event to the audit log, in the same transaction as the change, with the exceptions listed below. An event says what happened, to which record, in which lane, by which agent profile, and on which engine.

A read tells you what the memory says now. It does not tell you how it came to say it: who wrote the record, who corrected it, who deleted the one beside it.

The audit log answers that. Because each event is committed together with its change, there is no event for a change that failed. Events are read back with `e_audit`. The answer is assembled from rows; no model takes part.

## What is logged

| `event_type` | Written when |
|---|---|
| `sr_ingested` | A record is written by `e_ingest` |
| `sr_synced` | A record arrives from a peer |
| `sr_updated` | A record moves to a new version, by `e_update` or from a peer |
| `sr_deleted` | A record is deleted by `e_system` |
| `sr_undeleted` | A deleted record is undeleted by `e_system` |
| `property_added` | `e_property` adds an edge property, a connection or a group |
| `property_removed` | `e_property` removes an edge property, a connection, a group or an adjustment link |
| `correction_attached`, `correction_retracted` | A correction is pinned to a record, or retracted |
| `adjustment_attached` | An adjustment links a record |
| `bundle_imported` | A bundle is imported |

One event names one record. One call can write several events, including several for one record.

:::warning
These are not logged: reads and searches; changes to a policy; the tags the extractors derive; the edge properties passed on `e_ingest` or added by `e_update`; and deletions, edge properties and corrections applied from a peer, whose events arrive separately from the engine that made them. Events are not signed or hash-chained, and an event does not carry the record's content.
:::

## Whose account an event is

Each event carries `origin_instance_id`, the engine that recorded it. Every event travels to every peer and is filed there unchanged, under the origin it came with. That includes events about records in lanes that stay home, and edge property events carry the label and value. An engine that holds a peer's history holds it under the peer's name.

`seq` is the order on the engine you are asking and differs from engine to engine. `log_id` is minted per engine. The pair of `origin_instance_id` and `log_id` identifies one event anywhere in the mesh.

## Example
```text
e_audit {"action": "trace", "sr_id": "sr_3f9a1c20e47b5d16"}
```

The second event is shortened here; it carries the same fields as the first.

```json
{
  "sr_id": "sr_3f9a1c20e47b5d16",
  "count": 2,
  "events": [
    {
      "seq": 41, "log_id": "log_7c2e19ab05d3f4a1", "origin_instance_id": "engine-a",
      "timestamp": "2026-10-02T14:03:15.416485+00:00",
      "event_type": "sr_ingested", "sr_id": "sr_3f9a1c20e47b5d16",
      "lane": "renewals", "actor_profile": "renewals", "source_system": "claude-code",
      "details": {"authority_level": "conversational", "content_hash": "…"}
    },
    {
      "seq": 57, "log_id": "log_0be4d3f17a29c6e8", "origin_instance_id": "engine-a",
      "event_type": "correction_attached", "sr_id": "sr_3f9a1c20e47b5d16",
      "target": {"type": "correction", "id": "cor_91aa02c7d4e85b10"}
    }
  ]
}
```

Add `"expand": true` and the reply also carries the record itself, each correction in full, and the records linked by adjustment. `action: "list"` filters events by record, lane, agent profile, type, source or date. `action: "inspect"` opens one event by `log_id`; for an `sr_updated` event it returns the content before and after. `action: "history"` lists every state a record has had, newest first, up to `as_of`.

## Implications
**You audit what you can read.** `e_audit` returns only events in lanes the agent profile named on the call can read. The caller chooses that agent profile. See [lanes, agent profiles and policies](../governance/lanes.md).

**The trail outlives the record.** A trace of a deleted record returns its events, ending in `sr_deleted` with the content hash and authority the record had. If the record was ever updated, `inspect` on one of its `sr_updated` events still returns the version before and the version after, content included. See [tombstones](../agents-how-to/deleting-a-record.md).

**The archive holds a copy.** When an archive is configured, events are written to it in hourly files, one set per recording engine.

**Every event is kept.** The engine never deletes an audit event.

**A live feed exists beside it.** `GET /api/v1/feed` streams events recorded on this engine as they commit, filtered to the lanes an agent profile can read. Events received from peers are not streamed. It can miss events; the log is the authority.

## Reference

The tool, its arguments and its refusals: [`e_audit`](../reference/tools/e_audit.md). The feed: [the change feed](../observability/change-feed.md).

---
title: "Change Feed"
sidebar_position: 1
kind: concept
status: drafted
verified_against: null
lede: "Programs that show or react to what agents do in memory — a dashboard, a reviewer's screen, another agent — need each change as it happens, without polling. The change feed streams each audit-log event this engine writes, as it commits, over server-sent events; sends only events in lanes the chosen agent profile reads; replays what a client missed when it reconnects with its last cursor; and leaves the audit log as the record, so nothing missed live is lost."
---

Challenges addressed: [Auditable Decision-Making](../../use-cases/auditing-agentic-decisions/), [Multi-Agent Coordination](../../use-cases/agent-swarm-coordination/).

## Concepts

The change feed streams the engine's audit-log events over server-sent events, limited to the lanes an agent profile reads. A client that reconnects with the last cursor it saw is sent what it missed from the audit log.

A program that shows or reacts to changes should not have to poll. The change feed sends each audit-log event as it is written: an ingest, an update, an edge property added or removed, a correction, an adjustment, a deletion.

The feed is a copy, not the record. The audit log in the database is the record, and a client that misses messages reads them back from it.

## Subscribing

```bash
curl -N "http://localhost:8765/api/v1/feed?agent_profile=restricted"
```

The route is `GET /api/v1/feed`. It answers with `text/event-stream`. When authentication is on, it needs the same bearer as the other routes.

| Parameter | What it does |
|---|---|
| `agent_profile` | The agent profile whose lanes limit the stream. With none, the engine's default agent profile |
| `since_seq` | Replay every event after this cursor, then go live |
| `Last-Event-ID` header | The same as `since_seq`, as a browser's `EventSource` sends it on reconnect |

Without a cursor, the stream starts with events written after it opens.

## What each message holds

The message's SSE `id` is the event's `seq`. Its `data` is one JSON object:

| Field | What it is |
|---|---|
| `v` | The message format's version, `1` |
| `log_id` | The event's id |
| `seq` | This engine's cursor for the event. It is local: another engine numbers its events differently |
| `origin_instance_id` | The engine that wrote the event |
| `timestamp` | When it was written |
| `event_type` | What happened |
| `sr_id`, `lane`, `lane_uuid` | The record and lane it concerns, when it concerns one: `lane` as the label in this agent profile's view, `lane_uuid` the lane itself |
| `actor_profile`, `source_system` | The agent profile named on the call, and the system that made it |
| `credential` | Which credential made the call, when authentication is on: a client key (by the start of its hash), an OAuth user, or a peer |
| `target_type`, `target_id` | The object acted on, when it is not the record itself |
| `details` | Event-specific detail |

Lines starting with `:` are comments: `: live` when replay ends and live messages begin, and `: ping` every 15 seconds while nothing happens.

## Delivery

:::warning
Live messages are best-effort. If the engine cannot publish to Redis, the event is still written to the audit log and is not sent live. If live delivery is unavailable when a client connects, the stream sends any replay, then `: feed-live-unavailable`, and closes.
:::

- Only events in lanes the agent profile reads are sent. An event with no lane is not sent to any subscriber.
- The engine drops live messages it has already sent during replay. A client that reconnects or merges streams should still deduplicate on `log_id`.
- Live messages are the events this engine writes. Audit events received from a peer are written to the log and are sent on replay, not live.
- `FEED_ENABLED=false` stops live messages. Replay still works.
- The feed carries events, not content. To show a record's current state, read it with `e_read`.

## Reference

The audit log's event types: [the audit log](../../durability/the-audit-log/).

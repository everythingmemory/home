---
title: "Distributed Mesh Architecture"
sidebar_position: 5
kind: concept
status: drafted
verified_against: null
lede: "Organisations whose agents work across sites, regions or clouds need some of their memory in more than one place: shared between sites, gathered where it is overseen, and safe when one site is lost. The mesh connects independent engines so each site shares exactly the policies it chooses with exactly the peers it chooses; a central site can collect and audit what the others share; a shared record survives the loss of any one site; and every site keeps working when it is cut off, catching up when it reconnects."
---

Challenges addressed: [Enterprise Distributed Memory Requirements](../../use-cases/enterprise-memory-mesh/), [Vendor-Independent Memory](../../use-cases/vendor-independent-memory/).

## Concepts

Peering sets two engines up; the exchange carries what one shares and the other accepts, policy first, as its origin wrote it. Each engine works on its own and exchanges when connected. Nothing crosses by default.

A **mesh** is a set of engines connected to one another. Each engine in it is a **peer** of the engines it is connected to. Two activities make a mesh:

- **Peering** is the setup: pairing two engines and deciding what each offers and takes.
- **Exchange** is the runtime: what crosses between peered engines, and how each applies what it receives.

Two engines that hold the same record must agree on it: the same `sr_id`, the same edge properties, the same origin. So the exchange copies. A record arrives with the id, lane, authority, ingestion time and origin it was written with, and its edge properties under the ids the origin gave them. A receiver applies each item once, by its identity, so sending it twice changes nothing. Provenance, authority and history hold across the mesh.

## What crosses: share and accept

**What crosses is your choice, per peer.** A policy organizes memory — its lanes, source types, vocabulary and agent profiles — and says nothing about who receives it. Peering two engines exchanges nothing on its own. Each side decides: this engine **shares** a policy (or `all`, later ones included) with a peer, and the peer **accepts** it by id from the offer list it is shown. Only a policy that is both shared and accepted crosses — the policy first, then its lanes, whole, with every version of their records (edge properties included), vectors, corrections and audit events, each by its own lane. Deletions and undeletes never cross. A new accept brings the backlog; a revoke on either side stops further flow; what was sent stays sent.

**Relays.** A record relayed through an engine reaches that engine's own peers, under its own shares, and keeps its origin. Sites need not all peer with each other.

**Offline-first.** Each engine reads and writes on its own. When it reconnects, the next exchange carries what both sides missed.

## Peering

A **peer** is another engine this one exchanges with. Each engine keeps a row per peer, in its peer registry.

| Part of a peer row | What it is |
|---|---|
| `peer_url` | Where to reach the peer. A row with no URL is never dialled: the peer calls in. This is how a peer behind NAT is peered |
| Outbound key | The peer's key, which this engine sends when it calls the peer |
| Inbound key | A key this engine mints for the peer to send when the peer calls in. Shown once, kept as a hash |
| Shares | What this engine offers the peer: a policy by its id, or `all` (every policy, later ones too) |
| Accepts | What this engine takes from the peer: a policy by its id |

A **peer key** (`peer_` and 40 hexadecimal characters) opens only the two exchange routes, `POST /api/v1/sync/pull` and `/api/v1/sync/push`. Managing peers takes a client key. Peering needs authentication: with `AUTH_ENABLED=false`, every peering route refuses.

## How the exchange runs

The exchange is full duplex and pull only. Whichever side calls — the side whose peer row has a `peer_url` — runs one exchange that carries both directions, calling `POST /api/v1/sync/pull` on its peer, then `POST /api/v1/sync/push` with the page the peer asked for, and looping until neither side has more, or until a cap on rounds; the next exchange resumes from the bookmarks. A row with no `peer_url` is never dialled; that peer calls in. With `CRON_ENABLED=true`, the shipped schedule runs the exchange every five minutes. Every exchange states its protocol version, and a side that does not know the version refuses it by name.

Each engine keeps its own read bookmark per stream per peer. Items move in pages. A stream that fails leaves its bookmark where it was; the other streams continue and the next exchange retries it.

## The streams

| Stream | What crosses | Identity |
|---|---|---|
| `policy` | Policy events | `event_id` |
| `sr_entry` | Each version of each record: its whole state — content, lane, the edge properties declared on it. Deletions and undeletes are not sent. Tags do not cross; each engine derives its own | `event_id` |
| `correction` | Each version of a [correction](../../agents-how-to/correcting-a-record/) | `event_id` |
| `embedding` | Vectors of the active [embedding space](../../architecture/embedding-spaces/), by the record's lane, like the entries | `sr_id`, collection, chunk |
| `audit` | [Audit log](../../durability/the-audit-log/) events | origin and `log_id` |

## Example
Sarah's engine has shared the `renewals` policy with John's, and John's has accepted it. Sarah's agent records the renewal date in a lane of that policy.

```text
e_ingest {"content": "The Acme renewal is due 2026-12-31.", "properties": ["org:Acme", "topic:renewal"], "assign_lane": "renewals"}
```

On the next exchange the record crosses, then its edge properties and vector. John's engine holds it under the same `sr_id`, with Sarah's engine as its origin, and derives the record's tags itself. Step by step: [stacks in a mesh](../../operator-guide/stacks-in-a-mesh/).

## Implications
**A peer key opens the exchange routes only.** It is accepted on `POST /api/v1/sync/pull` and `/api/v1/sync/push` and refused everywhere else; managing peers takes a client key. The engine that mints a key shows it once and keeps a SHA-256 hash; the engine that uses it stores the key itself.

**Derived state is rebuilt on each engine.** The active correction, the resolved policy and a record's current version are folded locally from the events that crossed. Tags are derived locally from the content.

**Deletion is local.** A deletion or undelete is never sent to peers. A record deleted here stays deleted here even when a peer's later edit arrives; the edit is stored, and shows if the record is undeleted. A deletion on a peer does not delete the record here.

**Vectors cross only between matching spaces.** A receiver with no space for the sender's model skips the vector and embeds the record itself.

**The receiver sets the pace.** When its intake queue is deeper than `INTAKE_BACKPRESSURE_THRESHOLD` (default 2000 jobs), an engine asks its peers for nothing more and reads nothing more itself until it drains; it still sends what its peers ask for; the rows wait behind its bookmarks.

## Setting it up

Step by step: [stacks in a mesh](../../operator-guide/stacks-in-a-mesh/), [local stacks peered with eMemory SaaS](../../operator-guide/saas-peering/), [multi-site mesh](../../operator-guide/multi-site-mesh/).

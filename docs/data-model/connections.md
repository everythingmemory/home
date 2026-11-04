---
title: "Connections"
sidebar_position: 3
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "Agents that know how two records relate — this contract was signed by Sarah — need to state that relation outright, so later agents find it rather than guess it from labels the two happen to share. A connection writes a named relation between exactly two records, all or nothing; it reads the same from either side; it is matched like any edge property and followed ahead of widely shared ones when an agent walks the graph; and each one written or removed is audited."
---

Challenges addressed: [Context Window Limits and Lossy Compaction](../../use-cases/beyond-the-context-window/), [Multi-Agent Coordination](../../use-cases/agent-swarm-coordination/).

## Concepts

A connection is a named relation a caller asserts between exactly two records, such as "the contract was signed by Sarah". The engine writes it as one edge property value both records share, so it is read, matched and walked like any other edge property.

Two records that carry the same edge property have something in common. That is an inference: `org:Acme` on a contract and on a meeting note says both concern Acme, and nothing about how they relate.

A connection is an assertion: someone declared that two records stand in a named relation. An edge property names what a record is about; a connection names how two records relate. The agent instructions the engine ships keep the two apart, because another record's name written on a record as an edge property reads exactly like that record's own identity.

For a named membership of two or more records, see [groups](../groups/).

## Writing and removing a connection

| Action | Records | Writes | When a record cannot be written |
|---|---|---|---|
| `connect` | exactly two | `e_connect:<hint>_<token>` on both | nothing is written, and the call is refused |
| `disconnect` | exactly two, `sr_id=[a, b]` | removes the `e_connect` value they share from both | nothing is removed, and the call is refused |

The caller supplies the meaning in `hint`; spaces and colons in it become `_`. The engine supplies the uniqueness: `<token>` is 32 random hexadecimal characters, new on every call, so each call writes a new connection, even with the same hint and the same records.

The connection is the shared value itself: one value, on both records, reading the same from either side.

The label `e_connect` is reserved: `connect` is the one way to write it and `disconnect` the one way to remove it. Both records must be in lanes the agent profile can write.

**Removing.** `disconnect` is all-or-nothing, like `connect`: both records must exist, be writable, and carry the connection. If they share more than one connection, name the one to remove in `hint` — its value or the hint it was minted from; the reply to an unnamed call lists the shared connections to choose from. Removal writes a new version of each record, without the value, and keeps the earlier versions; the [audit log](../../durability/the-audit-log/) records a `property_removed` event for each.

## Example
Sarah's record and the signed Acme contract exist. The agent asserts the relation.

```text
e_property {"action": "connect", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"], "hint": "signed_by"}
```

```json
{
  "action": "connect",
  "property": "e_connect:signed_by_3a9f0c27d14e4b6a8e5f9d01c2b7a6e3",
  "members": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"],
  "stamped": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"]
}
```

## Implications
**A connection is read like an edge property.** `e_read` lists it under the record's `properties`, and `e_property` and `e_gather` `intersect` match it like any other `label:value`.

**Traverse walks it from either side.** `e_gather` `traverse` from one record returns the other, because they share the value. A connection is held by few records, so traverse follows it before widely shared edge properties. See [the edge property hypergraph](../../architecture/edge-property-graph/).

**Each write is audited.** Each record that receives the value writes a `property_added` event naming the connection.

## Reference

How-to: [connecting records](../../agents-how-to/connecting-records/). Every argument: [`e_property`](../../reference/tools/e_property/).

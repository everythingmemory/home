---
title: "Connecting Records"
sidebar_position: 10
kind: how-to
status: drafted
verified_against: null
lede: "Assert a named relation between exactly two records with e_property connect. It is all-or-nothing: if either record cannot be written, nothing is written."
---

## When to Use
When a relation between two records is a fact in itself — the contract was signed by Sarah — and not just something they have in common. What a connection is: [connections](../../data-model/connections/).

## Usage
```text
e_property {"action": "connect", "sr_id": ["sr_a…", "sr_b…"], "hint": "signed_by"}
```

`sr_id` names exactly two records; any other count is refused. Both must be in lanes the agent profile can write; if either is missing or not writable, the call is refused and nothing is written. `hint` is the meaning; spaces and colons in it become `_`. The engine adds 32 random hexadecimal characters, new on every call, so each call writes a new connection.

## Response
```json
{
  "action": "connect",
  "property": "e_connect:signed_by_3a9f0c27d14e4b6a8e5f9d01c2b7a6e3",
  "members": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"],
  "stamped": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"]
}
```

The value is an edge property on both records: `e_read` lists it, `intersect` matches it, and `e_gather` `traverse` walks it from either side.

## Example
```text
e_property {"action": "connect", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"], "hint": "signed_by"}
e_gather {"action": "traverse", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"}
```

The traverse returns Sarah's record among the contract's neighbours.

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/property" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "connect", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"], "hint": "signed_by"}'

curl -s -X POST "$EMEMORY_URL/api/v2/gather" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "traverse", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"}'
```

## Removing a connection

```text
e_property {"action": "disconnect", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"]}
```

```json
{"action": "disconnect", "property": "e_connect:signed_by_3a9f0c27d14e4b6a8e5f9d01c2b7a6e3", "removed": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"]}
```

All-or-nothing: if either record is missing, not writable, or does not carry the connection, nothing is removed. If the two records share more than one connection, add `hint` with the value or the hint it was made from; otherwise the call is refused and lists them. Each record gets a new version without the connection; earlier versions are kept, and the audit log records the removal.

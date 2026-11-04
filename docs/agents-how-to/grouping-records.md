---
title: "Grouping Records"
sidebar_position: 11
kind: how-to
status: drafted
verified_against: null
lede: "Assert a named membership among two or more records with e_property group. It is best-effort: it writes what it can and reports what it skipped."
---

## When to Use
When several records belong together as one named thing — the records of one deal, the attendees of one meeting. A group of two is a group, not a connection. What a group is: [groups](../../data-model/groups/).

## Usage
```text
e_property {"action": "group", "sr_id": ["sr_a…", "sr_b…", "sr_c…"], "hint": "acme renewal deal"}
```

`sr_id` names two or more records. `hint` is the meaning; spaces and colons in it become `_`. The engine adds 32 random hexadecimal characters, new on every call, so each call writes a new group.

## Response
```json
{
  "action": "group",
  "property": "e_group:acme_renewal_deal_a71f0d93c6e248b5f17a2c04e9d863b5",
  "members": ["sr_7b22…", "sr_91c0…"],
  "stamped": ["sr_7b22…", "sr_91c0…"],
  "skipped_unwritable": ["sr_c4e1…"]
}
```

Records in lanes the agent profile cannot write are left out and listed under `skipped_unwritable`; unknown ids under `not_found`. If none of the records can be written, the call is refused.

## Example
```text
e_property {"action": "group", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe", "sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"], "hint": "acme renewal deal"}
e_gather {"action": "intersect", "match": ["e_group:acme_renewal_deal_a71f0d93c6e248b5f17a2c04e9d863b5"]}
```

The intersect returns every member of the group.

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/property" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "group", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe", "sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"], "hint": "acme renewal deal"}'

curl -s -X POST "$EMEMORY_URL/api/v2/gather" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "intersect", "match": ["e_group:acme_renewal_deal_a71f0d93c6e248b5f17a2c04e9d863b5"]}'
```

## Removing from a group

```text
e_property {"action": "ungroup", "hint": "e_group:acme_renewal_deal_a71f0d93c6e248b5f17a2c04e9d863b5", "sr_id": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"]}
```

```json
{"action": "ungroup", "property": "e_group:acme_renewal_deal_a71f0d93c6e248b5f17a2c04e9d863b5", "removed": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"]}
```

`hint` is the group's value, as `group` returned it, or the bare token. With `sr_id`, the named records leave the group; without it, every member the agent profile can read does. Best-effort: records in lanes the agent profile cannot write are listed under `skipped_unwritable`, records that were not members under `not_member`, unknown ids under `not_found`. Each record removed gets a new version without the value; earlier versions are kept, and the audit log records the removal.

---
title: "Updating a Record"
sidebar_position: 7
kind: how-to
status: drafted
verified_against: null
lede: "Write the next version of a record you keep — a plan, a status, a document — with e_update. The sr_id stays the same, and every earlier version is kept."
---

## When to Use
When the record is an artifact that has moved on, and you want one record that always holds its current state. If the record was right and the world changed, [evolve the fact](../evolving-a-fact/) instead; if it was wrong, [correct it](../correcting-a-record/).

## Usage
```text
e_update {"sr_id": "...", "content": "...", "properties": ["label:value", ...], "note": "..."}
```

| Argument | What it does |
|---|---|
| `sr_id` | The record. Requires write access to its lane |
| `content` | The whole new content, never a difference. Omit it to change edge properties only |
| `properties` | Merged by label: each label named has all its values replaced; labels not named stay as they were |
| `note` | Why this version exists. Kept with the version |

Adjustment links, connections and groups are left alone. The record's tags are derived again from the new content.

## Response
`{sr_id, version, event_id, updated_at}`. `version` counts updates; `e_read` returns it, and `0` means never updated.

`e_read`, `e_gather` and `e_timeline` return the current version only, unless `e_read` is given `as_of`. Every earlier version is kept in the record's ledger: `e_audit` `inspect` on an update's `sr_updated` event returns the content before and after it.

## Example
Sarah keeps the renewal plan in one record. John takes over the draft.

```text
e_update {
  "sr_id": "sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98",
  "content": "Acme renewal plan: John sends the draft by 2026-11-14. Sarah signs by 2026-11-28.",
  "note": "John took over the draft from Sarah."
}
```

The reply carries `"version": 1`.

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/update" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_id": "sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98", "content": "Acme renewal plan: John sends the draft by 2026-11-14. Sarah signs by 2026-11-28.", "note": "John took over the draft from Sarah."}'
```

## Across the mesh

Versions travel to peers. When two engines write the same version at once, every engine settles on the same one: the entry from the engine whose identity sorts later, then the later event id. The other stays in the record's history. See [source records](../../data-model/source-records/#a-record-is-a-ledger).

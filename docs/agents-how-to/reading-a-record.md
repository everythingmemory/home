---
title: "Reading a Record"
sidebar_position: 5
kind: how-to
status: drafted
verified_against: null
lede: "`e_read` loads records by id, in full: content, lane, source type, authority, the system that wrote each one, its edge properties, and the corrections and adjustments attached to it."
---

## When to Use
The search tools return enough to choose records, not enough to reason over them. `e_read` takes a list of `sr_id`s and returns each record whole, with what has happened to it since it was written. Add `as_of` (a date or ISO datetime) to read each record as it stood at that moment. That reply differs from a normal read: it has no `corrections`; it gives `adjustment_tokens` in place of `adjustments`, and `written_at`, when the state shown was written; a record deleted by then comes back with `deleted: true` and `deleted_at`; and ids not yet written by then come back under `not_yet_written`.

```text
e_read {"sr_ids": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"]}
e_read {"sr_ids": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"], "as_of": "2026-03-01"}
```

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/read" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_91c0aa5e2d64b7f3a8e1c05d9b7342fe"]}'

curl -s -X POST "$EMEMORY_URL/api/v2/read" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"], "as_of": "2026-03-01"}'
```

## Response
| Field | What it is |
|---|---|
| `sr_id` | The record's id |
| `content` | The content, as the caller wrote it or as the latest update left it |
| `lane` | The lane the record lives in, by its label in your view (`crm`, or `crm@3f9a2` when two lanes you can see share the name) |
| `source_type` | Its source type |
| `authority_level` | Its authority: `human_correction`, `human_confirmation`, `documentary`, `conversational`, `system_inference` or `system_response` |
| `source_system` | The name of the system that wrote it |
| `ingested_at` | When it was written |
| `version` | Which entry of the record's ledger this is; `0` for the first. See [source records](../../data-model/source-records/#a-record-is-a-ledger) |
| `is_conversational`, `is_file_content` | Present, and `true`, only when the record was marked so |
| `properties` | Its edge properties, as `label:value` strings, when it has any, including its [connections](../../data-model/connections/) |
| `adjustments` | When the record is linked to an adjustment: for each link, the other records in it the agent profile can read |
| `corrections` | When the record has been corrected: the corrections attached to it |

The tags the extractor plugins derive are not shown. They are used by search only.

## Corrections and adjustments on a read

A [correction](../../agents-how-to/correcting-a-record/) is attached to the record it corrects. The record's content is not changed by it; `e_read` returns the record with its corrections beside it, so the reader sees both what was written and what is true.

An [adjustment](../../agents-how-to/evolving-a-fact/) is a later record linked to an earlier one. `e_read` on either record lists the other under `adjustments`.

`e_gather` and `e_timeline` do not return corrections in full. They flag a record with `has_correction` or `has_adjustment`, and `e_read` shows what the flag points to.

## What is left out

- An id that does not exist, an id of a deleted record, and an id in a lane the agent profile cannot read all come back under `not_found`. The reply does not say which.
- When an adjustment links to records in lanes the agent profile cannot read, those records are left out of `adjustments`. If that leaves a link with no records, the reply's `hint` says some adjustment records are not visible.
- Earlier versions are not returned unless you pass `as_of`, which reads each record as it stood at that date or time. `e_audit` `inspect` on an update's event returns the content before and after it.

## Reference

Every argument and refusal: [`e_read`](../../reference/tools/e_read/).

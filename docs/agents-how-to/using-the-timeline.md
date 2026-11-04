---
title: "Using the Timeline"
sidebar_position: 6
kind: how-to
status: drafted
verified_against: null
lede: "`e_timeline` returns records ordered by time, either by when they were written or by the dates their content names, and bounded by a window. This page says which time each option reads and how the bounds apply."
---

## When to Use
A question about a period needs records in order and inside a window. Every record has two kinds of time:

- **Ingest time**, when the record was written to this engine (`ingested_at`).
- **Content time**, the dates and times the content names. At ingest the date extractor (chrono-node) reads them, and each is kept as a span: a date names its whole day, a month its whole month. A record whose content names no date has no content time.

`order_by` chooses the time and the direction: `ingest_time_desc` (the default), `ingest_time_asc`, `content_time_desc` or `content_time_asc`. The window, set by `start_date` and `end_date` as ISO 8601 dates or times, is read against the same time and includes both ends. A value with no time zone is read as UTC, and a date with no time as midnight at its start: `"end_date": "2027-03-31"` ends the window at 00:00 UTC on 31 March. In a content-time order, a record with no content time is placed by its ingest time. Under a content-time order with a window, records whose content names no date are not returned.

## Usage
| Action | Which records |
|---|---|
| `list` | Every record, inside the window |
| `intersect` | Records that match every term in `match`, inside the window. A term matches an edge property whose label is the same and whose value contains the term's value, or a tag equal to it. A `label:value` term also matches a tag equal to its value alone, with no label |
| `traverse` | Records within seven days either side of the time the record named in `sr_id` was written. Under a content-time order, those 14 days are matched against content time. When that record exists, `start_date` and `end_date` are ignored |
| `find` | The records `e_gather` `find` would consider for `query` (see [finding records](../finding-records/)), put in time order |
| `changes` | What changed between `since` and `as_of` (default now): each record that is new, updated, deleted or undeleted in that span, newest first. It takes only `since`, `as_of`, `page` and `page_size`; pass back the `as_of` that page 1 returns for later pages |

With `list`, `intersect` or `traverse` and no `start_date` or `end_date`, the engine reads dates out of `query`, relative to now. One date bounds the window to that date; two bound it between them. With more than two, or two in reverse order, the reply returns no records and its `hint` says why. The reply's `parsed_temporal` lists the dates it read.

:::warning
`find` applies no window. `start_date`, `end_date` and dates in `query` do not bound its results.
:::

## Narrowing a large match

When an `intersect` matches more than 200 records, the engine drops the term that matches the most records, and repeats until the set is 200 or fewer or one term is left; the set can stay above 200. Terms with the label `time` or `duration` are never dropped. The reply's `hint` names the terms kept and the terms dropped. Pass `shed_idf_noise: false` to keep every term. The 200 are counted across all lanes, before records in lanes the agent profile cannot read are removed.

## Response
Each record in `srs` carries its `sr_id`, `content` and `ingested_at`, and the flags `has_correction` and `has_adjustment` where they apply. A page holds 30 records unless `page_size` says otherwise. Over MCP, `is_conversational_only: true` keeps only records marked as conversation, for `list`, `intersect` and `traverse`; the REST endpoint does not take it.

## Example
Sarah asks what was agreed about the Acme renewal in March.

```text
e_timeline {"action": "intersect", "match": ["org:Acme", "topic:renewal"], "start_date": "2027-03-01", "end_date": "2027-03-31", "order_by": "content_time_asc"}
```

The reply lists the records that carry both edge properties and whose dates overlap March 2027, earliest first.

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/timeline" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "intersect", "match": ["org:Acme", "topic:renewal"], "start_date": "2027-03-01", "end_date": "2027-03-31", "order_by": "content_time_asc"}'
```

## Reference

Every argument and refusal: [`e_timeline`](../../reference/tools/e_timeline/).

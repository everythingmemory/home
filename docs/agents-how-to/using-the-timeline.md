# Using the Timeline

`e_timeline` returns records ordered by time, either by when they were written or by the dates their content names, and bounded by a window. This page says which time each option reads and how the bounds apply.

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
| `traverse` | Records within seven days either side of the time the record named in `sr_id` was written. Under a content-time order, those 14 days are matched against content time. When that record exists and the agent profile can read it, `start_date` and `end_date` are ignored; a record it cannot read answers as one that does not exist |
| `find` | The records `e_gather` `find` would consider for `query` (see [finding records](finding-records.md)), put in time order |
| `changes` | What changed between `since` and `as_of` (default now): each record that is new, updated, deleted or undeleted in that span, newest first, each row naming its `author`. It takes only `since`, `as_of`, `lane`, `source_type`, `author`, `page` and `page_size`, and the three filters narrow it as they narrow the other actions; pass back the `as_of` that page 1 returns for later pages |

With `list`, `intersect` or `traverse` and no `start_date` or `end_date`, the engine reads dates out of `query`, relative to now. One date bounds the window to that date; two bound it between them. With more than two, or two in reverse order, the reply returns no records and its `hint` says why. The reply's `parsed_temporal` lists the dates it read.

:::warning
`find` applies no window. `start_date`, `end_date` and dates in `query` do not bound its results.
:::

## Narrowing by lane, source type or author

`lane`, `source_type` and `author` narrow every action, `changes` included. Each takes one name, and together they narrow by all three.

- `lane` names one lane the agent profile reads, by its name, its qualified name or its uuid. A lane it cannot read is refused as a lane that does not exist, and the refusal lists the lanes it reads.
- `source_type` is the name `e_read` shows. An unknown one is refused, and the refusal lists the builtins and the source types the lanes it reads declare.
- `author` is an agent profile name, matched against the profile that first wrote each record. Like the lane and the source type, it is fixed when the record is written and does not change after; a record no profile wrote has a null `author`. A name that wrote nothing matches nothing.

A `source_type` or `author` the engine's profile cannot apply is refused, never ignored.

`lane:x` in `match` is a label term, not the lane. Under `traverse` the anchor in `sr_id` may be any record the agent profile reads; `lane` narrows only the records returned.

## Narrowing a large match

When an `intersect` matches more than 200 records, the engine drops the term that matches the most records, and repeats until the set is 200 or fewer or one term is left; the set can stay above 200. Terms with the label `time` or `duration` are never dropped. The reply's `hint` names the terms kept and the terms dropped. Pass `shed_idf_noise: false` to keep every term. The 200 are counted across all lanes, before records in lanes the agent profile cannot read are removed.

## Response
Each entry in `srs` carries its `sr_id`, `lane` and `lane_uuid`, `source_type`, `version`, `author` (the agent profile that first wrote the record), `ingested_at`, its `properties` as `e_read` lists them, a `preview` of its content of at most 240 characters, and the flags `has_correction` and `has_adjustment` where they apply. `e_read` gives the full content.

A page holds at most 20 entries, or `page_size`, and at most 8,000 characters of previews and properties; one entry larger than that is a page by itself. The reply's `remaining` counts the entries after this page, and its `hint` gives the next call: the same arguments with `page` one higher. A page past the last returns no entries, and its `hint` names the last page.

Over MCP, `is_conversational_only: true` keeps only records marked as conversation, for `list`, `intersect` and `traverse`; the REST endpoint does not take it.

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

Every argument and refusal: [`e_timeline`](../reference/tools/e_timeline.md).

# Finding Records

Find records with e_gather: by a question in plain language (find), by edge properties (intersect, union), or by walking from a record you already have (traverse). Then read the ones you will reason over.

## When to Use
Whenever the agent needs records and does not have their ids. It knows a question, an edge property, or one record it has already found.

## The calls

| Action | Arguments | Returns |
|---|---|---|
| `find` | `query`, a question in plain language | Records ranked by four merged lookups; see [hybrid retrieval strategy](../architecture/how-search-ranks-results.md) |
| `intersect` | `match`, a list of edge properties | Records that carry every one, newest first |
| `union` | `match` | Records that carry any one; free-text terms: strongest match first, ties newest first |
| `traverse` | `sr_id` | Records that share an edge property with that record, including connections, groups and adjustments |
| `count` | `match`, or `sr_id` | Counts only, to size a result before fetching it |
| `group` | `by`, a label; optional `match`, `top` | Each value of that label, with the number of records under it |

All take `page` and `page_size` (20 by default for `find`, `intersect`, `union`, `traverse` and `group`; `count` returns counts only) and `agent_profile`. `find`, `intersect`, `union` and `traverse` also take `full`. `intersect`, `union` and `traverse` also take `context`, a phrase whose meaning reorders the results; equal ones keep their order. In a `union` of `label:value` and free-text terms, the `label:value` matches come first. In `intersect` and `union`, records ranked equal come newest first, then by `sr_id`. The structural actions are described in [the EPG](../architecture/edge-property-graph.md).

## Response
Each entry in `srs` carries its `sr_id`, `lane` and `lane_uuid`, `source_type`, `version`, `author` (the agent profile that first wrote the record), `ingested_at`, its `properties` as `e_read` lists them, a `preview` of its content of at most 240 characters, and `distance`. With `full: true` an entry carries the whole content as `content` in place of `preview`.

A `find` entry's `distance` is comparable only within one question. On a page of four or more, a `find` entry also carries `distance_quartile` (1 is the closest quarter of the page); on a page of two or more, the page carries `distance_spread` (`tight`, `moderate` or `huge`).

A record with a [correction](correcting-a-record.md) is flagged `has_correction`; one linked to an [adjustment](evolving-a-fact.md), `has_adjustment`. Read the records with [`e_read`](reading-a-record.md) before reasoning over them.

A page holds at most 20 entries, or `page_size`, and at most 8,000 characters of previews and properties, counted on the whole content when `full` is true; one entry larger than that is a page by itself, never cut. The reply's `remaining` counts the entries after this page, and its `hint` gives the next call: the same arguments with `page` one higher. A page past the last returns no entries, and its `hint` names the last page.

When the embeddings endpoint is not usable, `find` still answers from tags, edge properties and full text, and its distances are placeholders.

## Example
```text
e_gather {"action": "find", "query": "when is the Acme renewal due"}
```

```json
{
  "srs": [
    {"sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "source_type": "documentary", "version": 0, "author": "restricted", "preview": "Acme's renewal is due on 1 March. Sarah owns it.", "properties": ["org:Acme", "topic:renewal"], "ingested_at": "2026-10-30T15:02:11.218904+00:00", "distance": 0.21, "lane": "default", "lane_uuid": "lane_…", "has_correction": true}
  ],
  "page": 1,
  "total_pages": 1,
  "has_more": false,
  "remaining": 0
}
```

The record has a correction, so the agent reads it before answering. To gather everything on the same edges:

```text
e_gather {"action": "intersect", "match": ["org:Acme", "topic:renewal"]}
```

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/gather" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "find", "query": "when is the Acme renewal due"}'

curl -s -X POST "$EMEMORY_URL/api/v2/gather" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "intersect", "match": ["org:Acme", "topic:renewal"]}'
```

## Reference

Every argument and refusal: [`e_gather`](../reference/tools/e_gather.md).

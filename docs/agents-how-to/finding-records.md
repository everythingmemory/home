---
title: "Finding Records"
sidebar_position: 4
kind: how-to
status: drafted
verified_against: null
lede: "Find records with e_gather: by a question in plain language (find), by edge properties (intersect, union), or by walking from a record you already have (traverse). Then read the ones you will reason over."
---

## When to Use
Whenever the agent needs records and does not have their ids. It knows a question, an edge property, or one record it has already found.

## The calls

| Action | Arguments | Returns |
|---|---|---|
| `find` | `query`, a question in plain language | Records ranked by four merged lookups; see [hybrid retrieval strategy](../../architecture/how-search-ranks-results/) |
| `intersect` | `match`, a list of edge properties | Records that carry every one |
| `union` | `match` | Records that carry any one |
| `traverse` | `sr_id` | Records that share an edge property with that record, including connections, groups and adjustments |
| `count` | `match`, or `sr_id` | Counts only, to size a result before fetching it |
| `group` | `by`, a label; optional `match`, `top` | Each value of that label, with the number of records under it |

All take `page` and `page_size` (30 by default for `find`, 50 for `intersect`, `union` and `traverse`, 20 for `group`; `count` returns counts only) and `agent_profile`. `intersect`, `union` and `traverse` also take `context`, a phrase whose meaning reorders the results. The structural actions are described in [the EPG](../../architecture/edge-property-graph/).

## Response
Each record in `srs` carries its `sr_id` and `content`. A `find` result also carries `distance`, and, on a page of four or more, `distance_quartile` (1 is the closest quarter of the page); the page carries `distance_spread` (`tight`, `moderate` or `huge`). A distance is comparable only within one question.

A record with a [correction](../correcting-a-record/) is flagged `has_correction`; one linked to an [adjustment](../evolving-a-fact/), `has_adjustment`. `find` returns no edge properties; the reply's `hint` says so. Read the records with [`e_read`](../reading-a-record/) before reasoning over them.

When the embeddings endpoint is not usable, `find` still answers from tags, edge properties and full text, and its distances are placeholders.

## Example
```text
e_gather {"action": "find", "query": "when is the Acme renewal due"}
```

```json
{
  "srs": [
    {"sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "content": "Acme's renewal is due on 1 March. Sarah owns it.", "distance": 0.21, "has_correction": true}
  ],
  "page": 1,
  "total_pages": 1,
  "has_more": false,
  "hint": "Properties omitted. Use e_read(['sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1']) to see all properties for specific SRs."
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

Every argument and refusal: [`e_gather`](../../reference/tools/e_gather/).

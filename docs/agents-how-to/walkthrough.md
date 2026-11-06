# A Walkthrough

One path through Everything Memory, end to end: connect, store, find, read, update, adjust, correct, connect, ask by time, and delete. Each step shows the call, the reply, what it shows, and where to read more.

This walkthrough runs on a new stack with authentication off, as the shipped template sets it. Every call names the agent profile `restricted`, which a new engine provides: it reads every lane and writes the lane `default`. Ids in the replies are examples; yours differ. Replies are trimmed to the fields that matter.

## 1. Connect

The person setting up points the agent's MCP client at the API service. See [connecting clients](../operator-guide/connecting-clients-and-operating.md).

```text
MCP server URL: http://localhost:8765/mcp
```

On connecting, the agent receives the engine's instructions and the description of each of the ten tools. The skills that teach an agent these tasks are installed by the operator — see [Agent Skills](../operator-guide/agent-skills.md). It then asks what it may write:

```text
e_system {"action": "get_profile", "agent_profile": "restricted"}
```

```json
{
  "profile": "restricted",
  "can_reassign": false,
  "write_lanes": [{"lane": "default", "lane_uuid": "lane_…", "source_types": ["conversational", "documentary"]}],
  "read_lanes": [{"lane": "default", "lane_uuid": "lane_…"}]
}
```

The agent may write the open lane `default`, with either builtin source type and any labels. See [agent profiles](../governance/agent-profiles.md) and [source types](../governance/source-types.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/system" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "get_profile", "agent_profile": "restricted"}'
```

## 2. Store a record

```text
e_ingest {"content": "Acme's renewal is due on 1 March 2027. Sarah owns it.", "source_type": "documentary", "properties": ["org:Acme", "person:Sarah", "topic:renewal"], "agent_profile": "restricted"}
```

```json
{"sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "status": "accepted", "content_hash": "…", "ingested_at": "2026-10-30T15:02:11Z"}
```

The record is stored with three edge properties. Its tags and embedding follow in the background. See [storing a record](storing-a-record.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/ingest" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "Acme'"'"'s renewal is due on 1 March 2027. Sarah owns it.", "source_type": "documentary", "properties": ["org:Acme", "person:Sarah", "topic:renewal"], "agent_profile": "restricted"}'
```

## 3. Find it by meaning

```text
e_gather {"action": "find", "query": "who owns the Acme renewal", "agent_profile": "restricted"}
```

```json
{"srs": [{"sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "content": "Acme's renewal is due on 1 March 2027. Sarah owns it.", "distance": 0.24}], "page": 1, "total_pages": 1, "has_more": false}
```

Search found the record from a question that shares few of its words. See [search](finding-records.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/gather" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "find", "query": "who owns the Acme renewal", "agent_profile": "restricted"}'
```

## 4. Find it by edge property

```text
e_gather {"action": "intersect", "match": ["org:Acme", "topic:renewal"], "agent_profile": "restricted"}
```

The reply lists every record that carries both edge properties — this one among them. See [edge properties](../data-model/edge-properties.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/gather" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "intersect", "match": ["org:Acme", "topic:renewal"], "agent_profile": "restricted"}'
```

## 5. Read it

```text
e_read {"sr_ids": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"], "agent_profile": "restricted"}
```

```json
{"srs": [{"sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "content": "Acme's renewal is due on 1 March 2027. Sarah owns it.", "lane": "default", "source_type": "documentary", "authority_level": "documentary", "source_system": "…", "ingested_at": "2026-10-30T15:02:11Z", "version": 0, "properties": ["org:Acme", "person:Sarah", "topic:renewal"]}]}
```

The full record, with its provenance and authority. See [record lookup](reading-a-record.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/read" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"], "agent_profile": "restricted"}'
```

## 6. Update it

A separate record keeps the renewal plan, and the plan moves on.

```text
e_ingest {"content": "Renewal plan: Sarah drafts by 2026-11-14.", "properties": ["org:Acme", "topic:renewal"], "agent_profile": "restricted"}
e_update {"sr_id": "sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98", "content": "Renewal plan: John drafts by 2026-11-14; Sarah signs by 2026-11-28.", "note": "John took over the draft.", "agent_profile": "restricted"}
```

```json
{"sr_id": "sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98", "version": 1, "event_id": "…", "updated_at": "…"}
```

Reads now return version 1. The first version is kept: `e_audit` `inspect` on the update's event returns `from` (version 0) and `to` (version 1). See [updating a record](updating-a-record.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/ingest" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "Renewal plan: Sarah drafts by 2026-11-14.", "properties": ["org:Acme", "topic:renewal"], "agent_profile": "restricted"}'

curl -s -X POST "$EMEMORY_URL/api/v2/update" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_id": "sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98", "content": "Renewal plan: John drafts by 2026-11-14; Sarah signs by 2026-11-28.", "note": "John took over the draft.", "agent_profile": "restricted"}'
```

## 7. Adjust a fact

The due date moves. The first record was right when written, so the agent adds a record that adjusts it.

```text
e_ingest {"content": "Acme's renewal moved to 1 April 2027 at Acme's request.", "properties": ["org:Acme", "topic:renewal"], "adjusts": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"], "adjustment_label": "date moved", "agent_profile": "restricted"}
```

```json
{"sr_id": "sr_4d91…", "status": "accepted", "adjustment": {"adjustment_token": "date_moved_9c2e…", "adjusts_applied": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"]}}
```

The two records are linked; `e_read` on either lists the other under `adjustments`. See [evolving a fact](evolving-a-fact.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/ingest" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "Acme'"'"'s renewal moved to 1 April 2027 at Acme'"'"'s request.", "properties": ["org:Acme", "topic:renewal"], "adjusts": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"], "adjustment_label": "date moved", "agent_profile": "restricted"}'
```

## 8. Correct a wrong record

Sarah never owned the renewal: John does.

```text
e_correct {"action": "create", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "content": "John owns the Acme renewal, not Sarah.", "comment": "Per the account plan.", "agent_profile": "restricted"}
```

```json
{"correction_id": "cor_1e6b…", "version": 1, "status": "active", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "comment": "Per the account plan."}
```

Now `e_read` of the record returns, beside the unchanged content:

```json
{"corrections": [{"correction_id": "cor_1e6b…", "content": "John owns the Acme renewal, not Sarah.", "authority": "human_correction", "status": "active"}]}
```

and search flags it `has_correction`. See [correcting a record](correcting-a-record.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/correct" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "create", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "content": "John owns the Acme renewal, not Sarah.", "comment": "Per the account plan.", "agent_profile": "restricted"}'
```

## 9. Connect two records and traverse

```text
e_property {"action": "connect", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98"], "hint": "plan_for", "agent_profile": "restricted"}
e_gather {"action": "traverse", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "agent_profile": "restricted"}
```

The traverse returns the plan, the adjusting record, and the records that share `org:Acme` or `topic:renewal`. See [connecting records](connecting-records.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/property" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "connect", "sr_id": ["sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98"], "hint": "plan_for", "agent_profile": "restricted"}'

curl -s -X POST "$EMEMORY_URL/api/v2/gather" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "traverse", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "agent_profile": "restricted"}'
```

## 10. Ask by time

```text
e_timeline {"action": "intersect", "match": ["org:Acme"], "start_date": "2027-03-01", "end_date": "2027-04-30T23:59:59Z", "order_by": "content_time_asc", "agent_profile": "restricted"}
```

The reply lists the records about Acme whose content names a date in March or April 2027, earliest first: the original due date, then the moved one. See [temporal retrieval](using-the-timeline.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/timeline" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "intersect", "match": ["org:Acme"], "start_date": "2027-03-01", "end_date": "2027-04-30T23:59:59Z", "order_by": "content_time_asc", "agent_profile": "restricted"}'
```

## 11. Delete

```text
e_system {"action": "delete", "sr_ids": ["sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98"], "agent_profile": "restricted"}
e_read {"sr_ids": ["sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98"], "agent_profile": "restricted"}
```

```json
{"srs": [], "not_found": ["sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98"]}
```

The record has left retrieval. Its versions and its audit events remain: `e_audit` `trace` still answers for it, and `e_system` `undelete` brings it back. Record deletes are off as shipped; this step needs the engine's owner to have turned on `deletions_enabled` — otherwise the delete is refused, naming the switch. See [deleting a record](deleting-a-record.md).

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/delete" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98"], "agent_profile": "restricted"}'

curl -s -X POST "$EMEMORY_URL/api/v2/read" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_8b2d77e1c05a9e42a7c3f1d6e5b40c98"], "agent_profile": "restricted"}'
```

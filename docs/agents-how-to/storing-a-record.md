# Storing a Record

Write new content to memory with e_ingest: the content, its edge properties, its source type, and the lane it goes to.

## When to Use
Whenever there is something to keep that memory does not already hold. For content memory already holds that has moved on, see [updating a record](updating-a-record.md) and [evolving a fact](evolving-a-fact.md).

## Usage
```text
e_ingest {"content": "...", "properties": ["label:value", ...], "source_type": "...", "assign_lane": "...", "agent_profile": "..."}
```

| Argument | Required | What it does |
|---|---|---|
| `content` | Yes | The content, as a string: text, a document, or JSON as text. Empty content is refused |
| `properties` | No | [Edge properties](../data-model/edge-properties.md) as `label:value` strings. Labels starting with `e_` are refused |
| `source_type` | No; `conversational` | The record's [source type](../governance/source-types.md). In a closed lane it must be one the lane declares |
| `assign_lane` | No; the home lane | The [lane](../governance/lanes.md) to write to. It must be declared and writable by the agent profile |
| `agent_profile` | No; the engine's default | The [agent profile](../governance/agent-profiles.md) the call runs as |
| `is_conversational` | No | Marks the record as conversation, so it gets a window vector with the turns before it |
| `is_file_content` | No | Marks the record as part of a file, for the same reason |
| `adjusts`, `adjustment_label` | No | Links the new record to earlier ones; see [evolving a fact](evolving-a-fact.md) |

Before writing to a lane, an agent can ask what it may write there: `e_system` `get_profile` returns each writable lane, its source types and the labels each allows.

## Response
```json
{"sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "status": "accepted", "content_hash": "…", "ingested_at": "2026-10-30T15:02:11Z"}
```

The edge properties are on the record when the call returns. The extractor plugins and the embedding run afterwards, in the background. A refusal is `{"error": "…"}` and names what is allowed: a lane the agent profile can write, a source type the lane accepts, or a label the source type allows.

## Example
```text
e_ingest {"content": "Acme's renewal is due on 1 March 2027. Sarah owns it.", "properties": ["org:Acme", "person:Sarah", "topic:renewal"]}
```

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/ingest" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "Acme'"'"'s renewal is due on 1 March 2027. Sarah owns it.", "properties": ["org:Acme", "person:Sarah", "topic:renewal"]}'
```

The shipped agent instructions recommend one fact per record, written to stand alone; see [source records](../data-model/source-records.md).

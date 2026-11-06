# Evolving a Fact

Record that a fact which was right has since changed: write a new record with e_ingest and link it to the earlier one with adjusts. Both stay, linked.

## When to Use
When the earlier record was true when it was written, and reality has moved on: a price renegotiated, a date moved, a decision revisited. If it was never true, [correct it](correcting-a-record.md).

## Usage
```text
e_ingest {"content": "...", "properties": [...], "adjusts": ["sr_..."], "adjustment_label": "..."}
```

The engine mints one value, `e_adjustment:<adjustment_label>_<32 hex>`, and writes it as an [edge property](../data-model/edge-properties.md) on the new record and on each record in `adjusts`. The shared value is the link. Adjusting the newer record again adds the next link, so a fact's evolution forms a chain.

Each record in `adjusts` must be in a lane the agent profile can write. One that is not is skipped and reported; the new record is still written.

## Response
The usual `e_ingest` reply, plus:

```json
{"adjustment": {"adjustment_token": "renewal_repriced_4c1e9a07d2b35f68e1a0c4d7b9f23e56", "adjusts_applied": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"]}}
```

`e_read` on either record lists the other under `adjustments`. `e_gather` and `e_timeline` flag both `has_adjustment`, and `e_gather` `traverse` walks from one to the other. Which came first is read from the ingest times.

## Example
The renewal price was right in March and changed in June.

```text
e_ingest {
  "content": "Acme renegotiated the renewal to $46,000 a year in June 2026.",
  "properties": ["org:Acme", "topic:renewal"],
  "adjusts": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"],
  "adjustment_label": "renewal repriced"
}
```

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/ingest" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "Acme renegotiated the renewal to $46,000 a year in June 2026.", "properties": ["org:Acme", "topic:renewal"], "adjusts": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"], "adjustment_label": "renewal repriced"}'
```

## Removing an adjustment

```text
e_property {"action": "unadjust", "hint": "e_adjustment:renewal_repriced_4c1e9a07d2b35f68e1a0c4d7b9f23e56"}
```

```json
{"action": "unadjust", "property": "e_adjustment:renewal_repriced_4c1e9a07d2b35f68e1a0c4d7b9f23e56", "removed": ["sr_4d91…", "sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"]}
```

`hint` is the link's value, as `adjustment_token` returned it, or the bare token. With `sr_id`, the link is removed from the named records only; without it, from every record the agent profile can read that carries it. Best-effort: records in lanes the agent profile cannot write are listed under `skipped_unwritable`, records without the link under `not_member`, unknown ids under `not_found`. The records themselves stay. Each record the link is removed from gets a new version without it; earlier versions are kept, and the audit log records the removal.

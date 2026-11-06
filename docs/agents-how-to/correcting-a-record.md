# Correcting a Record

State the truth about a record that was wrong with e_correct. The correction is attached to that one record; the record's content is not changed, and every reader gets both.

## When to Use
When the record was wrong when it was written. If it was right and has since changed, [evolve the fact](evolving-a-fact.md). If it should leave memory, [delete it](deleting-a-record.md).

| The situation | What to do |
|---|---|
| The record was never true | Correct it |
| The record was true, and the world moved on | Evolve the fact |
| The record should leave memory | Delete it |

## The calls

One correction names exactly one record, and does not change once written. To change it, retract it and create another.

| Action | Arguments | What it does |
|---|---|---|
| `create` | `sr_id`, `content`, optional `comment`, `authority` | Attaches a correction to the record. Requires write access to the record's lane |
| `retract` | `correction_id` | Retracts the correction. Requires write access to its lane |
| `inspect` | `correction_id` | Returns one correction |
| `list` | — | Lists corrections |

## Response
From then on `e_read` returns the record with its corrections beside it, and `e_gather` and `e_timeline` flag the record `has_correction`. A retracted correction is still returned by `e_read`, without its text.

A correction carries `human_correction` [authority](../data-model/authority.md) unless the call says otherwise. The engine does not check that a person made it, and search does not rank by authority.

:::note
`e_correct` `list` and `inspect` return corrections, with their text and the record each names, whatever lanes the agent profile can read.
:::

## Example
The agent recorded a date; a person reads the contract and finds it was wrong.

```text
e_correct {
  "action": "create",
  "sr_id": "sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63",
  "content": "The Acme renewal is due 2026-12-31. The earlier date was misread from a draft.",
  "comment": "Checked against the signed contract."
}
```

Days later another agent asks about the renewal. `e_gather` returns the record flagged `has_correction`, and `e_read` returns the original and the correction together.

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/correct" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "create", "sr_id": "sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63", "content": "The Acme renewal is due 2026-12-31. The earlier date was misread from a draft.", "comment": "Checked against the signed contract."}'
```

# Authority

When records disagree — a remark on a call against a signed contract — agents and auditors need to know which carries more weight, and on what basis, instead of picking the newer or better-worded one. Authority stamps every record with a level set by its source type, never raised by the agent that writes it; returns the level on every `e_read`; tells every connecting agent the order of the levels, so it weighs conflicts by a stated rule; and records the level in the audit log.

Challenges addressed: [Auditable Decision-Making](../use-cases/auditing-agentic-decisions.md), [Tracking Changes Through Time](../use-cases/data-evolution.md).

## Concepts

Authority is how much weight a record carries when two records disagree. The engine sets it from the record's source type when the record is written.

Not all knowledge is equal. eMemory tags every fact with its authority and surfaces it on read; the model weighs it, adjudicating conflicts with the precedence made explicit. Your corrections stick: they come back beside the original, for the model to weigh, and old data never silently overrides what you said last week.

Two records can disagree. One says the renewal is due in November because someone said so on a call. Another says December because the signed contract says so. An agent that picks the newer one, or the one that reads better, is guessing.

Every record carries an **authority**. The levels are ordered. The order is a convention the engine gives to every connecting agent; the agent applies it.

| Level, highest first | Meaning |
|---|---|
| `human_correction` | The default label on a correction |
| `human_confirmation` | Reserved for a fact a person confirmed. No tool assigns it by default |
| `documentary` | It was taken from a written source |
| `conversational` | It was said in conversation |
| `system_inference` | The system inferred it |

## Where a level comes from

`e_ingest` has no authority argument. The agent names a source type, and the engine writes the level that belongs to that type.

| The record is written | Its authority is |
|---|---|
| To an open lane, as `conversational` | `conversational` |
| To an open lane, as `documentary` | `documentary` |
| To a closed lane, as one of its source types | The `authority` the policy declares for that type, or `conversational` if it declares none |

A [correction](../agents-how-to/correcting-a-record.md) is separate. It carries `human_correction` unless the call says otherwise.

:::warning
`e_correct` accepts an `authority` argument and records the value it is given. The engine does not check that value against the levels above.
:::

A policy declares the level for each of its source types. Use `documentary`, `conversational` or `system_inference`. Any other value passes upload with a warning, and a value that is not one of the engine's levels then makes every ingest of that type fail.

The engine does not verify who or what is behind a level. A level says how a record was labelled when it was written.

## What the engine does with it

:::warning
With the retrieval profiles that ship, the engine does not rank or filter results by authority. `e_gather` and `e_timeline` do not return it. The agent reads the level with `e_read` and applies the order.
:::

`e_read` returns `authority_level` on every record and `authority` on every active correction attached to it. The engine also tells every connecting agent the order of the levels, in the instructions it sends when the agent connects.

## Example
An agent asks about the Acme renewal and reads the two records it finds.

```text
e_read {"sr_ids": ["sr_3f9a1c20e47b5d16a2c8e09f4b1d7e63", "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"]}
```

```json
{
  "srs": [
    {
      "sr_id": "sr_3f9a1c20e47b5d16a2c8e09f4b1d7e63",
      "content": "Sarah said on the 2026-10-02 call that the Acme renewal is due 2026-11-30.",
      "lane": "default",
      "lane_uuid": "lane_…",
      "source_type": "conversational",
      "authority_level": "conversational",
      "source_system": "acme-agent",
      "ingested_at": "2026-10-02T15:04:11.218904+00:00",
      "version": 0
    },
    {
      "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1",
      "content": "The signed Acme contract sets the renewal date at 2026-12-31.",
      "lane": "default",
      "lane_uuid": "lane_…",
      "source_type": "documentary",
      "authority_level": "documentary",
      "source_system": "acme-agent",
      "ingested_at": "2026-10-05T09:41:02.770113+00:00",
      "version": 0
    }
  ]
}
```

`documentary` is above `conversational`. The agent answers 2026-12-31 and can say why.

## Implications
**The source type decides.** An agent that wants a record to carry `documentary` must write it as a documentary record. It cannot write a conversational record and raise its level.

**An operator sets the levels for a closed lane.** The policy declares each source type and its authority. See [lanes, agent profiles and policies](../governance/lanes.md).

**A correction does not depend on the level of the record it corrects.** It is attached to the record and returned with it, whatever authority the record carries.

**The level is on the audit trail.** The event written when a record is ingested includes its authority. See [the audit log](../durability/the-audit-log.md).

## Reference

Where authority is returned: [`e_read`](../reference/tools/e_read.md). Where a correction's authority is set: [`e_correct`](../reference/tools/e_correct.md).

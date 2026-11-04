---
name: e-properties
description: Property discipline for eMemory — label:value pairs that make structural retrieval work. Standard labels, reuse before inventing, relations with connect and group, and fixing property gaps.
when_to_use: Before the first e_ingest in a session, when designing labels for a new domain, or when retrieval is noisy or incomplete (usually a property gap).
---

## Model

`label:value` — the label is the vocabulary, the value the instance: `person:Sarah Chen`, `project:billing`. A label alone marks membership: `commitment` = "this is a commitment". Properties are what `intersect`, `union`, `count` and `group` match on.

## Rules

1. 2–5 per SR: one entity + one topic.
2. Reuse labels: `e_property(action="list")`. Search them: `e_property(action="find", term="price")`.
3. Reuse values: `e_property(action="intersect", match=["person"])`. Same entity, same value.
4. `source_system:<origin>` on anything external.
5. No instance data in labels: `person:Sarah Chen` + `commitment:api_proposal`, not `sarah_commitment:api`.
6. Don't tag what no query will use (`day:tuesday`).
7. Values that may need correcting go in content, where a correction can reach them.
8. A closed lane rejects unlisted labels; the error lists them. Your allowed labels per lane: `e_system(action="get_profile", agent_profile="...")`.
9. Labels starting `e_` are engine-made; you can't add them.

## Standard labels

| Kind | Labels |
|---|---|
| Entity | `person`, `company`, `organization`, `project`, `product`, `technology`, `vendor` |
| Topic | `topic`, `decision`, `commitment`, `action_item`, `finding`, `recommendation` |
| Assessment | `priority`, `tier`, `sentiment`, `alignment`, `status`, `deal_status` |
| Provenance | `source_system`, `batch`, `file` (a path or URL the SR is about) |
| Rules | `directive`, `directive:<topic>`, `scope:global` / `scope:project` |
| Session | `session:current`, `preference`, `state` |

Extend as the domain needs; check first.

## Relations — assert them, don't imply them

A shared value says two SRs have something in common, not what passed between them. Name the relation:

```
e_property(action="connect", sr_id=["sr_a", "sr_b"], hint="employs")       # exactly two
e_property(action="group", sr_id=["sr_a", "sr_b", "sr_c"], hint="q3 launch")  # two or more
e_property(action="disconnect", sr_id=["sr_a", "sr_b"])
e_property(action="ungroup", hint="e_group:<token>")
```

Never put another record's name or sr_id in a property value.

## Fixing

- Add: `e_property(action="add", sr_id="sr_...", properties=["project:billing"])`
- Remove values: `e_property(action="remove", sr_id="sr_...", properties=["topic:db"])`
- Remove a whole label: `e_property(action="remove", sr_id="sr_...", labels=["topic"])`
- Fragmented values (`topic:db` vs `topic:database`): add the canonical one, remove the stray.

## Patterns

- **Directive:** `properties=["directive", "directive:security", "scope:global"]`; find all with `e_gather(action="intersect", match=["directive"])`. Retire one with a correction, not a delete.
- **Research:** shared `research:<topic>` on evidence, findings and the decision.
- **Session continuity:** `session:current` + a topic label on decisions and findings as they happen.
- **Boards:** `e_gather(action="group", by="deal_status")` → counts per value.

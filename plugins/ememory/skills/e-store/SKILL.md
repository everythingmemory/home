---
name: e-store
description: Store knowledge in eMemory with structure and provenance — one fact per SR, properties for retrieval, adjustments when knowledge evolves, decomposition of external data.
when_to_use: When a fact, decision, preference, commitment or finding worth keeping surfaces — from conversation, a document, or an external system. When persisting session context before it can be lost.
---

## Steps

1. Already known? `e_gather(action="find", query="...")`.
   - Same fact, now wrong → `e-correct`.
   - True then, moved on since → store a new SR with `adjusts=` (below).
   - Your own record that IS an evolving artifact → `e_update` (below).
2. Pick properties: which `intersect` query should find this? Reuse existing labels and values (`e_property(action="list")`, `e_property(action="intersect", match=["person"])`).
3. Ingest, one call per fact:

```
e_ingest(
  content="Decision: use FastAPI for the billing service.",
  source_type="documentary",
  properties=["decision:web_framework", "technology:fastapi", "project:billing"]
)
```

## Inputs

- `source_type`: `conversational` (default; preferences, informal context) or `documentary` (decisions, confirmed facts, documents). A lane may allow others; `e_system(action="get_profile")` lists them.
- `properties`: `["label:value", ...]`, 2–5. Labels starting `e_` are reserved.
- `assign_lane`: another lane you may write; omit for your home lane.
- `adjusts=[sr_ids]` (+ optional `adjustment_label`): links the new SR to the one(s) it refines.

```
e_ingest(content="Billing launch moved to 2027-05-16 (was 2027-05-07).",
         source_type="documentary",
         properties=["project:billing", "topic:deadline"],
         adjusts=["sr_abc123"], adjustment_label="deadline")
```

## e_update — the same record, next state

For a record you wrote that is itself the artifact (a plan, a roster, a running status). The `sr_id` stays, so links still point at it.

```
e_update(sr_id="sr_abc123", content="<the full new content>", note="why")
```

- `content` is the full new state, never a diff.
- `properties` merge by label: each label you pass has its values replaced; others are untouched. To remove a property use `e_property(action="remove")`.

## External data

One fact per SR, even from a compound object. Tag every SR `source_system:<origin>`; batch imports also `batch:<id>`.

```
# CRM: {"name": "Jane Park", "title": "VP Eng", "company": "Acme Corp", "deal": "evaluation"}
e_ingest(content="Jane Park is VP of Engineering at Acme Corp.", source_type="documentary",
         properties=["person:Jane Park", "company:acme_corp", "source_system:crm"])
e_ingest(content="Acme Corp is evaluating the product (CRM deal status: evaluation).",
         source_type="documentary",
         properties=["company:acme_corp", "deal_status:evaluation", "source_system:crm"])
```

## Rules

- One fact per SR; content stands alone without the conversation.
- Absolute dates: "next Friday" → "Friday 2027-05-07".
- Extract the knowledge; don't store chat logs.
- Never store secrets — store where they live ("Acme API key is in the team password manager under 'Acme'").
- Missing properties on an SR you found? Add them: `e_property(action="add", sr_id="sr_...", properties=["topic:billing"])`.

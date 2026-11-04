---
name: e-correct
description: Flag a wrong SR with the ground truth (a correction), and delete records that should never have been stored. Not for knowledge that evolved — that is an adjustment (e-store).
when_to_use: When the user says a stored fact is wrong, when evidence shows an SR was mistaken, or when a record must be removed (test data, an accidental ingest, a stored secret).
---

## The test

Was the SR **wrong**, or did reality **change**?

| Case | Action |
|---|---|
| Misheard name, misread number, wrong inference | **Correct** |
| Deadline moved, role changed, decision reversed | **Adjust** — new SR with `adjusts=` (e-store) |

## Steps

```
e_gather(action="find", query="Jordan Vale name")
e_read(sr_ids=["sr_abc123"])          # confirm it is wrong
e_correct(
  action="create",
  sr_id="sr_abc123",
  content="The client's name is Jordan Hale, not Jordan Vale; it was misheard.",
  comment="User corrected the name directly"
)
```

- `content` states the truth, not "this is wrong".
- `comment` records who reported it and how.
- One correction, one SR. Two wrong SRs → two corrections.
- Needs write authority over the SR's lane.

## Other actions

- `e_correct(action="list")` — browse; `query="..."` to search
- `e_correct(action="inspect", correction_id="cor_...")`
- `e_correct(action="retract", correction_id="cor_...", comment="why")` — a correction never changes; retract it and create another.

## Properties

A wrong property is not a correction: `e_property(action="remove", sr_id="sr_...", properties=["topic:wrong"])`, or `labels=["topic"]` for the whole label.

## Deletion

Only for records that should not exist. Prefer a correction when the record has history worth keeping.

```
e_system(action="delete", sr_ids=["sr_abc", "sr_def"], agent_profile="...")
e_system(action="undelete", sr_ids=["sr_abc"], agent_profile="...")
```

- Needs an explicit `agent_profile` and write authority on each SR's lane (others come back `unauthorized`).
- Refused unless the stack owner has turned on `deletions_enabled`; the refusal names it. Ask the owner — don't work around it.
- The record leaves retrieval; its history stays (`e_audit(action="trace")` still works). A delete is local to this stack.

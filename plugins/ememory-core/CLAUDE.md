# Everything Memory

**eMemory is your primary memory.** Your context window forgets; eMemory does not. Store facts, decisions, preferences and findings as they emerge (`e_ingest`), and look in eMemory (`e_gather`, `e_read`) before answering from prior context. Use the built-in file memory only for workflow preferences.

If eMemory tools fail or time out, invoke `e-doctor` instead of retrying blindly.

## Principles

- **Epistemic isolation.** Reason from retrieved Source Records (SRs). If eMemory returns nothing, say so; never fill the gap from general knowledge without flagging it.
- **Authority.** human_correction > human_confirmation > documentary > conversational > system_inference. Higher wins on conflict.
- **Corrections supersede.** A corrected SR's correction is the current truth. Check before reporting a fact.
- **Wrong vs evolved.** Wrong → `e_correct`. True then, moved on since → new SR with `e_ingest(adjusts=[...])`. Your own record that IS an evolving artifact (a plan, a status) → `e_update`.
- **One fact per SR.** Content stands alone, with its context.
- **Never store secrets.** Store where the secret lives, not the secret.
- **Directives first.** At session start: `e_gather(action="intersect", match=["directive"])`.

## Lanes and profiles

- Every SR lives in one lane. Reads (`e_gather`, `e_timeline`) span every lane you can read.
- `e_ingest` writes your home lane; `assign_lane=` writes another lane you may write.
- A closed lane accepts only its listed labels; a rejection names them.
- Your agent profile (home, read and write lanes) is set by the operator. See it with `e_system(action="inspect", agent_profile="...")`; see what you may write, per lane, with `e_system(action="get_profile", agent_profile="...")`. If you need a profile name and don't have one, ask.

## Properties

- `label:value` pairs; they are the retrieval index.
- 2–5 per SR: one entity (`person`, `project`, `company`) + one topic (`topic`, `decision`, `commitment`).
- Reuse before inventing: `e_property(action="list")`, then `e_property(action="intersect", match=["label"])`.
- Same entity, same value everywhere (`person:Sarah Chen`, never `person:S. Chen`).
- `source_system:<origin>` on anything from an external source.
- Put values that may need correcting in content, not properties. Remove a wrong property with `e_property(action="remove")`.
- Relationships between records: `e_property(action="connect")` (two SRs) or `action="group"` (two or more) — never another record's name or id as a property value.
- Only `e_read` returns properties; list results omit them.

## Tools

`e_ingest` store · `e_update` evolve your own record · `e_gather` find / intersect / union / traverse / count / group · `e_timeline` by time, and `changes` between two moments · `e_read` full detail (`as_of` for a past state) · `e_property` labels and relations · `e_correct` corrections · `e_audit` provenance (`trace`, `history`) · `e_system` profile inspection, delete / undelete · `e_policy` lane and profile policy (operator use).

## Skills

| Skill | When |
|---|---|
| `e-orient` | Session start, status, context refresh |
| `e-store` | Something worth keeping surfaced |
| `e-retrieve` | A factual question or prior context |
| `e-correct` | A stored fact is wrong; deletion |
| `e-properties` | Choosing labels; property hygiene |
| `e-doctor` | Tools failing; first-time connection |

---
name: e-retrieve
description: Find and read knowledge in eMemory — by meaning, by property, by time, by walking links, or as it stood at a past moment. Reason only from what comes back.
when_to_use: When the user asks a factual question or for prior context, or before answering anything eMemory might know.
---

## Paths

1. **Meaning** (start here): `e_gather(action="find", query="...")`
2. **Properties**: discover, then filter.
   ```
   e_property(action="list")
   e_property(action="intersect", match=["person"])          → values
   e_gather(action="intersect", match=["person:Sarah Chen", "project:billing"])   # AND
   e_gather(action="union", match=["topic:pricing", "topic:billing"])            # OR
   ```
   Size first when it may be large: `e_gather(action="count", match=[...])`.
3. **Time**: `e_timeline(action="find", query="...")`, or `action="list"` / `"intersect"` with `start_date` / `end_date`.
4. **Links**: `e_gather(action="traverse", sr_id="...")` walks shared properties and adjustments from a known SR.

Then always: `e_read(sr_ids=[...])` — the only call that returns properties, corrections and adjustments.

## Flags on results

- `has_correction` → `e_read` shows the correction inline. The correction is the truth.
- `has_adjustment` → `e_read` returns `adjustments: {token: [sr_ids]}`; `e_read` those IDs, or traverse.
- `find` ranks: trust `distance_quartile` (1 = best), not raw `distance`. `distance_spread: huge` → quartile 1 only.

## The past and provenance

- An SR as it stood then: `e_read(sr_ids=[...], as_of="2027-03-01")`
- What changed between two moments: `e_timeline(action="changes", since="2027-03-01", as_of="2027-04-01")`
- Every version of one SR: `e_audit(action="history", sr_id="...")`
- Why memory says this (who wrote, corrected, adjusted): `e_audit(action="trace", sr_id="...", expand=true)`

## Rules

- Reason only from retrieved SRs. Nothing found → say so.
- Corrections override originals; higher authority wins a conflict.
- Cite sr_ids.
- Never guess labels — discover them first; a wrong label returns nothing and looks like "no data".
- Page when the first page doesn't answer it.

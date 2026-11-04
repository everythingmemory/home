---
name: e-orient
description: Orient from eMemory at session start — standing directives, recent activity, active corrections, and what the knowledge base holds.
when_to_use: At session start, after context compaction, when the user asks for a status or briefing, or when switching project.
---

## Steps (4–6 calls; a survey, not research)

1. Directives — they bind everything that follows:
   `e_gather(action="intersect", match=["directive"])`
2. What's tracked:
   `e_property(action="list")` → labels with counts
3. Recent activity:
   `e_timeline(action="list", order_by="ingest_time_desc")`
   and, if the convention is in use, `e_gather(action="intersect", match=["session:current"])`
4. Corrections:
   `e_correct(action="list")`
5. Read the few SRs that matter:
   `e_read(sr_ids=[...])`

New deployment or unknown scope: `e_system(action="inspect", agent_profile="...")` → home, read and write lanes, SR counts per lane.

## Output

3–6 sentences:
- **Directives:** standing rules, if any
- **What's here:** SR counts, main projects / people / topics
- **Recent:** what was stored or corrected lately
- **Corrections:** any that change current understanding — lead with these

Empty or sparse eMemory: say so. Never fill in from general knowledge.

## Rules

- Fast, read-only. Note SRs with no properties as gaps; fix them later, not here.
- Summarize; the user drills down.

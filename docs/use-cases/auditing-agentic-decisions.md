---
title: "Auditable Decision-Making"
sidebar_position: 1
kind: concept
status: drafted
verified_against: null
lede: "In a governed enterprise, people must be able to trace why an agent made a decision back to the data it held at that moment: where that data came from, how much authority it carried, who recorded it, and whether it had since been corrected, even as data is updated, corrected and retracted over time. Everything Memory records provenance on every record; keeps every earlier version, correction and audit event; links each correction and adjustment to the exact records it affects; and bounds each agent's reads and writes by lane."
---

## Approach
Real-world data is never static: facts are updated, corrected, retracted and restated. An agent records information as it arrives and makes its decisions from what it has stored, and without a trail back to that data, AI cannot be trusted with consequential work.

Data held only in a context window or in a vendor's notes cannot show where it came from, who could change it, or what was written. Everything Memory is built the opposite way: every fact is accountable by construction.

- **Full provenance on every fact.** Each record keeps its source, source type, authority level and timestamp. "Where did the agent learn that?" has an answer, every time.
- **History that stays.** An update keeps every earlier version in the record's ledger; a retracted correction remains as a stub; a delete takes the record out of retrieval — its row, edge properties and vectors are removed — while its tombstone, its update ledger (the final version included) and its audit events stay.
- **Traceable lineage.** Every correction and adjustment links to the exact records it affects (no fuzzy matching) and surfaces on read: walk a fact from today's version back through every change.
- **Scoped access and authority.** Lane-based read and write grants in agent profiles bound what each agent can see and change; the authority levels make precedence explicit and inspectable.
- **Data residency on your terms.** Run it self-hosted or local, with no internet access — sensitive memory never has to leave your perimeter.

- **Provenance on every record.** Each [source record](../../data-model/source-records/) carries the system that wrote it, its source type, its [authority](../../data-model/authority/) and when it was written. `e_read` returns all of them.
- **An audit log of writes.** Ingests, updates, corrections, adjustments, edge properties added with `e_property` or removed, deletions and policy changes each write an event, in the same transaction as the change. Each event names the record, the lane, the agent profile named on the call and, with authentication on, the credential that made it. `e_audit` reads them back, and `trace` still works after the record is deleted. See [the audit log](../../durability/the-audit-log/).
- **Corrections kept beside the original.** A [correction](../../agents-how-to/correcting-a-record/) is attached to the record it corrects; the record is not changed. A reader sees both what was written and what is true.
- **Separate work areas.** [Lanes](../../governance/lanes/) and [agent profiles](../../governance/agent-profiles/) keep each agent's records in its own lane. An evaluating agent can read other agents' lanes and write its findings to its own — oversight as a derivative work, with nothing of the originals disturbed.

## Example
Days after an agent told Mary that Sarah picked Postgres for analytics, she asks why.

```text
e_audit {"action": "trace", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1", "expand": true}
```

The reply lists, oldest first, the ingest of the record (by which agent profile, system and credential), the correction attached to it a week later ("ClickHouse, not Postgres"), and the record and correction in full.

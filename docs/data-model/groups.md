---
title: "Groups"
sidebar_position: 3.1
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "Agents often need records back together that belong under one name — the people at a meeting, the documents of a deal, the steps of a plan — without copying them or moving them between lanes. A group writes one named membership on two or more records; any member finds the rest, by traverse or by matching the group's value; members stay in their own lanes; a record that cannot be written is skipped and reported, not fatal to the rest; and each change is audited."
---

Challenges addressed: [Multi-Agent Coordination](../../use-cases/agent-swarm-coordination/).

## Concepts

A group is a named membership a caller asserts among two or more records, such as "the attendees of the Acme kickoff". The engine writes it as one edge property value every member shares, so the whole group is found from any one member.

Where a [connection](../connections/) states how two records relate, a group states that several records belong together under one name. A group of two is still a group: it says the two belong together, not how one relates to the other.

## Writing and removing a group

| Action | Records | Writes | When a record cannot be written |
|---|---|---|---|
| `group` | two or more | `e_group:<hint>_<token>` on each | the others are written; the reply lists the rest under `skipped_unwritable` and `not_found` |
| `ungroup` | the group's value as `hint` (`e_group:<token>` or the bare token); optionally the records in `sr_id` | removes the value from the named records, or from every holder the agent profile can read | the others are removed from; the reply lists the rest under `skipped_unwritable`, `not_member` and `not_found` |

As with connections, the caller supplies the meaning in `hint` and the engine adds a unique 32-character token, so each `group` call makes a new group. The label `e_group` is reserved: `group` and `ungroup` are the one way to write and remove it. Members must be in lanes the agent profile can write.

`group` and `ungroup` are best-effort: they do what they can and report the rest. Removal writes a new version of each record without the value, keeps the earlier versions, and records a `property_removed` event for each in the [audit log](../../durability/the-audit-log/).

## Example

```text
e_property {"action": "group", "sr_id": ["sr_1a…", "sr_2b…", "sr_3c…"], "hint": "acme kickoff attendees"}
```

The reply returns the group's value, `e_group:acme_kickoff_attendees_<token>`, and the records it was written on.

## Implications
**Any member finds the rest.** `e_gather` `traverse` from one member, or `intersect` on the group's value, returns the whole group.

**A group can span lanes.** Members stay in their own lanes; the group is visible to an agent only where it can read the members.

## Reference

How-to: [grouping records](../../agents-how-to/grouping-records/). Every argument: [`e_property`](../../reference/tools/e_property/).

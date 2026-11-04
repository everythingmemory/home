---
title: "Adjustments"
sidebar_position: 3.2
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "Agents tracking facts that change — a price renegotiated, a date moved — need the earlier value kept as true for its time, not overwritten, and the later one linked to it. An adjustment writes the new fact as its own record and links it to the one it evolves; both keep their own time, source and authority; successive adjustments form a chain that every read shows, search results flag and traverse walks; and each link written or removed is audited."
---

Challenges addressed: [Tracking Changes Through Time](../../use-cases/data-evolution/), [Point-in-Time Recall](../../use-cases/what-was-true-when/).

## Concepts

An adjustment links a newer record to an earlier one it evolves: the earlier fact was true when it was written, and reality has since moved on. Both records stay, linked, and a fact's evolution forms a chain.

Facts change in three ways, and eMemory records each differently:

| What happened | How it is recorded |
|---|---|
| A fact was right, and has since changed — a price renegotiated, a date moved | **an adjustment**: a new record, linked to the earlier one |
| The record is a document or plan that moved on, and one record should hold its current state | **an [update](../source-records/#updating-a-record)**: the next version of the same record |
| The record was never true | **a [correction](../../agents-how-to/correcting-a-record/)**: attached to it, stating the truth |

An adjustment keeps both facts as facts: what was true in March and what is true in June are separate records, each with its own time, source and authority.

## How an adjustment is written

The newer record is written with `e_ingest`, naming the earlier records in `adjusts` and the change in `adjustment_label`. The engine mints one value, `e_adjustment:<label>_<32 hex>`, and writes it as an edge property on the new record and on each record it adjusts. The shared value is the link. Adjusting the newer record again adds the next link.

Each adjusted record must be in a lane the agent profile can write; one that is not is skipped and reported, and the new record is still written.

`e_property` `unadjust` removes the link — from the named records, or from every holder the agent profile can read — and leaves the records themselves in place. The label `e_adjustment` is reserved: `adjusts` and `unadjust` are the one way to write and remove it.

## Implications
**Reads show the chain.** `e_read` on either record lists the other under `adjustments`; `e_gather` and `e_timeline` flag both `has_adjustment`; `e_gather` `traverse` walks from one to the other. Which came first is read from their ingest times.

**Each step is audited.** The link's writing and removal are events in the [audit log](../../durability/the-audit-log/).

## Reference

How-to: [evolving a fact](../../agents-how-to/evolving-a-fact/). Every argument: [`e_ingest`](../../reference/tools/e_ingest/), [`e_property`](../../reference/tools/e_property/).

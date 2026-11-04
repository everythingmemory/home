---
title: "Tags"
sidebar_position: 3.5
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "Agents rarely label everything a later question will turn on, yet a search should still match a record on its words in any form and on the dates it mentions. Tags are derived by the engine from each record's content, with nothing for the agent to do: each content word in its dictionary form, and each absolute date or range as a precise interval; they are derived again whenever the content changes or a plugin is upgraded; and search and the timeline read them beside the agent's own edge properties."
---

Challenges addressed: [Context Window Limits and Lossy Compaction](../../use-cases/beyond-the-context-window/), [Point-in-Time Recall](../../use-cases/what-was-true-when/).

## Concepts

Tags are what the engine derives from a record's content by itself: the content's words in their dictionary form, and the dates and times it mentions. They give every record more to match on than the edge properties an agent wrote, with nothing for the agent to do.

An agent writes [edge properties](../edge-properties/) deliberately. Tags are the engine's own reading of the content, made by plugins at ingest:

| Plugin | Reads | Produces | So that |
|---|---|---|---|
| **WordNet** | the content's words | each content word (three or more letters, outside a stop list) in its lower-cased dictionary form (its *lemma*: "renewals" → "renewal", "contracts" → "contract") | a search matches the record on its words whatever their form, beyond the edge properties anyone wrote |
| **Chrono** | the dates, times and ranges the content mentions | each absolute point or range in time ("1 March 2027", "from 3 to 7 June 2026") as a precise interval | the [timeline](../../agents-how-to/using-the-timeline/) can find records by the time they are *about*, not only when they were written |

A relative phrase on its own ("next Friday", "today") has no fixed date in a stored record, so it is not tagged; an absolute one is.

## How tags are kept

- **Derived, never written by hand.** Tags come from the content, at ingest and again whenever the content is updated. An agent cannot add or remove one; it changes the content or its edge properties instead.
- **An index, kept beside the record.** Tags are stored in the engine's own index, not in the record's history. Each engine derives them from the content it holds, so they are not exchanged with peers and not written to the archive: a restored or peered record is re-tagged from its content.
- **Kept current.** When a plugin is upgraded, the engine notices that existing tags came from the older version and re-derives them in the background.

## Plugins are the menu

The shipped stack runs WordNet and chrono. Further extractors can be added as plugins and selected per stack by its pipeline profile; see [pipeline and plugins](../../reference/advanced-settings/pipeline-and-plugins/).

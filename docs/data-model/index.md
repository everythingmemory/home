---
title: "Data Model"
sidebar_position: 0
kind: concept
status: drafted
verified_against: null
lede: "What an engine stores: source records, the edge properties that join them into a hypergraph, connections and groups, the authority each record carries, and corrections and adjustments. The rules that govern them are in the governance model."
---

The model is designed to be as simple as possible while providing maximum flexibility in what it can represent.

```mermaid
flowchart TB
  record["Source record<br/>any content"]
  props["Edge properties<br/>label:value = hyperedge"]
  idioms["Idioms: annotation, adjustments,<br/>connections, groups"]
  corr["Correction"]
  gov["Governance model<br/>policies, agent profiles, lanes, source types"]

  record -- carries --> props
  props -- "joins every record sharing it" --> record
  idioms -- "written as" --> props
  corr -- "attached to" --> record
  gov -. governs .-> record
```

## The parts

**Source record.** Data — any content an agent or a program stores: a sentence, a document, a large JSON object, a part of a file — kept as it was written, with its source type, [authority](authority/), the system that wrote it and when. See [source records](source-records/).

**Edge properties.** The core of the data model: `label:value` pairs on a record, like `person:Sarah` or `topic:database`. When two or more records share one, an edge is imputed — one N-ary edge touching every record that carries it. The records and their edge properties form the Edge Property Graph, a hypergraph. Agentic annotation, adjustments (a linked list), connections (1-to-1) and groups (membership) are idioms on that one mechanism. See [edge properties](edge-properties/).

**Connections and groups.** The asserted kind of edge: a named relation or membership, written by the engine as one reserved edge property value shared by every member. See [connections](connections/) and [groups](groups/).

**Authority.** How much weight a record carries, set by its source type and returned by `e_read`. See [authority](authority/).

**Corrections.** The truth, attached to the record it corrects. The record's content is not changed. See [corrections](../agents-how-to/correcting-a-record/).

**Adjustments.** A newer record linked to an earlier one that was right and has since changed. See [updates and adjustments](../agents-how-to/evolving-a-fact/).

**Governance.** Policies, agent profiles, lanes and source types decide who reads and writes what, and what a record may be. See the [governance model](../governance/).

**Durability and the mesh.** The [archive](../durability/) keeps a copy from which an engine is rebuilt; the [mesh](../architecture/distributed-mesh-architecture/) exchanges records between engines.

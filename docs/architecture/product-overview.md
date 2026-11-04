---
title: "Product Overview"
slug: /
sidebar_position: 0
sidebar_label: "Product Overview"
kind: concept
status: drafted
verified_against: null
lede: "Everything Memory is the system of record for AI agents. Agents write records and read them back through ten tools over MCP. The engine keeps each record as it was written, where it came from, and what later happened to it — and never forgets."
---

Everything Memory — eMemory for short — is the system of record for AI agents: the store of facts they write to and read from, kept with its full history. An agent reaches it through ten tools over the Model Context Protocol (MCP). A program that is not an agent reaches the same operations through a REST API.

![One memory, everywhere: one eMemory, reached over MCP by every surface](/img/one-memory-everywhere.svg)

Everything Memory (eMemory):

- provides long-term memory for AI agents, built on **provenance**;
- stores knowledge as **source records** that trace to their source;
- retrieves it with **precision** — by meaning, by edge property and by time;
- **corrects** it when it's wrong, or **adjusts** it when it evolves;
- works with any model whose client speaks **MCP** — Claude, OpenAI, your own.

It gives your models a foundation of what was said, by whom, at what authority — and what was later corrected — and it remembers the **why** behind every fact. *"Why did you say that?"* — *"Because you corrected me last month."* Everything Memory tracks how your information evolves over time **without losing the details**: a timeline substrate for deep, durable agent memory. That kind of remembering becomes **learning** — accumulating what is specifically true about you and the agentic workflows you run.

## The agentic memory challenge

The things that are genuinely hard about memory for agents, and how Everything Memory meets them:

| | |
|---|---|
| **Agents need to remember everything** | History by design — nothing compacted or summarized away; an update or a delete keeps every version in a ledger. Facts kept verbatim; the full history of knowledge is kept |
| **Agents need a memory that helps them learn** | Teach it your private, ever-changing knowledge — no retraining. Tell it once, correct it when it's wrong, and it sticks. Persists across sessions, agents, and models |
| **Agents need to deal with real-world data messiness** | Facts conflict, evolve, and arrive at different levels of authority. eMemory absorbs the mess: correct, adjust, tombstone. It surfaces authority and history so the agent resolves — no recency guesswork |
| **Agents need to understand and leverage data provenance** | Not just storage — knowledge. Every fact carries provenance and authority. Its instructions tell the agent to reason only from what it retrieves, and to say *I don't know* when memory is silent |
| **Agents need to produce explainable, auditable results** | Every fact traces to its source. Every write is a retained, queryable event in the [audit log](durability/the-audit-log/). Show what was recorded, when, by which credential, and what later corrected or adjusted it |
| **Agent memory needs to be owned by you** | One governed memory — person, team, workgroup, or whole enterprise. Lane-scoped: isolated where they must be, shared where they should |
| **Agent memory needs to support strict compliance standards** | Governing policies, full provenance, history that is kept. Lane-based access and data residency on your terms. The audit log and provenance an auditor can inspect |
| **The enterprise needs an agent memory bus** | One system of record for everything agents know. A shared memory bus all agents read and write through, over MCP. Every model and surface plugs into the same governed memory |

## What it stores

The unit is the **source record**: one piece of content, kept exactly as the caller sent it. With the content the engine keeps:

- the **lane** the record lives in;
- its **source type** and **authority** level;
- the name of the system that wrote it — the MCP client's own name, or the name a REST caller gives — and the time it was written;
- its **edge properties**: `label:value` pairs such as `person:Sarah` or `org:Acme`.

Records that carry the same edge property are linked by it. Extractor plugins also read each record's content in the background; what they return is kept as the record's **tags**, which retrieval reads and `e_read` does not show. See [Data model](data-model/).

## What happens to a record later

- An **update** replaces a record's content. The record keeps its id, and each earlier version is kept in the record's ledger.
- A **correction** states the truth about a record that was wrong. The record's content is not changed; the correction is returned with it.
- An **adjustment** is a new record linked to an earlier one that was right and has since changed.
- A **deletion** takes the record out of retrieval on this engine; the record's history stays, the deleted state included, and an **undelete** brings it back. A deletion is local: it is never sent to peers. Record deletes are off until the engine's owner turns on `deletions_enabled`.

Changes write events to an **audit log**, which an agent reads with `e_audit`. See [the Agent Guide](agents-how-to/).

## How records are found

`e_gather` finds records by meaning, by edge property, or by walking the edge properties a record shares with others. `e_timeline` returns records in time order. `e_read` loads the full detail of the records found, with their corrections and adjustments. See [the Agent Guide](agents-how-to/) and [Hybrid Retrieval](architecture/how-search-ranks-results/).

## Who may read and write what

Every record lives in exactly one lane. An **agent profile** names the lanes a call may read and write. The caller names the agent profile on the call; a call that names none runs under the engine's default agent profile. Nothing checks which agent profile a caller names; see the [operator guide](operator-guide/) for client keys. A **policy**, a YAML document, declares the lanes, source types, labels and agent profiles an engine runs with. See [Governance Model](governance/).

## Keeping and sharing

Postgres is the live index; the **archive** is the durable store it can be rebuilt from. The engine writes its records, and what has happened to them, as objects in S3-compatible object storage — the stack's bundled archive store by default. An engine that loses its database rebuilds from the archive. See [Durability](durability/).

Engines connected to one another form a **mesh**. Peering sets two engines up as **peers**; they then exchange records. See [Mesh](architecture/distributed-mesh-architecture/).

## How it is used

An operator starts the stack, sets its keys and connects clients: see the [operator guide](operator-guide/). An agent connects over MCP and stores, finds, reads, updates, corrects and deletes records with ten tools: see the [agent guide](agents-how-to/), starting with [a walkthrough](agents-how-to/walkthrough/). A program uses the same operations over REST.

## Where it runs

eMemory is a set of containers started with Docker Compose, on hardware you choose, with no internet access needed: the embedding model runs in the stack. See [microservice architecture](architecture/microservice-architecture/) and [deployment options](deployment-options/).

---
title: "Lanes"
sidebar_position: 1.5
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "Teams, clients and roles working through one memory need their work kept apart: each agent working where it is meant to without disturbing anyone else's, and each body of work kept in one consistent shape. A lane is that separate workspace: every record lives in exactly one; each agent reads and writes the lanes its profile grants; a lane's source types keep its records consistent; a lane can stay on this engine for good or be shared with chosen peers; and records in different lanes stay linked by the edge properties they share."
---

Challenges addressed: [Multi-Agent Coordination](../../use-cases/agent-swarm-coordination/), [Multi-Agent Isolation](../../use-cases/multi-agent-isolation/), [Auditable Decision-Making](../../use-cases/auditing-agentic-decisions/), [Enterprise Distributed Memory Requirements](../../use-cases/enterprise-memory-mesh/).

## What a lane is

A lane is the workspace a record lives in. Every record is in exactly one lane, and who may read and write it and what it may carry are decided by its lane; whether it leaves the engine is decided by the shares of its lane's policy.

A record's lane is fixed when it is written. Lanes run side by side — a team, a client, a role, a body of work — like swim lanes in a pool.

A lane decides three things for every record in it:

| The lane decides | So that |
|---|---|
| **who may read and write it** — through each agent's profile: a home lane, and grants on others | agents see only the work they are meant to, and cannot disturb anyone else's |
| **what a record in it may be and carry** — through the lane's [source types](../source-types/) | the records of one workspace stay in one consistent shape |
| **whether it leaves the engine** — through the shares of the policy that declares it: a lane crosses only to peers its policy is shared with and that accept it | a lane can stay on this engine for good, or be shared with chosen peers |

Records in different lanes are still linked by the [edge properties](../edge-properties/) they share, so an agent that may read both lanes sees the connections between them.

![Lanes crm, ops and people, each holding its own records, linked across lanes by shared edge properties such as org:Acme](/img/lanes.svg)

## Where a record goes

A record lands in the writing agent's home lane, or in another lane the agent names and may write. Reads — search, read, timeline and audit — span every lane the agent may read.

## How lanes are made

Lanes are declared in a policy, with their source types and the agent profiles that use them. How to declare them, how lanes are named and shown, and every rule: [lanes in governance](../../governance/lanes/).

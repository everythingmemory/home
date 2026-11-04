---
title: "Multi-Agent Isolation"
sidebar_position: 7.5
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "One engine serving many agents (separate clients, teams, matters or roles) is safe only if their data is kept apart: one client's support agent must not find another client's records, a research agent must not overwrite the legal team's, and a site's records must not reach a peer unless someone decided they should. Everything Memory keeps every record in exactly one lane; enforces each agent profile's lanes on every search, read and write; lets a lane close its vocabulary; and decides, per policy and per peer, what may leave the engine."
---

## Approach
All of it is done with [policies](../../governance/policies/) and [lanes](../../governance/lanes/):

- **Every record lives in exactly one lane.** A lane is a separate workspace: what is in it is read, written and shared as a unit.
- **Each agent works through an agent profile.** An [agent profile](../../governance/agent-profiles/) names the agent's home lane and the other lanes it may read or write — nothing more. The engine enforces it on every call: a search, a read, the timeline and the audit log return only records in lanes the profile may read, and a write to a lane the profile may not write is refused, naming the lane.
- **A lane can close its vocabulary.** Its [source types](../../governance/source-types/) list the labels allowed there, so agents in a lane write the shape of record that lane expects.
- **What leaves the engine is decided per peer.** This engine shares a policy with a peer and the peer accepts it; only then do that policy's lanes cross. Nothing crosses by default. See [enterprise distributed memory requirements](../enterprise-memory-mesh/).
- **Deletion is local.** A deletion on one engine never removes records from another.

Isolation and [coordination](../agent-swarm-coordination/) are the same mechanism used two ways: grant read on another lane and agents build on each other's work; grant nothing and they never see each other.

## What isolation covers
The agent profile is named on each call, and the engine enforces that profile's lanes. A client key does not itself limit which profile its holder may name. So give each agent's harness its own profile and its own key, and keep keys as you would any credential: the key's holder decides which profile it acts as, and every act is recorded in the audit log under that key.

## Example
A policy with one lane per client:

| Agent | Home lane | Also reads | Also writes |
|---|---|---|---|
| Support agent, Acme | `client-acme` | — | — |
| Support agent, Globex | `client-globex` | — | — |
| Account review | `review` | `client-acme`, `client-globex` | — |

The Acme agent searches for "renewal terms" and finds only Acme's records; the same search from the Globex agent finds only Globex's. Neither can write in the other's lane — the write is refused, naming the lane. The review agent reads both and writes its findings in `review`, which neither support agent can see.

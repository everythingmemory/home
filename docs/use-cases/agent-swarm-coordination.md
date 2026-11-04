---
title: "Multi-Agent Coordination"
sidebar_position: 7
kind: concept
status: drafted
verified_against: null
lede: "A team of agents needs a shared picture of the work without agents overwriting each other's data, without a message bus between them, and with a way to trace afterwards which agent wrote what, and from which records. Everything Memory gives each role its own lane through a policy and agent profiles; lets an agent read others' lanes and write derivative records in its own, linked by shared edge properties; keeps every earlier version; and records the source, authority and agent profile of every write."
---

## Approach
- **The work is partitioned.** A [policy](../../governance/policies/) declares a [lane](../../governance/lanes/) per role and an [agent profile](../../governance/agent-profiles/) per agent: a home lane to write in, and other lanes it may read. The lane's [source types](../../governance/source-types/) constrain what each role writes.
- **Agents build on each other's work.** An agent reads another's lane and writes its own derivative records in its own lane, linked to the originals through shared [edge properties](../../data-model/edge-properties/) such as `org:Acme`. The originals are never touched.
- **Relations are asserted.** [Adjustments](../../agents-how-to/evolving-a-fact/) chain a newer record to the one it evolves; [connections](../../data-model/connections/) and [groups](../../data-model/groups/) assert named relations. Each needs write access to the lanes of the records it links.
- **Changes are kept over time.** Updates keep every earlier version; corrections and adjustments are dated in the audit log.
- **It is auditable.** Every record carries its source system, source type and authority; every write names the agent profile and, with authentication on, the credential. See [auditing](../auditing-agentic-decisions/).

![Lanes crm, ops and people, each holding its own records, linked across lanes by shared edge properties such as org:Acme](/img/lanes.svg)

No messaging, no agent blocking on another: the memory is the channel, the shared edge properties are the wiring.

## Patterns

Lanes and agent profiles let you orchestrate how agents build on each other's work without interfering with each other, or even knowing the others exist.

- **Separation of concerns.** One agent owns its lane and does one job: a support agent fills `ops` with the records of its world, oblivious to any other agent. A second agent has a different role and a different lane — granted read on `ops` and write on `crm` — so it can study the first agent's records and create its own derivative ones in `crm`: a follow-up, a risk, a state change that links back to the originals through shared edge properties (`org:Acme`) yet lives entirely in its own lane. The first agent's data is never touched; the second builds a new layer on top.
- **Results-based, auditable evaluations.** Stack more roles and it compounds. An evaluating agent reads the others' lanes and writes its own records that flag drift or degradation, or that propose skill and prompt improvements: oversight as a derivative work, with nothing of the originals disturbed.
- **Dynamic human-in-the-loop handling.** An agent scans across lanes for a record that needs a person's judgment, solicits it through an agent interface, and writes the answer back as an adjustment; the original agents come around later, see it resolved, and carry on. The adjustment links to the original when the agent can write the original's lane; otherwise the answer is linked by shared edge properties.
- **Many more patterns.** Pipelines, reviewers, summarizers, escalators, evaluators, human-in-the-loop. Each is a focused role reading only what it's granted and writing only what it owns.

## Example
| Agent | Agent profile's home lane | Also reads | Also writes |
|---|---|---|---|
| Researcher | `research` | — | — |
| Analyst | `analysis` | `research` | — |
| Reviewer | `review` | `research`, `analysis` | `analysis` |

The researcher records a finding:

```text
e_ingest {"content": "Acme's Q3 churn was 4.1%, per the Q3 board pack.", "source_type": "documentary", "properties": ["org:Acme", "topic:churn"], "agent_profile": "researcher"}
```

The analyst finds it, and writes its analysis in its own lane, on the same edge properties:

```text
e_gather {"action": "intersect", "match": ["org:Acme", "topic:churn"], "agent_profile": "analyst"}
e_ingest {"content": "Acme's churn is rising: 4.1% in Q3 against 2.8% in Q2.", "properties": ["org:Acme", "topic:churn"], "agent_profile": "analyst"}
```

The reviewer reads both, finds the Q2 figure was 3.8%, and attaches a correction to the analyst's record with `e_correct`, which it may do because it can write `analysis`. The analyst's next read of its record shows the correction beside it.

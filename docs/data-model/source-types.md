# Source Types

Records of many kinds — contacts, contracts, meeting notes — written by many agents need to be told apart, weighed and kept in one shape, or labels drift and records that should meet never do. A source type names each record's kind; sets how much weight it carries; limits the labels, values and JSON keys it may hold, refusing a write that breaks them with a message naming what is allowed; and is plain data in a policy, so changing it needs no migration.

Challenges addressed: [Multi-Agent Coordination](../use-cases/agent-swarm-coordination.md), [Auditable Decision-Making](../use-cases/auditing-agentic-decisions.md).

## What a source type is

A source type is the kind of a record — a contact, a contract, a meeting note. It gives a lane a lightweight data model: each record is typed, the type sets how much weight the record carries, and the type limits which labels, values and content shapes it may have.

Every record names its source type when it is written. A source type is declared on a lane, and does three things:

| A source type | So that |
|---|---|
| **types the record** — `contact`, `contract`, `meeting` | agents and people can tell what kind of thing a record is, and find every record of a kind |
| **sets its [authority](authority.md)** — how much weight the record carries | a signed contract outweighs a conversational remark when the two disagree |
| **limits its shape** — which edge-property labels it may carry, which values a label may take, whether its content must be JSON with given keys | the records of one kind stay consistent, and `org:Acme` never drifts into `company:Acme` |

A lane that declares no source types is **open**: it accepts the two built-in types, `conversational` and `documentary`, with any labels. A lane that declares its own is **closed** to them: only its types, and only the labels they allow.

## How source types are made

Source types are declared on a lane in a policy. What each declaration enforces, the built-in types, and examples: [source types in governance](../governance/source-types.md).

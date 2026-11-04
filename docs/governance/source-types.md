---
title: "Source Types"
sidebar_position: 4
kind: concept
status: drafted
verified_against: null
lede: "An owner with many agents writing to one lane needs them to share one vocabulary, or `org:Acme` and `company:Acme` never meet and the memory sprawls. Source types, declared on a lane in a policy, close it to every label they do not list; can restrict a label to a set of values and require JSON content with given keys; fix each record's authority by its type; and refuse a bad write with a message naming what is allowed, so agents correct themselves."
---

Challenges addressed: [Multi-Agent Coordination](../../use-cases/agent-swarm-coordination/), [Context Window Limits and Lossy Compaction](../../use-cases/beyond-the-context-window/).

## Concepts

A source type is a kind of source record, declared on a lane in a policy. It adds a lightweight data architecture: each record is typed, the type sets the record's authority, and the type limits which edge-property labels, label values and content shapes the record may carry.

Edge properties are the essential connection construct. Because of that, edge-property hygiene matters — it's what lets agents curate, connect, and manage source-record data in a predictable way. If every agent invents its own labels, `org:Acme` and `company:Acme` never meet. The optional **source type** was created for that reason: it defines the set of allowed property labels as a constrained set an agent may choose from. That avoids edge-property sprawl.

Source types — and the label vocabulary each may carry — are declared in [policy](../policies/), on a lane, not hard-coded. They are data, not code: there is no schema migration, and a change is a new policy version, kept in the policy's ledger with the rest of it.

## Typing

Every record names a source type when it is written (`source_type` on `e_ingest`; `conversational` when omitted). The engine resolves the name within the target lane and stamps the type on the record.

| Lane | Source types it accepts | Labels |
|---|---|---|
| **Open**: declared with no source types | The builtins `conversational` and `documentary` | Any |
| **Closed**: declares one or more source types | Only its own enabled source types; the builtins are refused | Only the labels the chosen type allows |

A lane no running policy declares takes no write.

## What a source type can require

| Declared on the type | What the engine enforces |
|---|---|
| `allowed_labels` | A write with any other label is refused. A type with no labels allows none |
| `values` on a label | The label is closed to those values. A label without `values` takes any value |
| `content_format: json` | The content must parse as JSON |
| `required_keys` (needs `content_format: json`) | The content must be a JSON object with those top-level keys |
| `authority` | The [authority](../../data-model/authority/) stamped on every record of the type; `conversational` when the type names none |

Nothing requires a record to carry a particular label: the checks limit labels, they do not demand them. The checks run on `e_ingest` and `e_update`. `e_property` `add` checks a label against the combined label list of the lane's source types, and does not check values.

## Example
The four source types from the [edge properties](../../data-model/edge-properties/) figure, as a policy fragment:

```yaml
# policy fragment — source types defined inside a lane
lanes:
  crm:
    source_types:
      contact:  { authority: documentary, allowed_labels: [person, org, title] }
      meeting:  { authority: documentary, allowed_labels: [person, org, topic] }
      deal:     { authority: documentary, allowed_labels: [org, topic, stage] }
      report:   { authority: documentary, allowed_labels: [org, topic] }
```

To close a label to a set of values, write it as a map:

```yaml
      deal:
        authority: documentary
        allowed_labels:
          - org
          - topic
          - label: stage
            values: [lead, proposal, won, lost]
```

An agent writes a meeting with a label the type does not allow:

```text
e_ingest {"content": "Renewal call with Acme.", "source_type": "meeting", "assign_lane": "crm", "properties": ["org:Acme", "budget:120k"]}
```

```json
{"error": "label(s) ['budget'] not allowed for source_type 'meeting' in lane 'crm'; allowed: ['org', 'person', 'topic']"}
```

Other refusals name what is allowed in the same way:

- `lane 'crm' is closed — source_type must be one of ['contact', 'deal', 'meeting', 'report'] (got 'conversational'); builtins are excluded in a closed lane.`
- `value 'maybe' not allowed for label 'stage' on source_type 'deal' in lane 'crm'; allowed values (in order): ['lead', 'proposal', 'won', 'lost']`
- `lane 'notes' is open — source_type must be a builtin ['conversational', 'documentary'] (got 'meeting').`

## Implications
**An agent learns the map from the refusal.** Every refusal lists what is allowed, so an agent corrects its call without being told the policy in advance. `e_system` `get_profile` returns, for each lane the agent profile can write, the source types it offers and the labels each allows.

**Authority follows the type, not the caller.** An agent cannot set a record's authority except by choosing its source type.

## Reference

See [lanes](../lanes/) and [agent profiles](../agent-profiles/).

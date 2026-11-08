# Vendor-Independent Memory

Organisations that use models from more than one vendor, or may switch, need memory no vendor keeps: memory built into a vendor's product stays in that product, is left behind or carried over as text on a move, and is not shared with another vendor's assistants. Everything Memory serves the same records to any agent whose client speaks MCP and to any program over REST; calls no language model itself; leaves the records as they are when a model changes; and keeps them in your own PostgreSQL and archive.

## Approach
For how memory is kept today, see [the agent memory landscape](../evaluating/agent-memory-today.md).

- **One engine, any model.** Any agent whose client speaks MCP connects to the same engine, at the same time. Any program uses the REST API. The engine does not call a language model, so nothing in it depends on which model an agent runs. See [connecting clients](../operator-guide/connecting-clients-and-operating.md).
- **The same memory for every agent.** Every agent reads the same [source records](../data-model/source-records.md), [edge properties](../data-model/edge-properties.md), corrections and adjustments, limited only by the [agent profile](../governance/agent-profiles.md) it names.
- **Switching a model changes nothing in the memory.** The records stay as they are; the next agent reads them.
- **You hold the data.** Records live in your own PostgreSQL and, with the [archive](../durability/index.md) on, in your own archive, on machines you choose. The embeddings endpoint is yours to choose too, and can be one you host.

## Example
Two agents, on models from two different vendors, both name the agent profile `sales_agent` and read the lane `sales`. The first records a fact:

```text
e_ingest {"content": "Acme asked for a 12% discount on the renewal.", "properties": ["org:Acme", "topic:renewal"], "agent_profile": "sales_agent"}
```

The second, in its own session, asks:

```text
e_gather {"action": "find", "query": "what discount did Acme ask for", "agent_profile": "sales_agent"}
e_read {"sr_ids": ["<the sr_id found>"]}
```

It reads the same record. `source_system` names the client that wrote it.

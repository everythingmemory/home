# Glossary

The words these docs use, each with one meaning.

| Term | Meaning |
|---|---|
| **Adjustment** | A later record linked to an earlier one that was right and has since changed. See [adjustments](../agents-how-to/evolving-a-fact.md). |
| **Agent** | The AI system that calls the tools. |
| **Agent profile** | A named set of lanes a call may read and write: a home lane, and others. The caller names it on a call; a call that names none runs under the engine's default agent profile. See [agent profiles](../governance/agent-profiles.md). |
| **Authority** | The level a record was labelled with when written. From highest to lowest: human correction, human confirmation, documentary, conversational, system inference. The engine does not rank by it. See [authority](../data-model/authority.md). |
| **Archive** | The durable copy of everything the engine knows, kept in S3-compatible object storage when it is turned on. The database can be rebuilt from it. See [the archive](../durability/archive-and-restore.md). |
| **Correction** | A statement of the truth, pinned to a record that was wrong. See [corrections](../agents-how-to/correcting-a-record.md). |
| **Edge property** | A `label:value` pair on a record, such as `org:Acme`. Records that share one are joined by it: one N-ary edge touching every record that carries it. See [edge properties](../data-model/edge-properties.md). |
| **Edge Property Graph (EPG)** | The graph that records and their edge properties form, held in PostgreSQL with no separate graph store. See [the EPG](../architecture/edge-property-graph.md). |
| **eMemory** | Short for Everything Memory. |
| **Engine** | One running instance of Everything Memory. |
| **Exchange** | The runtime activity of a mesh: what crosses between peered engines, and how each applies it. See [the exchange](../architecture/distributed-mesh-architecture.md). |
| **Folder Intake** | The service, in its own compose file, that watches a folder and writes each file and each part of its text as records. See [documents and files](../use-cases/beyond-the-context-window.md#documents-and-files). |
| **Label** | The first half of a property: the `person` in `person:Sarah`. |
| **Lane** | The partitioning mechanism: every record lives in exactly one lane, and access and vocabulary are decided per lane; a lane's records cross the mesh with its policy, when that policy is shared and accepted. *Swim lane* is the familiar picture. See [lanes](../governance/lanes.md). |
| **MCP** | Model Context Protocol, the protocol agents use to call the tools. |
| **Mesh** | Engines connected to one another. Peering sets it up; exchange is what crosses while it runs. See [the mesh](../architecture/distributed-mesh-architecture.md). |
| **Peer** | Another engine this one is peered with. |
| **Peering** | The setup of a mesh: pairing two engines and deciding what each offers and takes. See [the mesh](../architecture/distributed-mesh-architecture.md). |
| **Policy** | The document that declares lanes, source types, labels and agent profiles. See [policies](../governance/policies.md). |
| **Source record** | The unit stored: any content a caller writes, kept word for word with its edge properties, lane, source type, authority and provenance. Called a *record* after first use, and `SR` in tool text. See [source records](../data-model/source-records.md). |
| **Source type** | The declared kind of a record, on a lane in a policy. It sets the record's authority and limits its labels, label values and content shape. See [source types](../governance/source-types.md). |
| **Tag** | A word or value an extractor plugin returned for a record, kept in the record's tag index and read by retrieval. A tag is not an edge property: `e_read` and `e_property` do not list it, and it is not exchanged with peers or written to the archive. See [the pipeline and its plugins](advanced-settings/pipeline-and-plugins.md). |
| **Tombstone** | A kept marker of a deletion on this engine. It is never sent to peers; an undelete lifts it. See [deleting a record](../agents-how-to/deleting-a-record.md). |
| **Update** | A new version of a record's own content or properties. Earlier versions are kept in that record's ledger. |
| **Value** | The second half of a property: the `Sarah` in `person:Sarah`. |

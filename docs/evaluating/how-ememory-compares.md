---
title: "Comparison"
sidebar_position: 1
kind: explanation
status: drafted
verified_against: null
lede: "Everything Memory beside the memory built into the vendors' assistants and the memory layers most named in 2026: Mem0, Zep and Graphiti, Letta and LangMem. What each keeps, how each handles change, where each runs, what eMemory offers that differs, and where the others do more."
---

This page states what each product does, from its own documentation, and how eMemory differs.

## Side by side

| | What is stored | Change and history | Instances exchanging with each other | Where it runs |
|---|---|---|---|---|
| **Vendor assistant memory** (Claude, ChatGPT, Gemini) | Notes the assistant saves about the user; past chats it can search or refer to | The assistant updates its notes; the user can review and delete them. ChatGPT's details from past chats "can change over time" as it updates what to remember. | Not described in the documentation checked | The vendor's service |
| **Mem0** | By default, facts, decisions and preferences a language model extracts from messages. With `infer=False`, the payload as provided. | Adding never overwrites. An update overwrites the stored value; a history endpoint lists each `ADD`, `UPDATE` and `DELETE` with the earlier memory. | Not described in the documentation checked | Mem0's platform, or the open-source library or self-hosted server |
| **Zep and Graphiti** | A graph of entities and facts a language model extracts from episodes; each fact traces to the episode it came from | Each fact carries when it held, when it stopped holding, when Zep learned it and when Zep learned it had stopped. A contradicted fact is invalidated, not deleted. Point-in-time queries. | Not described in the documentation checked | Zep's service, or Zep in your cloud (Enterprise); Graphiti is open source on Neo4j, FalkorDB or Amazon Neptune |
| **Letta** | Memory blocks pinned in the agent's context and edited by the agent; archival memory in a vector database; every message | Blocks are edited in place. When the conversation outgrows the context, older messages are summarized for the context; the messages stay retrievable. | Not described in the documentation checked | Letta's service, or a Letta server you run |
| **LangMem** | Memories a language model forms and consolidates from conversations | The model reconciles new information with old: some memories are updated or consolidated, some deleted or invalidated | Not described in the documentation checked | A library; memories go to a LangGraph store you choose |
| **Everything Memory** | Each source record as the caller wrote it, with lane, source type, authority, the writing system and the time | An update keeps every earlier version in the record's ledger. A correction is pinned to the records it corrects. A deletion leaves a tombstone. No read as of a past time. | Peers exchange records and their history | Containers on hardware you choose |

## What eMemory offers

**Records are kept as written.** The engine does not call a language model to extract, summarize, merge or consolidate records. Content written twice is two records. An update replaces a record's current content and keeps each earlier version, in full, in the record's ledger. A deletion takes the record out of retrieval and leaves a tombstone; the ledger and the audit events stay, and with the archive on, the record's objects stay in object storage.

Some things are removed. A deletion takes the record out of retrieval on this engine — its edge properties and vectors go with it — while every version stays in its history, and an undelete brings it back. A deletion is local and never sent to peers. An operator can purge a policy, which deletes its events. See [deleting a record](../../agents-how-to/deleting-a-record/).

Of the others, Mem0 and LangMem store what a model extracts unless told otherwise; Zep keeps the source episode beside the facts it extracts; Letta keeps every message.

**A correction states the truth without altering the record.** It is a separate object pinned to the one record it corrects, and `e_read` returns the record with it. A correction does not change: to change one, retract it and write another. See [corrections](../../agents-how-to/correcting-a-record/). Mem0 and LangMem change or remove the memory itself; Zep invalidates a contradicted fact and keeps it, with its time bounds.

**Changes are audited.** Each change a tool makes writes an event in the same transaction, naming the record, lane, agent profile and engine; `e_audit` reads them, including the content before and after an update. Every record carries the system that wrote it and its authority level. Mem0 has a history of each memory's changes, and its self-hosted server keeps a request audit log. See [the audit log](../../durability/the-audit-log/).

**Engines exchange as peers.** Two peered engines exchange records (each version, with its edge properties), corrections, policies and audit events, as streams of events, each item applied once by its identity. From the same entries every engine derives the same current state, the latest by version with a fixed tie-break, so edits made on two engines at once settle on the same answer everywhere; the other version stays in the record's history. What crosses is chosen per peer: one side shares a policy, the other accepts it. Records, edge properties, corrections, tombstones and audit events take ids with 128 random bits; the events of updates, corrections and policies take ids with 122. The documentation checked for the other products does not describe exchange between independently run instances; Letta's Agent File moves an agent from one server to another as a file. See [the exchange](../../architecture/distributed-mesh-architecture/).

**The data is yours, and the model is your choice.** Records live in your PostgreSQL and, with the [archive](../../durability/) on, in your S3-compatible object storage. Any agent reaches the engine over MCP, and any program over REST. You choose the embeddings endpoint. eMemory does not ship an export bundle. Claude imports memory from another assistant as text that the other assistant writes out and you paste in; Gemini accepts that text and also imports another assistant's exported chat history. Claude can write out its memories for you to copy, and includes memory in its data export. Mem0's platform exports memories to a schema you define, and Letta saves an agent, with its memory blocks and messages but not its archival memory, to an Agent File that any Letta server imports.

**It runs where you put it.** eMemory is a set of containers you run with Docker Compose. It needs an embeddings endpoint it can reach, which can be one you host. The shipped stack runs with no internet access: the WordNet corpus is in its image, and the default embedding model runs locally. Mem0, Graphiti, Letta and LangMem can also be run on your own infrastructure, and Zep offers deployment in your own cloud.

## Where the others do more

- **No setup.** Assistant memory is on in the product; there is nothing to run.
- **Facts from conversations.** Mem0, Zep and LangMem turn conversation into memories with a language model. eMemory stores what the caller writes and decides nothing about what to keep.
- **Time.** Zep and Graphiti record when each fact held and answer what was true at a point in time. eMemory records when each record and each version was written, and has no as-of read.
- **An agent runtime.** Letta runs the agent, with its memory in its context. eMemory runs no agent.
- **Managed service.** Mem0, Zep and Letta offer hosted services.

See [What Everything Memory is](../../).

## Sources

Checked on 2026-10-26.

- Anthropic: [Using Claude's chat search and memory](https://support.claude.com/en/articles/11817273-using-claude-s-chat-search-and-memory-to-build-on-previous-context); [Importing and exporting your memory](https://support.claude.com/en/articles/12123587-importing-and-exporting-your-memory-from-claude)
- OpenAI: [Memory FAQ](https://help.openai.com/en/articles/8590148-memory-faq)
- Google: [Get personalization based on your past Gemini chats](https://support.google.com/gemini/answer/16598469); [Import from other AI platforms to Gemini Apps](https://support.google.com/gemini/answer/16868299)
- Mem0: [Add memory](https://docs.mem0.ai/core-concepts/memory-operations/add); [Update memory](https://docs.mem0.ai/core-concepts/memory-operations/update); [Memory history](https://docs.mem0.ai/api-reference/memory/history-memory); [Open source overview](https://docs.mem0.ai/open-source/overview); [Memory export](https://docs.mem0.ai/platform/features/memory-export)
- Zep: [Facts](https://help.getzep.com/facts); [Graphiti overview](https://help.getzep.com/graphiti/getting-started/overview); [Graphiti on GitHub](https://github.com/getzep/graphiti); [Pricing](https://www.getzep.com/pricing)
- Letta: [Memory](https://docs.letta.com/guides/agents/memory); [Archival memory](https://docs.letta.com/guides/agents/archival-memory); [Compaction](https://docs.letta.com/guides/core-concepts/messages/compaction); [Agent File](https://docs.letta.com/guides/agents/agent-file)
- LangMem: [Conceptual guide](https://langchain-ai.github.io/langmem/concepts/conceptual_guide/)

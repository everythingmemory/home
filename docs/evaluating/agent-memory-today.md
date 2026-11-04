---
title: "Agent Memory Landscape"
sidebar_position: 0
sidebar_label: "Agent Memory Landscape"
kind: explanation
status: drafted
verified_against: null
lede: "Agents already remember things in several ways: the memory built into the model vendors' assistants, memory files, retrieval over a vector database, and dedicated memory layers. This page says what each keeps, where each stops, and how Everything Memory works."
---

There are many ways for an agent to keep what it learns. Most people use the memory built into the assistant they already use. Developers add memory files, retrieval over a vector database, or a dedicated memory layer. For personal and team use these work well.

Everything Memory — eMemory for short — is one more way. It is built for regulated, governed and sovereign use, and is general enough for wider use.

## The approaches

| Approach | What it keeps | How it is found | What bounds it | How change over time is handled | Who holds the data |
|---|---|---|---|---|---|
| **Memory in the vendor's assistant** (Claude, ChatGPT, Gemini) | Notes the assistant saves about the user, and past chats it can refer to | The assistant decides what to recall in a conversation | What the assistant brings into its context window | The assistant updates its saved notes; the user can review and delete them | The vendor, in the user's account |
| **Memory files** (`CLAUDE.md`, Claude Code auto memory, the Claude memory tool) | Text files the person or the model writes | Loaded at the start of a session, or opened by the model when it chooses | The size of what is loaded or opened; Claude Code loads the first 200 lines or 25KB of its auto memory | Files are edited in place; history exists if the files are kept under version control | Whoever stores the files |
| **Retrieval over a vector database** | Chunks of documents with their vectors and whatever metadata is stored with them | Similarity search, often with metadata filters | The database | Whatever the builder implements: re-indexing, overwriting, or keeping versions | Whoever runs the database |
| **Memory layers** (Mem0, Zep and Graphiti, Letta, LangMem) | Memories a language model extracts from conversations, or a graph of entities and facts, or memory blocks the agent edits | Search by meaning, by entity, by graph, or by the agent's own tools | The store behind them | Varies: overwriting with a history of changes (Mem0), facts with validity intervals that are invalidated, not deleted (Zep, Graphiti), consolidation by a language model (LangMem). See [how eMemory compares](../how-ememory-compares/). | A vendor's service, or infrastructure you run |
| **Everything Memory** | Each source record exactly as it was written, with its lane, source type, authority, writing system and time | `e_gather` by meaning, by edge property, or by walking shared edge properties; `e_timeline` in time order | The database: PostgreSQL with pgvector, or Qdrant for vectors | An update keeps every earlier version in the record's ledger; a correction is pinned to the records it corrects; an adjustment links a later record; a deletion leaves a tombstone | You: your PostgreSQL, and with the [archive](../../durability/) on, your object storage |

## Where the built-in approaches stop

Memory held in files or saved notes reaches the model through its context window. That suits a person's preferences and a team's conventions. It does not hold millions of records, and the vendors do not offer it for that: Claude Code loads a bounded part of its auto memory, and the Claude memory tool's documentation tells the application to cap file sizes.

Time is the second limit. Facts change, some turn out to have been wrong, and a reader often needs to know what was recorded, by whom, and what it replaced. Some memory layers do model time: Zep and Graphiti keep, on each fact, when it held, when it stopped holding, and when the system learned each, and they invalidate a contradicted fact instead of deleting it.

The third is the vendor. Memory kept in one vendor's assistant moves to another mostly as text: Claude imports memory that the other assistant writes out, and Gemini accepts that text and also imports another assistant's exported chat history.

## How eMemory differs

eMemory stores records in a database and returns only the records a read finds. Its size is bounded by the database, not by a context window.

It keeps what it was given. The engine does not call a language model to extract, summarize or merge records. A record carries the name of the system that wrote it and its authority level. An update keeps each earlier version in the record's ledger. A correction states what is true and leaves the records it corrects unchanged. Changes write events to an audit log. eMemory does not offer a read of the memory as it stood at a past time.

Lanes, agent profiles and a policy say which calls may read and write which records. Engines can be peered and then exchange records. eMemory runs on hardware you choose, reached by any agent over MCP or by any program over REST, with an embeddings endpoint you supply, which can be one you host. The shipped stack runs with no internet access: the WordNet corpus is in its image, and the default embedding model runs locally.

[How eMemory compares](../how-ememory-compares/) sets it beside the products above. [What Everything Memory is](../../) and [The parts](../../architecture/microservice-architecture/) describe it.

## Sources

Checked on 2026-10-26.

- Anthropic, [Memory tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)
- Anthropic, [How Claude remembers your project](https://code.claude.com/docs/en/memory) (Claude Code)
- Anthropic, [Using Claude's chat search and memory](https://support.claude.com/en/articles/11817273-using-claude-s-chat-search-and-memory-to-build-on-previous-context)
- OpenAI, [Memory FAQ](https://help.openai.com/en/articles/8590148-memory-faq)
- Anthropic, [Importing and exporting your memory](https://support.claude.com/en/articles/12123587-importing-and-exporting-your-memory-from-claude); Google, [Import from other AI platforms to Gemini Apps](https://support.google.com/gemini/answer/16868299)
- Google, [Personalization in Gemini Apps](https://support.google.com/gemini/answer/15637730) and [Get personalization based on your past Gemini chats](https://support.google.com/gemini/answer/16598469)
- Zep, [Facts](https://help.getzep.com/facts); [Graphiti](https://github.com/getzep/graphiti)
- Mem0, [Add memory](https://docs.mem0.ai/core-concepts/memory-operations/add); Letta, [Memory](https://docs.letta.com/guides/agents/memory); LangMem, [Conceptual guide](https://langchain-ai.github.io/langmem/concepts/conceptual_guide/)

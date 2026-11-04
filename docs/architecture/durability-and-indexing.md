---
title: "Durability and Indexing Strategy"
sidebar_position: 1.5
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "A system of record has to keep everything for good and still answer an agent in milliseconds — two jobs one store does badly. eMemory splits them: the archive holds the data itself, encrypted and never pruned on its own; Percona's PostgreSQL is the hybrid index over it — records, properties, tags and vectors, with full-text, graph and time lookups beside them; vectors can live in Qdrant instead; and the whole index is rebuildable from the archive, which is itself portable and secure."
---

Challenges addressed: [Context Window Limits and Lossy Compaction](../../use-cases/beyond-the-context-window/), [Auditable Decision-Making](../../use-cases/auditing-agentic-decisions/), [Tracking Changes Through Time](../../use-cases/data-evolution/).

## Two layers

| Layer | What it holds | Its job | If it is lost |
|---|---|---|---|
| **The archive** — the bundled store, in the folder you name, or your own S3-compatible bucket | every version of every record, every correction, policy event and audit event, and the vectors, as encrypted objects | **durability:** the data itself, kept for good | it is the memory — back it up, and keep its key apart |
| **The index** — Percona's PostgreSQL | the same records arranged for retrieval: ledgers of versions, and caches of each record's current state, edge properties, tags and vectors | **speed:** every kind of lookup an agent needs, in milliseconds | the engine rebuilds it from the archive |
| **Vectors, optionally in Qdrant** | the vectors, instead of in PostgreSQL | **scale:** similarity search moved to a dedicated vector store, taking that load off the database, so the stack can hold more records | refilled from the archive, like the rest of the index |

## The archive is the data

Everything the engine is told is written to the [archive](../../durability/archive-and-restore/) shortly after it changes, as objects encrypted with your `ARCHIVE_KEY`. Nothing in the engine deletes an archive object: a deleted record's history stays there too. The archive is what you back up, what a lost engine is rebuilt from, and what makes the index disposable.

## PostgreSQL is the hybrid index

Agent memory is usually assembled from several systems: a vector database for meaning, a search engine for words, a graph database for relations, something else for time. eMemory's index does all of it in PostgreSQL, with the extensions and index types PostgreSQL already has:

| An agent asks for | The index answers with |
|---|---|
| records **like this** — by meaning | vectors in `pgvector`, with HNSW indexes, one table per [embedding space](../embedding-spaces/) — or in Qdrant |
| records **with these words** | full-text search over the content, on a GIN index |
| records **with this property** — exact, prefix or similar | the edge properties, on B-tree and trigram indexes |
| records **connected to this one** | the [edge property hypergraph](../edge-property-graph/): joins on shared values, in SQL |
| records **about this time** | the time ranges the content mentions, as `tstzmultirange` values on a GiST index |
| records **as they stood then** | each record's ledger of versions |

[Hybrid retrieval](../how-search-ranks-results/) combines them into one ranked answer, under one set of access rules: the lanes an agent may read apply to every kind of retrieval alike.

## Vectors: in PostgreSQL or in Qdrant

Vectors live in PostgreSQL by default (`VECTOR_STORE=pgvector`). A stack can keep them in Qdrant instead (`VECTOR_STORE=qdrant`), a container of its own beside the database; everything else stays in PostgreSQL.

Both are built to scale: in PostgreSQL, each collection has its own HNSW index once the space is fully embedded, so a search reads only the vectors it needs and stays fast as the memory grows, and most memories run well with everything in one database. Qdrant is there for scale, by separating responsibilities: similarity search is the heaviest lookup as a memory grows, and the vectors are its largest part. The database scales up, on one machine; Qdrant also scales out — its distributed mode spreads a collection across nodes — and can keep an index on fast disk rather than in memory (Qdrant's own features; the shipped overlay runs a single node). Moving the vectors there takes that load off the database, so each part grows on hardware sized for it. Switching does not move vectors: the new store starts empty and the engine's sweeps refill it, from the archive's vectors or by embedding the records again; switching back to PostgreSQL finds its old vectors in place. See [vector store settings](../../configuration/vector-store/).

## Why this split

- **The data can never be lost to an index problem.** Re-indexing, a new embedding model, a new vector store, a corrupted or deleted database: the archive is untouched, and the index is rebuilt from it.
- **The index is rebuildable, so its technology is a choice.** Because the archive holds the data and the index is rebuilt from it, nothing about the memory depends on how it is indexed. The vector store already sits behind one interface with two implementations, PostgreSQL and Qdrant, and others can be added there; PostgreSQL carries the rest of the index.
- **One index to run.** One database to deploy, secure, monitor and size, instead of three or four, each with its own consistency, access control and backup story.
- **Consistent by construction.** A record and the properties it is given are written in one transaction; its tags and vectors follow shortly after from the ingest worker.
- **Encrypted at both layers.** The archive's objects are encrypted with your key; the shipped database runs Percona's transparent data encryption, so every table and index on disk is encrypted too.
- **Familiar to the people who approve it.** Operators and security teams already know how to run, audit and harden PostgreSQL and S3-compatible storage.

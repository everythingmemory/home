---
title: "Vector store"
sidebar_position: 4
kind: reference
status: drafted
verified_against: null
lede: "Where the engine keeps its vectors: in its own database, or in a separate vector store."
---

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `VECTOR_STORE` | `pgvector` | — | `pgvector` keeps vectors in PostgreSQL; `qdrant` in Qdrant. The Qdrant overlay sets it |
| `QDRANT_API_KEY` | empty | — | Required by the Qdrant overlay |

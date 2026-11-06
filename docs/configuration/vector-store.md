# Vector store

Where the engine keeps its vectors: in its own database, or in a separate vector store.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `VECTOR_STORE` | `pgvector` | — | `pgvector` keeps vectors in PostgreSQL; `qdrant` in Qdrant. The Qdrant overlay sets it |
| `QDRANT_API_KEY` | empty | — | Required by the Qdrant overlay |

An unknown `VECTOR_STORE` stops the engine at start, naming the valid ones.

## Switching to Qdrant

Set in `.env`, then restart the stack:

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.qdrant.yml
QDRANT_API_KEY=<a key you mint: openssl rand -hex 24>
```

With other overlays, list them all, e.g. `docker-compose.yml:docker-compose.open.yml:docker-compose.qdrant.yml`.

Switching moves no vectors. The new store starts empty and refills from the records: the sweeps restore the archive's vectors or embed the records again. The old pgvector rows stay; switching back is the same setting.

---
title: "Embeddings and the model gateway"
sidebar_position: 3
kind: reference
status: drafted
verified_against: null
lede: "The embedding model the engine searches by meaning with, and the model gateway that serves it."
---

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `EMBEDDING_BASE_URL` | — (required) | `http://gateway:4000/v1` | The OpenAI-compatible endpoint the engine embeds through |
| `EMBEDDING_MODEL` | — (required) | `nomic-embed-text` | The route the gateway serves. The model name is the [embedding space](../../architecture/embedding-spaces/): a new name opens a new space, and the embedding sweep re-embeds every record into it |
| `EMBEDDING_API_KEY` | empty | empty | A bearer key for the endpoint, if it needs one |
| `OPENROUTER_API_KEY` | — | — | In `gateway.env`, read by the gateway only. Needed only to switch to the shipped OpenRouter route (`EMBEDDING_MODEL=text-embedding-3-small`) |
| `EMBED_MAX_CHUNKS` | `64` | — | The most chunks a record is embedded in; text past them has no vector |
| `WINDOW_EMBED_SIZE` | `5` | — | How many records a window vector covers |

The gateway's routes are in `conf/gateway.yaml`: each names a model, where it is served, and its vector width (`output_vector_size`), which the engine requires.

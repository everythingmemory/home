# Embeddings and the model gateway

The embedding model the engine searches by meaning with, and the model gateway that serves it.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `EMBEDDING_BASE_URL` | — (required) | `http://gateway:4000/v1` | The OpenAI-compatible endpoint the engine embeds through |
| `EMBEDDING_MODEL` | — (required) | `nomic-embed-text` | The route the gateway serves. The model name is the [embedding space](../architecture/embedding-spaces.md): a new name opens a new space, and the embedding sweep re-embeds every record into it, queued in batches on the maintenance queue |
| `EMBEDDING_API_KEY` | empty | empty | A bearer key for the endpoint, if it needs one |
| `OPENROUTER_API_KEY` | — | — | In `gateway.env`, read by the gateway only. Needed only to switch to the shipped OpenRouter route (`EMBEDDING_MODEL=text-embedding-3-small`) |
| `EMBED_MAX_CHUNKS` | `64` | — | The most chunks a record is embedded in; text past them has no vector |
| `WINDOW_EMBED_SIZE` | `5` | — | How many records a window vector covers |

The gateway is [LiteLLM](https://docs.litellm.ai/). Its routes are in `conf/gateway.yaml`: each names a model, where it is served, and its vector width (`output_vector_size`), which the engine requires.

- The engine embeds through the `conf/gateway.yaml` entry whose `model_name` is `EMBEDDING_MODEL`.
- `model_info.output_vector_size` is required: without it the engine embeds nothing on that route.
- `model_info.document_prefix` and `query_prefix` are optional task prefixes, added before every record and every question; they are part of the [embedding space](../architecture/embedding-spaces.md).
- `nomic-embed-text` (the default) is served by the stack's `local-embed` service: 768 wide, prefixed, no key, nothing leaves the machine.
- `text-embedding-3-small` goes through OpenRouter: 1536 wide, no prefixes; set `OPENROUTER_API_KEY` in `gateway.env` (from `gateway.env.template`) and `EMBEDDING_MODEL=text-embedding-3-small` in `.env`.
- A key is named in the file as `os.environ/NAME` and set in `gateway.env`, never in the file.
- `litellm_settings`: two retries (`num_retries`), a 120-second timeout (`request_timeout`), and parameters a provider does not accept dropped (`drop_params`).
- The gateway reads the file at start: restart the `gateway` service after a change.

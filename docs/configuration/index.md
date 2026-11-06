# Configuration Options

The settings an operator sets, one page per area. The pipeline profiles and their plugins are under advanced settings.

Settings are environment variables, set in `.env` beside the compose file — the stack's one settings file, which `./e.sh init` writes from the template `.env.example`. A value in the **Shipped** column is what the template or the compose file sets; **Engine default** is what the engine uses when the variable is absent. Changing a setting takes effect when the stack restarts. Client keys are not settings: they live in `conf/keys.yaml` (see [authentication](authentication.md)).

- [Database](database.md)
- [Authentication](authentication.md)
- [Embeddings and the model gateway](embeddings.md)
- [Vector store](vector-store.md)
- [Archive](archive.md)
- [Workers and scheduled jobs](workers.md)
- [Load and queue thresholds](load-and-queue.md)
- [Deletion](deletion.md)
- [Profiles](profiles.md)
- [Logging](logging.md)

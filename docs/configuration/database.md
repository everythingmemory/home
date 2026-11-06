# Database

The database's name, user and password, and how the engine reaches it.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `POSTGRES_DB`, `POSTGRES_USER` | `ememory` | `ememory`; required | The database and its user |
| `POSTGRES_PASSWORD` | — | empty; required | The database password. `docker compose up` refuses to start without it. It is fixed into the database volume on first start |
| `DB_POOL_SIZE`, `DB_MAX_OVERFLOW` | `5`, `10` | — | Database connections per process, and the burst above them |

# Archive

Where the archive is written, and the key that encrypts it.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `ARCHIVE_ENABLED` | `false` | `true` | Writes the [archive](../durability/archive-and-restore.md) |
| `ARCHIVE_ENDPOINT_URL`, `ARCHIVE_BUCKET`, `ARCHIVE_REGION` | empty, empty, `nyc3` | `http://archive-store:8333`, `ememory-archive`, `us-east-1` (the bundled archive store) | Where the archive lives |
| `ARCHIVE_DIR` | empty | required; `./e.sh init` makes the folder and sets it | The absolute path of the host folder the bundled archive store writes to. It is bind-mounted, so it must exist before the first start |
| `ARCHIVE_ACCESS_KEY`, `ARCHIVE_SECRET_KEY` | empty | required; `./e.sh init` generates them | The login for the archive store. On the bundled store, any pair becomes its one identity at start |
| `ARCHIVE_PREFIX` | empty | empty | A prefix for every object name, to share one bucket between stacks |
| `ARCHIVE_KEY` | empty | required; `./e.sh init` generates it | The archive encryption key: 32 random bytes, base64-encoded — the one archive setting whose format is required. Object bodies are encrypted with AES-256-GCM |
| `ARCHIVE_READ_ONLY` | `false` | — | Restores from the archive and never writes to it |
| `RESTORE_FETCH_CONCURRENCY`, `RESTORE_FETCH_TIMEOUT_SECONDS` | `16`, `30` | — | How many archive objects a restore fetches at once, and how long one fetch may take |

## The folder and the key

- **`ARCHIVE_DIR` outlives the stack.** It is a host folder, so `docker compose down -v` does not touch it.
- **A missing folder is refused, never created.** `docker compose up` refuses a path that does not exist, so a mistyped one never starts an empty archive.
- **On macOS**, the folder must sit under a folder Docker shares with its containers: `/Users`, `/Volumes` or `/private`.
- **Keep `ARCHIVE_KEY` apart from the archive**, in a password manager. A lost key is an unreadable archive.
- **The index is rebuilt from the archive.** The database is the index; the sync sweep restores it from the archive when a worker starts and every 5 minutes.

## Moving the archive to another S3-compatible store

Set `ARCHIVE_ENDPOINT_URL`, `ARCHIVE_BUCKET`, `ARCHIVE_REGION`, `ARCHIVE_ACCESS_KEY` and `ARCHIVE_SECRET_KEY` to the other store's, and restart. The bucket must exist: the engine does not create one. The bundled archive store then sits idle.

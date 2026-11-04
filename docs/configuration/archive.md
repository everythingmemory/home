---
title: "Archive"
sidebar_position: 5
kind: reference
status: drafted
verified_against: null
lede: "Where the archive is written, and the key that encrypts it."
---

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `ARCHIVE_ENABLED` | `false` | `true` | Writes the [archive](../../durability/archive-and-restore/) |
| `S3_ENDPOINT_URL`, `S3_BUCKET`, `S3_REGION` | empty, empty, `nyc3` | `http://archive-store:8333`, `ememory-archive`, `us-east-1` (the bundled archive store) | Where the archive lives |
| `ARCHIVE_DIR` | empty | required | The absolute path of the host folder the bundled archive store writes to. It is bind-mounted, so it must exist before the first start |
| `S3_ACCESS_KEY`, `S3_SECRET_KEY` | empty | required | How the engine reaches the archive |
| `S3_KEY_PREFIX` | empty | — | A prefix for every object name, to share one bucket between stacks |
| `ARCHIVE_KEY` | empty | required | The archive encryption key (32 bytes, base64). Object bodies are encrypted with AES-256-GCM |
| `ARCHIVE_READ_ONLY` | `false` | — | Restores from the archive and never writes to it |
| `RESTORE_FETCH_CONCURRENCY`, `RESTORE_FETCH_TIMEOUT_SECONDS` | `16`, `30` | — | How many archive objects a restore fetches at once, and how long one fetch may take |

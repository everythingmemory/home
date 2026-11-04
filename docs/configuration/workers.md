---
title: "Workers and scheduled jobs"
sidebar_position: 6
kind: reference
status: drafted
verified_against: null
lede: "The background workers and the scheduled jobs they run."
---

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `REDIS_PASSWORD` | empty | empty; required | The job queue's password. `docker compose up` refuses to start without it; the engine and every worker carry it |
| `EMEMORY_PORT`, `CONSOLE_PORT`, `EMEMORY_NETWORK` | — | `8765`, `8766`, `ememory` | The host ports of the engine and the console (both on 127.0.0.1) and the name of the stack's Docker network. Change them only to run a second stack on one machine |
| `CRON_ENABLED` | `false` | `true` | Runs the scheduled jobs: the embedding, tagging, archive and exchange sweeps |
| `INGEST_WORKER_MAX_JOBS` | `5` | — | How many records the ingest worker processes at once |
| `ARCHIVE_WORKER_MAX_JOBS` | `10` | — | How many archive writes run at once |
| `MAINTENANCE_WORKER_MAX_JOBS` | `5` | — | How many repair batches run at once |
| `WORKER_MAX_JOBS` | `1` | — | How many jobs the scheduled-jobs worker runs at once |

The schedule itself is in `conf/cron.yaml`. Batch sizes are in `conf/limits.yaml`: `tag_derive_batch` (20), `embed_batch` (50), `embed_repair_limit` (500), and `page_size_ceiling` (10000), the largest `page_size` a read accepts.

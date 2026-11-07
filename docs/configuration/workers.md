# Workers and scheduled jobs

The background workers and the scheduled jobs they run.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `REDIS_PASSWORD` | empty | empty; required | The job queue's password. `docker compose up` refuses to start without it; the engine and every worker carry it. `./e.sh init` generates it as hex, so it needs no quoting |
| `EMEMORY_PORT`, `CONSOLE_PORT`, `EMEMORY_NETWORK` | — | `8765`, `8766`, `ememory` | The host ports of the engine and the console (both on 127.0.0.1) and the name of the stack's Docker network. Change them only to run a second stack on one machine |
| `CRON_ENABLED` | `false` | `true` | Runs the scheduled jobs: the embedding, tagging, archive and exchange sweeps, and the restore from the archive |
| `INGEST_WORKER_MAX_JOBS` | `5` | — | How many records the ingest worker processes at once |
| `ARCHIVE_WORKER_MAX_JOBS` | `10` | — | How many archive writes run at once |
| `MAINTENANCE_WORKER_MAX_JOBS` | `5` | — | How many repair batches run at once |
| `WORKER_MAX_JOBS` | `1` | — | How many jobs the scheduled-jobs worker runs at once |

The schedule is in `conf/cron.yaml`, read by `ememory-worker` at start when `CRON_ENABLED=true`:

- `task_embedding_sweep`: hourly at :00 and at start; queues every record with no vector in the active embedding space, in batches, on the maintenance worker.
- `task_tagging_sweep`: hourly at :00 and at start; queues every record with no current tags, in batches, on the maintenance worker; queues nothing while the last pass's jobs are still queued.
- `task_sync_sweep`: every 5 minutes and at start; restores from the archive what the database lacks and queues for the archive what the archive lacks; nothing when the archive is off.
- `task_sync_peers`: every 5 minutes; one exchange with each active peer.
- `task_archive_audit`: every 5 minutes, at :02, :07, …; writes each changed hour of the audit log to the archive.
- An entry's fields are `month`, `day`, `weekday`, `hour`, `minute`, `second` (a number, a list, or `every`) and `run_at_startup`; a field left out matches every value, except `second` (`0`), so an entry with no `minute` runs every minute.
- A job is not queued again while a run of it is queued or running; an unknown job name is skipped with a warning.
- Delete an entry to stop that job; delete the file or set `CRON_ENABLED=false` to stop all.

Batch sizes and the page ceiling are in `conf/limits.yaml`:

- `page_size_ceiling` (`10000`): the largest `page_size` a paging tool (`e_property`, `e_gather`, `e_timeline`, `e_correct`, `e_audit`) accepts; a larger one is refused, not cut down.
- `tag_derive_batch` (`20`): records per tagging job; one job must finish within the maintenance worker's 300-second job timeout.
- `embed_batch` (`50`): records per embedding job, one embedding call each; same 300-second timeout.
- `embed_repair_limit` (`500`): the most window vectors one embedding sweep pass queues for repair.
- The three batch sizes are each at least `1`.

A change to either file takes effect when the stack restarts.

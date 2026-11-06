# Sizing

What the stack needs from its machine: a fixed base for the services, and disk that grows with the records you keep. Measured on one stack; treat the per-record figures as a starting estimate and check your own with the commands at the end.

## The base: the stack itself

The stack runs fourteen services. Each has a memory limit in the compose file, so no service can take the whole machine:

| Service | What it does | Memory limit |
|---|---|---|
| `ememory-postgres` | the database (encrypted at rest) | 1.5 GB |
| `gateway` | the model gateway | 1.5 GB |
| `ememory-worker`, `ememory-worker-ingest` | background jobs: tagging, embedding, ingest | 1 GB each |
| `local-embed` | the local embedding model | 1 GB |
| `ememory-api` | the engine's API and MCP endpoint | 512 MB |
| `archive-store` | the archive | 512 MB |
| `plugin-wordnet` | word senses for tagging | 512 MB |
| `ememory-redis`, `ememory-worker-archive`, `ememory-worker-maintenance` | the job queue and two workers | 384 MB each |
| `chrono-engine`, `plugin-chrono`, `console` | time reading, and the web console | 256, 128, 128 MB |

The limits add up to about 9 GB, but they are ceilings, not use: measured at rest with 4,203 records, the whole stack used **about 2.7 GB**. That is why 4 GB is the minimum and 8 GB is comfortable — it leaves room for the bursts a large import or a re-embedding causes.

**CPU:** 2 CPUs run it; 4 make ingest and re-embedding noticeably faster, because the local embedding model runs on the CPU. There is no GPU requirement.

**Disk for the images:** about 6 GB, pulled once.

## What grows: your records

Measured on one stack, 4,203 records averaging about 1,200 characters each, with full history, vectors and audit:

| Where | Size | Per record |
|---|---|---|
| the database | 106 MB | about 25 KB |
| the archive folder (`ARCHIVE_DIR`) | 88 MB | about 21 KB |

Records much longer or shorter than 1,200 characters move these figures roughly in proportion. A rough guide from these measurements:

| Records | Database | Archive folder | Memory for the engine |
|---|---|---|---|
| 10,000 | about 250 MB | about 210 MB | 4–8 GB |
| 100,000 | about 2.5 GB | about 2.1 GB | 8 GB |
| 1,000,000 | about 25 GB | about 21 GB | 16 GB, with the database's own settings raised |

These rows are extrapolated in a straight line from one measured stack; the larger ones are estimates, not measurements. Plan disk for the database and the archive folder separately: the archive folder is the one you back up and keep, the database is rebuilt from it.

## Check your own

```bash
docker stats --no-stream                       # memory per service, now
du -sh "$ARCHIVE_DIR"                           # the archive folder
docker compose exec ememory-postgres sh -c \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "select pg_size_pretty(pg_database_size(current_database()))"'
curl -s http://localhost:8765/health            # the record count is sr_count
```

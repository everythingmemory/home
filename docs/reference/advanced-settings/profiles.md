# Profiles

Two settings choose which component lists the engine runs: PIPELINE_PROFILE for ingest and question search, and TEMPORAL_PROFILE for e_timeline. Both name blocks in conf/profiles.yaml.

## What each setting selects

| Setting | Default | Selects | Used by |
|---|---|---|---|
| `PIPELINE_PROFILE` | `retrieval_v1` | A block with an `ingestion` list and a `curate` list | Ingest (`e_ingest`, `e_update`), and `e_gather` `find` |
| `TEMPORAL_PROFILE` | `timeline_v1` | A block with the `temporal`, `temporal_discourse` and `temporal_find` lists | `e_timeline` |

The structural actions of `e_gather` (`intersect`, `union`, `traverse`) run the fixed `gather` block in the same file.

## The shipped profiles

| Profile | Ingest extractors | Notes |
|---|---|---|
| `retrieval_v1` | WordNet, chrono-node | The default, and the one pipeline profile the release ships. Runs on the shipped stack |

| Temporal profile | Reads a question's dates with | Notes |
|---|---|---|
| `timeline_v1` | chrono-node | The default. Runs on the shipped stack |
| `temporal` | Duckling | Needs Duckling's services, which the shipped stack does not run |

The question search runs tags and edge properties, full text, record vectors and window vectors, merged. See [search](../../agents-how-to/finding-records.md).

- Each profile in `conf/profiles.yaml` lists, per path, its components in the order they run; a key named after a component holds its settings (for example `slice_page: {page_size: 30}`).
- `ingestion` runs its components one after another; a record that fails validation goes no further.
- `curate` (`e_gather` `find`) runs its retrievers at once, then the rest in order.
- `temporal` serves `e_timeline` `list`, `intersect` and `traverse`; `temporal_discourse` the same with conversational records only; `temporal_find` serves `find`.
- The release ships `retrieval_v1`, `timeline_v1`, `temporal`, `gather`, and `default`, a placeholder that runs nothing.
- `timeline_v1` is `temporal` with the question's dates read by chrono-node; it inherits the rest (`<<: *temporal`).
- Both defaults need the `chrono` entry in `conf/plugins.yaml`.
- Switching to a pipeline profile with other extract plugins changes the tag version, so every record's tags are derived again, once.

## Switching

Set the name in `.env` and restart the stack. An unknown `PIPELINE_PROFILE` or `TEMPORAL_PROFILE` — a name that is not a block in `conf/profiles.yaml` — or a temporal block missing one of its three lists, stops the engine at startup with the reason. A switch changes what runs from then on; records already ingested keep the tags they have.

`/health` names the pipeline profile and the temporal profile in force.

## Reference

The components and plugins: [pipeline and plugins](pipeline-and-plugins.md).

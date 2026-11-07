# Profiles

One setting, PIPELINE_PROFILE, chooses which component lists the engine runs for ingest, e_gather and e_timeline. It names a block in conf/profiles.yaml; the release ships one, profile_v1.

## What the setting selects

| Setting | Default | Selects |
|---|---|---|
| `PIPELINE_PROFILE` | `profile_v1` | A block in `conf/profiles.yaml` with one component list per call below |

| Pipeline | Runs for |
|---|---|
| `ingest` | `e_ingest`, `e_update` |
| `gather_find` | `e_gather` `find` |
| `gather` | `e_gather` `intersect`, `union` and `traverse` |
| `timeline` | `e_timeline` `list`, `intersect` and `traverse` |
| `timeline_conversational` | The same, with `is_conversational_only` |
| `timeline_find` | `e_timeline` `find` |

## The shipped profile

`profile_v1` extracts with WordNet and chrono-node at ingest, and reads a question's dates for `e_timeline` with chrono-node. It runs on the shipped stack and needs the `chrono` entry in `conf/plugins.yaml`.

The question search runs tags and edge properties, full text, record vectors and window vectors, merged. See [search](../../agents-how-to/finding-records.md).

- The block lists, per pipeline, its components in the order they run. A key named after a component holds that component's settings, one set for every pipeline (for example `slice_page: {page_size: 30}`, the default page of `e_gather` and `e_timeline`).
- `ingest` runs its components one after another; a record that fails validation goes no further.
- `gather_find` runs its retrievers at once, then the rest in order.
- Switching to a profile with other extract plugins changes the tag version, so every record's tags are derived again, once.

## Switching

A profile of your own goes in a `profiles.yaml` under `CONF_OVERRIDE_DIR`, which replaces the shipped file whole, so copy `profile_v1` into it too. Set `PIPELINE_PROFILE` in `.env` and restart the stack. The engine stops at startup with the reason when `PIPELINE_PROFILE` names no block in the file, or a block without one of the six lists above. A switch changes what runs from then on; records already ingested keep the tags they have.

## Reference

The components and plugins: [pipeline and plugins](pipeline-and-plugins.md).

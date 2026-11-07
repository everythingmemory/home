# Pipeline and Plugins

Ingest is a named sequence of components, read from conf/profiles.yaml. Some of those components are extractor plugins: separate services, declared in conf/plugins.yaml, that read a record's content and return tags.

## The ingest pipeline

The pipeline is a list of component names in a pipeline profile in `conf/profiles.yaml`, selected by `PIPELINE_PROFILE` (see [profiles](profiles.md)). The shipped default, `profile_v1`, runs ingest in this order:

| Component | Does |
|---|---|
| `validate` | Computes the content hash |
| `persist` | Writes the record and its `sr_ingested` [audit](../../durability/the-audit-log.md) event |
| `agent_properties` | Writes the edge properties the caller supplied |
| `plugin_wordnet` | Returns the content's words, each lemmatized and given a WordNet category |
| `plugin_chrono` | Returns the dates, times and date ranges the content mentions, through chrono-node |
| `embed` | Computes and writes the embedding |
| `archive` | Writes the record to the archive |

`e_ingest` returns once the first three have run. The rest follow in the background.

## What the extractors return: tags

The engine keeps what the extractors return as the record's tags, in one row per record: each value, lower-cased, and, for each date or time an extractor resolved, the span of time it covers. `e_gather` with `find` and `e_timeline` read the tags. Tags are not edge properties: `e_read` and `e_property` do not list them, they are not exchanged with peers, and they are not written to the archive.

Each engine derives tags from the content it holds. For a record it writes, that happens during ingest; when an update changes a record's content on the engine that wrote it, a background job derives them again. For a record received from a peer or restored from the archive, and for an update received from a peer, a scheduled job derives them on its next hourly pass, when `CRON_ENABLED=true`. That job also repairs any record whose tags an earlier job could not derive, and derives every record's tags again when an extractor's declared version changes.

At ingest `plugin_chrono` resolves relative expressions such as "Friday" or "today" against a reference time of zero and keeps no time span for them; the expression itself is kept as a tag. Only dates the content states in full get a span. A date or time that names no zone is read in the `America/Los_Angeles` zone. chrono-node does not return durations, quarter or half-year codes, or seasons.

## Plugins

Each extractor runs in its own container. The engine calls it over HTTP: `POST /invoke` with the record's text, followed by the values of the edge properties the caller passed. The plugin answers with a list under `eps`. Each plugin also answers `GET /health`.

Plugins are declared in `conf/plugins.yaml`:

```yaml
plugins:
  chrono:
    type: extract
    url: http://plugin-chrono:8000/invoke
    health_url: http://plugin-chrono:8000/health
    timeout: 60
    retries: 0
    optional: true
```

| Field | Meaning |
|---|---|
| `type` | `extract`: a profile can run it at ingest, and what it returns is kept as the record's tags. `embed`: it serves vectors. `tokenize`: never run at ingest; the engine calls it by name, at question time only. Any other value stops the engine when it reads the file |
| `url`, `health_url` | The plugin's two routes |
| `timeout` | Seconds before a call is abandoned |
| `retries` | How many times a timeout or a 5xx reply is retried |
| `optional` | `true`: if the plugin still does not answer, the pipeline carries on without it, and the scheduled job derives the record's tags later. `false`: the components after it do not run for that record |
| `json_input` | For JSON content: `raw` (the text as stored, the default) or `leaves` (the leaf values, a blank line between each) |
| `raw_input` | `true`: the plugin is sent the content exactly as stored, without the edge-property values after it — for a plugin that parses a strict format, such as JSON. Not with `json_input: leaves`; the engine refuses the pair at start |

A 4xx reply is not retried and fails the background job for that record, whatever `optional` says; the steps after it, embedding included, do not run.

Registered is not running. Each `extract` entry becomes a component named `plugin_<name>` that a pipeline profile can list, and it is called only when a profile lists it, or when a retrieval component names it: `e_timeline` reads a question's dates through `chrono` under `profile_v1`, and `e_gather` lemmatizes a question through `wordnet`. The file also registers `duckling` and `json_leaf`, whose services the shipped stack does not run; no shipped profile names them.

- `wordnet` stays registered whatever the profile: `e_gather` `find` lemmatizes the question through it, and full-text search runs on those words.
- `chrono` reads JSON content raw: on leaves joined by blank lines one match could run across two values.
- `duckling` reads JSON as leaves (on raw JSON it reads every quoted number as a duration), and is not retried: a long record is slow, and a retry repeats the same work.
- `json_leaf` is sent the content raw (`raw_input: true`): the edge-property values after it would break its JSON parse.
- `conf/ep_versions.yaml` gives each extractor a `version`, a `schema_id` (the name its output is kept under) and `is_visible`.
- An extractor's `version`, with the others the pipeline profile runs, makes up the tag version; raise it when the extractor's output changes, and the tagging sweep derives every record's tags again.
- A `plugin_<name>` entry's output is tags, never listed to agents whatever `is_visible` says; `agent_property` and `connection` (the edges of `connect` and `group`) are what an agent asserted, and are visible.
- Every `extract` plugin in `conf/plugins.yaml` needs an entry in `conf/ep_versions.yaml`.

## Example
```text
e_ingest {"content": "The Acme renewal was signed on 2026-10-05.", "properties": ["org:Acme", "topic:renewal"]}
```

`e_read` of the new record lists `org:Acme` and `topic:renewal` and no other edge property. The record's tags hold the content's words as WordNet lemmatizes them, and the span of 5 October 2026 that chrono-node resolved. An `e_timeline` call with `order_by` set to `content_time_asc` places the record on that day.

## Implications
**Extraction is local.** Two engines holding one record each derive its tags. With different pipeline profiles they hold different tags.

**A missing plugin is silent to the caller.** With `optional: true`, `e_ingest` succeeds. The engine's log names the skipped plugin.

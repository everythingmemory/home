# Load and queue thresholds

When the engine slows its peers, defers repair work, or stops live change messages under load.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `INTAKE_BACKPRESSURE_THRESHOLD` | `2000` | — | How deep the intake queue may get before this engine asks its peers to pause; `0` turns it off |
| `QUEUE_SOFT_CEILING` | `0.8` | — | The share of the job queue's memory above which repair work is not queued; `0` turns it off |
| `FEED_ENABLED` | `true` | — | `false` stops the change feed's live messages; audit events are still written |

---
title: "Profiles"
sidebar_position: 2
kind: reference
status: drafted
verified_against: null
lede: "Two settings choose which component lists the engine runs: PIPELINE_PROFILE for ingest and question search, and TEMPORAL_PROFILE for e_timeline. Both name blocks in conf/profiles.yaml."
---

## What each setting selects

| Setting | Default | Selects | Used by |
|---|---|---|---|
| `PIPELINE_PROFILE` | `retrieval_v1` | A block with an `ingestion` list and a `curate` list | Ingest (`e_ingest`, `e_update`), and `e_gather` `find` |
| `TEMPORAL_PROFILE` | `timeline_v1` | A block with the `temporal`, `temporal_discourse` and `temporal_find` lists | `e_timeline` |

The structural actions of `e_gather` (`intersect`, `union`, `traverse`) run the fixed `gather` block in the same file.

## The shipped profiles

| Profile | Ingest extractors | Notes |
|---|---|---|
| `retrieval_v1` | WordNet, chrono-node | The default. Runs on the shipped stack |
| `agentic_eval_v2` | WordNet, Duckling | Needs Duckling's services, which the shipped stack does not run |
| `agentic_eval_v1` | WordNet, Duckling, JSON leaves | Needs Duckling's and the JSON-leaf plugin's services |

| Temporal profile | Reads a question's dates with | Notes |
|---|---|---|
| `timeline_v1` | chrono-node | The default |
| `temporal` | Duckling | Needs Duckling's services |

All three pipeline profiles run the same question search: tags and edge properties, full text, record vectors and window vectors, merged. See [search](../../../agents-how-to/finding-records/).

## Switching

Set the name in `local.env` and restart the stack. A name that is not a block in `conf/profiles.yaml`, or a temporal block missing one of its three lists, stops the engine at startup with the reason. A switch changes what runs from then on; records already ingested keep the tags they have.

`/health` names the pipeline profile and the temporal profile in force.

## Reference

The components and plugins: [pipeline and plugins](../pipeline-and-plugins/).

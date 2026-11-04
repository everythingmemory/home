---
title: "Observability"
sidebar_position: 0
kind: reference
status: drafted
verified_against: null
lede: "Operators and reviewers need to see what the engine is doing — whether it is healthy, what it wrote, and what failed. eMemory reports its state at a health endpoint; streams every change as it happens through the change feed; keeps every change in the audit log, readable at any time; and logs each service, with the time each step took."
---

import DocCardList from '@theme/DocCardList';

| Signal | What it tells you |
|---|---|
| **Health** — the API's `/health` | whether the engine is up, its release, its database and queue, its embedding model and its record and vector counts |
| **The change feed** | every change as it is written, live, for dashboards and reviewers |
| **The audit log** | every change, kept for good: who, what, when and from which engine — see [the audit log](../durability/the-audit-log/) |
| **Logs** | each service's log, on standard error, with the time each step of a call or job took |

<DocCardList />

---
title: "Patterns Built on the Mesh"
sidebar_position: 5
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "A realm of reference memory, a collector for audit and tracking, reporting, work groups, and travel: each built from sharing, accepting and agent profiles."
---

Every pattern below uses the same two choices — an owner **shares** a policy, a peer **accepts** it — and the same agent profiles. Combine them freely: one engine can be in several patterns at once.

## A realm: reference memory every site reads

A **realm** is the set of engines that take one organisation's reference memory — policies, product facts, approved procedures. One engine holds it and shares it; every site accepts it, and its agent profiles grant only **read** on those lanes, so sites use the reference memory and add their own work beside it, in their own lanes.

```mermaid
flowchart LR
  corp["Corporate engine<br/>reference lanes"] -- "shares" --> s1["Site A"]
  corp -- "shares" --> s2["Site B"]
  corp -- "shares" --> s3["Site C"]
  classDef e fill:#e8f2fc,stroke:#7aa7d6,color:#0b2a4a
  class corp,s1,s2,s3 e
```

## A collector: one place to audit and track

Sites share the policies whose work must be overseen; a collector engine accepts them all. It holds those records with every version and the audit events about them, so auditors and trackers work in one place, while each site's other lanes stay home.

```mermaid
flowchart LR
  s1["Site A"] -- "shares" --> col["Collector engine<br/>audit and tracking"]
  s2["Site B"] -- "shares" --> col
  s3["Site C"] -- "shares" --> col
  classDef e fill:#e8f2fc,stroke:#7aa7d6,color:#0b2a4a
  class col,s1,s2,s3 e
```

## Reporting

A reporting engine accepts what the reports need and gives its agents and programs read-only profiles. Dashboards follow changes live through its [change feed](../../observability/change-feed/), with no load on the sites that wrote them.

```mermaid
flowchart LR
  sites["Sites"] -- "share" --> rep["Reporting engine"]
  rep -- "change feed" --> dash["Dashboards and reports"]
  classDef e fill:#e8f2fc,stroke:#7aa7d6,color:#0b2a4a
  class sites,rep,dash e
```

## Work groups

A team's engines share one team policy with each other, both ways: everyone in the group reads and builds on the group's memory, and nothing outside that policy leaves anyone's engine.

```mermaid
flowchart LR
  a["Team member A"] <-- "team policy" --> b["Team member B"]
  b <-- "team policy" --> c["Team member C"]
  a <-- "team policy" --> c
  classDef e fill:#e8f2fc,stroke:#7aa7d6,color:#0b2a4a
  class a,b,c e
```

## Travel and remote work

A laptop runs its own engine, the real thing rather than a cache. Offline — on a plane, at a remote site — its agents keep reading and writing; when it reconnects, it exchanges what it missed with the engines it peers with, in both directions.

```mermaid
flowchart LR
  lap["Laptop engine<br/>works offline"] <-. "exchanges when connected" .-> home["Office or cloud engine"]
  classDef e fill:#e8f2fc,stroke:#7aa7d6,color:#0b2a4a
  class lap,home e
```

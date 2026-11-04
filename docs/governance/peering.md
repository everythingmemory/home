---
title: "Peering"
sidebar_position: 8
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "An owner whose agents run on several engines, under different owners and rules, needs to decide exactly what moves between them and with whom, and to stop it at will. Peering lets each side choose for itself: an owner shares a policy with a chosen peer and the peer accepts it, so nothing crosses that both did not pick, and nothing crosses by default; each peer has its own key, which opens only the exchange and can be rotated or removed; and deletions never cross."
---

Challenges addressed: [Enterprise Distributed Memory Requirements](../../use-cases/enterprise-memory-mesh/), [Multi-Agent Isolation](../../use-cases/multi-agent-isolation/).

## Two decisions, one on each side

Peering is how an engine's owner decides what moves between engines: which engines it trusts, which of its policies it offers, which of theirs it takes, and how to stop. Each side decides for itself; nothing crosses that both owners did not choose.

Records cross between engines a policy at a time, and only by two choices:

| On the engine that has the records | On the engine that wants them |
|---|---|
| **shares** a policy with a peer: offers the lanes it declares | **accepts** that policy from the peer: takes them |

A record crosses only when its lane's policy is shared by its owner (that policy, or `all`) and accepted by the peer; the bootstrap and built-in policies every engine seeds for itself never cross. Either side can stop at any time: the owner by no longer sharing, the peer by no longer accepting.

## Trust between engines

- **Peering needs authentication.** An engine with authentication off refuses to peer.
- **Each peer has its own key.** An engine can mint an inbound key for a peer (and must, for a peer it cannot dial); it is shown once, and the peer sends it on every exchange. A peer key opens only the two exchange routes — it can read and send what is shared, and nothing else; managing peers takes a client key or an OAuth sign-in.
- **Keys rotate.** Minting a replacement stops the old key at once.
- **Unpairing is one step.** Removing a peer ends every exchange with it.

## What crosses, and what never does

- **Records cross whole:** every version, with corrections, adjustments and the audit events about them — in their lane, keeping the engine that wrote them.
- **Deletions never cross.** A deletion is a decision about one engine's own copy: it stays on the engine where it was made, and a peer's records are never removed by another engine's deletion.
- **Tags never cross:** each engine derives its own from the content.
- **Exchanges are pull, in both directions at once.** Either engine can start an exchange, and an exchange cut short loses nothing: the next one, from either side, continues where it stopped.

## Setting it up

Step by step, with every command: [stacks in a mesh](../../operator-guide/stacks-in-a-mesh/), [local stacks peered with eMemory SaaS](../../operator-guide/saas-peering/), [a multi-site mesh](../../operator-guide/multi-site-mesh/). How the exchange works underneath: [distributed mesh architecture](../../architecture/distributed-mesh-architecture/).

---
title: "Local Stacks Peered with eMemory SaaS"
sidebar_position: 3
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "Stacks on laptops or your own servers, peered with a stack on eMemory SaaS: offline-first, exchanging what they missed when connectivity returns."
---

Stacks hosted locally — on laptops or on your own servers — are peered with a stack on eMemory SaaS.

![eMemory SaaS and a local eMemory engine, exchanging, with MCP clients around them](/img/local-cloud.svg)

**Offline-first.** A local stack is the real thing, not a cache: it reads and writes with no internet at all. On a plane, in a SCIF, off the grid: agents keep working; when connectivity returns, it exchanges what it missed. There is no hub: the SaaS stack is a peer like any other, and every exchange is peer-to-peer, with what crosses chosen per peer.

It's MCP underneath, so anything that speaks MCP plugs into the same memory — local or SaaS, Claude or not.

Guide: [Local Stacks Peered with eMemory SaaS](../../operator-guide/saas-peering/).

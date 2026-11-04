---
title: "A Multi-Site Enterprise Mesh"
sidebar_position: 4
kind: concept
status: drafted
verified_against: "core 1.2.8"
lede: "One engine per region or site, for low latency and data residency, peered directly: one governed, audited body of knowledge with no central chokepoint."
---

One eMemory per region or site, each serving MCP to its own agents and people, for low latency and data residency. Sites peer directly, and every team reads and writes one governed, audited body of knowledge with no central chokepoint: the memory bus is the mesh itself, not a hub.

![Three regional eMemory engines, US, EU and Japan, each serving MCP to its own agents and people; US and Japan share both ways, and EU accepts what they share and shares nothing of its own](/img/enterprise-mesh.svg)

A stack passes what it received on to its own peers, under its own shares, so sites need not all peer with each other. A site's lanes stay home unless it shares the policy that declares them.

Guide: [Multi-Site Mesh](../../operator-guide/multi-site-mesh/).

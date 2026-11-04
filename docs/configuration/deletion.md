---
title: "Deletion"
sidebar_position: 8
kind: reference
status: drafted
verified_against: null
lede: "The owner's switch that allows or forbids deleting records."
---

`deletions_enabled`, in `conf/settings.yaml` (not `local.env`), allows this engine's record deletes and undeletes; `false` as shipped.

It is off because eMemory is the system of record for AI agents: it remembers everything, and every change keeps what came before. A deletion takes a record out of every agent's view, so whether any agent may do that is the owner's decision. Even when it is on, a deletion hides a record rather than erasing it — its history, its audit events and its archive objects are all kept, and it can be undone.

Why, what a deletion does, and every detail of the switch: [the deletion switch](../../governance/deletion-switch/).

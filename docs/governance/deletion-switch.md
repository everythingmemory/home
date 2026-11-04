---
title: "Deletion Switch"
sidebar_position: 7
kind: reference
status: drafted
verified_against: null
lede: "eMemory is the system of record for AI agents: it remembers everything it is told, and every change keeps what came before. Deleting a record is the one act that takes something out of an agent's view, so it is the owner's decision, made once per engine — off as shipped — and even then nothing is erased."
---

## Why deletion is off

Everything else in eMemory adds: an update writes a new version and keeps the old one, a correction is attached to the record it corrects, an adjustment links the new fact to the old. That is what makes the memory trustworthy — any record can be traced back through every version, and an agent's past decisions can be checked against what it knew at the time.

A deletion is different: it removes a record from what agents can find. An agent that can delete can make the memory forget something it would be inconvenient to remember, so the ability belongs to the engine's owner, not to whichever agent holds a key. As shipped, no one can delete; an owner who needs deletion turns it on deliberately.

## What a deletion does

When deletion is on and a record is deleted:

- **it leaves retrieval:** search, reads and the timeline no longer return it, and its vectors and edge properties go with it;
- **its history stays:** the deletion is the last version in the record's ledger, every earlier version is kept, the audit log keeps every event about it, and the archive keeps every object — nothing is erased automatically;
- **it can be undone:** an undelete brings the record back at its last version;
- **it stays on this engine:** a deletion never travels to peers.

So a deletion hides a record from agents; it is not erasure. Removing data for good is a deliberate act by a person with access to the archive, outside the engine.

## The switch

| Switch | File | Shipped | What it governs |
|---|---|---|---|
| `deletions_enabled` | `conf/settings.yaml` | `false` | This engine's record deletes and undeletes: `e_system` `delete`, `e_system` `undelete`, and the REST delete |

- **Off:** a record delete or undelete is refused with: *deletions are off on this engine: conf/settings.yaml `deletions_enabled` is false. Its owner turns it on and restarts the engine; nothing was deleted* (or *undeleted*).
- **On:** any client key can remove records from retrieval. The engine logs a warning at start saying so.
- Removing an edge property is an edit, not a deletion, and is always allowed.
- A deletion is local: it is never sent to peers, and a record shared out stays on the peers that hold it. See [deleting a record](../../agents-how-to/deleting-a-record/#deletion-is-local).
- The switch is read once per process: change it and restart the engine and its workers. A value that is not `true` or `false` reads as `false`, with a warning.
- `/health` states the switch under `deletions`.

`conf/settings.yaml` can be overridden from `CONF_OVERRIDE_DIR`; an override replaces the whole file, so it names every switch it means to set.

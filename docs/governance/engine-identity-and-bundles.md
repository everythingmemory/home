---
title: "Engine Identity, Bundles and Take-over"
sidebar_position: 6
kind: how-to
status: drafted
verified_against: "core 1.2.8"
lede: "A bundle is one file holding a whole memory — records with their full history, corrections, policies, the audit log and, optionally, the vectors. Export one to back up or move a memory; import it into another engine to restore it there or to add it to a memory that already has its own."
---

## An engine's identity

Every engine has an identity, fixed when it is first started. Every record, version, correction and audit event it writes carries that identity, so any engine — this one, a peer, a restored copy — can tell whose writes they are. Deletions are judged by it: an engine applies its own deletions, never another's. Peers know each other by it.

An identity moves only one way: a new, empty engine can **take over** the identity of the engine a bundle came from (below). Nothing else changes an engine's identity.

## What a bundle is

A bundle is a single compressed file the engine writes on request. It holds:

- every record, with every version of it, deleted records included;
- corrections, policies and the audit log;
- the records' vectors (leave them out with `--no-embeddings`; the receiving engine then computes its own).

A bundle names the engine that made it. That name decides how another engine imports it (below).

A bundle is a copy you hold, beside the archive. The archive is how one engine recovers its own memory; a bundle is how a memory moves between engines, or is kept somewhere the engine cannot reach.

## The bundle tool

Bundles are written and read by the engine; a small tool on your side carries the file to and from it, encrypting and decrypting on your machine. It is part of eMemory's command-line image, so nothing is installed but the container engine you already run the stack with. Run it from the folder that holds (or will hold) the bundle file; it joins the stack's network (`ememory` unless you set `EMEMORY_NETWORK`) and reaches the engine by its service name:

```bash
docker run --rm -it --network ememory -v "$PWD":/work \
  -e EMEMORY_URL=http://ememory-api:8765 -e EMEMORY_API_KEY=<client key> \
  ghcr.io/everythingmemory/cli bundle <export|import> …
```

The examples below shorten that to `bundle`. The same image will carry eMemory's other command-line tools as they are added. The image's tag matches the release you run.

## Export

```bash
bundle export my-memory.ememory --encrypt
```

- `--encrypt` encrypts the file with a passphrase you choose, on your machine; the passphrase never reaches the engine. **There is no recovery: a lost passphrase is a lost bundle.** Keep it in your password manager.
- `--policy <uuid>` exports one policy and the records in its lanes instead of the whole engine.
- `--no-embeddings` leaves the vectors out; the file is much smaller.

Export and import accept a client key only (the same `emem_…` keys an agent uses), not an OAuth sign-in.

## Import

```bash
bundle import my-memory.ememory --merge
```

An encrypted bundle asks for its passphrase. What happens next depends on whose bundle it is:

| The bundle was made by | Choose | What happens |
|---|---|---|
| this engine | nothing | it imports as is |
| another engine, and this one is new and empty | `--take-over` | this engine **becomes** the engine that made the bundle — its identity, then its data. It prints `take-over:`, restarts itself, and you run the same import again to bring the data in. |
| another engine, and this one has a memory of its own | `--merge` | the bundle's records are added beside this engine's own, each keeping the engine that wrote it |

Run the same import twice and nothing is duplicated: what is already here is skipped.

### What a merge does with deletions

A deletion is a choice an engine's owner makes on their own copy, so a merge does not apply the bundle's deletions: a record the bundle holds deleted arrives **live**, and the import says how many with a warning. Delete them here if you do not want them.

### Choosing take-over or merge

- **Take-over** moves a memory to new hardware: the new engine carries on as the old one. Never run the old engine again once the new one has taken over — two engines with one identity confuse every peer they sync with.
- **Merge** brings a memory into one that already exists, or into a new engine you want to keep its own identity.

## Report

The import prints what it did per section — accepted and skipped counts for policies, records (and their history entries), corrections, vectors and audit events — then any warnings. Vectors made by a different embedding model are not stored (`foreign_space`); the engine computes its own for those records.

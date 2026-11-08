# Engine Identity and Bundles

A bundle is one file holding a memory — records with their full history, corrections, policies and, optionally, the vectors. Export one to keep a copy or to bring a memory into another engine; the importing engine takes it in as its own. An engine itself moves with its archive.

## An engine's identity

Every engine has an identity, fixed when it is first started. Every record, version, correction and audit event it writes carries that identity, so any engine — this one, a peer, a restored copy — can tell whose writes they are. Deletions are judged by it: an engine applies its own deletions, never another's. Peers know each other by it.

An import never changes an engine's identity.

## Moving an engine

An engine moves with its archive: give a fresh stack the same archive — the `ARCHIVE_DIR` folder, or the same external bucket — and the same `ARCHIVE_KEY`. It starts as the same engine, with the same identity, and rebuilds its memory from the archive. See [archive and restore](../durability/archive-and-restore.md). Do not run the old engine again once the new one is running: two engines with one identity confuse every peer they exchange with.

A bundle does not move an engine. It brings a memory into another engine, which keeps its own identity.

## What a bundle is

A bundle is a single compressed file the engine writes on request. It holds:

- every record, with every version of it;
- corrections, policies and the audit log;
- the records' vectors (leave them out with `--no-embeddings`; the receiving engine then computes its own).

A bundle names the engine that made it.

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
bundle import my-memory.ememory
```

An encrypted bundle asks for its passphrase. Every bundle is imported the same way, whichever engine made it:

- **Everything gets a new id.** Each record, lane, source type, profile, policy and correction takes an id of this engine's, worked out from the bundle's id and the two engines' identities. Every reference follows: a record's lane and type, a profile's home lane and grants, a correction's record, a vector's record.
- **Everything becomes this engine's own.** Imported records and policy changes are stamped with this engine's identity, so you can edit an imported policy here. The history is kept whole: every version, with its original time, action and note.
- **The same bundle again adds nothing.** The new ids come out the same every time, so what is already here is skipped, and an import that stopped part-way continues when you run it again. A later bundle from the same engine adds only what is new in it.

Some ids are the same on every engine and are kept as they are: the built-in lanes and profiles every engine seeds for itself, the built-in record types (`conversational`, `documentary`) and shipped policies. A shipped policy is not imported: install it here (`policy install <name>`). A bundle with records in a shipped policy's lane is refused until that policy is installed here, and the refusal names the command.

Link values — what `e_connect`, `e_group` and `e_adjustment` hold — arrive as they were written, so links between imported records still hold. Content, metadata, the agent profile and the credential recorded on each change arrive as written too.

### Deleted records

Deletions are not imported. A record the bundle holds as deleted is left out, together with its corrections and vectors, and the import warns how many. With `--include-deleted` such records arrive live instead.

### The audit log

The bundle's audit log is not imported. The import writes one event of its own to this engine's audit log, naming the bundle and what was imported.

### Profile names

A profile name names one profile. When a profile of a policy that would run here after the import would share its name with a profile running here, or with another such profile in the same bundle, the import is refused whole and the refusal lists each clash, with its policy. Profiles of policies that would not run here (never activated, or retired by their author) are imported and do not clash. Give the bundle's profile a new name as it comes in:

```bash
bundle import my-memory.ememory --rename-profile alice=alice-archive
```

`alice=alice-archive` renames every profile the bundle names `alice`; `crm/alice=alice-crm` renames only the one in the bundle's policy `crm`, which is how two profiles of one name in the same bundle are told apart. `--rename-profile` can be given more than once. In a terminal, the tool asks for a new name for each clashing profile of the bundle, by policy (an empty answer keeps that one's name), and imports again.

A stopped import continues only with the options it was started with; run with others, it is refused. A profile this engine already holds under the same id is the same profile, so importing a bundle a second time does not clash with what the first import brought.

### Things to know

- **Importing a bundle into the engine that made it makes a second copy** of everything in it, under new ids. Its profiles clash with the originals and need new names.
- **Between two peered engines, share a memory by peering or by bundle, not both.** A bundle's records arrive under new ids, so a record that also reaches the other engine through peering is held twice.
- **Folder Intake.** The `folder_id` and `file_id` values Folder Intake wrote arrive as they were. Watching the same folder from this engine starts a fresh chain of records; it does not continue the imported one.

## Report

The import prints what it did per section — accepted, skipped and left-out counts for policies, records (and their history entries), corrections and vectors — then any warnings. Vectors made by a different embedding model are not stored (`foreign_space`); the engine computes its own for those records.

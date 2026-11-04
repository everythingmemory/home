---
title: "The Console"
sidebar_position: 1.7
kind: how-to
status: drafted
verified_against: "console 1.0.10"
lede: "People who oversee an engine — operators, reviewers, auditors — need to see its memory directly, without an agent in between. The console is the engine's own web view: browse records with their full provenance and history, read the policies in force and every change to them, review what was deleted and when, check the engine's health, and manage its policies and peer pairings."
---

## What it is

The console ships with every stack and runs beside the engine. It shows one engine's memory as the engine itself holds it. It writes policies and peer pairings, never records — storing, updating, correcting and deleting records are done by agents and programs, through the tools.

## What it shows

| Room | What you see |
|---|---|
| **Records** | every record in the lanes the console may read, each with its content, edge properties, source, authority, version, corrections, adjustments and the full trail of events about it |
| **Audit log** | every event the engine recorded — what was written, by whom, in which lane and when — filtered by event type, lane, actor, source system, record and date |
| **Control plane** | every policy and the lanes, source types and agent profiles it declares, its history, and its YAML; edit, fork or create a policy, and turn one on or off |
| **Peers** | this engine's pairings: add a peer, mint a key for one, sync now, remove one |
| **Deletions** | what was deleted and what properties were removed, when, and by which agent profile |
| **Engine** | the engine's health, the records held per lane, its exchange with peers, the engine and profile this console uses, its version, and signing out |

A policy's YAML can be downloaded from the control plane.

## Signing in

Open the console in a browser on the machine the stack runs on; the [quickstart](../quickstart/) gives its address. With authentication on, sign in with a client key — the same kind of `emem_…` key an agent uses.

- **Mint a key just for people,** rather than reusing an agent's. Removing its hash later ends the console's access without touching any agent, and the audit log shows the console's activity under that key.
- **The key never stays in the browser.** The console's own server checks it with the engine once, then holds it; the browser keeps only a session cookie that scripts on the page cannot read.
- The console reads through the `restricted` agent profile, which every engine carries and which may read every lane.
- **A session lasts.** It ends after 30 days, or when you sign out — not when you step away. Set `CONSOLE_SESSION_MAX` (and, if you want one, an idle limit with `CONSOLE_SESSION_IDLE`) in `local.env` to change that; `0` means no limit. Restarting the console signs everyone out, because it never writes a key to disk.

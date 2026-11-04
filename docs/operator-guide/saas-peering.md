---
title: "Local Stacks Peered with eMemory SaaS"
sidebar_position: 13
kind: how-to
status: drafted
verified_against: null
lede: "Peer a stack on a laptop or your own server with an engine on eMemory SaaS. The local stack dials out; the SaaS engine never needs to reach it."
---

The deployment option: [locally hosted stacks peered with eMemory SaaS](../../deployment-options/local-and-saas/). The concepts: [peering](../../governance/peering/).

## How it works

A local stack behind NAT or a firewall cannot be dialled. It does not need to be: the side that calls runs one exchange that carries both directions. So the SaaS engine holds an **accept-only** row for the local stack — a row with no URL and an inbound key — and the local stack holds a row with the SaaS engine's URL and that key.

## What only ConcurAI can provision

The SaaS side of the pairing is a call to the SaaS engine's peer routes with a credential that engine accepts. Minting the accept-only row and its key, and sharing or accepting policies on the SaaS engine, are done there. **TODO — how a SaaS customer obtains the key and sets the SaaS engine's shares and accepts (through ConcurAI, or a route offered to customers).**

## Steps on the local stack

1. Set `AUTH_ENABLED=true` and a client key in `API_KEY_HASH_LIST`; peering refuses while authentication is off. The local stack does not need to be published to the network.
2. Obtain from the SaaS side the key its accept-only row was minted with (`KEY_FROM_SAAS`).
3. Pair:

   ```bash
   export EMEMORY_URL=http://localhost:8765
   export EMEMORY_API_KEY=<the local stack's client key>
   ./e.sh peer add https://<your SaaS engine's address> --peer-token "$KEY_FROM_SAAS"
   ```

4. Share and accept as in [stacks in a mesh](../stacks-in-a-mesh/), steps 4 to 6: share on whichever side offers, accept on the other, and run `./e.sh peer sync <peer id>` from the local stack.

The local stack reads and writes with no connection; when it reconnects, the next exchange (on the schedule, or `peer sync`) carries what both sides missed.

# Stacks in a Mesh

Peer two engines, share a policy from one, accept it on the other, check that it crossed, and revoke it.

The deployment option: [stacks in a mesh](../deployment-options/stacks-in-a-mesh.md). The concepts: [distributed mesh architecture](../architecture/distributed-mesh-architecture.md).

## Before you start

- Two stacks, A and B, each started as in the [quickstart](quickstart.md).
- On both: `AUTH_ENABLED=true`, a client key (`./e.sh client-key create`) that may do `peers` work — a key with no scope may, and the API service published to the other (`COMPOSE_FILE=docker-compose.yml:docker-compose.open.yml`). Peering refuses while authentication is off.
- `e.sh` on the operator's machine. Set, for whichever engine you are working on:

  ```bash
  export EMEMORY_URL=https://a.example   # or https://b.example
  export EMEMORY_API_KEY=<that engine's client key>
  ```

## Steps

1. **On A, mint the key B will send.**

   ```bash
   curl -s -X POST "$EMEMORY_URL/api/v1/sync/peers" -H "Authorization: Bearer $EMEMORY_API_KEY" \
     -H "Content-Type: application/json" -d '{"peer_url": "https://b.example", "mint_inbound_key": true}'
   ```

   Keep the `inbound_key` from the reply (`KEY_FOR_B`); it is shown once.

2. **On B, mint the key A will send**, the same call with `"peer_url": "https://a.example"`. Keep its `inbound_key` (`KEY_FOR_A`).

3. **Give each side the other's key.**

   ```bash
   # on A
   ./e.sh peer add https://b.example --peer-token "$KEY_FOR_A"
   # on B
   ./e.sh peer add https://a.example --peer-token "$KEY_FOR_B"
   ```

   `peer add` updates the row the mint created, since it names the same URL. `./e.sh peer list` shows each peer and its id.

4. **On A, share a policy.** Find its id, then share it:

   ```bash
   ./e.sh policy list
   ./e.sh peer share <B's peer id on A> <policy id>
   ```

   `all` shares every policy, later ones too. `peer add … --share TARGET` pairs and shares in one step.

5. **On B, see the offer and accept it.** Offers are learned from an exchange, so run one first:

   ```bash
   ./e.sh peer sync <A's peer id on B>
   ./e.sh peer offers <A's peer id on B>
   ./e.sh peer accept <A's peer id on B> <policy id>
   ```

6. **Exchange and check.**

   ```bash
   ./e.sh peer sync <A's peer id on B>
   ./e.sh peer status
   ```

   On B, a record written on A in one of the policy's lanes is now found by `e_gather` and read by `e_read`, with A's engine as its origin. With `CRON_ENABLED=true`, the exchange also runs on the schedule (every five minutes).

## Revoking

```bash
./e.sh peer unshare <B's peer id on A> <policy id>     # on A: stop offering
./e.sh peer unaccept <A's peer id on B> <policy id>    # on B: stop taking
./e.sh peer remove <peer id>                           # unpair
```

Revoking stops further flow. What was already exchanged stays on the receiving engine.

## What can go wrong

- `peering needs auth`: set `AUTH_ENABLED=true` on that engine.
- `peer offers` shows nothing: no exchange has run yet; run `peer sync`.
- A peer key used on any route but the two exchange routes is refused; manage peers with a client key.

## Command reference

`e.sh` is the command-line script over the REST API. It reads `EMEMORY_URL` and `EMEMORY_API_KEY` (a client key of the engine it talks to).

| Command | What it does |
|---|---|
| `e.sh peer add URL --peer-token T [--share TARGET]` | Pairs the engine at `URL`, sending `T` when calling it; optionally shares in the same step |
| `e.sh peer list` | Peers, with status, last exchange, shares and accepts |
| `e.sh peer share PEER_ID TARGET` | Offers a policy id or `all` |
| `e.sh peer unshare PEER_ID TARGET` | Revokes a share |
| `e.sh peer offers PEER_ID` | What the peer offers, as of its last exchange, and which are accepted |
| `e.sh peer accept PEER_ID TARGET` | Takes a policy id from the offers |
| `e.sh peer unaccept PEER_ID TARGET` | Stops taking it |
| `e.sh peer sync [PEER_ID]` | Exchanges now, with one peer or all |
| `e.sh peer status` | This engine's exchange status |
| `e.sh peer remove PEER_ID` | Unpairs |
| `e.sh policy list` | Policies, with their ids |

Minting an inbound key is a REST call; `e.sh` has no verb for it:

```bash
curl -s -X POST "$EMEMORY_URL/api/v1/sync/peers" -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" -d '{"peer_url": "https://b.example", "mint_inbound_key": true}'
```

The reply carries `peer_id` and, this once, `inbound_key`. `POST /api/v1/sync/peers/{peer_id}/inbound-key` mints a replacement; the old key stops working at once.

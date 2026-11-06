# Multi-Site Mesh

Run one stack per site, peer the sites, and decide per site what it shares. A stack passes on what it received to its own peers, under its own shares.

The deployment option: [a multi-site enterprise mesh](../deployment-options/multi-site.md). Pairing two stacks: [stacks in a mesh](stacks-in-a-mesh.md).

## Plan the shares

Each site decides, per peer, which policies it offers and which it takes. Write it down before pairing:

| Site | Shares with | Policies | Accepts from | Policies |
|---|---|---|---|---|
| EMEA | Headquarters | `sales` | Headquarters | `company` |
| Headquarters | EMEA, APAC | `company`, `sales` | EMEA | `sales` |
| APAC | Headquarters | — | Headquarters | `company`, `sales` |

A policy a site never shares — EMEA's `legal`, say — never leaves it.

## Relays

Sites need not all peer with each other. A stack that received a policy from one peer passes it on to another peer when it shares that policy with it — by the policy's id, or with `all` — and that peer accepts it. In the table, APAC receives EMEA's `sales` through Headquarters.

```bash
# on Headquarters: pass EMEA's sales policy on to APAC
./e.sh peer share <APAC's peer id> <sales policy id>
# on APAC
./e.sh peer sync <Headquarters' peer id>
./e.sh peer accept <Headquarters' peer id> <sales policy id>
```

A record that arrives through a relay keeps its origin: the site that wrote it.

## Steps

1. Stand up each site's stack as a [single stack](single-stack.md), with authentication on and the API service published to the sites it peers with.
2. Pair each pair of sites in the plan, as in [stacks in a mesh](stacks-in-a-mesh.md) steps 1 to 3.
3. Set each site's shares and accepts from the plan.
4. With `CRON_ENABLED=true`, exchanges run every five minutes; `./e.sh peer sync` runs one now.
5. Check on each site with `./e.sh peer list` (last exchange, shares, accepts) and `./e.sh peer status`.

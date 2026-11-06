# Authentication

Whether callers must present a key, which keys the engine accepts and what each may do, and signing in through an identity provider.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `AUTH_ENABLED` | `false` | `false`; required | With `true`, every caller except `/health` must send a client key from `conf/keys.yaml`. With `false`, every caller is accepted, and the API service is published on 127.0.0.1 only |
| `OAUTH_ISSUER` | empty | — | The identity provider's issuer URL. Turns OAuth on, alongside client keys. See [your own identity provider](../operator-guide/auth-own-identity-provider.md) |
| `OAUTH_JWKS_URI` | empty | — | Where the provider publishes its signing keys |
| `OAUTH_AUDIENCE` | empty | — | Optional: the audience a JWT must carry |
| `OAUTH_RESOURCE` | empty | — | This engine's canonical `https` URL, named in its protected-resource metadata |
| `OAUTH_CUSTOMER_UUID` | empty | — | The value a token's `customer_uuid` claim must equal; unset, every OAuth token is refused |
| `OAUTH_JWKS_CACHE_SECONDS`, `OAUTH_INTROSPECTION_CACHE_SECONDS` | `3600`, `60` | — | How long signing keys and introspection results are cached |

## Opening the engine to other machines

The shipped stack publishes the engine on 127.0.0.1 only. To reach it from other machines, set in `.env`:

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.open.yml
```

The overlay publishes the engine's port on every interface and forces `AUTH_ENABLED=true`, whatever `.env` says.

## Client keys

`conf/keys.yaml` is the engine's one registry of client keys. Each entry is one key: a `label`, which names the key in refusals and in the [audit log](../durability/the-audit-log.md) (`client:<label>`), and the key's SHA-256 `hash`. The key itself is never in the file. With authentication on and neither a key in the file nor `OAUTH_ISSUER`, the engine refuses to start.

Create a key with `./e.sh client-key create`. It prints the key (`emem_…`) once and appends its entry to the file:

```bash
./e.sh client-key create --label scout --profiles restricted
```

```yaml
keys:
  - label: console
    hash: "<64 hex characters>"
  - label: scout
    hash: "<64 hex characters>"
    profiles: [restricted]
  - label: ops
    hash: "<64 hex characters>"
    operations: [policies, peers, admin]
```

| Field | What it holds |
|---|---|
| `label` | Required and unique: letters, digits, `.`, `_` or `-`, up to 64, starting with a letter or digit |
| `hash` | Required: the SHA-256 of the key, 64 hexadecimal characters |
| `profiles` | Optional: the agent profiles the key may act as |
| `policies` | Optional: policy names or uuids; the key may act as every profile those policies declare, including one a policy gains later |
| `operations` | Optional: the operator work, outside any profile, the key may do — any of `policies`, `peers`, `bundles`, `admin`, `records` |

- **No scope field, everything.** An entry with no `profiles`, `policies` or `operations` opens every profile and every operation.
- **Any scope field, only what it names.** A scoped key acts only as the profiles its fields open. Naming no profile, it gets the default profile if its scope opens it; if the scope opens exactly one profile, that one; otherwise the call is refused, naming the profiles it may act as. Operator work it does not hold is refused by name (`403` over REST, an error result over MCP): the refusal names the key and the operations it has.
- **Reading policy structure is open to every key** — the profiles, the policies, the catalog and their history.
- **Revoking a key** is deleting its entry.
- **Checked at start.** The engine reads the file when it starts, so an edit takes effect on restart. A name the engine does not know, an empty list, a malformed hash or a repeated label stops the start with the reason. The engine warns at start when group or others can write the file.

Peer keys and OAuth tokens are not in this file and carry no scope.

`API_KEY_HASH_LIST` is retired: set, it stops the engine at start. Client keys live in `conf/keys.yaml`.

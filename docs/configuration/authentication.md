# Authentication

Whether callers must present a key, which keys the engine accepts and what each may do, and signing in through an identity provider.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `AUTH_ENABLED` | `false` | `false`; required | With `true`, every caller except `/health` must send a client key the engine holds. With `false`, every caller is accepted, and the API service is published on 127.0.0.1 only |
| `SEED_KEY_HASHES` | empty | written by `./e.sh init` | The first client keys, `label:hash,…` (each key's SHA-256). Read only while the engine holds no client key, and ignored after |
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

The engine holds its client keys. Each is a `label`, which names the key in refusals and in the [audit log](../durability/the-audit-log.md) (`client:<label>`), the key's SHA-256 `hash`, and an optional scope. The key itself is never kept. The list is part of the engine's own configuration, which is written to the [archive](archive.md), encrypted, with every change: a restore brings the keys back. With authentication on and neither a client key nor `OAUTH_ISSUER`, the engine refuses to start.

**The first key.** `./e.sh init` mints one, `client`, with no scope, prints it once, and writes its hash to `SEED_KEY_HASHES` in `.env`. An engine that holds no key takes the keys `SEED_KEY_HASHES` names when it starts. If the archive holds the engine's configuration, the engine takes the keys from there and ignores `SEED_KEY_HASHES`.

**Managing keys.** `./e.sh client-key` calls the engine at `EMEMORY_URL`, as the console does. Every verb needs a client key with no scope. A scoped key is refused, even one with the `admin` operation, and so is an OAuth token. With authentication off, these calls are open, like every other call. A change takes effect on the next call. No restart is needed.

```bash
./e.sh client-key create --label scout --profiles restricted   # prints the key once
./e.sh client-key list                                          # MANAGES: may manage keys
./e.sh client-key scope --label scout --policies team           # replaces the whole scope
./e.sh client-key scope --label scout --unscoped
./e.sh client-key rotate --label scout     # a new key, same scope; the old one stops now
./e.sh client-key rotate --label scout --hash <sha256>   # you made the key; no key comes back
./e.sh client-key revoke --label scout     # the key stops now
./e.sh client-key download --out client-keys.yaml
./e.sh client-key upload client-keys.yaml
```

`download` writes the list, hashes only:

```yaml
keys:
- label: client
  hash: <64 hex characters>
- label: scout
  hash: <64 hex characters>
  profiles: [restricted]
- label: ops
  hash: <64 hex characters>
  operations: [policies, peers, admin]
```

| Field | What it holds |
|---|---|
| `label` | Required and unique: letters, digits, `.`, `_` or `-`, up to 64, starting with a letter or digit |
| `hash` | Required: the SHA-256 of the key, 64 hexadecimal characters |
| `profiles` | Optional: the agent profiles the key may act as |
| `policies` | Optional: policy names or uuids; the key may act as every profile those policies declare, including one a policy gains later |
| `operations` | Optional: the operator work, outside any profile, the key may do — any of `policies`, `peers`, `bundles`, `admin`, `records` |

`upload` changes scope only. Each of these refuses the whole upload, and every error is listed:

- a label the engine does not hold (`create` adds a key)
- a key missing from the file (`revoke` removes one)
- a changed label
- a changed hash (`rotate` replaces it)
- an unknown field or operation

- **No scope field, everything.** An entry with no `profiles`, `policies` or `operations` opens every profile and every operation.
- **Any scope field, only what it names.** A scoped key acts only as the profiles its fields open. Naming no profile, it gets the default profile if its scope opens it; if the scope opens exactly one profile, that one; otherwise the call is refused, naming the profiles it may act as. Operator work it does not hold is refused by name (`403` over REST, an error result over MCP): the refusal names the key and the operations it has.
- **Keys and policies, in any order.** A profile or policy name the engine does not know yet is a warning, not a refusal; the key opens nothing for that name until it exists. The first time a name is found, the key holds that profile or policy by its uuid, so a same-named profile that arrives later is not it. A policy name that two policies share is refused when the key is used. Name such a policy by its uuid. An empty list opens nothing. An unknown operation is refused.
- **Reading policy structure is open to every key** — the profiles, the policies, the catalog and their history.
- **The last key that can manage keys stays.** `revoke`, `scope` and `upload` refuse a change that would leave no key with no scope.
- **A read-only archive** (`ARCHIVE_READ_ONLY=true`) loads the keys and refuses every change to them.

Peer keys and OAuth tokens are not client keys and carry no scope.

`API_KEY_HASH_LIST` and `conf/keys.yaml` are retired. If either is present, the engine does not start.

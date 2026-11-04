---
title: "Authentication"
sidebar_position: 2
kind: reference
status: drafted
verified_against: null
lede: "Whether callers must present a key, which keys the engine accepts, and signing in through an identity provider."
---

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `AUTH_ENABLED` | `false` | `false`; required | With `true`, every caller except `/health` must send a client key. With `false`, every caller is accepted, and the API service is published on 127.0.0.1 only |
| `API_KEY_HASH_LIST` | empty | empty | The SHA-256 hashes of the client keys, comma-separated. Every key is equal; removing a hash revokes that key. With authentication on and neither a hash nor `OAUTH_ISSUER`, the engine refuses to start |
| `OAUTH_ISSUER` | empty | — | The identity provider's issuer URL. Turns OAuth on, alongside client keys. See [your own identity provider](../../operator-guide/auth-own-identity-provider/) |
| `OAUTH_JWKS_URI` | empty | — | Where the provider publishes its signing keys |
| `OAUTH_AUDIENCE` | empty | — | Optional: the audience a JWT must carry |
| `OAUTH_RESOURCE` | empty | — | This engine's canonical `https` URL, named in its protected-resource metadata |
| `OAUTH_CUSTOMER_UUID` | empty | — | The value a token's `customer_uuid` claim must equal; unset, every OAuth token is refused |
| `OAUTH_JWKS_CACHE_SECONDS`, `OAUTH_INTROSPECTION_CACHE_SECONDS` | `3600`, `60` | — | How long signing keys and introspection results are cached |

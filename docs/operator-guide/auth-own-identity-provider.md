# Authentication with Your Own Identity Provider

Configure a self-hosted engine as an OAuth 2.1 resource server for your own identity provider, so people sign in from ChatGPT, claude.ai and other MCP clients.

:::warning[Not yet tested with third-party identity providers]
This page describes what the engine's code does. It has been run only against eMemory SaaS's own identity provider.
:::

## How the engine checks a token

With `AUTH_ENABLED=true` and `OAUTH_ISSUER` set, the engine accepts, besides its client keys:

| Token | How it is checked |
|---|---|
| A JWT | Signed with RS256 by a key in the provider's JWKS (`OAUTH_JWKS_URI`); issuer equal to `OAUTH_ISSUER`; audience equal to `OAUTH_AUDIENCE` when that is set, not checked when it is not |
| An opaque token | Sent to `<OAUTH_ISSUER>/oauth/introspect/` and accepted while the provider says it is active |

Either way, the token must carry a claim named `customer_uuid` equal to `OAUTH_CUSTOMER_UUID`. A token without it, with another value, or arriving at an engine with no `OAUTH_CUSTOMER_UUID` set, is refused (fail closed). Configure your provider to add this claim to the tokens it issues for this engine.

Client keys keep working alongside OAuth.

## The flow

1. A client calls `/mcp` with no token. The engine answers `401`, pointing to its metadata document.
2. The client reads `/.well-known/oauth-protected-resource` (RFC 9728): the engine's `resource` identifier (`OAUTH_RESOURCE`) and its authorization server (`OAUTH_ISSUER`).
3. The client sends the person to the provider to sign in, asking for a token for that resource (RFC 8707 `resource=`).
4. The client calls the engine with `Authorization: Bearer <token>`, and the engine checks it as above.

For ChatGPT and claude.ai, the provider must support the MCP authorization flow: dynamic client registration, or a client registered in advance that you give the connector.

## Settings

| Setting | What it is |
|---|---|
| `OAUTH_ISSUER` | The provider's issuer URL. Turns OAuth on |
| `OAUTH_JWKS_URI` | Where the provider publishes its signing keys |
| `OAUTH_AUDIENCE` | Optional. The audience a JWT must carry |
| `OAUTH_RESOURCE` | This engine's canonical `https` URL, with no port or path. Unset, the metadata names the host the request came in on |
| `OAUTH_CUSTOMER_UUID` | The value the token's `customer_uuid` claim must equal |
| `OAUTH_JWKS_CACHE_SECONDS`, `OAUTH_INTROSPECTION_CACHE_SECONDS` | How long signing keys (default 3600) and introspection results (default 60) are cached |

## Requirements

- JWTs must be signed with RS256.
- The introspection address is fixed at `<OAUTH_ISSUER>/oauth/introspect/`, and the engine sends no client credentials with it. A provider whose introspection endpoint is elsewhere, or requires the caller to authenticate, works only with JWTs.
- The engine publishes `scopes_supported: ["read", "write"]` and does not check scopes on a call.

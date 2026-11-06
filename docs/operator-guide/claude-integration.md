# Claude Integration

Connect Claude Code, Claude Desktop and claude.ai to an eMemory stack over MCP: the endpoint, the client key, the agent profile, and a first check that the tools appear.

## What the engine expects

| | |
|---|---|
| Endpoint | `http://localhost:8765/mcp` for a stack on this machine (streamable HTTP); `https://<your host>/mcp` for a stack published over HTTPS |
| Credential | With `AUTH_ENABLED=true`, the header `Authorization: Bearer <client key>`, where the key has an entry in `conf/keys.yaml`. With authentication off, no header |
| Agent profile | Named per call with the `agent_profile` argument; a call that names none runs as the engine's default agent profile. A key scoped to profiles acts only as those. Tell the agent which to use in its instructions or a skill |

Create a client key: see [client keys](connecting-clients-and-operating.md#client-keys).

## Claude Code

Claude Code connects from your machine, so it reaches a stack on `localhost`.

```bash
claude mcp add --transport http everythingmemory http://localhost:8765/mcp \
  --header "Authorization: Bearer <client key>"
```

Leave out `--header` while authentication is off. `--scope project` writes the entry to `.mcp.json` in the project, shared with the team; `--scope user` makes it available in all your projects. Or write `.mcp.json` yourself, keeping the key in an environment variable:

```json
{
  "mcpServers": {
    "everythingmemory": {
      "type": "http",
      "url": "http://localhost:8765/mcp",
      "headers": {
        "Authorization": "Bearer ${EMEMORY_KEY}"
      }
    }
  }
}
```

Name the server `everythingmemory`: the [agent skills](agent-skills.md) plugin's permission examples use that name (`mcp__everythingmemory__*`).

Install the skills plugin as described in [agent skills](agent-skills.md).

## Claude Desktop and claude.ai

Both reach remote MCP servers as **custom connectors**, and a custom connector is called from Anthropic's cloud, not from your device: the server must be reachable over the public internet from Anthropic's addresses. A stack on `localhost` or a private network cannot be added this way. It applies to a stack published over HTTPS — your own, behind `docker-compose.open.yml` and a TLS proxy, or eMemory SaaS.

1. In Claude, open **Settings › Connectors** and add a custom connector.
2. URL: `https://<your host>/mcp`.
3. Credential: under request headers, `Authorization: Bearer <client key>`; or sign in with OAuth — see [authentication with eMemory SaaS](auth-ememory-saas.md) and [authentication with your own identity provider](auth-own-identity-provider.md).

Custom connectors are available on all Claude plans; on Free, one. Source: Anthropic, [Get started with custom connectors using remote MCP](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp).

## First check

Restart the client if it was running, then ask the agent to call:

```text
e_property {"action": "list"}
```

A reply listing labels (an empty list on a new stack) shows the tools are connected. In Claude Code, `/mcp` shows the server's status. If the tools stop responding, the `e-doctor` skill diagnoses the connection.

Sources: Anthropic, [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp).

---
title: "ChatGPT and OpenAI Integration"
sidebar_position: 4
kind: how-to
status: drafted
verified_against: null
lede: "Connect ChatGPT and OpenAI's APIs to an eMemory stack over MCP: what each can reach, and the credential each can send."
---

The endpoint, client key and agent profile are as in [Claude integration](../claude-integration/#what-the-engine-expects).

## Which OpenAI surface can reach which stack

| Surface | Calls the server from | Reaches `localhost` | Sends a client key |
|---|---|---|---|
| OpenAI Agents SDK (`MCPServerStreamableHttp`) | Your own process | Yes | Yes, as a header |
| Responses API, `mcp` tool | OpenAI's servers | No; the server must be on the public internet | `authorization` field, an access token |
| ChatGPT, developer mode | OpenAI's servers | No | OAuth or no authentication only |

## OpenAI Agents SDK

The SDK connects from your process, so it reaches a stack on this machine.

```python
import os
from agents.mcp import MCPServerStreamableHttp

ememory = MCPServerStreamableHttp(
    name="everythingmemory",
    params={
        "url": "http://localhost:8765/mcp",
        "headers": {"Authorization": f"Bearer {os.environ['EMEMORY_KEY']}"},
    },
)
```

Source: OpenAI Agents SDK, [MCP](https://openai.github.io/openai-agents-python/mcp/).

## Responses API

The `mcp` tool is called by OpenAI's servers, so the stack must be published over HTTPS.

```json
{
  "type": "mcp",
  "server_label": "everythingmemory",
  "server_url": "https://<your host>/mcp",
  "authorization": "<client key>",
  "require_approval": "never"
}
```

**Unverified:** that the `authorization` value reaches the engine as `Authorization: Bearer <client key>`. Source: OpenAI, [Connectors and MCP servers](https://developers.openai.com/api/docs/guides/tools-connectors-mcp).

## ChatGPT

In developer mode (Settings › Apps › Advanced settings), ChatGPT adds a remote MCP server as an app. It offers OAuth or no authentication, not a fixed client key. A self-hosted stack published to the internet must run with authentication on, so ChatGPT can connect only to an engine that offers OAuth: eMemory SaaS (see [authentication with eMemory SaaS](../auth-ememory-saas/)) or a stack configured for [your own identity provider](../auth-own-identity-provider/). Source: OpenAI, [ChatGPT developer mode](https://developers.openai.com/api/docs/guides/developer-mode).

## First check

Have the agent call `e_property {"action": "list"}`. A reply listing labels shows the tools are connected.

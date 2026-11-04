---
title: "Authentication with eMemory SaaS"
sidebar_position: 7
kind: how-to
status: drafted
verified_against: null
lede: "An engine on eMemory SaaS uses ConcurAI's identity provider. There is nothing for the customer to set up; ChatGPT and claude.ai connect by signing in."
---

## How it works

An engine on eMemory SaaS is an OAuth 2.1 resource server whose identity provider is ConcurAI's. The engine is configured for it when the engine is provisioned: the issuer, the engine's public address, and the customer it belongs to. A token is accepted only when it was issued for that customer.

There is nothing for the customer to configure on the engine.

## Connecting a client

| Client | How |
|---|---|
| claude.ai, Claude Desktop | Add a custom connector with the engine's address, `https://<your engine>/mcp`, and sign in when Claude asks. See [Claude integration](../claude-integration/#claude-desktop-and-claudeai) |
| ChatGPT | In developer mode, add the engine's address as an app with OAuth, and sign in when ChatGPT asks. See [ChatGPT and OpenAI integration](../chatgpt-openai-integration/#chatgpt) |
| Claude Code, the OpenAI Agents SDK, OpenClaw, other clients | The same sign-in where the client supports MCP OAuth; otherwise a client key from the engine's operator |

When a client first connects without a token, the engine answers `401` and points it at its metadata document, `/.well-known/oauth-protected-resource`, which names the identity provider. The client sends the person to sign in there and receives a token bound to this engine.

## Client keys

Client keys keep working alongside sign-in, for programs and scripts. To get an eMemory SaaS account and its first client key, [register](https://everythingmemory.ai/ememory/register/) and choose the hosted trial.

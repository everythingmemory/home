---
title: "OpenClaw Integration"
sidebar_position: 5
kind: how-to
status: drafted
verified_against: null
lede: "Connect OpenClaw to an eMemory stack as a remote MCP server, with the client key as a header."
---

The endpoint, client key and agent profile are as in [Claude integration](../claude-integration/#what-the-engine-expects).

## Configuration

OpenClaw keeps its outbound MCP servers under `mcp.servers` in its configuration. Add eMemory as a streamable-HTTP server:

```bash
openclaw mcp set everythingmemory '{"url":"http://localhost:8765/mcp","transport":"streamable-http","headers":{"Authorization":"Bearer ${EMEMORY_KEY}"}}'
```

Set `EMEMORY_KEY` in the environment of the host OpenClaw runs on. Leave out `headers` while authentication is off. `transport` must be `streamable-http`; left out, OpenClaw uses SSE. If OAuth is enabled for the server entry, OpenClaw ignores a static `Authorization` header.

`localhost` works when OpenClaw runs on the same machine as the stack; otherwise use the stack's published address.

## First check

```bash
openclaw mcp probe
```

The probe opens a live connection and lists the server's capabilities; eMemory's ten tools should appear.

Sources: OpenClaw, [`openclaw mcp`](https://docs.openclaw.ai/cli/mcp.md) and [Transports and OAuth](https://docs.openclaw.ai/cli/mcp/transports).

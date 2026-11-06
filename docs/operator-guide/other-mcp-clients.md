# Other MCP Clients

The general recipe for any MCP client: the endpoint, the key header, the agent profile, and a first check.

1. **Endpoint.** `http://localhost:8765/mcp` over streamable HTTP, or `/mcp/sse` for a client that speaks only the older SSE transport. A client that calls from a vendor's cloud needs the stack published over HTTPS.
2. **Key.** With `AUTH_ENABLED=true`, send `Authorization: Bearer <client key>` on every request. Give each client its own key, so one can be revoked alone, and scope it to that client's profiles. See [client keys](../configuration/authentication.md#client-keys).
3. **Agent profile.** The agent names it with the `agent_profile` argument on its calls; tell it which in its instructions. With none, calls run as the engine's default agent profile.
4. **Instructions.** On connecting, the client receives the engine's instructions and the description of each tool. For a client without plugins, give the agent the text of the [agent skills](agent-skills.md) as well.
5. **First check.** Call `e_property` with `{"action": "list"}`. A reply listing labels (empty on a new stack) shows the connection works.

# Security

## Reporting a vulnerability

Report it privately through this repository's **Security** tab: choose **Report a vulnerability**. The report reaches only the maintainers. Please do not open a public issue, pull request or discussion for a suspected vulnerability.

Include what you can of:

- the version or commit you tested (`GET /health` reports the engine version);
- the component affected — engine, a plugin, the compose stack, `e.sh`, Folder Intake (`watcher/`) or the bundle CLI (`bundle/`);
- the steps to reproduce it, and any configuration it depends on (with secrets removed);
- what an attacker gains, and from what starting position (no access, a client key, a peer key, access to the host);
- whether you have shared it with anyone else.

We will acknowledge your report, keep you informed while we investigate, and tell you when a fix is released. Please give us reasonable time to release a fix before you disclose the issue publicly.

There is no bug bounty programme.

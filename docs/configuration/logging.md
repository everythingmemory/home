# Logging

Where the engine logs, and in what format.

The engine logs to standard error, in the format set by `conf/logging.yaml`. `LOG_LEVEL` (for example `DEBUG`) overrides the root level set in `conf/logging.yaml`.

- The engine, its workers and its command-line tools all load `conf/logging.yaml`.
- Each line is `time  call-id  level  module  message`; the call id is shared by the lines of one request.
- `uvicorn.access` writes a line only for a request answered with status 400 or above.
- `arq.worker` is at `WARNING`: the per-job start and finish lines are off; the sweeps log their own work at `INFO`, and failures at `WARNING`.
- `httpx`, `httpcore`, `hpack`, `alembic.runtime.plugins` and `core.middleware` are at `WARNING`.
- A change takes effect when the stack restarts.

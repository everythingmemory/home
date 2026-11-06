#!/usr/bin/env bash
# Copyright (c) 2026 ConcurAI
# SPDX-License-Identifier: BUSL-1.1
# e.sh — eMemory admin CLI: a thin curl wrapper over the REST admin API.
# Works against any instance (self-hosted or cloud) via URL + client key. JSON is
# pretty-printed via python3 (json.tool); tables use python3 (+ pyyaml). No jq.
#
# Connection (flag or env):
#   --url URL        EMEMORY_URL        e.g. http://localhost:8765  or  https://<customer>.<domain>
#   --api-key KEY    EMEMORY_API_KEY    client key (required wherever the engine runs with AUTH_ENABLED=true, as cloud does)
#   --insecure                          skip TLS verification (self-signed certs)
# HTTPS is native curl (cert verification on); redirects followed (-L). -h/--help.
#
# Three nouns — `profile` and `lane` are components; `policy` is the versioned whole:
#   profile list [--json]                 configured agent profiles (resolved)
#   profile get NAME                      one profile
#   lane    list [--json]                 unified: registry x observed counts + origin
#   lane    get LANE [--json]             one lane: config + count + origin
#   lane    rename LANE NEW [--dry-run]   rename a lane — one policy event; no record, entry or row moves
#                                         A lane is its uuid; its name is a label. Wherever a LANE is
#                                         taken it may be a name, name@fragment (shown where two lanes
#                                         share a name), or the lane uuid
#   policy  list [--source S]             every policy the engine knows: the ones in its ledger and
#                                         the shipped ones not yet installed. SOURCE = built-in |
#                                         shipped | local | peer; STATE = available (shipped, not
#                                         installed) | installed (in the ledger, not running) | active.
#                                         --source shows one SOURCE. Who RECEIVES a policy is not the
#                                         policy's business: see `peer share`
#   policy  install NAME                  install shipped law HERE: seed its events + activate locally.
#                                         Same ids on every engine, so two estates that install it hold
#                                         ONE policy when they pair. Read-only: upload can't edit it
#   policy  download [NAME] [--out FILE]  one EDITABLE source policy -> FILE (default <name>.yaml);
#                                         NAME required when several local policies exist
#   policy  catalog [--by-policy] [--all]  read-only COMBINED catalog the engine enforces (union of
#                                         activated); --by-policy pivots lanes/profiles under each
#                                         policy; --all also lists inactive (disabled) policies
#   policy  upload FILE [--dry-run]       apply a whole-policy YAML (genesis-then-edit on its uuid).
#                  [--fork|--adopt]       on an UNSEEN, foreign-authored uuid: --fork mints a fresh
#                                         independent copy; --adopt claims genesis here (migration)
#   policy  enable NAME | disable NAME    toggle whether the policy RUNS (an event: paired engines follow)
#   policy  retire NAME | unretire NAME   author-only: SYNCED enable=false — excludes the policy fleet-wide
#   policy  purge NAME [--force]          LOCAL hard-delete of a policy's events (never-shared only; retire to share)
#   source_record list [LANE] [--where label:value] [pN]   SRs by lane and/or property (alias: sr)
#   source_record get SR_ID               one SR: content + lane + declared properties (+ tags)
#                                         (a record's lane is fixed at birth: there is no move)
#   source_record undelete SR_ID... --agent-profile NAME
#                                         bring deleted SRs back (needs conf/settings.yaml
#                                         `deletions_enabled: true` on the engine)
#   property list [LABEL]                 list property labels (+counts), or values for one label
#   export  OUT [--policy UUID] [--no-embeddings] [--encrypt]
#                                     write the engine's BUNDLE to OUT: the whole engine, or
#                                     one policy and its data. --encrypt wraps it in age by passphrase
#                                     HERE (prompted, or $EMEMORY_BUNDLE_PASSPHRASE) — the passphrase
#                                     never reaches the engine. Needs python3 with the bundle package
#                                     (pip install -e bundle/) — set EMEMORY_PYTHON to its venv
#   import  FILE [--take-over | --merge]
#                                     import a bundle (decrypted here when it is age ciphertext).
#                                     Your own bundle imports as is; another engine's needs
#                                     --take-over (an empty engine becomes it) or --merge (added
#                                     as another engine's, without its deletions)
#   ingest  DIR --agent-profile NAME [--lane L] [--property k:v]... [--glob PATTERN]
#               [--prune] [--watch] [--dry-run] [--max-size B] [--sync]
#                                     FOLDER INTAKE: every document under DIR becomes memory,
#                                     verbatim — PDF/DOCX/HTML/XLSX converted to text here, text
#                                     and markdown as they are, anything else refused BY NAME.
#                                     Idempotent: a rerun ingests only what changed. A file that
#                                     left the directory is reported as an orphan and KEPT unless
#                                     --prune tombstones it. --watch reruns the same pass on a
#                                     loop; --dry-run says what would happen. Needs python3 with
#                                     the watcher package (pip install -e watcher/) — set
#                                     EMEMORY_PYTHON to pick a venv's python.
#   peer    add URL [--push|--pull|--both] [--peer-token T] [--share POLICY_UUID|all]
#                                         pair a peer; --peer-token = the PEER's bearer (distinct from
#                                         --api-key, which auths e.sh to THIS engine); --share = pair and
#                                         share in one step
#   peer    list                          paired peers: id, url, status, last-synced, shares, accepts
#   peer    share PEER_ID POLICY_UUID|all offer a policy (by uuid, `policy list`), or every policy (later
#                                         ones too), to that peer. Nothing crosses until the peer
#                                         ACCEPTS it, and nothing crosses without a share
#   peer    unshare PEER_ID POLICY_UUID|all revoke a share: further flow stops; what was sent stays sent
#   peer    offers PEER_ID                what that peer offers us (as its last exchange said) + ACCEPTED
#   peer    accept PEER_ID POLICY_UUID    take that policy (by uuid, from `peer offers`) from the peer;
#                                         re-reads that peer from the start so the backlog arrives
#   peer    unaccept PEER_ID POLICY_UUID  stop taking it
#   peer    remove PEER_ID                unpair a peer
#   peer    sync [PEER_ID]                on-demand push+pull (one peer, or all if omitted)
#   peer    status                        this engine's sync status (cursors, peer count)
#   client-key create --label L [--profiles a,b] [--policies p,q] [--operations x,y] [--file PATH]
#                                         create a client key (emem_...): prints it ONCE, and appends its entry
#                                         (label, hash, scope) to conf/keys.yaml (--file names another). Give
#                                         the key to one holder: an agent's harness, or the console (a dedicated
#                                         key for people). One key per holder; revoke it by deleting its entry.
#                                         No scope flag = every profile and every operation; with any, only what
#                                         they name. OPERATIONS: policies, peers, bundles, admin, records. The
#                                         engine checks the names when it restarts. Runs here: no --url, no
#                                         engine call
#   init [--archive-dir PATH]             first setup, on this machine: write .env from .env.example with
#                                         fresh passwords and archive keys, make the archive folder
#                                         (default $HOME/ememory-data/archive) and name it as ARCHIVE_DIR,
#                                         and start conf/keys.yaml. Refuses when .env exists. Prints no
#                                         secret but ARCHIVE_KEY, once. Runs here: no --url, no engine call
#
# Policy is an event-sourced ledger: download ONE source policy -> edit -> policy
# upload (genesis-then-edit on its uuid; uuids are carried for lineage). `catalog`
# is the read-only union the engine actually enforces; `enable/disable` toggle
# whether the policy RUNS — an event on the policy stream, so paired engines
# follow it. No per-item create/update/delete.
# (`agent_profile` is an alias for `profile`.)
# Peering is P2P: `peer add` pairs an engine by URL. Sync runs on the cron
# schedule; `peer sync` triggers it on demand. Pairing alone exchanges nothing:
# what crosses is what THIS engine shares with the peer AND the peer accepts.
set -euo pipefail

URL="${EMEMORY_URL:-}"
TOKEN="${EMEMORY_API_KEY:-}"
INSECURE=""

REST=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)      URL="$2"; shift 2 ;;
    --api-key)  TOKEN="$2"; shift 2 ;;
    --insecure) INSECURE="1"; shift ;;
    -h|--help)  REST+=("help"); shift ;;
    *)          REST+=("$1"); shift ;;
  esac
done

usage() { awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"; }

noun="${REST[0]:-}"
verb="${REST[1]:-}"
[[ "$noun" == "agent_profile" ]] && noun="profile"   # alias to match REST/MCP term
[[ "$noun" == "sr" ]] && noun="source_record"        # short alias

if [[ -z "$noun" || "$noun" == "help" ]]; then usage; exit 0; fi

if [[ "$noun" == "init" ]]; then
  HERE="$(cd "$(dirname "$0")" && pwd)"
  ENV_FILE="$HERE/.env"
  EXAMPLE="$HERE/.env.example"
  ARCHIVE="$HOME/ememory-data/archive"
  set -- "${REST[@]:1}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --archive-dir) [[ $# -ge 2 ]] || { echo "error: init: --archive-dir needs a path" >&2; exit 2; }
                     ARCHIVE="$2"; shift 2 ;;
      *) echo "error: init [--archive-dir PATH] - unknown argument '$1'" >&2; exit 2 ;;
    esac
  done
  if [[ -e "$ENV_FILE" || -L "$ENV_FILE" ]]; then
    echo "error: $ENV_FILE already exists - init writes a new one and never overwrites. Edit it, or move it away and run init again." >&2
    exit 2
  fi
  [[ -f "$EXAMPLE" ]] || { echo "error: no $EXAMPLE to start from" >&2; exit 2; }
  case "$ARCHIVE/" in
    /*) ;;
    *) echo "error: init: --archive-dir must be an absolute path (got '$ARCHIVE')" >&2; exit 2 ;;
  esac
  case "$ARCHIVE/" in
    */./*|*/../*) echo "error: init: --archive-dir must have no . or .. in it" >&2; exit 2 ;;
  esac
  case "$ARCHIVE" in
    *[[:space:]\"\'\\\$\#]*)
      echo 'error: init: --archive-dir must have no spaces, quotes, \, $ or # in it' >&2; exit 2 ;;
  esac
  if command -v openssl >/dev/null 2>&1; then
    _hex()    { openssl rand -hex "$1"; }
    _base64() { openssl rand -base64 32; }
  elif command -v python3 >/dev/null 2>&1; then
    _hex()    { python3 -c 'import secrets, sys; print(secrets.token_hex(int(sys.argv[1])))' "$1"; }
    _base64() { python3 -c 'import base64, os; print(base64.b64encode(os.urandom(32)).decode())'; }
  else
    echo "error: init needs openssl or python3 to generate the passwords and keys; neither is on PATH" >&2
    exit 2
  fi
  ARCHIVE_KEY_VALUE="$(_base64)"
  TMP_ENV="$(umask 077 && mktemp "$HERE/.env.init.XXXXXX")"
  trap 'rm -f "$TMP_ENV" "$TMP_ENV.next"' EXIT
  cp "$EXAMPLE" "$TMP_ENV"
  _set() {  # NAME VALUE: the one `NAME=` line of the file becomes NAME=VALUE
    [[ -n "$2" ]] || { echo "error: init: could not generate $1" >&2; exit 2; }
    N="$1" V="$2" awk 'BEGIN { n = ENVIRON["N"]; v = ENVIRON["V"] }
      index($0, n "=") == 1 { print n "=" v; c++; next } { print }
      END { exit (c == 1 ? 0 : 3) }' "$TMP_ENV" > "$TMP_ENV.next" ||
      { echo "error: init: .env.example must hold exactly one '$1=' line" >&2; exit 2; }
    mv "$TMP_ENV.next" "$TMP_ENV"
  }
  _set POSTGRES_PASSWORD "$(_hex 24)"
  _set REDIS_PASSWORD "$(_hex 24)"
  _set ARCHIVE_ACCESS_KEY "$(_hex 20)"
  _set ARCHIVE_SECRET_KEY "$(_hex 32)"
  _set ARCHIVE_KEY "$ARCHIVE_KEY_VALUE"
  _set ARCHIVE_DIR "$ARCHIVE"
  mkdir -p "$ARCHIVE"
  chmod 600 "$TMP_ENV"
  [[ -e "$ENV_FILE" || -L "$ENV_FILE" ]] && { echo "error: $ENV_FILE appeared while init ran; left it alone" >&2; exit 2; }
  mv "$TMP_ENV" "$ENV_FILE"
  KEYS="$HERE/conf/keys.yaml"
  KEYS_NOTE="conf/keys.yaml is already there - left as it is."
  if [[ ! -e "$KEYS" ]]; then
    awk '{ print } /^keys:/ { exit }' "$HERE/conf/keys.yaml.example" > "$KEYS"
    KEYS_NOTE="Started conf/keys.yaml (no keys yet)."
  fi
  echo "Wrote $ENV_FILE: fresh POSTGRES_PASSWORD, REDIS_PASSWORD, ARCHIVE_ACCESS_KEY,"
  echo "ARCHIVE_SECRET_KEY and ARCHIVE_KEY, and ARCHIVE_DIR=$ARCHIVE (made)."
  echo "$KEYS_NOTE"
  echo
  echo "Save ARCHIVE_KEY in your password manager now — a lost key is an unreadable archive:"
  echo
  echo "ARCHIVE_KEY=$ARCHIVE_KEY_VALUE"
  echo
  echo "Next:"
  echo "  docker compose up -d"
  echo "  To turn auth on: ./e.sh client-key create --label you, then AUTH_ENABLED=true in .env"
  exit 0
fi

if [[ "$noun" == "client-key" ]]; then
  [[ "$verb" == "create" ]] || { echo "error: client-key create --label L [--profiles a,b] [--policies p,q] [--operations x,y] [--file PATH]" >&2; exit 2; }
  KEYS_FILE="$(cd "$(dirname "$0")" && pwd)/conf/keys.yaml"
  exec python3 - "$KEYS_FILE" "${REST[@]:2}" <<'PY'
import hashlib, json, os, re, secrets, sys, tempfile

OPERATIONS = ("policies", "peers", "bundles", "admin", "records")
LABEL = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}")
HEADER = ("# conf/keys.yaml - this engine's client keys (./e.sh client-key create).\n"
          "# See conf/keys.yaml.example for the shape. Read when the engine starts.\n"
          "keys:\n")

def fail(text):
    sys.stderr.write(f"error: {text}\n")
    sys.exit(2)

path, args = sys.argv[1], sys.argv[2:]
opts = {}
while args:
    flag = args.pop(0)
    if flag not in ("--label", "--profiles", "--policies", "--operations", "--file"):
        fail(f"client-key create: unknown argument {flag!r}")
    if not args:
        fail(f"client-key create: {flag} needs a value")
    opts[flag[2:]] = args.pop(0)
label = opts.get("label", "")
if not LABEL.fullmatch(label):
    fail("client-key create needs --label: a word of letters, digits, '.', '_' or "
         "'-' (up to 64), starting with a letter or digit - it names the key")
path = opts.get("file", path)
scope = {}
for field in ("profiles", "policies", "operations"):
    if field in opts:
        names = [n.strip() for n in opts[field].split(",")]
        if not all(names):
            fail(f"--{field}: a comma-separated list of names, none empty")
        scope[field] = names
bad = sorted(set(scope.get("operations", ())) - set(OPERATIONS))
if bad:
    fail(f"--operations: unknown {', '.join(bad)}; the operations are {', '.join(OPERATIONS)}")

text = HEADER
mode = 0o644
if os.path.exists(path):
    with open(path) as fh:
        text = fh.read()
    mode = os.stat(path).st_mode & 0o777
    if not re.search(r"^keys:[ \t]*(#.*)?$", text, re.M):
        fail(f"{path} has no `keys:` line to append to; fix the file (see "
             "conf/keys.yaml.example) and create the key again")
    held = re.findall(r"^\s*-?\s*label:\s*[\"']?([^\"'\s#]+)", text, re.M)
    if label in held:
        fail(f"{path} already holds a key labelled '{label}'; labels are unique")
    if text and not text.endswith("\n"):
        text += "\n"

key = "emem_" + secrets.token_urlsafe(32)
entry = f"  - label: {label}\n    hash: \"{hashlib.sha256(key.encode()).hexdigest()}\"\n"
for field, names in scope.items():
    entry += f"    {field}: [{', '.join(json.dumps(n) for n in names)}]\n"

directory = os.path.dirname(os.path.abspath(path))
os.makedirs(directory, exist_ok=True)
fd, tmp = tempfile.mkstemp(prefix=".keys.", dir=directory)
try:
    with os.fdopen(fd, "w") as fh:
        fh.write(text + entry)
    os.chmod(tmp, mode & ~0o022)
    os.replace(tmp, path)
except BaseException:
    if os.path.exists(tmp):
        os.unlink(tmp)
    raise

if not scope:
    act_as, ops = "every profile", "every"
else:
    act_as = ", ".join(scope.get("profiles", []) +
                       [f"the profiles of policy {p}" for p in scope.get("policies", [])]) or "no profile"
    ops = ", ".join(scope.get("operations", [])) or "none"
shown = "conf/keys.yaml" if "file" not in opts else path
print(f'Created a client key for "{label}".  It may act as: {act_as}  '
      f"(operations: {ops})  Its hash was added to {shown}; restart the stack "
      "to use it.")
print()
print(f"{key}   <- give this to the agent; shown once, never stored")
PY
fi

[[ -z "$URL" ]] && { echo "error: no URL (pass --url or set EMEMORY_URL)" >&2; exit 2; }
URL="${URL%/}"
AP="$URL/api/v2/agent-profiles"     # profiles + export/import/versions (control plane)
LANES="$URL/api/v2/lanes"           # observed lane usage (data plane)
ADMIN="$URL/api/v2/admin"           # admin command dispatch (operations)
SR="$URL/api/v2/source-records"     # source-record reads (admin)
PROP="$URL/api/v2/properties"       # property discovery (admin)
SYNC="$URL/api/v1/sync"             # P2P peering — register/list/unpair + on-demand sync

CURL=(curl -sS -L)
[[ -n "$INSECURE" ]] && CURL+=(--insecure)
[[ -n "$TOKEN" ]] && CURL+=(-H "Authorization: Bearer $TOKEN")

args=("${REST[@]:2}")

_fmt() {  # pretty-print JSON from stdin (python3; raw fallback). No jq.
  if command -v python3 >/dev/null 2>&1; then python3 -m json.tool; else cat; fi
}

_req() {  # METHOD FULL_URL [extra curl args] -> formatted body; non-2xx -> stderr + return 1
  local method="$1" url="$2"; shift 2
  local tmp code
  tmp="$(mktemp)"
  code="$("${CURL[@]}" -o "$tmp" -w '%{http_code}' -X "$method" "$@" "$url")" \
    || { rm -f "$tmp"; echo "error: request failed ($url)" >&2; return 1; }
  if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then _fmt <"$tmp"; rm -f "$tmp"
  else echo "HTTP $code" >&2; _fmt <"$tmp" >&2; rm -f "$tmp"; return 1; fi
}

_get_to_file() {  # FULL_URL OUTFILE (hard-fail on non-2xx)
  "${CURL[@]}" -f "$1" -o "$2" || { echo "error: GET failed ($1)" >&2; exit 1; }
}

_need_py() { command -v python3 >/dev/null 2>&1 || { echo "error: this view needs python3" >&2; return 1; }; }

_render_policies() {  # POLICIES_JSON SHIPPED_JSON SOURCE_FILTER -> one table
  _need_py || { _fmt <"$1"; _fmt <"$2"; return; }
  python3 - "$1" "$2" "$3" <<'PY2'
import sys, json
present = json.load(open(sys.argv[1]))
shipped = json.load(open(sys.argv[2])).get("shipped", [])
want = sys.argv[3]
# SOURCE is where the policy came from: the engine's own scaffolding
# (built-in), the build's law (shipped), authored here (local), or another
# engine's (peer). STATE: a shipped policy not in the ledger is `available`;
# one in the ledger is `active` when this engine runs it, else `installed`.
rows = []
for p in present:
    source = ("built-in" if p["bootstrap"] or p["policy_uuid"] == "pol_builtins" else
              "shipped" if p.get("shipped") else
              "local" if p["local"] else "peer")
    rows.append((p.get("policy_name") or "-", p["policy_uuid"], source,
                 "active" if p["enabled"] else "installed"))
held = {p["policy_uuid"] for p in present}
for r in shipped:
    if r["policy_uuid"] not in held:
        rows.append((r["name"], r["policy_uuid"], "shipped", "available"))
rows = [r for r in rows if not want or r[2] == want]
if not rows:
    print("(no policies)"); sys.exit()
rows = [("NAME", "UUID", "SOURCE", "STATE"), *rows]
w = [max(len(c) for c in col) for col in zip(*rows)]
for r in rows:
    print("  ".join(c.ljust(w[i]) for i, c in enumerate(r)).rstrip())
PY2
}

_merge_inactive() {  # CATALOG_JSON POLICIES_JSON -> catalog JSON (inactive_policies populated)
  _need_py || { cat "$1"; return; }
  python3 - "$1" "$2" <<'PY'
import sys, json
cat = json.load(open(sys.argv[1]))
roster = json.load(open(sys.argv[2]))
active = {p["policy_uuid"] for p in cat.get("activated_policies", [])}
inactive = cat.get("inactive_policies", [])
have = {p["policy_uuid"] for p in inactive}
for p in roster:
    if not p.get("enabled") and p["policy_uuid"] not in active and p["policy_uuid"] not in have:
        inactive.append({"policy_uuid": p["policy_uuid"], "policy_name": p.get("policy_name"),
                         "origin": p.get("origin"), "bootstrap": p.get("bootstrap", False),
                         "enabled_local": False})
cat["inactive_policies"] = inactive
print(json.dumps(cat))
PY
}

_render_catalog_by_policy() {  # CATALOG_JSON -> same data pivoted under each policy
  _need_py || { _fmt <"$1"; return; }
  python3 - "$1" <<'PY'
import sys, json
cat = json.load(open(sys.argv[1]))
# Seed an ACTIVE bucket per activated policy, then file each lane/profile under
# its owning policy_uuid (already carried on every member).
pols = {}
for p in cat.get("activated_policies", []):
    pols[p["policy_uuid"]] = {"policy_uuid": p["policy_uuid"], "policy_name": p.get("policy_name"),
                              "origin": p.get("origin"), "enabled": True, "lanes": {}, "profiles": {}}
def bucket(pu):
    return pols.setdefault(pu, {"policy_uuid": pu, "enabled": True, "lanes": {}, "profiles": {}})
# Lanes are keyed by uuid; each is filed under its label (its name, or
# name@fragment where two lanes here share it).
for lane_uuid, lane in (cat.get("lanes") or {}).items():
    bucket(lane.get("policy_uuid"))["lanes"][lane.get("lane") or lane_uuid] = dict(
        {k: v for k, v in lane.items() if k not in ("policy_uuid", "lane")}, lane_uuid=lane_uuid)
for name, prof in (cat.get("profiles") or {}).items():
    bucket(prof.get("policy_uuid"))["profiles"][name] = {k: v for k, v in prof.items() if k != "policy_uuid"}
# INACTIVE policies (present only when the catalog carries inactive_policies —
# natively on newer engines, or merged in by --all). Identity only — `policy
# download <name>` to inspect, `policy enable <name>` to activate.
for p in cat.get("inactive_policies", []):
    pols.setdefault(p["policy_uuid"], {
        "policy_uuid": p["policy_uuid"], "policy_name": p.get("policy_name"), "origin": p.get("origin"),
        "enabled": False, "note": "disabled — `policy download <name>` to inspect, `policy enable <name>` to activate"})
out = {"default_agent_profile": cat.get("default_agent_profile"),
       "policies": {(p.get("policy_name") or pu): p for pu, p in pols.items()}}
print(json.dumps(out, indent=2))
PY
}

_render_peers() {  # PEERS_JSON_FILE ({count, peers:[...]}) -> table
  _need_py || { _fmt <"$1"; return; }
  python3 - "$1" <<'PY'
import sys, json
peers = json.load(open(sys.argv[1])).get("peers", [])
if not peers:
    print("(no peers)"); sys.exit()
rows = [("PEER_ID", "URL", "STATUS", "LAST_SYNCED", "SHARES", "ACCEPTS")]
for p in peers:
    rows.append((p.get("peer_id") or "-", p.get("peer_url") or "(dials us)",
                 p.get("status") or "-", p.get("last_synced_at") or "never",
                 ",".join(a["target"] for a in p.get("shares") or []) or "-",
                 ",".join(a["target"] for a in p.get("accepts") or []) or "-"))
w = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
for r in rows:
    print("  ".join(c.ljust(w[i]) for i, c in enumerate(r)))
PY
}

_render_offers() {  # OFFERS_JSON_FILE ({offers:[...]}) -> table
  _need_py || { _fmt <"$1"; return; }
  python3 - "$1" <<'PY'
import sys, json
d = json.load(open(sys.argv[1]))
offers = d.get("offers") or []
if not offers:
    print("(nothing offered%s)" % ("" if d.get("offers_at") else " - no exchange yet"))
    sys.exit()
rows = [("TARGET", "NAME", "VERSION", "ACCEPTED")]
for o in offers:
    rows.append((o.get("target") or "-", o.get("name") or "-",
                 str(o.get("version")) if o.get("version") is not None else "-",
                 "yes" if o.get("accepted") else "no"))
w = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
for r in rows:
    print("  ".join(c.ljust(w[i]) for i, c in enumerate(r)))
print("(as of %s)" % d.get("offers_at"))
PY
}

_render_profiles() {  # FMT PROF_FILE DEFAULT
  _need_py || return 1
  python3 - "$1" "$2" "$3" <<'PY'
import sys, json
fmt, pf, default = sys.argv[1], sys.argv[2], sys.argv[3]
profs = json.load(open(pf))
if fmt == "json":
    print(json.dumps(profs, indent=2)); sys.exit(0)
def table(rows):
    w = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
    for r in rows: print("  ".join(r[i].ljust(w[i]) for i in range(len(r))).rstrip())
def lane(ref):  # {lane_uuid, lane} -> its label; the wildcard stays `*`
    return ref.get("lane") if isinstance(ref, dict) else str(ref or "")
rows = [("PROFILE", "HOME", "READ", "WRITE", "ENABLED", "DEFAULT")]
for p in profs:
    rows.append((p["name"], lane(p.get("home_lane")),
                 ",".join(lane(r) for r in p.get("read_lanes") or []),
                 ",".join(lane(r) for r in p.get("write_lanes") or []),
                 "yes" if p.get("enabled") else "no",
                 "yes" if p["name"] == default else ""))
table(rows)
PY
}

_render_lanes() {  # FMT CATALOG_JSON USAGE_FILE TARGET
  _need_py || return 1
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys, json
fmt, cf, uf, target = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
catalog = json.load(open(cf))
registry = catalog.get("lanes") or {}
usage = {u["lane_uuid"]: u for u in json.load(open(uf))}

rows = []
for lane_uuid in set(registry) | set(usage):
    reg = lane_uuid in registry
    cfg = registry.get(lane_uuid) or {}
    u = usage.get(lane_uuid) or {}
    cnt = u.get("sr_count", 0)
    if not reg:
        note = "no running policy declares it"
    elif not cfg.get("enabled", True):
        note = "disabled"
    elif cnt == 0:
        note = "declared, empty"
    else:
        note = ""
    rows.append({"lane": cfg.get("lane") or u.get("lane") or lane_uuid,
                 "lane_uuid": lane_uuid, "name": cfg.get("name"),
                 "policy_uuid": cfg.get("policy_uuid"), "registered": reg,
                 "mode": cfg.get("mode") if reg else None,
                 "sr_count": cnt, "origin": u.get("origin"),
                 "remote_instances": u.get("remote_instances") or [], "note": note})
rows.sort(key=lambda o: o["lane"])

if target:
    match = [o for o in rows if target in (o["lane"], o["lane_uuid"])] or \
            [o for o in rows if o["name"] == target]
    if len(match) != 1:
        sys.stderr.write(("lane '%s' not found\n" % target) if not match else
                         ("lane '%s' is ambiguous: %s\n" % (target, ", ".join(o["lane"] for o in match))))
        sys.exit(1)
    o = match[0]
    if fmt == "json":
        print(json.dumps(o, indent=2)); sys.exit(0)
    for k in ("lane", "lane_uuid", "policy_uuid", "registered", "mode", "sr_count", "origin", "remote_instances", "note"):
        v = o[k]
        if isinstance(v, bool): v = "yes" if v else "no"
        elif isinstance(v, list): v = ", ".join(v) or "—"
        if v is None or v == "": v = "—"
        print("%-18s %s" % (k + ":", v))
    sys.exit(0)

if fmt == "json":
    print(json.dumps(rows, indent=2)); sys.exit(0)
def table(trows):
    w = [max(len(r[i]) for r in trows) for i in range(len(trows[0]))]
    for r in trows: print("  ".join(r[i].ljust(w[i]) for i in range(len(r))).rstrip())
trows = [("LANE", "DECLARED", "MODE", "SRs", "NOTE")]
for o in rows:
    trows.append((o["lane"], "yes" if o["registered"] else "no",
                  o["mode"] or "—",
                  str(o["sr_count"]), o["note"]))
table(trows)
PY
}

_render_srs() {  # FILE (list JSON) -> table of sr_id + lane + ingested + snippet
  _need_py || { cat "$1"; return; }
  python3 - "$1" <<'PY'
import sys, json
d = json.load(open(sys.argv[1]))
srs = d.get("source_records", [])
rows = [("SR_ID", "LANE", "INGESTED", "SNIPPET")]
for s in srs:
    rows.append((s["sr_id"], str(s.get("lane") or ""),
                 (s.get("ingested_at") or "")[:10], (s.get("snippet") or "")[:78]))
w = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
for r in rows:
    print("  ".join(r[i].ljust(w[i]) for i in range(len(r))).rstrip())
scope = d.get("lane") or ("--where " + ",".join(d.get("match") or []))
print("\n(%d SRs [%s] — page %s/%s)" % (
    d.get("total", 0), scope, d.get("page", 1), d.get("total_pages", 1)))
PY
}

_render_props() {  # FILE -> labels table, or values table for one label
  _need_py || { cat "$1"; return; }
  python3 - "$1" <<'PY'
import sys, json
d = json.load(open(sys.argv[1]))
if "labels" in d:
    rows = [("LABEL", "SRs")] + [(x["label"], str(x["sr_count"])) for x in d["labels"]]
elif "values" in d:
    print("label: %s\n" % d.get("label", ""))
    rows = [("VALUE", "SRs")] + [(x["value"], str(x["sr_count"])) for x in d["values"]]
else:
    print(json.dumps(d, indent=2)); sys.exit(0)
w = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
for r in rows:
    print("  ".join(r[i].ljust(w[i]) for i in range(len(r))).rstrip())
PY
}

case "$noun" in
  profile)
    case "$verb" in
      list)
        raw=""; for a in "${args[@]:0}"; do [[ "$a" == "--json" ]] && raw=1; done
        fmt="table"; [[ -n "$raw" ]] && fmt="json"
        prof="$(mktemp)"; _get_to_file "$AP" "$prof"
        cat="$(mktemp)"; _get_to_file "$AP/catalog" "$cat"
        default="$(python3 -c 'import sys,json;print((json.load(open(sys.argv[1])) or {}).get("default_agent_profile") or "")' "$cat" 2>/dev/null || echo "")"
        _render_profiles "$fmt" "$prof" "$default"
        rm -f "$prof" "$cat" ;;
      get)
        name=""; for a in "${args[@]:0}"; do [[ "$a" == "--json" ]] || name="$a"; done
        [[ -z "$name" ]] && { echo "error: profile get NAME" >&2; exit 2; }
        _req GET "$AP/$name" ;;
      *) echo "error: profile {list|get NAME} [--json]" >&2; exit 2 ;;
    esac ;;

  lane)
    case "$verb" in
      list|get)
        name=""; raw=""
        for a in "${args[@]:0}"; do
          case "$a" in --json) raw=1 ;; *) name="$a" ;; esac
        done
        [[ "$verb" == "get" && -z "$name" ]] && { echo "error: lane get LANE" >&2; exit 2; }
        fmt="table"; [[ -n "$raw" ]] && fmt="json"
        cat="$(mktemp)"; _get_to_file "$AP/catalog" "$cat"
        use="$(mktemp)"; _get_to_file "$LANES/usage" "$use"
        _render_lanes "$fmt" "$cat" "$use" "$name"
        rm -f "$cat" "$use" ;;
      rename)
        dry="false"; pos=()
        for a in "${args[@]:0}"; do
          case "$a" in --dry-run) dry="true" ;; *) pos+=("$a") ;; esac
        done
        old="${pos[0]:-}"; new="${pos[1]:-}"
        [[ -z "$old" || -z "$new" ]] && { echo "error: lane rename LANE NEW [--dry-run]" >&2; exit 2; }
        body="{\"command\":\"lane.rename\",\"args\":{\"old\":\"$old\",\"new\":\"$new\",\"dry_run\":$dry}}"
        _req POST "$ADMIN" -H "Content-Type: application/json" --data "$body" ;;
      *) echo "error: lane {list|get LANE | rename LANE NEW [--dry-run]}" >&2; exit 2 ;;
    esac ;;

  policy)
    case "$verb" in
      list)
        src=""; i=0
        usage_list="error: policy list [--source built-in|shipped|local|peer]"
        while [[ $i -lt ${#args[@]} ]]; do
          case "${args[$i]}" in
            --source) src="${args[$((i+1))]:-}"; i=$((i+2))
                      [[ -z "$src" ]] && { echo "$usage_list" >&2; exit 2; } ;;
            *)        echo "$usage_list" >&2; exit 2 ;;
          esac
        done
        case "$src" in
          ""|built-in|shipped|local|peer) ;;
          *) echo "error: --source is one of built-in, shipped, local, peer" >&2; exit 2 ;;
        esac
        tmp="$(mktemp)"; shp="$(mktemp)"
        trap 'rm -f "$tmp" "$shp"' EXIT     # _get_to_file exits on a failed GET
        _get_to_file "$AP/policies" "$tmp"; _get_to_file "$AP/shipped" "$shp"
        _render_policies "$tmp" "$shp" "$src" ;;
      install)
        nm="${args[0]:-}"
        [[ -z "$nm" ]] && { echo "error: policy install NAME (see \`policy list --source shipped\`)" >&2; exit 2; }
        _req POST "$AP/install" -H "Content-Type: application/json" \
          --data "{\"name\":\"$nm\"}" ;;
      download)
        name=""; out=""; i=0
        while [[ $i -lt ${#args[@]} ]]; do
          case "${args[$i]}" in
            --out) out="${args[$((i+1))]:-}"; i=$((i+2)) ;;
            -*)    echo "error: policy download [NAME] [--out FILE]" >&2; exit 2 ;;
            *)     name="${args[$i]}"; i=$((i+1)) ;;
          esac
        done
        out="${out:-${name:-policy}.yaml}"
        q=""; [[ -n "$name" ]] && q="?policy=$(python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$name")"
        tmp="$(mktemp)"
        code="$("${CURL[@]}" -o "$tmp" -w '%{http_code}' "$AP/export$q")"
        if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then mv "$tmp" "$out"; echo "downloaded ${name:+'$name' }-> $out" >&2
        else echo "error (HTTP $code): $(cat "$tmp")" >&2; rm -f "$tmp"; exit 1; fi ;;
      catalog)
        by_policy=""; allp=""
        for a in "${args[@]:0}"; do
          case "$a" in --by-policy) by_policy=1 ;; --all) allp=1 ;; esac
        done
        tmp="$(mktemp)"
        if [[ -n "$allp" ]]; then
          _get_to_file "$AP/catalog?include_inactive=true" "$tmp"
          pl="$(mktemp)"; _get_to_file "$AP/policies" "$pl"
          _merge_inactive "$tmp" "$pl" > "$tmp.m" && mv "$tmp.m" "$tmp"
          rm -f "$pl"
        else
          _get_to_file "$AP/catalog" "$tmp"
        fi
        if [[ -n "$by_policy" ]]; then _render_catalog_by_policy "$tmp"; else _fmt <"$tmp"; fi
        rm -f "$tmp" ;;
      upload)
        file=""; q=""
        for a in "${args[@]:0}"; do
          case "$a" in
            --dry-run) q="${q}&dry_run=true" ;;
            --fork)    q="${q}&fork=true" ;;     # mint a brand-new independent copy
            --adopt)   q="${q}&adopt=true" ;;    # deliberately claim genesis of a foreign uuid
            *)         file="$a" ;;
          esac
        done
        [[ -z "$file" || ! -f "$file" ]] && { echo "error: policy upload FILE [--dry-run] [--fork|--adopt]" >&2; exit 2; }
        [[ -n "$q" ]] && q="?${q#&}"
        _req POST "$AP/import$q" -H "Content-Type: application/x-yaml" --data-binary "@$file" ;;
      enable|disable)
        nm="${args[0]:-}"
        [[ -z "$nm" ]] && { echo "error: policy $verb NAME" >&2; exit 2; }
        en=true; [[ "$verb" == disable ]] && en=false
        _req POST "$AP/activation" -H "Content-Type: application/json" \
          --data "{\"policy\":\"$nm\",\"enabled\":$en}" ;;
      retire|unretire)
        nm="${args[0]:-}"
        [[ -z "$nm" ]] && { echo "error: policy $verb NAME" >&2; exit 2; }
        rt=true; [[ "$verb" == unretire ]] && rt=false
        _req POST "$AP/retire" -H "Content-Type: application/json" \
          --data "{\"policy\":\"$nm\",\"retired\":$rt}" ;;
      purge)
        nm=""; force=false
        for a in "${args[@]:0}"; do
          case "$a" in --force) force=true ;; *) nm="$a" ;; esac
        done
        [[ -z "$nm" ]] && { echo "error: policy purge NAME [--force]" >&2; exit 2; }
        _req POST "$AP/purge" -H "Content-Type: application/json" \
          --data "{\"policy\":\"$nm\",\"force\":$force}" ;;
      *) echo "error: policy {list|install|download|catalog|upload|enable|disable|retire|unretire|purge}" >&2; exit 2 ;;
    esac ;;

  source_record)
    [[ "$verb" == --* ]] && { args=("$verb" ${args[@]+"${args[@]}"}); verb="list"; }   # `sr --where ...`
    case "$verb" in
      list)
        lane=""; pg=1; raw=""; where=""
        i=0
        while [[ $i -lt ${#args[@]} ]]; do
          case "${args[$i]}" in
            --json)   raw=1; i=$((i+1)) ;;
            --where)  where="${args[$((i+1))]:-}"; i=$((i+2)) ;;
            p[0-9]*)  pg="${args[$i]#p}"; i=$((i+1)) ;;
            [0-9]*)   pg="${args[$i]}"; i=$((i+1)) ;;
            *)        lane="${args[$i]}"; i=$((i+1)) ;;
          esac
        done
        [[ -z "$lane" && -z "$where" ]] && { echo "error: source_record list LANE [pN]  |  list [LANE] --where label:value [pN]" >&2; exit 2; }
        q="page=$pg"; [[ -n "$lane" ]] && q="$q&lane=$lane"; [[ -n "$where" ]] && q="$q&match=$where"
        if [[ -n "$raw" ]]; then
          _req GET "$SR?$q"
        else
          tmp="$(mktemp)"; _get_to_file "$SR?$q" "$tmp"
          _render_srs "$tmp"; rm -f "$tmp"
        fi ;;
      get)
        name="${args[0]:-}"
        [[ -z "$name" ]] && { echo "error: source_record get SR_ID" >&2; exit 2; }
        _req GET "$SR/$name" ;;
      undelete)
        prof=""; ids=()
        i=0
        while [[ $i -lt ${#args[@]} ]]; do
          case "${args[$i]}" in
            --agent-profile|--profile) prof="${args[$((i+1))]:-}"; i=$((i+2)) ;;
            *) ids+=("${args[$i]}"); i=$((i+1)) ;;
          esac
        done
        [[ ${#ids[@]} -eq 0 || -z "$prof" ]] && { echo "error: source_record undelete SR_ID... --agent-profile NAME" >&2; exit 2; }
        body="$(python3 -c 'import json,sys; print(json.dumps({"sr_ids":sys.argv[2:],"agent_profile":sys.argv[1]}))' "$prof" "${ids[@]}")"
        _req POST "$URL/api/v2/undelete" -H "Content-Type: application/json" --data "$body" ;;
      *) echo "error: source_record {list LANE [pN] | get SR | undelete SR... --agent-profile NAME}" >&2; exit 2 ;;
    esac ;;

  property)
    case "$verb" in
      list)
        label=""; raw=""
        for a in "${args[@]:0}"; do
          case "$a" in --json) raw=1 ;; *) label="$a" ;; esac
        done
        url="$PROP"; [[ -n "$label" ]] && url="$PROP/$label"
        if [[ -n "$raw" ]]; then
          _req GET "$url"
        else
          tmp="$(mktemp)"; _get_to_file "$url" "$tmp"; _render_props "$tmp"; rm -f "$tmp"
        fi ;;
      *) echo "error: property list [LABEL] [--json]" >&2; exit 2 ;;
    esac ;;

  peer)
    case "$verb" in
      add)
        url=""; dir="bidirectional"; token=""; share=""; i=0
        usage="error: peer add URL [--push|--pull|--both] [--peer-token T] [--share POLICY_UUID|all]"
        while [[ $i -lt ${#args[@]} ]]; do
          case "${args[$i]}" in
            --push)                 dir="push"; i=$((i+1)) ;;
            --pull)                 dir="pull"; i=$((i+1)) ;;
            --both|--bidirectional) dir="bidirectional"; i=$((i+1)) ;;
            --peer-token)           token="${args[$((i+1))]:-}"; i=$((i+2)) ;;
            --share)                share="${args[$((i+1))]:-}"
                                    [[ -z "$share" || "$share" == -* ]] && { echo "error: --share needs a target: a policy uuid, or all" >&2; exit 2; }
                                    i=$((i+2)) ;;
            -*) echo "$usage" >&2; exit 2 ;;
            *)  url="${args[$i]}"; i=$((i+1)) ;;
          esac
        done
        [[ -z "$url" ]] && { echo "$usage" >&2; exit 2; }
        body="$(python3 -c 'import json,sys; print(json.dumps({"peer_url":sys.argv[1],"direction":sys.argv[2],"auth_token":(sys.argv[3] or None)}))' "$url" "$dir" "$token")"
        out="$(_req POST "$SYNC/peers" -H "Content-Type: application/json" --data "$body")"
        echo "$out"
        if [[ -n "$share" ]]; then
          pid="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["peer_id"])' "$out")"
          body="$(python3 -c 'import json,sys; print(json.dumps({"target":sys.argv[1]}))' "$share")"
          _req POST "$SYNC/peers/$pid/shares" -H "Content-Type: application/json" --data "$body" \
            || { echo "error: the peer $pid IS paired, but the share '$share' was NOT recorded — run: peer share $pid $share" >&2; exit 1; }
        fi ;;
      share|accept)
        pid="${args[0]:-}"; tgt="${args[1]:-}"
        [[ -z "$pid" || -z "$tgt" ]] && { echo "error: peer $verb PEER_ID TARGET" >&2; exit 2; }
        body="$(python3 -c 'import json,sys; print(json.dumps({"target":sys.argv[1]}))' "$tgt")"
        _req POST "$SYNC/peers/$pid/${verb}s" -H "Content-Type: application/json" --data "$body" ;;
      unshare|unaccept)
        pid="${args[0]:-}"; tgt="${args[1]:-}"
        [[ -z "$pid" || -z "$tgt" ]] && { echo "error: peer $verb PEER_ID TARGET" >&2; exit 2; }
        _req DELETE "$SYNC/peers/$pid/${verb#un}s/$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$tgt")" ;;
      offers)
        pid="${args[0]:-}"; [[ -z "$pid" ]] && { echo "error: peer offers PEER_ID" >&2; exit 2; }
        tmp="$(mktemp)"; _get_to_file "$SYNC/peers/$pid/offers" "$tmp"; _render_offers "$tmp"; rm -f "$tmp" ;;
      list)
        tmp="$(mktemp)"; _get_to_file "$SYNC/peers" "$tmp"; _render_peers "$tmp"; rm -f "$tmp" ;;
      remove|rm|delete)
        pid="${args[0]:-}"; [[ -z "$pid" ]] && { echo "error: peer remove PEER_ID" >&2; exit 2; }
        _req DELETE "$SYNC/peers/$pid" ;;
      sync)
        pid="${args[0]:-}"
        if [[ -n "$pid" ]]; then
          _req POST "$SYNC/peers/$pid/sync"
        else   # no id → sync every peer
          tmp="$(mktemp)"; _get_to_file "$SYNC/peers" "$tmp"
          for p in $(python3 -c 'import json,sys;[print(x["peer_id"]) for x in json.load(open(sys.argv[1]))["peers"]]' "$tmp"); do
            echo "# $p" >&2; _req POST "$SYNC/peers/$p/sync"
          done; rm -f "$tmp"
        fi ;;
      status)
        _req GET "$SYNC/status" ;;
      *) echo "error: peer {add|list|remove|sync|status|share|unshare|offers|accept|unaccept}" >&2; exit 2 ;;
    esac ;;

  ingest)
    ing_args=("${REST[@]:1}")
    [[ ${#ing_args[@]} -eq 0 ]] && { echo "error: ingest DIR --agent-profile NAME [--lane L] [--property k:v]... [--glob P] [--prune] [--watch] [--dry-run]" >&2; exit 2; }
    ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    PY_BIN="${EMEMORY_PYTHON:-python3}"
    command -v "$PY_BIN" >/dev/null 2>&1 || { echo "error: no python3 (set EMEMORY_PYTHON)" >&2; exit 2; }
    if ! PYTHONPATH="$ROOT/watcher" "$PY_BIN" -c 'import httpx' >/dev/null 2>&1; then
      echo "error: ingest needs httpx (pip install -e $ROOT/watcher), or set EMEMORY_PYTHON to a venv python" >&2
      exit 2
    fi
    ing_extra=()
    [[ -n "$INSECURE" ]] && ing_extra+=(--insecure)
    EMEMORY_API_KEY="$TOKEN" PYTHONPATH="$ROOT/watcher${PYTHONPATH:+:$PYTHONPATH}" \
      exec "$PY_BIN" -m watcher.cli --url "$URL" ${ing_extra[@]+"${ing_extra[@]}"} "${ing_args[@]}" ;;

  export|import)
    ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    PY_BIN="${EMEMORY_PYTHON:-python3}"
    command -v "$PY_BIN" >/dev/null 2>&1 || { echo "error: no python3 (set EMEMORY_PYTHON)" >&2; exit 2; }
    if ! PYTHONPATH="$ROOT/bundle" "$PY_BIN" -c 'import httpx, pyrage' >/dev/null 2>&1; then
      echo "error: $noun needs the bundle package (pip install -e $ROOT/bundle), or set EMEMORY_PYTHON to a venv python" >&2
      exit 2
    fi
    bun_extra=()
    [[ -n "$INSECURE" ]] && bun_extra+=(--insecure)
    EMEMORY_API_KEY="$TOKEN" PYTHONPATH="$ROOT/bundle${PYTHONPATH:+:$PYTHONPATH}" \
      exec "$PY_BIN" -m ememory_bundle.cli --url "$URL" ${bun_extra[@]+"${bun_extra[@]}"} "${REST[@]}" ;;

  *)
    echo "error: unknown noun '$noun' (expected profile | lane | policy | peer | source_record | property | ingest | export | import | client-key)" >&2
    usage; exit 2 ;;
esac

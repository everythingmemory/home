# Policies

An owner running several agents on one engine needs rules about who reads and writes what, and needs to change them as the work changes, without code or migrations. A policy declares lanes, their source types and labels, and agent profiles in one YAML document; each upload is appended to the policy's ledger as an event; a change takes effect when it is uploaded; a lane, source type, label or agent profile is retired with enabled: false; and several policies can be enabled at once.

Challenges addressed: [Auditable Decision-Making](../use-cases/auditing-agentic-decisions.md), [Multi-Agent Coordination](../use-cases/agent-swarm-coordination.md), [Enterprise Distributed Memory Requirements](../use-cases/enterprise-memory-mesh.md).

## Concepts

Everything Memory keeps its rules as data. A **policy** declares:

- lanes, and the [source types](source-types.md) each lane accepts, with their labels;
- [agent profiles](agent-profiles.md), with their home lane and grants.

```yaml
# lanes partition the memory; profiles get per-lane access
lanes:
  crm:    { enabled: true }    # sales swim lane
  ops:    { enabled: true }    # support swim lane
  people: { enabled: true }    # employees & customers

profiles:
  sales:
    home_lane: crm                  # implicit read + write to home
    can_read_other_lanes:  [ops]    # sees ops (deal → project), can't write it
    can_write_other_lanes: []
  support:
    home_lane: ops                  # read + write to ops
    can_read_other_lanes:  [people]
    can_write_other_lanes: [people] # also owns the people lane
```

The engine's default agent profile is not part of a policy: it is an operator setting.

A policy is uploaded with `e_policy` or the REST API, by any caller the engine accepts. `e_policy` lists and downloads policies for any caller.

## Implications
**A policy is a ledger.** Each upload is appended as an event, and the rules in force are computed from the events. Downloading a policy and uploading the edited document changes it in place. A lane, source type, label or agent profile is retired with `enabled: false`. An operator can purge a whole policy, which deletes its events.

**Several policies can be enabled at once.** The engine applies them together. Two policies may declare same-named lanes; they are two lanes. A bare name that matches both in the caller's view is refused as ambiguous — name the lane by its [qualified label](lanes.md#lane-labels) or its UUID.

**Changing the rules needs no migration.** A new lane, source type or label takes effect when the policy is uploaded.

## Built in and optional

Policies come in two tiers.

- **Built in** — the floor every engine carries: the lane `default` and the agent profile `restricted`. It is always there.
- **Shipped** — optional policies in the build, for features that need their own lanes and profiles. One is installed by name, on each engine, only when its feature is wanted. The feature refuses to start without it and names the command that installs it.

One listing shows every policy the engine knows — its NAME, UUID, SOURCE (`built-in`, `shipped`, `local` or `peer`) and STATE (`available`, `installed` or `active`); `--source` narrows it to one source:

```bash
./e.sh policy list
./e.sh policy list --source shipped
```

The shipped policies are the release's optional ones, the files in `conf/policies/` (`files` and `shared`). Installing one is one command:

```bash
./e.sh policy install <name>
```

Installing shares nothing with a peer: what crosses is decided per peer, as for any policy. See [peering](peering.md).

## An example: the `files` policy

[Folder Intake](../use-cases/beyond-the-context-window.md#documents-and-files) writes the records of a watched folder. It needs a lane to write to, a source type for those records and a profile to write as, so it ships with this policy:

```yaml
policy_uuid: pol_files
policy_name: files
overview: >
  Folder Intake's lane. One closed lane holding the records of watched folders -
  each folder, each file and each file's parts - and the profile that writes
  them. Install it on each engine that runs Folder Intake; sharing it with a
  peer is a separate act.
lanes:
  files:
    lane_uuid: lane_files
    enabled: true
    description: the records of watched folders - folders, files and their parts
    source_types:
      file:
        st_uuid: st_files_file
        file: true
        authority: documentary
        description: a folder, a file or a part of one, as Folder Intake read it
        allowed_labels:
          - folder_id
          - watch_status
          - file_id
          - file_path
          - folder
          - file_name
          - file_format
          - content_hash
          - event
          - chunk_index
          - label: filepart
            values: [superseded]
profiles:
  folder_intake:
    profile_uuid: prof_files_folder_intake
    enabled: true
    description: Folder Intake's writer - it reads and writes `files`, nothing else
    home_lane: files
```

- `policy_uuid` and `policy_name` — the policy's fixed id and its name, the same on every engine.
- `overview` — what the policy is for, in words.
- `lanes: files` — one lane, closed: it takes only the source types it declares.
- `source_types: file` — the one source type in `files`, at `documentary` authority.
- `file: true` — marks it as the type Folder Intake writes every record with.
- `allowed_labels` — every label Folder Intake writes, and no other; `filepart` takes only the value `superseded`.
- `profiles: folder_intake` — the profile Folder Intake writes as; its home lane is `files`, and it reads and writes nothing else.

Install it, then see it in the listing as `shipped` and `active`:

```bash
./e.sh policy install files
./e.sh policy list --source shipped
```

**Adding your own stamps.** `files` is closed, so it refuses a label it does not list, such as `matter:`. To stamp records with `matter:acme`, write your own policy: a lane with one `file: true` source type whose `allowed_labels` list every label above plus `matter`, and a profile whose home lane is that lane. Upload it, then ingest as that profile:

```bash
./e.sh policy upload my-matters.yaml
./e.sh ingest ~/Contracts --agent-profile matters --property matter:acme
```

The engine refuses a `file: true` source type that leaves out a label Folder Intake writes.

## Copying a policy to another engine

Download it on one engine and upload it on the other:

```bash
./e.sh policy download crm-policy --out crm-policy.yaml    # on the first engine
./e.sh policy upload crm-policy.yaml --fork                # on the second
```

The file records the engine that wrote it. A plain upload of another engine's policy is refused, so two engines never each believe they own the same policy. Choose one:

- **`--fork`** — a new, independent copy with a fresh id, owned by this engine.
- **`--adopt`** — this engine takes the policy over, keeping its id; for moving a policy to a new engine.

Either way, the policy lists as `local` on the engine it was uploaded to.

## Reference

The tool: [`e_policy`](../reference/tools/e_policy.md).

# MCP tool descriptions

Agent-facing description for each `e_*` tool. FastMCP serves the section body
(below each `## <tool>` header) as that tool's `description` in `tools/list`.
This is the cold, skill-less contract — keep each one minimum-sufficient
(action enums, `match` grammar where relevant, one example, anti-patterns,
output shape). Cross-cutting concepts (agent_profile, home lane, read/write
authority, correct-vs-adjust) live in `mcp_instructions.txt`; don't repeat them
here. Edit prose here, not in the Python docstrings.

## e_read

Load full detail for specific SRs by ID. Input: `sr_ids` (list).

Each returned SR carries `content`, `lane` (its label) and `lane_uuid`, `source_type`,
`authority_level`, `source_system`, `ingested_at`, `version` (0 = never updated), and —
when present — `is_conversational` / `is_file_content` (only when true), `properties` (["label:value"]), `adjustments` ({token: [linked
sr_ids]}), and `corrections` (the superseding truth; retracted ones appear as
stubs, preserving provenance). IDs you can't read, or that don't exist, come back
under `not_found`. If an adjustment links to SRs outside your read scope, its
`adjustments` entry is empty and a root `hint` says so. This is where you read
evidence before reasoning; pair it with `e_gather` (which finds the IDs).
Example: `e_read(sr_ids=["sr_abc123", "sr_def456"])`.

`as_of` (a date or ISO datetime, e.g. `"2026-03-01"` = midnight UTC) reads each
SR in the state given by the entries written by that moment that this engine
holds, instead of now: its content, properties and lane then, with `version` and `written_at` (when that state was written). An SR
deleted by then comes back as `deleted: true` with `deleted_at`; one not written
yet is listed under `not_yet_written`. The time is when each change was
originally written — the same on every engine holding the same entries;
deletion is local. Corrections are not part of a past
state and are not shown. `adjustment_tokens` are the SR's own adjustment tokens
then; find the linked SRs with `e_gather(action="traverse")`. If the writing engine's clock was wrong, a change falls
at the time that clock said. Example: `e_read(sr_ids=["sr_abc123"], as_of="2026-03-01")`.

## e_property

Discover and manage properties — `label:value` pairs that enable structural retrieval.

Actions:
- `list` — labels that exist (within your read scope).
- `intersect` — `match=["label"]` (category) or `["label:value"]` (exact); returns matching values/SRs.
- `find` — `term="..."` keyword search across labels and values.
- `add` — attach properties to SR(s) you can WRITE: `sr_id` (string or list) + `properties=["label:value", ...]`. Add-only and idempotent. A closed lane rejects labels outside its vocabulary; reserved `e_*` labels are engine-only and rejected; adding to an SR you can read but not write is refused.
- `remove` — `sr_id` + `properties` (those values) and/or `labels` (whole labels).

- `connect` — assert a NAMED RELATION between **exactly two** SRs:
  `sr_id=[a, b]` + `hint="employs"` → the engine stamps `e_connect:employs_3049e7c1b82d4f6a9e05c3d71a8b2f64`
  on both. The edge IS the shared value, so it is bidirectional and all-or-nothing:
  if either side is unwritable or missing, nothing is written.
- `group` — assert a NAMED MEMBERSHIP among **two or more** SRs: `sr_id=[...]` +
  `hint="poker night"` → `e_group:poker_night_a71f0d93c6e248b5f17a2c04e9d863b5` on each. A two-member group is
  legal and is NOT an edge.
- `disconnect` — `sr_id=[a, b]`: removes their shared `e_connect` from both,
  all-or-nothing. Sharing several? Name one with `hint` (token or hint).
- `ungroup` / `unadjust` — `hint="e_group:<token>"` / `"e_adjustment:<token>"`,
  optional `sr_id=[...]` (none = every holder you can see): removes it; unwritable
  ones are skipped and reported (`skipped_unwritable`, with their lanes in
  `unwritable_lanes`).

Never express a relationship by putting another entity's name on a record — that
is ambiguous with the record's own identity. State identity with `name:`, assert
structure with `connect`/`group`. You supply the meaning (`hint`); the engine
supplies the uniqueness.

Always `list`/`intersect` before inventing a label — reuse what exists.

## e_gather

Find and gather evidence from the knowledge graph (scoped to your read authority).

Actions:
- `find` — `query="..."`, ranked by semantic relevance.
- `intersect` — `match=[...]`, AND (an SR must have all terms).
- `union` — `match=[...]`, OR (any term).
- `traverse` — `sr_id="..."`, walk shared-property and adjustment edges out from a known SR.
- `count` — counts, never records. `match=["label:value", ...]` (exact terms only) → intersection `total` + per-term `ep_counts`; or `sr_id="..."` → per-property neighbor cardinality (`edges`) + `total_neighbors`. Size a result before fetching it.
- `group` — board-shaped read: `by="label"` buckets that label's values with distinct-SR counts (optional exact-term `match` scope; `top=N` adds up to 5 sample sr_ids per bucket). Paged, counts only.

`find` results carry `distance` (relative — *not* comparable across queries), `distance_quartile` (1 = best in this set — reason with this, not raw distance), and a page-level `distance_spread` (`tight` = results roughly equal, `moderate`, `huge` = sharp dropoff → trust quartile 1, paging likely returns noise). Results name their `lane` and `lane_uuid` and flag `has_correction` / `has_adjustment`. Use `e_gather find` for relevance-ordered results (`e_timeline find` for time-ordered), then `e_read` to load full detail before reasoning.

## e_timeline

Retrieve knowledge ordered by time (scoped to your read authority).

Actions: `list` (everything), `find` (`query="..."` semantic), `intersect` (`match=[...]` filter), `traverse` (from an anchor `sr_id`), `changes` (what changed between two moments). Bound the window of `list`, `intersect` and `traverse` with `start_date`/`end_date`; `find` takes no window (it ranks by relevance, then orders by time); `order_by` ∈ {`ingest_time_desc`, `ingest_time_asc`, `content_time_desc`, `content_time_asc`}. `shed_idf_noise` (default true) trims over-common terms from dense result sets. Results name their `lane` and `lane_uuid` and flag `has_correction` / `has_adjustment` like `e_gather`.

`changes` — what changed between two moments, `since` and `as_of` (a date or ISO datetime, a bare date is midnight UTC; `as_of` defaults to now): each SR whose state differs between them, as `new`, `updated` (with what changed; `hidden_change` when it is outside what you can see), `deleted` or `undeleted`, newest first, paged. `changed_at` is the newest entry in the window. An SR written and deleted again inside the window, or changed and changed back, did not change. Pass back the `as_of` page 1 returns for every later page. The moments are when each change was originally written, by the writing engine's clock — the same answer on every engine holding the same entries; deletion is local; a wrong clock places its changes where it said. Not a catch-up feed: an entry keeps its author's time and can arrive later than that, so a window already read can gain entries and its pages can reshuffle. To catch up on what arrived over the mesh, use `e_audit(action="list", since_seq=N)`: each entry that arrives from a peer writes an `sr_synced` event there. A bundle import appears as one `bundle_imported` event; a restore from the archive writes none.

## e_ingest

Store new knowledge — one fact per SR. Content should stand alone (include the reasoning/context, not just the conclusion).

Key inputs:
- `source_type`: `conversational` (default) | `documentary` — validated against the profile/lane's allowed types (an operator may extend the allowlist or allow any).
- `properties`: `["label:value", ...]` — dimensions you'd filter or compare on (not content). Reserved `e_*` labels are rejected.
- `is_conversational`: opt the SR into the conversational continuum — enables window-expansion / neighbor recall so adjacent turns are retrieved together. Set true for dialogue you want recalled in context (e.g., a user/assistant exchange whose surrounding turns matter).
- `is_file_content`: marks the SR as a contiguous chunk of a larger file (boosts windowed recall across that file's parts). Leave false unless ingesting file parts via the file-upload skill/script.
- `assign_lane`: send the SR to a specific lane you're authorized to write; omit to use your profile's home lane. Name it by its name, by its qualified name `name@fragment` (shown where two lanes you can see share a name), or by its lane uuid; an ambiguous name is refused with the qualified names to choose from.
- `adjusts`: `[sr_ids]` (+ optional `adjustment_label`) — link this new SR to prior SR(s) it refines, clarifies, or extends (knowledge accumulating — *not* error; use `e_correct` for **wrong**). Usually 1:1 (an adjustment edge between two SRs); name several to bind a tight group under one shared token. The token is stamped on the new SR and each writable target (others skipped + reported), shown on `e_read` and walkable by `e_gather traverse`.

Returns the new `sr_id` (plus an `adjustment` summary when `adjusts` is used).

## e_update

Store the next state of an SR you already wrote — the SAME authored artifact, evolved in place. The `sr_id` never changes, so every link, property, reference and audit anchor pointing at that record still points at it.

Use it when the record IS the artifact and the artifact moved on: a plan, a spec, a roster, a running summary, a status. Not for a fact that got a companion (`e_ingest adjusts=`), and not for a record that was wrong (`e_correct`).

Key inputs:
- `sr_id`: the record to evolve. Requires write authority over its lane.
- `content`: the FULL new content — an update states the next state, never a diff. Omit to change only properties.
- `properties`: `["label:value", ...]` — MERGED BY LABEL. Every label you mention has all of its values replaced by the ones you pass (`["children:Ana","children:Bo"]` becomes the whole `children` set); labels you do not mention stay exactly as they were. Same lane vocabulary as `e_ingest`.
- `note`: why this version exists. Kept in the record's history, shown by `e_audit`.

To remove a property, use `e_property` `remove`; passing `properties: []` removes nothing. Properties an extractor produced are re-derived automatically. Engine-minted structure — connections, groups, adjustment tokens — is never touched, and its `e_*` labels are refused here (remove them with `e_property` `disconnect` / `ungroup` / `unadjust`).

Returns `{sr_id, version, event_id, updated_at}`. An update that changes nothing writes nothing and returns `{sr_id, version, event_id: null, unchanged: true}`. Reads (`e_read`, `e_gather`, `e_timeline`) then see the new content and only the new content — superseded versions stay in the record's history, readable via `e_audit(action="inspect")` on the `sr_updated` event.

## e_correct

Record and manage corrections. A correction states the truth about an SR that is WRONG, pinned to exactly one `sr_id` (one correction, one record). For an SR that is right but has since evolved, use `e_ingest adjusts=` instead.

Actions: `create` (`content` + `sr_id`, both required), `retract` (`correction_id`), `inspect` (view one), `list` (browse). A correction names one record and does not change: to change one, retract it and create another. Requires write authority over the target SR's lane. A correction supersedes the original and surfaces on `e_read` and as `has_correction` in `e_gather`/`e_timeline`.

## e_system

System operations.

Actions:
- `inspect` — `agent_profile="..."`: returns that profile's `home_lane`, resolved effective read/write lanes, and per-lane SR counts. Unknown profile → `not_found`.
- `get_profile` — `agent_profile="..."`: your WRITE schema. Every lane is `{lane, lane_uuid}`; types by name, never id. Returns `write_lanes` — each with the `source_types` it offers and, per type, its `allowed_labels` (closed lane: its types; open lane: builtins `conversational`/`documentary`, free labels) — plus `home_lane`/`home_lane_uuid`, `read_lanes` (unconstrained), `can_reassign`, `profile`. Pick a `source_type` from the list; keep labels within its `allowed_labels`.
- `delete` — `sr_ids=[...]`. A record delete is the last version in that record's history: the record leaves retrieval — its properties and vectors go with it; its corrections stay recorded and show again if it is undeleted — and its history stays, the deleted state included (`e_audit` `trace` still works). A delete is local: peers keep the record. To remove a property, use `e_property` `remove`. Returns `deleted` (the SRs a version was written for) and `event_ids` ({sr_id: the version's event id}). Requires an explicit `agent_profile` and write authority over each SR's lane; SRs outside it are returned as `unauthorized`, ones that do not exist as `not_found`.
- `undelete` — `sr_ids=[...]`: each record returns at its latest version (a peer's edit too), the one `e_read` shows; the next write numbers past its history. Returns `undeleted`, `event_ids`, and live ones as `not_deleted`. Authority as `delete`.

A delete and an undelete need the owner's `deletions_enabled` switch (`conf/settings.yaml`); off, they are refused naming it.

## e_audit

Provenance trail — the event spine's reader. Every mutation (ingest, sync arrival, correction create/retract, adjustment, property add/remove, delete) writes an immutable event; this tool reads them back. Read-only, scoped to your readable lanes.

Actions:
- `trace` — `sr_id`: every event touching that SR, oldest first. Works after deletion (the trail outlives the data). Add `expand=true` for a self-contained evidence package: the SR (or its deletion record), full correction views, adjustment clusters — no follow-up calls needed.
- `list` — filterable stream: `sr_id`, `correction_id`, `lane` (a name, `name@fragment`, or a lane uuid), `actor_profile`, `event_type`, `source_system`, `start_date`/`end_date`, paged newest-first. `since_seq=N` switches to oldest-first catch-up from that cursor (feed replay).
- `inspect` — `log_id`: full detail for one event.
- `history` — `sr_id`: every state the SR has had up to `as_of` (default now, echoed; pass it back for every later page — that keeps local writes since page 1 out, but a peer entry arriving late with an earlier time can still reshuffle pages), newest first, paged: each with its `version`, `kind` (create, update, tombstone, undelete), `written_at` (when it was originally written), the `engine` and `credential` that wrote it, and what changed from the state before it that you can read — `replaced_version` (null when there is none), `content_changed` with the new `content`, `properties_added`, `properties_removed`, `adjustment_tokens` (the SR's own tokens, when they changed) and `hidden_change` (a change outside what you can see). To read the whole SR as it stood at one moment, use `e_read(as_of=...)`.

An event names its `lane` (the label) and `lane_uuid`.

Use `trace` to answer "why does memory say this?" mechanically: what was ingested, by whom, what corrected or adjusted it, and when.

## e_policy

Policy management — the engine's governance verb. `list` and `download` are open
(read-only): download returns the uuid-CARRYING yaml — edit that and upload to
EDIT in place (genesis-then-edit; a uuid-free upload authors a NEW policy).
`upload` (with optional dry_run), `enable`, and `disable` change policy.
Refusals are self-documenting. Every change lands on the policy ledger with full
history.

# Deleting a Record

Take a record out of retrieval with e_system delete, bring it back with undelete, or remove some of its edge properties. A deletion is local to this engine and keeps the record's history.

## When to Use

When a record, or an edge property on it, should no longer be found. It is rarely the right first move: a record that was wrong takes a [correction](correcting-a-record.md), and one that has changed takes an [adjustment](evolving-a-fact.md).

:::warning
Record deletes and undeletes are off as shipped. The engine's owner turns them on with `deletions_enabled` in `conf/settings.yaml` and restarts the engine. Off, both are refused with: *deletions are off on this engine: conf/settings.yaml `deletions_enabled` is false. Its owner turns it on and restarts the engine; nothing was deleted.* Removing an edge property is always allowed. See [deletion switch](../governance/deletion-switch.md).
:::

## Usage

```text
e_system {"action": "delete", "sr_ids": ["sr_..."], "agent_profile": "..."}
e_system {"action": "undelete", "sr_ids": ["sr_..."], "agent_profile": "..."}
e_property {"action": "remove", "sr_id": ["sr_..."], "properties": ["label:value"], "agent_profile": "..."}
```

| Action | What it does |
|---|---|
| `delete` | Writes the deleted state as the last version in each record's history. The record leaves retrieval; its edge properties and vectors go with it |
| `undelete` | Each record returns at its latest version — including an edit a peer made while it was deleted here |
| `e_property` `remove` | Writes a new version of each record without the matching values. Reserved `e_*` labels are refused; use `disconnect`, `ungroup` or `unadjust` |

A delete or undelete must name an `agent_profile` whose write lanes cover each record; `remove` runs as the named or default profile. Records outside it come back under `unauthorized`, unknown ids under `not_found`, and neither is touched.

## Response

`delete` returns `deleted` (the records a version was written for) and `event_ids` (each version's event id). `undelete` returns `undeleted`, `event_ids`, and records that were not deleted under `not_deleted`.

After a delete, `e_read`, `e_gather` and `e_timeline` no longer find the record. What stays:

- **Its history.** Every version, with its content, and the deleted state, in the record's history.
- **The audit events.** `e_audit` `trace` still answers for the `sr_id`, ending in `sr_deleted`.
- **Its corrections.** They stay recorded and show again if the record is undeleted.
- **The archive copy.** The engine never deletes objects from the archive.

:::warning
A deletion is not erasure. The record's content remains in its history and in the archive.
:::

## Deletion is local

A deletion is never sent to peers. A record this engine shared stays on the peers that hold it, and a deletion made on a peer does not delete it here. A peer's later edit to a record deleted here is stored, and the record stays deleted until it is undeleted here. A restore from the archive reproduces this engine's own deletions.

## Example

```text
e_system {"action": "delete", "sr_ids": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"], "agent_profile": "renewals"}
e_read {"sr_ids": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"]}
e_system {"action": "undelete", "sr_ids": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"], "agent_profile": "renewals"}
```

The `e_read` lists the id under `not_found`; after the `undelete`, it returns the record at its latest version.

**REST equivalent**

```bash
curl -s -X POST "$EMEMORY_URL/api/v2/delete" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"], "agent_profile": "renewals"}'

curl -s -X POST "$EMEMORY_URL/api/v2/read" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"]}'

curl -s -X POST "$EMEMORY_URL/api/v2/undelete" \
  -H "Authorization: Bearer $EMEMORY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"sr_ids": ["sr_3f9a1c20e47b5d16a2e8c0b7d4f19a63"], "agent_profile": "renewals"}'
```

Over REST, a record delete and undelete are their own endpoints, `/api/v2/delete` and `/api/v2/undelete`, each taking `sr_ids` and `agent_profile`.

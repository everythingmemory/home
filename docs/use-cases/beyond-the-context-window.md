# Context Window Limits and Lossy Compaction

Agents working from a team's documents, an organisation's records or a year of their own work need more data than a context window holds, and when the window fills, compaction summarises it and drops the details: the exact figure, name, date or reason for a decision. Everything Memory keeps records outside the window, whole and as written; lets an agent find records by meaning, edge property or time and load only those; serves the same records across sessions, agents and models; and turns a folder of documents into records whole.

## Approach
Data held in a context window, or loaded into it from files, is bounded by the window and gone when the session ends, and what compaction summarised away cannot be recovered from the summary.

- **The memory is a database.** Records live in PostgreSQL, bounded by the database, not by a context window. A record can be a sentence, a document, a large JSON object or one part of a file. See [source records](../data-model/source-records.md).
- **The agent loads only what it needs.** It finds records by meaning ([search](../agents-how-to/finding-records.md)), by [edge property](../data-model/edge-properties.md) (`intersect`, `union`, `traverse`) or by [time](../agents-how-to/using-the-timeline.md), then reads only those with [`e_read`](../agents-how-to/reading-a-record.md).
- **Nothing is summarised away.** A record is stored as written and stays that way; compaction in the agent's session no longer costs it anything, because the details are in the memory, not in the window.
- **It persists across sessions, agents and models.** Any agent whose client speaks MCP reaches the same memory. At the start of a session an agent can list what was written most recently and the labels in use.
- **Documents come in whole.** Folder Intake turns a folder into records, described below.

## Documents and files

Not everything worth remembering arrives through a tool call. One command, `e.sh ingest`, turns a folder of documents into memory — verbatim, in the formats you already have. It runs on the machine that holds the files and writes to the engine over its REST API, as the profile `folder_intake`, into the lane `files`; both come from the shipped [`files` policy](../governance/policies.md#an-example-the-files-policy), installed first.

1. It walks the folder, skipping names that start with a dot.
2. It converts each file to text: PDF, Word (`.docx`), Excel (`.xlsx`) and HTML by converter; text, Markdown, CSV, JSON, YAML and code as they are. Anything without a converter is refused by name rather than smuggled in as a blob.
3. It splits the text on its own boundaries: headings, then paragraphs, lines and sentences.
4. It writes a record for the folder, one per file and one per part, all with the lane's one `file: true` source type (shipped: `file`, at `documentary` authority). The file's record holds the hash of its text, so a second run writes only what changed.

Each part carries the edge properties `file_path`, `folder`, `file_name`, `file_format` and `chunk_index`, plus `file_id`. `folder` is the part's subfolder within the ingested folder (`.` for a file at its top), so "everything in the subfolder Acme" is an intersection, not a guess.

PDF, DOCX, HTML, XLSX, Markdown and plain text go in as the text they say — nothing summarised, nothing inferred. Every part carries where it came from, plus the lane and any edge properties you name that the lane allows. Rerunning ingests only what changed; a file that leaves the folder is reported and kept unless you ask for `--prune` (`--prune` deletes, so it needs `deletions_enabled` on). `--watch` runs the same pass on a loop, and the Folder Intake service (`folder-intake`, in `docker-compose.folder.yml`) runs it as a container watching one folder.

```text
  eMemory ingest — /Users/you/Contracts
  ──────────────────────────────────────────────────────────
  files seen              6
  converted               3
  unchanged (skipped)     0
  refused                 1
        1  no converter for .png: logo.png
  ingested                5 files
        new 5  edited 0  resurrected 0
  chunks ingested         5
  orphans                 0
```

## Example
```bash
./e.sh policy install files
./e.sh ingest ~/Contracts --agent-profile folder_intake
```

Later, in a new session, the agent orients itself and then asks:

```text
e_timeline {"action": "list", "page_size": 10}
e_property {"action": "list"}
e_gather {"action": "find", "query": "when does the Acme MSA renew"}
e_gather {"action": "intersect", "match": ["folder:Acme"]}
e_read {"sr_ids": ["<an sr_id from the result>"]}
```

To stamp the records with your own labels, such as `matter:acme`, see [adding your own stamps](../governance/policies.md#an-example-the-files-policy).

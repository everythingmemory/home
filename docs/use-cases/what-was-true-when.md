# Point-in-Time Recall

Some questions about stored data are about time, not topic: what was recorded about Acme last week, what is due in March, what a record said before it was updated, and when it was found to be wrong; answering them needs every version and change kept with its time. Everything Memory returns what was recorded in any window, in time order; orders records by the dates their content names; keeps every earlier version in a record's ledger; and lists each correction and adjustment in order, with its time.

## What can be answered today, and how

| Question | How |
|---|---|
| What was recorded in a period | `e_timeline` returns what was recorded in any window, in time order: [`e_timeline`](../agents-how-to/using-the-timeline.md) with a window on ingest time (`start_date`, `end_date`) |
| What names a date in a period | `e_timeline` ordered by content time: the dates the records' content names, read by the date extractor at ingest |
| What a record said before it was updated | Every earlier version is kept in the record's ledger; `e_audit` `inspect` on an update's event returns the content before and after it |
| What a record said at a given time | `e_read` with `as_of` returns each record as it stood then |
| Every state a record has held | `e_audit` `history` lists each state its ledger holds, in order |
| What changed in a period | `e_timeline` `changes` lists what changed between `since` and `as_of` |
| When a record was corrected or adjusted | Each correction and adjustment is an audit event with its time; `e_audit` `trace` lists them in order |
| What else happened around a record | `e_timeline` `traverse`: records written within seven days either side of it |

## Example
What was written about Acme in the last week of October, newest first:

```text
e_timeline {"action": "intersect", "match": ["org:Acme"], "start_date": "2026-10-24", "end_date": "2026-10-31"}
```

What names a date in March 2027, earliest first:

```text
e_timeline {"action": "list", "start_date": "2027-03-01", "end_date": "2027-03-31T23:59:59Z", "order_by": "content_time_asc"}
```

The history of one record:

```text
e_audit {"action": "trace", "sr_id": "sr_7b22e4d1a90c3f5812ab94c6e0d3f7a1"}
```

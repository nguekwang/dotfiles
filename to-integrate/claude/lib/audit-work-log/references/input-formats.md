# Input formats

## Raw log

One interval per line, two time tokens (H:MM or HH:MM), tab- or space-separated:

```
8:52	8:55
8:55	8:55
8:55	8:56
```

Consecutive lines are expected to chain (previous end == next start). A zero-length line (`8:55	8:55`) is valid — it usually represents an instantaneous action like a clock-in stamp, not a gap.

`scripts/find-gaps.py` parses this format directly; it just needs two HH:MM-shaped tokens per non-empty line, so extra whitespace or a leading label won't break it as long as the two times are present and in order.

## Task list

This is a pasted spreadsheet/task-tool export. The exact column order and count vary between tools and even between exports from the same tool, so don't assume fixed column indices — instead identify columns by what they contain:

- **Project/client column**: usually the first or second text column. One recurring literal value (in Japanese exports, commonly `案件対応外`, meaning "not client work" — internal/admin tasks) marks non-client rows; every other distinct value is a client/project name. Treat that literal as its own category and every other value as a project category.
- **Task name column**: free-text description of what was done, often containing a `>` separator for sub-steps (e.g. `kpiee報告 > 定量報告`).
- **Start/end time columns**: look for the pair of HH:MM-shaped columns nearest the end of the row — these are what you match against the raw log's intervals. There are usually *other* time-like columns too (a scheduled/target time, e.g. `10:00`, with no matching end time, or an anomalous stray time-shaped value in a delta/status column) — don't confuse those with the actual start/end pair. Cross-check against the raw log rather than trusting column position alone: if a row's start/end doesn't match any raw log interval, prefer the raw log's timing and just use the row for its project/task label.
- **Duration/status columns**: often present (scheduled minutes, actual minutes, a +/- delta, a status like `完了`) but not needed for the gap or chart logic — useful only as extra color if the user asks about them specifically.

Rows are normally in chronological order and line up one-to-one with the raw log's intervals (same start/end times, same count). If a row's start/end doesn't exactly match any raw log interval, prefer the raw log as ground truth for timing and the task row as ground truth for labeling — don't let a mismatch block the analysis, just note it if it seems like more than a rounding difference.

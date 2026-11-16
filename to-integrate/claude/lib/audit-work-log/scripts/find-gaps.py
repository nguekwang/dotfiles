#!/usr/bin/env python3
"""Find coverage gaps in a raw start/end time log against a work window.

This does only the arithmetic that's easy to get subtly wrong by hand
(minute sums, off-by-one boundaries): parsing HH:MM pairs, summing
accounted minutes inside a window, and locating every place where one
entry's end time doesn't match the next entry's start time. It does NOT
try to guess what happened during a gap -- that needs the task list and
human/LLM judgment, which belongs in the command's reasoning step, not here.

Usage:
    python find-gaps.py --raw raw_log.txt [--window-start 08:50] [--window-end 18:00]

raw_log.txt: one interval per non-empty line, two HH:MM (or H:MM) tokens
separated by whitespace/tab, e.g.:
    8:52	8:55
    8:55	8:55
    8:55	8:56
"""
import argparse
import json
import re
import sys

TIME_RE = re.compile(r"(\d{1,2}):(\d{2})")


def to_minutes(h: int, m: int) -> int:
    return h * 60 + m


def parse_time(token: str) -> int:
    match = TIME_RE.search(token)
    if not match:
        raise ValueError(f"not a time: {token!r}")
    h, m = int(match.group(1)), int(match.group(2))
    return to_minutes(h, m)


def fmt(minutes: int) -> str:
    minutes = minutes % (24 * 60)
    return f"{minutes // 60:02d}:{minutes % 60:02d}"


def parse_log(text: str, warnings: list):
    intervals = []
    for lineno, line in enumerate(text.splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        tokens = TIME_RE.findall(line)
        if len(tokens) < 2:
            warnings.append(f"line {lineno}: could not find two times in {line!r}, skipped")
            continue
        (h1, m1), (h2, m2) = tokens[0], tokens[1]
        start = to_minutes(int(h1), int(m1))
        end = to_minutes(int(h2), int(m2))
        if end < start:
            warnings.append(f"line {lineno}: end before start ({line!r}), skipped")
            continue
        intervals.append((start, end))
    return intervals


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", required=True, help="path to raw log text file")
    ap.add_argument("--window-start", default="08:50")
    ap.add_argument("--window-end", default="18:00")
    args = ap.parse_args()

    warnings = []
    with open(args.raw, encoding="utf-8") as f:
        text = f.read()

    intervals = parse_log(text, warnings)
    if not intervals:
        print(json.dumps({"error": "no valid intervals parsed", "warnings": warnings}, ensure_ascii=False, indent=2))
        sys.exit(1)

    intervals.sort()
    for i in range(1, len(intervals)):
        if intervals[i][0] < intervals[i - 1][1]:
            warnings.append(
                f"overlap: interval {fmt(intervals[i-1][0])}-{fmt(intervals[i-1][1])} "
                f"overlaps {fmt(intervals[i][0])}-{fmt(intervals[i][1])}"
            )

    win_start = parse_time(args.window_start)
    win_end = parse_time(args.window_end)
    window_total = win_end - win_start

    # accounted minutes = sum of each interval's overlap with the window
    accounted = 0
    for s, e in intervals:
        overlap = min(e, win_end) - max(s, win_start)
        if overlap > 0:
            accounted += overlap

    # all gaps across the whole log (not clipped to window), plus the
    # boundary gaps at the very start/end of the window if the log doesn't
    # reach them.
    all_gaps = []

    if intervals[0][0] > win_start:
        all_gaps.append((win_start, intervals[0][0]))

    for i in range(len(intervals) - 1):
        gap_start, gap_end = intervals[i][1], intervals[i + 1][0]
        if gap_end > gap_start:
            all_gaps.append((gap_start, gap_end))

    if intervals[-1][1] < win_end:
        all_gaps.append((intervals[-1][1], win_end))

    gaps_out = []
    for gs, ge in all_gaps:
        overlaps_window = ge > win_start and gs < win_end
        gaps_out.append({
            "start": fmt(gs),
            "end": fmt(ge),
            "duration_minutes": ge - gs,
            "overlaps_window": overlaps_window,
        })

    result = {
        "window": {"start": fmt(win_start), "end": fmt(win_end), "total_minutes": window_total},
        "accounted_minutes_in_window": accounted,
        "missing_minutes_in_window": window_total - accounted,
        "fully_covered": accounted == window_total,
        "day_span": {"log_start": fmt(intervals[0][0]), "log_end": fmt(intervals[-1][1])},
        "intervals_count": len(intervals),
        "all_gaps": gaps_out,
        "warnings": warnings,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

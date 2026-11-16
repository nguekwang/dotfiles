---
name: audit-work-log
description: Audit a day's work-time log against the work window, explain any missing time gaps, and render a project/category timeline as an HTML artifact
disable-model-invocation: true
---

# Daily Timelog Audit (audit-work-log)

You are auditing one day of work-time tracking. The user provides two blocks of tab-separated data for a single day — either as `$ARGUMENTS` or pasted in their message(s):

- **Raw log**: lines of two times each (start, end), e.g. `8:52\t8:55`. This is the ground truth for what time ranges are actually accounted for.
- **Task list**: a table (usually tab-separated, pasted from a spreadsheet/task tool) where each row is a project/client name, a task description, and start/end time columns that line up with the raw log entries. Column layout varies between exports — see `.claude/lib/audit-work-log/references/input-formats.md` for how to find the columns you need without assuming a fixed schema.

`$ARGUMENTS`: {{ARGUMENTS}}

If neither block is present in `$ARGUMENTS` or the recent conversation, ask the user for both — the gap inference and the per-project chart both need the task list, not just the raw log. If they mention a work window other than the 08:50–18:00 / 550-minute default (or the data implies a different one), use theirs instead.

## What to produce, every time, in this order

1. **Coverage check** — does the work window have zero unaccounted time?
2. **Gap inference** — if not, list every gap and reason about what the person was probably doing, using the task list entries immediately before/after each gap.
3. **Visual analytics** — an HTML Artifact with band/timeline charts of the day: by project (案件) and by task category (案件対応 vs 案件対応外, or whatever categorization the data supports), plus a time-share summary.
4. **The employer's read** — the same day, reviewed the way whoever is paying for these hours would actually read it: bluntly, and looking for the things that would make them ask a question in a 1-on-1. See Step 5.

Don't skip straight to the chart — the coverage check and gap reasoning are the substance the user actually wants confirmed; the chart is the summary on top. Step 4's critique is not optional politeness-padding to skip when the day looks fine — a clean day still gets a real read, even if the read is "nothing here would worry me."

## Why this is split into a script + reasoning

Summing minutes and finding where one interval's end doesn't match the next interval's start is pure arithmetic — do it with `.claude/lib/audit-work-log/scripts/find-gaps.py`, not by eyeballing a list of times. Hand-checking invites off-by-one and boundary mistakes (e.g. missing that the log's first entry starts *after* the window opens). But guessing what happened during a gap is a judgment call about this specific person's day — that only a human/LLM reading the surrounding task names can make well, so do that step yourself instead of trying to encode it as rules.

## Step 1: Get the two inputs

See `.claude/lib/audit-work-log/references/input-formats.md` for how to read the task list's columns robustly — layouts vary between exports.

## Step 2: Run the gap-finder script

Save the raw log block to a file (use the scratchpad directory) and run:

```bash
python3 .claude/lib/audit-work-log/scripts/find-gaps.py --raw <raw_log.txt> --window-start 08:50 --window-end 18:00
```

This returns JSON with: accounted/missing minutes in the window, whether it's `fully_covered`, the full list of gaps (`all_gaps`, each tagged `overlaps_window`), and the log's actual start/end span for the whole day (useful in step 4 since the day often runs past the window, e.g. into overtime). If the script reports warnings (unparsed lines, overlaps), surface those to the user rather than silently ignoring them — they usually mean the pasted log has a formatting quirk worth flagging.

## Step 3: Report ① coverage and ② gap inference

**①** State plainly whether the window is fully covered, quoting the numbers: accounted minutes vs. the target (e.g. "510分/550分、40分不足"). If `fully_covered` is true, say so and skip straight to the chart.

**②** For each gap in `all_gaps` (lead with the ones where `overlaps_window` is true, but don't hide the others — a gap right after the window like an evening break is still worth naming), find the task-list rows whose start/end time border that gap: the row ending exactly at the gap's start, and the row starting exactly at the gap's end. Reason from there, the same way you would explain a colleague's calendar gap:

- Same project on both sides → probably an interruption or continued work on that project that didn't get logged (a call, a wait on a reply, a bathroom break).
- Project changes across the gap → probably a transition: moving location, switching context, a meeting between the two.
- Nearby task names containing words like 移動 (move floors/rooms), 相談 (consulting someone), 一時離席 (stepped away), 報告 (reporting), or a meeting/standup name → strong, specific hints — use them by name in your explanation rather than a generic guess.
- A gap right at the very start or end of the window (before the first entry, after the last) usually means clocking-in overhead or a closing task that wasn't logged — call that out as a distinct, more mundane case rather than forcing the same "interruption" framing.

Keep each gap's writeup to 1–2 sentences citing the actual neighboring task names — vague speculation ("probably a break") is much less useful than "帯グラフの前後がメーカーズシャツ鎌倉の案件で、次のタスクも同案件の相談なので、その場での口頭相談が延びていたと考えられる".

## Step 4: Build the visual analytics (③)

Read the task list directly (no script needed here — table shapes vary too much to hardcode, and matching each row to its time range is straightforward once you can see the table) and build a timeline dataset: for every task-list row, its start time, end time, project/client name, task name, and a category — treat any project value that literally means "outside client work" (e.g. `案件対応外`) as its own category, and every other project name as a distinct client category. Include the gaps too (from step 2's JSON) as their own segments so the chart makes the uncovered time visible instead of silently skipping it.

Before writing any chart code, load the **dataviz** skill for color/form/accessibility conventions and the **artifact-design** skill for how to lay out the page — both apply here even though this is a personal report, not a product UI. Then publish via the Artifact tool. Build at least:

- **Timeline by project**: a horizontal band/Gantt chart across the day's full time span (use the actual log span from step 2, not just the window — overtime past 18:00 is part of the day too), one lane per project, with gaps rendered as a visually distinct (e.g. hatched/muted) segment rather than a blank space that looks like a chart bug. With more than a handful of projects, one lane per project (small multiples) is the right call over a single color-coded lane — position, not hue alone, then carries identity.
- **Timeline by category**: the same time axis, colored by the 案件対応 vs 案件対応外 (or finer) category instead of by individual project — this is the one that answers "how much of my day was internal overhead vs client work."
- **A time-share summary**: total minutes per project (and per category), as a horizontal bar list — more readable than a pie for more than ~5 categories, but a donut is fine if there are few. Sort by minutes descending so the biggest chunks of the day are immediately visible.

Make the two timelines share the same x-axis scale and line up vertically if laid out in the same page — the point is to let someone visually correlate "what category was I in" with "which project was that" at a glance, plus spot the gaps in context.

## Step 5: The employer's read (④)

The user wants this section read the way whoever pays for these hours would actually read it — not as a supportive coach, as the person whose money bought this time and is deciding whether it was well spent. Be direct. Don't soften findings with "頑張っていると思いますが" hedges, don't praise for its own sake, and don't manufacture complaints just to fill the section — a genuinely clean day gets told it's clean, in the same blunt register.

Ground every point in a number you can actually compute from this day's data, not vibes. Go looking for material patterns like these (compute what applies to this day's data; not every day will have all of them):

- **Non-billable share** — what fraction of the day was `案件対応外` (or whatever the internal/admin category is)? Say it as a percentage of the whole day, not just a minute count — "138分" sounds fine, "22%の勤務時間" reads differently.
- **Weak gap justifications** — of the gaps from Step 3, which ones have a genuinely weak explanation ("多分休憩", no strong task-name signal on either side)? Stack them up and say what they cost in aggregate, not just individually.
- **Thrashing / context-switching** — stretches where the person bounced between many different projects in quick, short (<5 min) blocks. Name the actual stretch (time range, how many switches, which projects) — "12:47〜13:30の間に4案件を細切れに切り替えている" is a real finding; "マルチタスクが多い" is not.
- **Overtime pattern** — how far past the window's end did the day actually run, and does that look like a one-off or a pattern worth asking about?
- **Estimate vs. actual, if the task list has those columns** — rows where actual time was wildly under or over the scheduled estimate, at scale, across the day. Systematically-padded estimates and systematically-blown ones are both worth naming, and they mean different things — say which one this looks like.
- **Lopsided client attention** — a client that got a handful of minutes all day sitting next to one that ate a third of it, when nothing in the data suggests that's intentional prioritization.
- **Log-padding smell** — a large count of sub-2-minute logged tasks can mean real rapid-fire work, or it can mean the log is being kept granular to look busy. Say which it looks like here, and why.

Pick the 2-4 findings that are actually material for this specific day — this is a review, not a checklist to exhaust. State each as a manager would say it out loud in a 1-on-1: the number, why it matters to someone paying for the time, and (if there's an obvious one) what better would have looked like. Skip anything you can't back with a number from this day's actual data.

## Output structure

Reply in the chat with ① and ② as text (numbers + reasoning — this is what the user asked to confirm, don't bury it only inside the artifact), then publish and hand over the artifact for ③ and ④. Don't restate every chart's contents in prose; the artifact speaks for itself. Give ④ (the employer's read) its own clearly-labeled section in both the chat reply and the artifact — it's a distinct voice from the neutral audit in ①-③, so don't blend it into the same paragraphs.

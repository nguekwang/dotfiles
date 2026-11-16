---
name: medallion-layers
description: Moving every piece of outside data through three medallion layers - bronze `bronze-source/` keeps originals exactly as received and never changes them, silver `silver-lake/` holds each source cleaned and normalized with its lineage, gold `golden-mart/` holds deliverables built only from silver. Use whenever the user hands over data or material (a CSV or Excel export, a news article, a web page, pasted text, a screenshot, a PDF, an API response), and whenever you save, clean, normalize, join, aggregate, or report on such data.
---

# Medallion Layers

Outside data moves through three layers, one direction only: bronze, then silver, then gold. Each layer has one place, one job, and one rule about change, so any number in a deliverable can be traced back to the original it came from, and any processing step can be rerun from that original.

## Layers

| Layer | Place | What it holds | Change rule |
| --- | --- | --- | --- |
| Bronze | `bronze-source/<source>/` | The material exactly as received: the original file, bytes and format unchanged, or the pasted text verbatim | Written once, never edited, overwritten, renamed, or deleted |
| Silver | `silver-lake/<source>/` | The same source cleaned, typed, normalized, and deduplicated, in a regular form (CSV, JSON, or Markdown with a fixed schema) | Regenerated freely, but only from bronze of the same source |
| Gold | `golden-mart/` | Deliverables for the user: reports, charts, summaries, comparisons, joins across sources | Built only from silver, named per the `files-and-repository` skill's Artifact Output |

A source is one origin of data with one shape: one system's export, one news outlet, one form, one person's pasted notes on one subject. Name it in kebab-case (`crm-export-results`, `nikkei-news`). Silver mirrors bronze one to one: `bronze-source/<source>/` and `silver-lake/<source>/` always carry the same `<source>`. Combining sources is a gold operation, never a silver one. Two standing exceptions, both without a bronze counterpart. The language audio from bronze under `silver-lake/languages/` (`french-verb/`, `french-vocabulary/`, `portuguese/`, `phonetics/` and `main.md`), moved from bronze on 2026-10-11 as it was, is not cleaned; because it is then the only copy, it follows the bronze change rule, never edited, overwritten, renamed, or deleted, and the write guard refuses the Write and Edit calls that change it as it does for bronze, on a best-effort basis: any route outside `check_bronze` in `.claude/hooks/guard-write.py`, every shell command among them, is not covered, and git history is the backstop. The other exception is the user's own notes in `silver-lake/`: the nine note directories `anth/`, `app/`, `dev/`, `images/`, `life/`, `math/`, `polyglot/`, `tech/`, `util/` and the notes, audio and documents from `notes/languages/`, moved from `notes/` on 2026-10-11 at the user's instruction (`polyglot/` moved from the repository root on 2026-10-12 at the user's instruction), and the nine loose note files at the `silver-lake/` root (`alcohol.md`, `arch.md`, `base.md`, `chemistry.md`, `claude-code.md`, `contract-creation-checklist.md`, `network.md`, `nvim.md` and `quick-note.md`), moved from `notes/` on 2026-10-12 at the user's instruction. It covers the notes the user or a command writes there later, such as `silver-lake/life/training.md`. They are edited as notes, may hold interpretation, carry no lineage, and are never regenerated from bronze. A new note directory or root note file joins this list first.

Claude's own records (session logs, branch records, review records, rule proposals) are not outside data. They stay where the `files-and-repository` skill's `.claude/` table puts them and do not pass through these layers.

## Procedure

### 1. Land in bronze

Before reading, cleaning, or answering anything from new material, save the original to bronze.

1. Pick the source. When `bronze-source/<source>/` does not exist yet, create it with a `main.md` stating what the source is, who or what produces it, and how it was obtained.
2. Save the material as `bronze-source/<source>/<yyyymmddhhmmss>-<content>.<ext>`: the landing timestamp, a kebab-case nominal group for the content, and the original extension. Pasted text lands as `.md` or `.txt`, verbatim, with nothing added.
3. Check confidentiality before landing, because `bronze-source/` is committed and pushed. Client data under a confidentiality agreement, personal information, and material from a secure room are not landed: stop and ask the user where it may be kept.

A bronze file is never corrected in place. When an original turns out wrong or incomplete, land the corrected material as a new file and let silver read the new one.

A source received as a tree, such as a repository directory or an export with folders, keeps its subdirectories as received; the landing form above applies to material landed file by file, every file name still follows the `files-and-repository` skill's "File Naming", and a subdirectory inside a source carries no `CLAUDE.md`.

One named exception. `bronze-source/CLAUDE.md`, the directory index, is not received data and may be edited in place so it stays current; it is never deleted or moved, since every directory carries its `CLAUDE.md` per `files-and-repository`, and the guards refuse that. No other path under `bronze-source/` is excepted.

### 2. Refine into silver

1. Read only from `bronze-source/<source>/` and write only to `silver-lake/<source>/`.
2. Clean without interpreting: fix types, encodings, date and number formats, column names, and duplicates. Opinions, hypotheses, and business conclusions belong in gold.
3. Record lineage in `silver-lake/<source>/CLAUDE.md`: one row per silver file, naming the bronze files it was built from and the steps applied, precise enough to rebuild the silver file from bronze alone.
4. When the steps are more than a few lines, keep them as a script next to the data or under `.claude/lib/`, and name it in the lineage row.

### 3. Serve from gold

1. Build the deliverable from silver files only. When a needed field is missing from silver, extend silver first, then build.
2. Name the silver files the deliverable used inside the deliverable itself, for example in a closing sources section.
3. A join, aggregate, or comparison across sources happens here and nowhere earlier.

## Verification

Before ending a task that touched data, check each item:

- Every piece of outside material the task used has a file in `bronze-source/`, and no existing file in `bronze-source/` was modified (the index `bronze-source/CLAUDE.md` excepted).
- Every silver file has a lineage row that names existing bronze files of the same source, except the language audio from bronze and the note directories and root note files of the second exception above (later notes included), which have no bronze copy.
- Every deliverable reads from silver only and names the silver files it used.
- Nothing confidential was landed without the user's decision.

`.claude/hooks/guard-write.py` refuses Write, Edit and NotebookEdit calls that change an existing file under `bronze-source/` or the language audio from bronze in `silver-lake/languages/` (the index `bronze-source/CLAUDE.md` excepted), on a best-effort basis: its `check_bronze` function is the exact list of what it refuses, and any other route, every shell command among them, is not covered, even when it names an existing file. Git history is the backstop. The rest of this list stays with the model.

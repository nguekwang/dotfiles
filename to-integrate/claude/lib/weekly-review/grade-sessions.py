#!/usr/bin/env python3
"""Weekly: grade the foreign-language prose the user typed in each new session.

Run by `.github/workflows/review-sessions.yml`. Until 2026-10-17 the same prompt
ran as the SessionEnd hook `grade-english.sh`, once per session on the machine
that ran it; it moved here so grading does not depend on a hook on each machine.

For each session log not yet in the ledger `silver-lake/polyglot/graded.txt`, a
headless Claude names the dominant language of the user's turns and, unless it
is Japanese, scores the writing 0-100 with a short critique. The result is one
file `silver-lake/polyglot/<lang>/log/<yyyy-mm-dd-HH:MM:SS>.md` in the form the
hook wrote, the timestamp being the session's start. A directory for a language
other than `en` needs a row in the `files-and-repository` skill's exemption
table, because the colons in these names are otherwise refused.
"""

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from session_log import ROOT, ask, meta, record, unprocessed, user_text  # noqa: E402

POLYGLOT = ROOT / "silver-lake" / "polyglot"
LEDGER = POLYGLOT / "graded.txt"

PROMPT = """\
You are an extremely strict multilingual writing examiner.

Below, between <<<UTTERANCES>>> and <<<END>>>, is everything one user typed
verbatim in one chat session, in order. It may include prose mixed with code,
commands, or file paths; judge only the natural-language prose.

Task:
1. Determine the single dominant natural language the user is writing prose
   in (ignore code/commands/paths when deciding). Give its ISO 639-1 code
   (e.g. en, es, fr, ko, zh, de, ar).
2. If that language is Japanese (ja), set "skip": true and set "score" and
   "comment" to null. Stop there.
3. Otherwise, assume the user already holds a C1 certificate in this
   language, and grade their writing on a 0-100 scale, calibrated like this:
   - A solid but unremarkable native-speaker baseline (correct, but casual
     and unpolished, like an average native dashing off a message) = 50.
   - 100 is reserved ONLY for prose that would be praised as excellent,
     precise, and elegant even by native speakers of that language,
     professional or literary quality.
   - Any grammar mistake, awkward phrasing, unnatural collocation, wrong
     register, or any other tell that the writer is not a native speaker
     must bring the score BELOW 50. Do not award 50 or higher unless the
     writing is genuinely flawless and natural throughout.
   - Be harsh and exacting. Most non-native writing, even strong C1 writing,
     should score well under 50. Do not grade on a curve or soften the score
     to be encouraging.
4. Write a short critique (2-4 sentences, in English) explaining the score:
   cite specific errors, or, if score >= 50, specific strengths.

Respond with EXACTLY one line of raw JSON and nothing else - no markdown
code fences, no preamble, no text outside the JSON object:
{{"lang":"<code>","skip":<true|false>,"score":<integer 0-100 or null>,"comment":"<string or null>"}}

<<<UTTERANCES>>>
{utterances}
<<<END>>>
"""


def parse(reply):
    """The JSON object in the reply, fences stripped, or None."""
    body = re.sub(r"^```(?:json)?\s*|\s*```$", "", reply.strip(), flags=re.M).strip()
    try:
        data = json.loads(body)
    except ValueError:
        return None
    return data if isinstance(data, dict) else None


def main():
    logs = unprocessed(LEDGER)
    if not logs:
        print("grade: nothing new")
        return 0
    failed = 0
    for log in logs:
        text = log.read_text(encoding="utf-8")
        typed = user_text(text)
        if not typed.strip():
            record(LEDGER, log.name)
            print(f"grade: {log.name}: no user turn")
            continue
        data = parse(ask(PROMPT.format(utterances=typed)) or "")
        if data is None:
            failed += 1
            print(f"grade: {log.name}: no usable reply, left for the next run")
            continue
        lang, score, comment = data.get("lang"), data.get("score"), data.get("comment")
        record(LEDGER, log.name)
        if data.get("skip") or lang == "ja" or not isinstance(lang, str) or not re.fullmatch(r"[a-z]{2,3}", lang):
            print(f"grade: {log.name}: skipped ({lang})")
            continue
        if not isinstance(score, int) or not 0 <= score <= 100 or not comment:
            print(f"grade: {log.name}: malformed grade, skipped")
            continue
        started = meta(text)["started"]
        m = re.fullmatch(r"(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})", started)
        stamp = f"{m.group(1)}-{m.group(2)}:00" if m else log.stem
        out = POLYGLOT / lang / "log" / f"{stamp}.md"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(
            f"# {stamp}\n\n- language: {lang}\n- score: {score}/100\n- session_id: {meta(text)['session_id']}\n\n{comment}\n",
            encoding="utf-8",
        )
        print(f"grade: {log.name}: {lang} {score}/100")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

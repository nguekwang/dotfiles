# parse-cashflow

Parse a Rakuten Bank 入出金明細 CSV export into daily net cash-flow JSON, and
optionally have Claude Opus 5 analyze it.

Rakuten Bank has no self-serve API for individuals — bank API access there is
gated behind registration as a 電子決済等代行業者. This tool works from a
manually exported CSV instead.

## Getting the CSV

Rakuten Bank internet banking → 入出金明細 → pick a 照会期間 (≤24 months,
≤3000 rows) → "CSV形式でダウンロード". Columns: 取引日, 入出金(円), 残高(円),
入出金先内容. Works with either Shift_JIS or UTF-8 exports.

## Usage

```sh
# Daily cash-flow JSON only (no LLM call) — e.g. to feed to another tool
./parse-cashflow fetch statement.csv

# Ask Claude Opus 5 to analyze it
./parse-cashflow analyze statement.csv
./parse-cashflow analyze statement.csv "Which week had the highest spending?"
```

`analyze` needs Anthropic credentials: `export ANTHROPIC_API_KEY=...`, or run
`ant auth login` first.

## Output shape (`fetch`)

One object per day with at least one transaction:

```json
{
  "date": "2026-09-01",
  "income": 250000,
  "expense": -1700,
  "net": 248300,
  "balance": 348300,
  "transactions": 3
}
```

`balance` is the end-of-day balance as of the last row seen for that date in
the CSV.

## Using it as a tool

`fetch` is deterministic and side-effect-free (stdin: none, stdout: JSON),
so it's a natural fit as a custom tool for a Claude API tool-use loop or a
Claude Code Bash call — pass it the CSV path, get structured data back, do
the analysis in the calling conversation instead of via `analyze`.

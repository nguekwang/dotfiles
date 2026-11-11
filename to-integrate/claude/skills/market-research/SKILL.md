---
name: market-research
description: "Producing source-backed market intelligence on a market, competitor set, pricing model, or go-to-market channel: fix the decision the research serves, bound the market, decompose it on one demand/supply/channel/economics axis, grade every source by tier and recency, and deliver a landscape summary, a competitor comparison table, a model shortlist with tradeoffs, and a source ledger. Use whenever the user asks to research a market, size an opportunity (TAM/SAM/SOM), compare competitors or substitutes, survey pricing or monetization models, or evaluate an acquisition channel."
---

# Market Research

Turn a vague growth or strategy request into source-backed market intelligence: fix the decision the research must serve, bound the market, decompose it on one axis, grade every piece of evidence, and deliver a landscape summary, a competitor comparison table, a model shortlist with tradeoffs, and a source ledger with confidence scores.

The deliverable serves the `research` employee of the AI-Org model (`.claude/lib/meeting-system/agents/research/README.md`, `.claude/lib/meeting-system/docs/organization-model.md`: the user is CEO, the agent is the research employee). It is an input, not a conclusion: `/estimate-impact` consumes it for KPI and impact modeling, `/write-proposal-narrative` consumes it for the executive narrative, and the deck it eventually feeds follows `.claude/lib/meeting-system/docs/playbooks/presentation-playbook.md`. Keep the decomposition discipline of the `logical-thinking` skill, the table form of the `figure-rendering` skill, and the register of the `prose-style` skill.

## Scope and Boundary

- In scope: the external world of a business decision. Market size and segmentation, competitors and substitutes, distribution and acquisition channels, pricing and monetization models, and the forces that shift them.
- Out of scope: the internal consequences of a decision. KPI models, impact estimates, and prioritization belong to `/estimate-impact`; narrative and slide construction belong to `/write-proposal-narrative`. This skill stops at evidence and the tradeoffs the evidence supports.
- Out of scope: source-code and repository analysis, which belongs to the `oss-repo-structure` skill even when the subject is a commercial product.
- The boundary line against `/estimate-impact` is ownership of the number: a figure observed in the world is research, a figure projected from a model is analytics. A research deliverable may state a competitor's published price; it must not state the revenue the user would earn at that price.

## Market Decomposition

Fix one axis before gathering anything. The axis is the path of the money: who pays, who is paid, how the two meet, on what terms, and what moves those terms. Every finding lands in exactly one of the five categories below, and the fifth is the explicit residual.

| Category | Question it answers | Typical evidence |
| --- | --- | --- |
| Demand | Who has the problem, how many are there, what do they spend today | Segment definitions, population and account counts, current spend, job-to-be-done statements, switching triggers |
| Supply | Who serves that demand now | Direct competitors, substitutes, the incumbent manual workflow, and the do-nothing option |
| Channel | How demand and supply meet | Acquisition paths, gatekeepers and platforms, partner and reseller routes, observed acquisition cost ranges |
| Economics | On what terms the exchange happens | Published pricing, packaging and monetization shapes, contract length, comparable business models |
| Context | What shifts the four above | Regulation, platform policy, technology change, macro and seasonal cycles |

Three placement rules keep the partition MECE.

- The do-nothing option is always a supply entry. A market where most demand is currently unserved is a different market from one where it is served badly, and omitting the null competitor hides that difference.
- A substitute sits in Supply, not Context, whenever a buyer could choose it instead this quarter. Context holds only forces no single buyer selects.
- A finding that fits no category goes in Context and is labeled as unplaced, rather than forced into the nearest fit. A hidden residual is a defect; a stated one is a finding.

## Evidence Discipline

Grade every source before it enters the deliverable. An ungraded claim is indistinguishable from an invented one, and the deck built downstream cannot repair that.

### Source Tiers

| Tier | Definition | Examples |
| --- | --- | --- |
| A | Primary and accountable. The publisher bears a cost for being wrong | Regulatory filings, audited financials, official statistics, a vendor's own live pricing and product pages |
| B | Secondary with a stated method | Analyst research that publishes its methodology, peer-reviewed work, trade press citing named sources |
| C | Interested party | Vendor whitepapers, press releases, funding announcements, case studies, marketing content |
| D | Unattributed | Blogs and aggregators restating one another, forum claims, and model recall carrying no citation |

- A Tier D item never supports a conclusion. It may only point at a Tier A or B source to be verified.
- Independence outranks tier count. Three articles tracing to one press release are one Tier C source, not three; trace each chain to its origin before counting it.
- When fetching a source fails on a connectivity error, reconnect per the `network-recovery` skill and retry rather than substituting recall.

### Recency

- Record the as-of date of every figure, separately from the publication date of the document carrying it.
- Compare that as-of date against the market's own cycle time: a quarter for advertising rates and platform policy, a year for pricing and competitor sets, several years for regulation and installed base.
- A figure older than one cycle is an assumption, not a fact. Carry it with its age stated, or drop it.

### Claim Types

Label every claim in the deliverable as exactly one of three types, per the research agent's done criteria.

- Fact: traceable to a graded source, quoted with its as-of date.
- Assumption: asserted without a source, with the reason it is plausible and the effect on the conclusion if it is wrong.
- Inference: derived from stated facts and assumptions, with the derivation shown in one line.

Never present an assumption or an inference in the grammar of a fact. If a number cannot be sourced, state the assumption and show the arithmetic; do not produce a figure whose provenance is the model itself.

### Confidence

Score each conclusion, not each source.

| Score | Criterion |
| --- | --- |
| High | Two or more independent Tier A or B sources agree, all within one cycle time |
| Medium | One Tier A or B source, or several agreeing sources with a common origin |
| Low | Tier C sources only, an out-of-cycle figure, or a load-bearing assumption in the derivation |

## Procedure

### 1. Frame the decision

Establish four things before any gathering: the objective, the target, the constraints, and the decision horizon. Ask only when an answer would change the work; otherwise state the working assumption explicitly and proceed.

- Write the decision as a sentence of the form "by `<horizon>`, decide whether to `<action>`". Research that serves no decision has no stopping rule.
- Record what evidence would change the answer. That list is the gathering plan.

### 2. Bound the market

- State the market boundary as an intersection of buyer, need, and geography, and state what is deliberately excluded.
- Fix one segmentation axis for the demand side and hold it, per the MECE rules of the `logical-thinking` skill. Mixing firmographic and behavioral segments in one level is a defect.

### 3. Gather against the five categories

Work the categories of "Market Decomposition" in order, recording each finding with its source, tier, and as-of date at the moment of capture. Retrofitting citations at the end loses the chain of origin.

- Start from Tier A where one exists: a competitor's own pricing page outranks any summary of it.
- For each competitor, capture the same fields, so the comparison table has no empty cells by accident. An unknown field is recorded as unknown, which is itself a finding.
- Stop when the evidence recorded in step 1 as decision-changing is either collected or established as unavailable.

### 4. Size the opportunity

Size only when the decision turns on magnitude. When it does, build the estimate twice.

- Bottom-up: countable units multiplied by observed price. This is the primary estimate because each factor is separately checkable.
- Top-down: a published market total narrowed by stated share assumptions. This is the cross-check.
- Report both, state the gap between them, and explain the gap. A single headline market total quoted alone is not a size estimate.
- Separate TAM, SAM, and SOM explicitly, and state the constraint that cuts each one down to the next.

### 5. Build the shortlist

- Derive candidate models from the Supply and Economics categories, not from invention.
- For each candidate, state the tradeoff, not only the appeal: what it costs, what it forecloses, and the condition under which it fails.
- Rank candidates on one stated criterion. Rank `n` of `N` is reported with `N` visible, per the `prose-style` skill.

### 6. Write the deliverable

Produce the four outputs of the research agent contract, in pyramid order per the `logical-thinking` skill: the governing conclusion first, support beneath it.

- Market landscape summary, organized on the five categories of the axis.
- Competitor comparison table, one competitor per row, identical fields per column, rendered per the `figure-rendering` skill.
- Model shortlist with tradeoffs.
- Source ledger: one row per source, carrying the tier, the as-of date, the claims it supports, and the confidence of each conclusion.

Place the file per the `files-and-repository` skill, and choose its language per the `language-selection` skill. Hand off by naming which conclusions are load-bearing for `/estimate-impact` and which are still open questions.

## Verification

Check the deliverable against every line before handing it off. A failure is a defect to fix, not a caveat to add.

- The decision sentence from step 1 is present, and every section serves it.
- The market boundary states both what is included and what is excluded.
- Every finding sits in exactly one of the five categories; the residual, if any, is labeled as unplaced.
- The do-nothing option appears in the Supply category.
- Every claim is labeled fact, assumption, or inference, and no assumption is written in the grammar of a fact.
- Every number carries an as-of date, and every out-of-cycle figure is marked as an assumption.
- Every source carries a tier; no conclusion rests on Tier D alone; agreeing sources have been traced to independent origins.
- Any size estimate is built bottom-up and cross-checked top-down, with the gap explained.
- Every shortlist candidate states its cost and its failure condition, not only its appeal.
- Every conclusion carries a confidence score, and at least one recommendation path is supported by explicit evidence.
- The source ledger accounts for every claim in the body; nothing in the body is unreferenced.

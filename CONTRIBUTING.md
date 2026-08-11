# Contributing

The most valuable contribution to Qadvisor is a **new advisor** or an **eval suite** for an
existing one. Both are described below. Bug fixes and doc improvements are always welcome.

## Adding a new advisor

### 1. Pick someone worth modeling

A good Qadvisor advisor:

- has a **documented, distinctive thinking framework** (books, essays, long-form interviews —
  enough public material to model faithfully, not vibes)
- covers a **decision domain the board currently lacks** (check the roster in the README —
  e.g., data-driven decisions and information design are known gaps: Nate Silver, Edward Tufte)
- would **disagree** with at least one existing advisor in interesting ways — debate is the
  product

### 2. Build on the three-part spine

Copy [docs/ADVISOR_TEMPLATE.md](docs/ADVISOR_TEMPLATE.md) to
`skills/qadvisor-{id}/SKILL.md`. Every advisor must have:

1. **A question framework** — 3-5 named thinking tools with enough depth that the model can
   *apply* them, not just name-drop them
2. **A decision domain** — what to bring this advisor, and a pointer to the `qadvisor`
   dispatcher for everything else
3. **A brake mechanism** — the specific decision patterns this advisor exists to kill

Plus the two output constraints every advisor shares:

- **Hard cap: 600 words** (≈600 characters for CJK output)
- **At least 3 specific numbers** per analysis (probabilities, amounts, timeframes, ratios)

And the language rule: advisors respond in the language the user writes in.

### 3. Wire it into the dispatcher

Add a row to the board table in `skills/qadvisor/SKILL.md` (pick the right layer) and, if the
advisor introduces a routing distinction (e.g., "X diagnoses, Y designs"), add a note to the
question-type table.

### 4. Run the eval (strongly encouraged)

PRs that include an eval run get merged faster. See [evals/README.md](evals/README.md):
5 hard questions from the advisor's domain × 5 binary criteria. Include your
`changelog.md` and `results.tsv` under `evals/{id}/`.

## Improving an existing advisor

Prompt changes to an existing advisor **must** come with eval evidence: run the advisor's
suite (or create one if it doesn't exist) before and after your change. A change that reads
better but scores worse is a regression.

## Style rules

- Skill body in English (it's instruction text for the model); user-facing output is
  language-adaptive by design
- Frontmatter `name:` must be lowercase `qadvisor-{id}`
- Keep the one-line Chinese intro under the title (`> ...`) — it's part of the project's
  bilingual identity
- No real-person quotes longer than 15 words; model the *framework*, don't reproduce the text

## Legal bar for personas

New advisors modeled on real people must stay within the bounds of
[DISCLAIMER.md](DISCLAIMER.md): public thinking frameworks only, commentary/educational
framing, no implication of endorsement. Living private individuals (not public figures) are
off the table.

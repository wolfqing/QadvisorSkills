# Evals

This suite answers one question: **does installing Qadvisor beat asking Claude to "think
like Munger"?**

It uses Claude Code's built-in eval runner, [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals),
which needs Claude Code v2.1.269 or later. Each case starts a fresh, isolated session, sends a
realistic prompt and scores the reply with graders. By default every case runs in two arms:

| Column | Meaning |
|--------|---------|
| **WITH** | Score with the Qadvisor plugin loaded. Natural phrasing such as "what would Munger say…" routes through the `qadvisor` dispatcher. |
| **W/OUT** | Score for the same prompt with no plugin: plain Claude asked to channel the advisor. |
| **Δ** | WITH minus W/OUT, which is what the plugin adds. |

`tool_used: Skill` graders only report whether the skill fired. They are left out of the
score in two-arm runs so that they do not inflate Δ.

## Cases

| Case | Tags | What it checks | Runs |
|------|------|----------------|------|
| `munger/quit-job` | munger, single-advisor | Quitting a $140k job for a $2k-MRR side project | 3 |
| `munger/price-war` | munger, single-advisor | Whether to match a competitor's 50% price cut | 3 |
| `munger/term-sheet` | munger, single-advisor | $3M for 30% with a 2x liquidation preference | 3 |
| `munger/market-pivot` | munger, single-advisor | Pivoting from US/EU revenue to a viral China spike | 3 |
| `munger/big-client` | munger, single-advisor | A $400k custom-feature client that would derail the roadmap | 3 |
| `board/price-war-en` | board, expensive | Standard board run ("board this"): at least 3 independent advisor subagents, ✅/⚠️/❌ verdicts, a reframed question, named perspectives with agreement and disagreement, concrete next steps | 2 |
| `board/roadmap-zh` | board, expensive | Standard board run in Chinese ("顾问团"): Chinese report, verdict marks, clear recommendation, next steps | 2 |
| `board/debate-munger-musk` | debate, expensive | Forced debate: both sides engage each other's arguments and reach a clear outcome | 1 |
| `trigger/no-trigger-coding` | trigger | An unrelated coding request must **not** invoke the board (scored in both arms) | 2 |

Every Munger case uses the same five graders, carried over from the
[legacy criteria](history/):

- **concise**: 800 words or fewer (the advisor cap is 600; the grader keeps the legacy 800-word bar as headroom for headings and assumption lines)
- **framework-depth**: at least 3 mental models, each applied to this situation's facts
- **quantitative**: at least 3 numbers the advisor works out itself
- **voice-and-verdict**: blunt, with a clear verdict
- **challenges-assumptions**: questions at least one premise of the question

## Run it

Run these from the repository root. They call the model on your account; the `expensive`
cases run many subagents.

```bash
# Full suite, two arms, pinned models
claude plugin eval . --trust-plugin --model sonnet --judge-model sonnet -j 4

# Quick iteration on the Munger cases: one arm, one run
claude plugin eval . --tag munger --runs 1 --ablation none

# Cheaper subset: Munger and trigger cases, with the baseline
claude plugin eval . --tag munger trigger
```

Results go to `evals/results/<timestamp>/`, which holds `report.html` and
`aggregate-result.json`. That directory is gitignored. Without `--judge-model`, the judge is
Haiku. Pin `sonnet` for scores you plan to publish.

## Results

<!-- EVAL-RESULTS:START -->
_Results pending._
<!-- EVAL-RESULTS:END -->

## History

[history/](history/) holds the original hand-run "autoresearch" loop that took the Munger
skill from 18/25 to 25/25. This suite replaces it.

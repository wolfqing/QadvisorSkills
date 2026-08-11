# Evals

Persona prompts are easy to write and hard to make good. This directory holds the eval
suites and optimization logs that keep Qadvisor's advisors honest.

## Methodology

Inspired by Karpathy-style "autoresearch" hill-climbing:

1. **Test inputs**: 5 hard, realistic questions from the advisor's decision domain
2. **Binary criteria**: each output is judged pass/fail on 5 dimensions:
   - **Concise** — within the output cap (600 words / ≈600 CJK characters)
   - **Deep framework application** — tools applied with situational insight, not name-dropped
   - **Quantitative reasoning** — ≥3 specific numbers (probabilities, amounts, timeframes, ratios)
   - **Voice** — the advisor's signature bluntness/style is present
   - **Challenges assumptions** — reframes the question or attacks an implicit premise
3. **Score**: 5 inputs × 5 criteria = 25 points per experiment
4. **Hill-climb**: mutate the SKILL.md, re-run, keep the change only if the score improves
5. **Log everything**: every experiment goes in `changelog.md`; scores in `results.tsv`

## Results so far

| Advisor | Baseline | Current | Log |
|---------|----------|---------|-----|
| munger | 18/25 (72%) | 25/25 (100%) | [munger/](munger/) |
| the other 16 | — | not yet evaluated | **open work — PRs welcome** |

The Munger run is the reference: the baseline failed all 5 conciseness checks (1000-1500 word
consultant reports) and 2/5 quantification checks. Adding a hard 600-word cap, per-section
sentence caps, and a ≥3-numbers requirement took it to 25/25. Those two constraints are now
standard across all 17 advisors — but only Munger's have been *verified*. Running the same
loop on the other advisors is the highest-value contribution you can make.

## Directory layout

```
evals/
  README.md            ← you are here
  review-ui.html       ← standalone review interface for scoring outputs
                          (loads fonts/XLSX from CDN — needs network)
  munger/
    SKILL.md.baseline  ← the pre-optimization skill, for reproduction
    changelog.md       ← every experiment: change, score, result
    results.tsv        ← machine-readable scores
```

To evaluate a new advisor, create `evals/{id}/` with the same three files.

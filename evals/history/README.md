# Eval history (legacy)

Before the native `claude plugin eval` suite existed, the Munger advisor was tuned with a
hand-run "autoresearch" loop, after Karpathy's hill-climbing idea:

- **Inputs**: 5 realistic decisions (quit job, price war, term sheet, market pivot, big client)
- **Criteria**: 5 binary checks per output: concise, deep framework use, at least 3 numbers,
  Munger voice, challenges assumptions. 5 x 5 = 25 points per experiment.
- **Loop**: change `SKILL.md`, re-run, keep the change only if the score goes up.

**Result**: the baseline scored **18/25 (72%)**. It failed every conciseness check, with
1000-1500-word consultant-style reports, and missed the numbers check on 2 of 5 inputs. One
change got it to **25/25 (100%)**: a hard 600-word cap, a sentence cap for each section, and
a rule to use at least 3 specific numbers.

| File | What it is |
|------|------------|
| [munger/SKILL.md.baseline](munger/SKILL.md.baseline) | The skill before optimization |
| [munger/changelog.md](munger/changelog.md) | Each experiment: change, score, outcome |
| [munger/results.tsv](munger/results.tsv) | Scores in machine-readable form |
| [review-ui.html](review-ui.html) | Stand-alone page for scoring outputs by hand (loads fonts and XLSX from a CDN) |

The [native suite](../README.md) replaces this loop. It keeps the same five Munger scenarios
and criteria and adds a no-plugin baseline, repeated runs and an LLM judge. Use the native
suite for any new work.

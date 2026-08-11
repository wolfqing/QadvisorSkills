# Qadvisor-munger Autoresearch Changelog

## Eval Criteria (Upgraded)

1. **Concise ≤800 words?** Total output under 800 Chinese characters
2. **Deep model application?** Models applied with genuine situational insight, not just named
3. **Quantitative reasoning?** ≥3 specific numbers (probabilities, amounts, timeframes, ratios)
4. **Munger voice?** Signature bluntness, wit, or memorable one-liners present
5. **Challenges assumptions?** Reframes the question or challenges user's implicit premise

## Test Inputs

1. "Should I quit my job to work full-time on OpenClawUP?"
2. "A competitor cut prices by 50%. Should I match?"
3. "An investor offered a term sheet but wants 30% equity. Should I take it?"
4. "Should I pivot from international to domestic China market?"
5. "A big client wants custom features that would derail our roadmap. Worth it?"

---

## Experiment 0 — baseline

**Score:** 18/25 (72.0%)
**Change:** None — original skill
**Result:** All 5 evals pass for model depth, Munger voice, and assumption challenging. ALL 5 fail conciseness (1000-1500 words each). 2/5 fail quantitative reasoning.
**Failing patterns:** Outputs are verbose consultant reports (1000-1500 words), some lack specific numbers.

## Experiment 1 — KEEP

**Score:** 25/25 (100.0%)
**Change:** Rewrote Output Format section with: (1) explicit 600-word hard limit + anti-verbosity directive in Munger's voice, (2) per-section sentence caps (2-3 sentences), (3) mandatory ≥3 specific numbers per analysis, (4) instruction to use numbers not adjectives
**Reasoning:** The two failure modes (verbosity and vague reasoning) are both instruction-following issues, not capability issues. Adding explicit constraints should fix both simultaneously.
**Result:** All 5 outputs now ≤600 words. All include ≥4 specific numbers. Model depth, Munger voice, and assumption-challenging maintained. Quality arguably improved — forcing conciseness eliminated filler and made the insights sharper.
**Notable outputs:** "死于恐慌不是竞争" (run 1), "等价于雇了一个永远不走的老板" (run 3), "你卖的是杠杆，定制是在主动消灭这个杠杆" (run 5)

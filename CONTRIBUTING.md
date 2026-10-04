# Contributing

The two most valuable contributions are a **new advisor** and an **eval suite** for an
existing advisor. Bug fixes and doc improvements are always welcome.

## How the pieces fit

| Path | What it is |
|------|------------|
| `skills/qadvisor-{id}/SKILL.md` | An advisor and the single source of truth for it. Users call it directly with `/qadvisor-{id}`. |
| `skills/qadvisor/SKILL.md` | The dispatcher, and the only skill Claude invokes on its own. It holds every natural-language trigger, the board table and the routing rules. |
| `skills/qadvisor/advisors/{id}.md` | A generated copy of each advisor's body, which the dispatcher reads. **Never edit by hand.** |
| `scripts/build.sh` | `sync` (the default) regenerates `advisors/`. `check` verifies sync and skill metadata, and CI runs it. `bundle` builds `dist/qadvisor-skill.zip` for upload to claude.ai, keeping only the frontmatter keys claude.ai accepts (see [step 4](#4-build-and-check)). |
| `evals/` | The `claude plugin eval` suite: `evals/{id}/` per advisor, plus `board/` and `trigger/`. |

**Why advisors are user-invoked.** Claude Code puts every model-invocable skill's description
into a listing budgeted at about 1% of the context window and drops descriptions when that
budget overflows. Seventeen long advisor descriptions overflowed it and competed for the same
triggers. Advisors now set `disable-model-invocation: true` and carry a one-line description.
All natural-language triggering lives in the dispatcher.

## Adding a new advisor

### 1. Pick someone worth modeling

- **A documented, distinctive framework**: books, essays and long-form interviews give enough
  public material to model the person faithfully. A general impression of how they think is
  not enough.
- **A decision domain the board lacks**: check the roster in the README. Known gaps include
  data-driven decisions (Nate Silver) and information design (Edward Tufte).
- **Real disagreement** with at least one existing advisor, because debate is the product.
- **Clears the [legal bar](#legal-bar-for-personas).**

### 2. Write the skill

Copy the block in [docs/ADVISOR_TEMPLATE.md](docs/ADVISOR_TEMPLATE.md) into
`skills/qadvisor-{id}/SKILL.md`. `{id}` is a short lowercase slug such as `munger`, `pg` or `sunzi`.

The frontmatter has exactly these keys:

```yaml
---
name: qadvisor-{id}
description: "{Full Name} — {domain} advisor on the Qadvisor board: {3-5 signature tools}. Calls this one advisor directly; for a multi-advisor review use /qadvisor."
argument-hint: "[decision or question]"
disable-model-invocation: true
---
```

The description is one line of at most 260 characters, and `check` enforces that limit. It
has no trigger phrases and no example questions; those belong in the dispatcher.

The body is built on a three-part spine:

1. **A question framework**: 3-5 named thinking tools, each deep enough for the model to
   *apply* it rather than just name-drop it.
2. **A decision domain**: what to bring this advisor, followed by the out-of-domain pointer.
3. **A brake mechanism**: the specific decision patterns this advisor exists to kill.

Keep these template lines verbatim:

- the language-adaptive line: *Think in English internally. Respond in the language the user
  writes in…*
- the out-of-domain pointer: *If the question falls outside your domain, offer your
  perspective briefly, then suggest the user run `/qadvisor`…*
- the hard-cap line: `**Hard cap: 600 words (≈1,000 characters for CJK output).**`
- the requirement for **at least 3 specific numbers** (probabilities, amounts, timeframes or
  ratios), followed by the grounding rule: *Ground every number in the user's facts or label
  it as an estimate; never present invented figures as facts.* In qualitative domains such as
  design or brand, thresholds and test criteria count as numbers.

### 3. Wire it into the dispatcher

Make three edits in `skills/qadvisor/SKILL.md`:

1. **Board table**: add a row in the right layer. The "Also known as" column lists every name
   the dispatcher should match: the full name, the Chinese name and any short form, as in
   `Paul Graham, PG, 保罗·格雷厄姆`. The last column is the framework link
   `[{id}.md](advisors/{id}.md)`.
2. **Question-type routing table (Step 3b)**: add the advisor to the question types it serves.
   If it introduces a routing distinction, note it there. For example, helmer diagnoses which
   powers exist and sunzi decides how to fight.
3. **Description**: add the surname to the list of advisor names so that a request like "what
   would Tufte say…" reaches the board. Use the full name where the surname alone is ambiguous.
   The description must stay at or under 1000 characters, and `check` enforces that limit.

Also update the advisor count ("17") everywhere it appears: the dispatcher, both READMEs,
`.claude-plugin/*.json`, the `scripts/build.sh` header and the banner (`docs/assets/banner.html`,
then re-render the PNGs). `grep -rniE '\b17\b|seventeen' --include='*.md' --include='*.json' --include='*.html' .`
finds them.

### 4. Build and check

```bash
bash scripts/build.sh          # sync: writes skills/qadvisor/advisors/{id}.md
bash scripts/build.sh check    # what CI runs
```

`check` fails in these cases:

- a skill's `name` doesn't match its directory
- a description is missing, or longer than 260 characters for an advisor, 1000 for the
  dispatcher or 1024 (the platform limit) for any other skill
- an advisor lacks `disable-model-invocation: true`
- the dispatcher doesn't reference `advisors/{id}.md`
- a generated file is missing, stale or orphaned

Never edit `advisors/*.md` by hand, because the next sync overwrites it. Commit the generated
file along with your source change.

To build the claude.ai upload zip, run `bash scripts/build.sh bundle`. claude.ai rejects a
skill whose frontmatter has any key outside `name`, `description`, `license`, `compatibility`,
`metadata` and `allowed-tools`, so the bundled `SKILL.md` keeps only `name` and `description`
from the source and adds `license: MIT`. Claude Code-only keys such as `argument-hint` are
dropped from the zip but stay in the repo. The body and `advisors/*.md` are copied unchanged.
`bundle` fails if the description exceeds 1024 characters or `name` differs from the
skill's folder name.

### 5. Add evals

A new-advisor PR should include 5 cases modeled on [evals/munger/](evals/munger/):

```
evals/{id}/{case}/
  prompt.md                    # copy munger's frontmatter; tags: [{id}, single-advisor]
  graders/
    skill-fired.md             # tool_used: Skill; swap munger for {id} in input_match
    concise.md                 # regex word cap; keep as is
    framework-depth.md         # llm: ≥3 of THIS advisor's tools applied to the case's facts
    quantitative.md            # llm: ≥3 figures the response derives, not the user's own
    voice-and-verdict.md       # llm: this advisor's voice plus a committed verdict
    challenges-assumptions.md  # llm: the premise this advisor typically attacks
```

Each prompt should be a hard, realistic question from the advisor's domain. It names the
advisor in plain language ("How would Edward Tufte look at this?") and gives concrete numbers.
Rewrite the llm rubrics for this advisor; copying Munger's wording tests the wrong framework.
`skill-fired` is reported as an indicator that the board fired and does not count toward the
score.

```bash
claude plugin eval . --tag {id}
```

The command runs every case with and without the plugin and prints a WITH / W/OUT / Δ table.
**Paste that table into the PR.** A Δ near zero means the advisor adds little over plain
Claude, so strengthen the framework before you submit. Use `--runs 1` while iterating, but the
table you paste should come from the default run.

## Improving an existing advisor

Prompt changes to an existing advisor **must** show before/after scores from the same command.
Run `claude plugin eval . --tag {id}` on `main` and again on your branch, then paste both
tables. If the advisor has no suite yet, add one first (step 5). A change that reads better but
scores worse is a regression. After editing, run `bash scripts/build.sh` and
`bash scripts/build.sh check`.

## Style rules

- The skill body is in English, because it is instruction text for the model. User-facing
  output adapts to the user's language by design.
- Keep the one-line Chinese intro (`> ...`) under the title and the 中文 name beside each
  thinking tool. They are part of the project's bilingual identity.
- No quote from a real person may exceed 15 words. Model the framework; don't reproduce the
  text.

## Legal bar for personas

Advisors modeled on real people must stay within [DISCLAIMER.md](DISCLAIMER.md):

- model public thinking frameworks only
- use commentary and educational framing
- imply no endorsement or affiliation

Only public figures qualify; living private individuals are off the table. The maintainers
respond promptly to takedown requests from a represented person or their estate.

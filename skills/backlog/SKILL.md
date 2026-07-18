---
name: backlog
description: "Survey a repository for outstanding work and present it as a single backlog. Use whenever the user types /backlog or asks things like 'what's on the backlog', 'what's left to do', 'what should I work on next', 'list the open EPICs / TODOs / tech debt', or 'what work is outstanding here'. Gathers EPIC docs, ROADMAP items, TODO/FIXME/HACK comments in source, an unreleased CHANGELOG, and open GitHub issues into one list; refreshes a BACKLOG.md; and creates/maintains a docs/TECHNICAL_DEBT.md (seeding it with untracked code TODOs plus an automation-flagged code review on first creation). If a repo has no tracked work at all, propose concrete expansions instead of returning nothing. Make sure to use this skill even when the user doesn't say the word 'backlog' but clearly wants an inventory of what's left to build or fix."
---

# /backlog

Turn a whole repository's scattered signals of unfinished work into one coherent picture the user can act on. Work lives in many places — EPIC design docs, a roadmap, code comments, a changelog's "Unreleased" section, GitHub issues — and no single one of them is the backlog. This skill gathers them, dedupes them, and hands the user a ranked inventory plus two durable artifacts: a refreshed `BACKLOG.md` and a maintained `docs/TECHNICAL_DEBT.md`.

The guiding principle: **the human stays editor-in-chief.** You surface and organize; anything you generate (proposed work, review findings) is clearly marked as machine-suggested so the user can keep, edit, or discard it without confusing it for work they authored.

## When to run

Trigger on `/backlog` or any request to enumerate outstanding work ("what's left", "what should I do next", "show me the open EPICs/TODOs", "any tech debt here"). The user wants an inventory, not a single fix.

## Workflow

Do these in order. Steps 1–3 are read-only discovery; tell the user what you're scanning so a large repo doesn't feel like a stall.

### 1. Discover task sources

Cast a wide net, because every repo organizes work differently. Look for, in roughly this priority:

- **EPIC / feature design docs** — files matching `EPIC*`, `RFC*`, `PROPOSAL*`, `DESIGN*`, `SPEC*` (commonly under `docs/`). Read enough of each to capture title and status (planned / in-progress / done). Many repos mark status in a header table or a checklist.
- **Roadmap / planning docs** — `ROADMAP.md`, `PLAN.md`, `TODO.md`, `BACKLOG.md`, `docs/ROADMAP*`. These often hold the highest-level intent.
- **Code comments** — `TODO`, `FIXME`, `XXX`, `HACK`, `BUG` markers in source. Preserve any semantic tag the author attached (e.g. `TODO RF:` for refactor, `TODO TD:` for tech-debt, `TODO PERF:`). These tags are signal, not noise — carry them through to classification. Exclude vendored/build dirs (`target/`, `node_modules/`, `dist/`, `.git/`, `vendor/`).
- **Changelog** — an "Unreleased" or "Next" section in `CHANGELOG.md` often lists committed-to-but-unshipped work.
- **GitHub issues** — if `gh` is available and authenticated, `gh issue list --state open --limit 50`. Skip silently if `gh` is absent or the repo has no remote; don't make it a blocker.

Use fast search tools (Grep/Glob) and read only what you need from each doc. The goal is an accurate index, not a full read of every file.

### 2. Classify and dedupe

Fold the raw findings into a clean list. For each item capture: a short title, its **source** (which file/line or issue #), a **category**, and a rough **status** where discernible.

Categories to bucket into:
- **EPIC / Feature** — net-new capability described by a design doc or roadmap entry.
- **Refactor** — restructuring without behavior change (often `TODO RF`).
- **Tech debt** — known shortcuts, missing tests, fragile code (often `TODO TD`, `HACK`, `FIXME`).
- **Bug** — known defect (`BUG`, `FIXME` describing wrong behavior).
- **Docs / Note** — annotations and reminders that aren't actionable engineering work; list these but keep them visually de-emphasized so they don't crowd out real tasks.

Dedupe across sources: an EPIC doc and a code TODO that describe the same work are one backlog item with two references, not two items. When a doc's header or checklist shows the work is already done, drop it (or list it under a short "Recently completed" note if useful for context) rather than presenting finished work as outstanding.

### 3. Handle the empty case

If discovery turns up genuinely nothing actionable — no open EPICs, no TODOs, no issues — do **not** just report "nothing found." Briefly study what the library/app actually does (its public API, README, module layout) and propose 3–6 concrete, plausible expansions: missing test coverage you can see, obvious feature gaps, ergonomics improvements, hardening. Mark every proposal as machine-suggested (see provenance convention below) and frame them as starting points, not commitments.

### 4. Maintain `docs/TECHNICAL_DEBT.md`

Locate an existing tech-debt doc first — check `docs/TECHNICAL_DEBT.md`, `TECHNICAL_DEBT.md`, and obvious variants (`TECH_DEBT`, `DEBT.md`). If a repo has a clearly preferred docs location, match it; otherwise default new files to `docs/TECHNICAL_DEBT.md`.

**If it does not exist — first-time creation:**
1. Seed it with every tech-debt-flavored code comment found in step 1 (`TODO`, `FIXME`, `HACK`, `XXX`, especially `TODO TD`/`TODO RF`), each with its `file:line` reference, that isn't already tracked elsewhere.
2. Run a **deep automated code review** to find debt the author never wrote a comment for. Dispatch a code-review subagent for thoroughness — prefer a dedicated reviewer agent (e.g. `feature-dev:code-reviewer`) if one is available, otherwise a general-purpose agent. Ask it to focus on: missing tests on public APIs, error handling that violates the project's own stated standards (read `CLAUDE.md`/contributing docs first), fragile patterns, and risky shortcuts. Have it return findings with `file:line`, a one-line problem statement, and a suggested fix.
3. Write every review finding into the doc **flagged as automation** (see provenance convention). This is the "initially performing a code review" step and only happens on creation — it's expensive, so don't redo it on every run.

**If it already exists — update in place:**
- Add newly-found code TODOs that aren't tracked yet.
- Preserve all human edits and the human/automation distinction. Never delete or rewrite items the user authored.
- Offer (don't force) a fresh deep review: "Want me to re-run the automated review pass? It can drift out of date." Run it only if the user says yes.

Use this structure for the doc:

```markdown
# Technical Debt

> Maintained by the `/backlog` skill. Items tagged 🤖 were proposed by automated
> review — review and edit them; they are suggestions, not facts.

## Tracked debt
<!-- Human-authored and code-comment-sourced items. -->
- [ ] **<title>** — <description> (`src/foo.rs:123`)

## 🤖 Automated review findings
<!-- Machine-proposed. Promote good ones up to "Tracked debt", delete the rest. -->
- [ ] 🤖 **<title>** — <problem>. Suggested: <fix>. (`src/bar.rs:45`)
```

### 5. Refresh `BACKLOG.md`

Write/overwrite `BACKLOG.md` at the repo root (or alongside an existing one) aggregating the classified inventory into a scannable, prioritized list. Group by category, lead with EPICs/Features, link each item to its source, and mark machine-proposed items with the provenance flag. Keep it terse — this is an index, not prose. Point to `docs/TECHNICAL_DEBT.md` for the debt detail rather than duplicating it.

### 6. Report to the user

Give a tight conversational summary: counts per category, the top few items worth doing next (with your reasoning), and note the two files you wrote/updated. Surface anything notable — e.g. a TODO that looks like a latent bug, or an EPIC marked in-progress with no recent activity. End by asking what they want to pull off the backlog next.

## Provenance convention — keep human and machine separate

Everything you propose (step 3 expansions, step 4 review findings, any item the user didn't author) must be visually distinct from work the user already tracks. Use the 🤖 marker and group machine items under their own heading. The reason matters: a backlog the user can't trust is a backlog they'll stop reading. Make it trivial for them to see "this came from automation" and to accept or reject it. Never silently promote a machine suggestion into the human-authored section.

## Notes on judgment

- **Read the project's own standards before reviewing.** If `CLAUDE.md` says "never use `unwrap()` in library code", debt findings should be measured against *that*, not generic defaults. A finding that contradicts house rules is noise.
- **Status over completeness.** A short, accurate backlog beats an exhaustive dump that lists finished and stale work as if it were live.
- **Don't commit.** Write the files; leave staging and commits to the user unless they explicitly ask. (Some environments forbid the agent from running git state-changing commands entirely — respect that.)

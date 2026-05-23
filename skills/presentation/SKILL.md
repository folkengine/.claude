---
name: presentation
description: Generate a step-by-step demo runbook for a specific feature, EPIC, PR, or branch — what to type, what to click, what to point at on screen. Use when the user types `/presentation <thing>` or asks for a "demo script", "demo runbook", "walkthrough", "presentation script", "show-and-tell steps", "live demo plan", or "how do I demo X" — even if they don't use the word "presentation". Project-agnostic: works in any repo (Rust, Node, Python, mixed). Always invoke this skill when the user wants a physical, manual demonstration of work they (or someone) has done, as opposed to a written summary or code review.
version: 1.0.0
---

# Presentation

You are helping the user prepare to *physically demonstrate* a feature in front of an audience — a teammate, a stakeholder, a conference, a recording. The user types `/presentation <thing>`; you produce a runbook they can read top-to-bottom while presenting.

`<thing>` is whatever the user typed after the command — an EPIC ID like `EPIC-23`, a feature name like `web spectator`, a PR number like `#7`, a branch name, or a free-form description. **The argument is authoritative**: don't second-guess what they meant. If you can't find material, ask once, then proceed with what you've got.

## The runbook output

ALWAYS use this exact section order:

```
# Demo: <feature title>

> One-sentence pitch — what the audience will see and why it's interesting.

## Audience & framing
Who this is for and the angle you're presenting from (engineering / product /
exec / curious outsider). Pick a sensible default if not specified; surface it
so the user can adjust.

## Prerequisites
Bullet list of things that must be true BEFORE the demo starts:
- repo checked out, on which branch
- env vars set
- containers / services running
- credentials / tokens
- terminal layout (number of panes, what's in each)
- browser tabs open
Anything the audience won't see you set up.

## Setup (~ X minutes)
Numbered list of commands to run just before the demo. Each step is:

1. **What you're doing in one phrase**
   ```bash
   <exact command>
   ```
   _Expected:_ what you see when it works (one line).
   _Talking point:_ one sentence you might say while it runs.

Keep talking points short — they're cues, not a script.

## The demo (~ Y minutes)
The main act. Same numbered format as Setup. Group related steps under
sub-headings (e.g. `### 1. Seat the bots`, `### 2. Watch a hand play`).

For every step that produces visible output (terminal, browser, dashboard):
- Show the exact command.
- Name the expected observation ("a `hand` span appears in Jaeger").
- Add a talking point.

If a step depends on something the audience CAN see (e.g. a browser panel),
say which window to point at.

## What to highlight verbally
Three to five bullet talking points the user can drop in throughout — the
*why*, not the *what*. The interesting design decisions, the constraints
this work resolves, what it unlocks next.

## Likely questions & answers
Three to five Q&A pairs the audience is likely to ask. Each Q is a real
phrasing; each A is one or two sentences.

## Cleanup
What to do after the demo: `docker compose down`, kill background processes,
reset branches, revert env vars. So the user's machine returns to the state
it was in.

## Troubleshooting
If known. List failure modes you've seen during the live smoke, with the
fix. Skip the section entirely if you found no real issues — don't invent
hypothetical failures.
```

## Workflow

Do these steps in order. Don't skip; if a step yields nothing, say so before moving on.

### Step 1 — Resolve the argument to material

The user gave you a descriptor. Find the material:

- **EPIC-style** (`EPIC-23`, `EPIC_12`, `epic 7`): look for `docs/EPIC-23*.md`, `docs/superpowers/specs/*epic-23*.md`, `docs/superpowers/plans/*epic-23*.md`. Note both the design (spec) and the plan if both exist — they cover different angles.
- **PR number** (`#7`, `PR 42`): `gh pr view <n> --json title,body,files,commits` for title, body, and changed files. If `gh` isn't available, fall back to git history.
- **Branch name** (`epic-22`, `feature/auth`): `git log main..<branch> --oneline` and `git diff --stat main...<branch>` to see what shipped.
- **Free-form** ("the new auth flow", "spectator"): grep the repo for the phrase — docs, READMEs, recent commit messages, file/dir names that match. Don't get clever; the user said the words for a reason.

If you find nothing, ask the user once: "I don't see X in this repo — did you mean Y, or should I treat this as a description and improvise from recent commits?" Then proceed.

### Step 2 — Build a mental model

Before writing anything, answer these for yourself:

1. **What does the feature do** (capability, not implementation)?
2. **What are the runnable entrypoints?** Binaries (`cargo run --bin X`), examples (`cargo run --example Y`), services on ports, scripts, npm tasks, docker-compose stacks, web UIs.
3. **What's visible to a human?** Logs, browser pages, dashboards, traces, generated files, terminal output. *No visible output = no demo. Say so out loud and pivot to whatever's adjacent.*
4. **What's the shortest path from "fresh clone" to "audience sees it work"?** The setup section is whatever it takes to get to step 1 of the demo.

If you have to guess at any of these, name your guess in the runbook so the user can correct it.

### Step 3 — Smoke the path (with confirmation)

The user wants the runbook to actually work. Verify by running pieces of it. **Two rules**:

- **Quick reads always go.** `git log`, `git diff`, `ls`, `cat`, `grep`, `cargo check`, `cargo metadata`, `gh pr view` — run them without asking.
- **Slow or stateful commands ask first.** Anything that takes more than ~30 seconds (cargo build, npm install, docker pull/build/up), starts a long-running process (server, daemon, stream), or mutates state (writes files outside the workspace, modifies env, opens browsers, hits paid APIs) requires a one-line confirmation before you run it.

Phrase the confirmation as a question the user can answer with "y/n" plus optional context:

> "I want to `docker compose up -d --build` to verify the demo path actually works end-to-end (~3 min, idle resources after). Run it? (y/n)"

If they say no, mark that step's `Expected:` line as `unverified — please confirm during dress rehearsal` and continue.

### Step 4 — Draft the runbook

Use the template above verbatim. Concrete tips:

- **Commands must be copy-pasteable.** No `<placeholder>` syntax; use real paths, real ports, real env-var values. If something is genuinely user-specific (a token, a personal email), use the user's actual value from git config or skip the step.
- **Each step's expected output is one line max.** "Container starts" beats a 20-line log dump.
- **Talking points are cues, not scripts.** Six to twelve words. The user will paraphrase; they don't want to read a paragraph.
- **Time estimates are real.** Sum them up at the top of Setup and The Demo. Round generously — demos run long.
- **Cleanup must actually undo Setup.** If Setup brought up containers, Cleanup brings them down. If Setup checked out a branch, Cleanup says how to get back.

### Step 5 — Save and announce

Write the runbook to `docs/presentations/<slug>.md` in the current repo. Slug:
- For EPIC arguments: `epic-23-bot-agents` (epic ID + 2-4 word title from the docs).
- For PRs: `pr-42-<title-slug>`.
- For free-form: kebab-case of the user's argument, truncated to ~40 chars.

Create the `docs/presentations/` directory if it doesn't exist.

Then **print the entire runbook to chat** in addition to writing the file. The user wants to skim it immediately; the file is for committing or sharing later. Finish with one line: `Saved to docs/presentations/<slug>.md`. Don't add a closing summary.

## Edge cases

**No material found at all.** If after a real search you have nothing — no docs, no matching commits, no code that looks related — say so and ask. Don't fabricate.

**Feature isn't actually demoable.** Some work has no visible surface (a refactor, a perf fix without a benchmark UI, a security patch). Say so directly: "EPIC-X is a refactor with no user-visible change; here's a 'what was true before vs. now' diff-walkthrough instead of a live demo." Then write that diff-walkthrough as the runbook.

**Multiple candidates.** If `EPIC-23` matches both a design doc and an implementation PR, that's fine — they're complementary. Pull from both. If it matches two *different* features (rare), ask which one.

**Cross-repo work.** If the feature spans multiple repos (e.g., service + spectator + agents), name them in Prerequisites and link to the entrypoint in each. Demo only the repo you're invoked in unless the user said otherwise.

**Live runtime check fails.** If a smoke command errors during Step 3, **don't paper over it** — capture the error in the Troubleshooting section, note the step that failed, and either fix it (if it's a one-line fix you can clearly identify) or flag it in the runbook as a known issue the user should resolve before the demo. A runbook that lies about working is worse than no runbook.

**Argument is just a word like "presentation".** The user typed `/presentation presentation`. They probably want a meta-demo of the skill itself; ask for clarification.

**No argument at all.** The user typed bare `/presentation`. Don't guess — ask what they want to demo, offering 2-3 concrete candidates pulled from the most recent merged EPICs / PRs / branches in the current repo. Example: "What should I prep a demo for? Recent candidates: EPIC-22 (OTel, just merged), EPIC-21 (Spectator, last week), or a free-form description." Then proceed once they pick.

## Style notes

- The runbook is for a human reading aloud — not for an LLM. Use the second person sparingly, prefer terse third-person ("Run the command", not "Now you will run").
- Don't add motivational filler ("Now for the exciting part!"). Audiences notice.
- One sentence per talking point. If you need two, the point is two points.
- Code blocks are bash unless the demo step is genuinely something else (SQL, a URL paste, etc.).
- No emoji in the runbook unless the user asked for it.

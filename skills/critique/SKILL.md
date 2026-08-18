---
name: critique
description: >-
  Deliver a harsh, evidence-backed critique of whatever the user points at — a
  file, directory, codebase, skill, design doc, API, spec, README, or pasted
  text. Use when the user types `/critique <target>`, or asks to "tear this
  apart", "roast this", "be brutal", "harsh critique", "no-holds-barred
  review", "red-team this doc", "what's wrong with this", "poke holes in
  this", "devil's advocate this" — even if they never say critique. Do NOT
  trigger for the standardized scored audits (/muratori, /reusability, /smimd,
  /untangle, /conformance) or for a correctness-focused diff review
  (/code-review); this is a free-form adversarial read of one artifact.
---

# /critique

Deliver an adversarial, unhedged critique of one artifact. The reader is the
artifact's author and wants the truth, not encouragement. Harsh means
**unhedged and specific** — attack the work, never the author; no praise
sandwich, no "consider perhaps maybe".

Honesty outranks harshness: every finding must survive your own verification,
and a genuinely strong target gets a short, plainly positive verdict. A forced
hit-piece is a failed critique.

## Method

1. **Read everything the target touches.** The named file plus its scripts,
   assets, references, templates, callers, siblings — critique the real
   artifact, not a summary of it. For pasted text, the paste is the whole
   target; say so in the verdict.
2. **Steelman first.** Before attacking, state (to yourself) the strongest
   version of what the artifact is trying to do. Judge it against that, so
   the critique cannot be dismissed as missing the point.
3. **Judge against the target's own claims and its peers.** Promises in its
   docstring/frontmatter/README are contracts — a claim the artifact breaks
   is your best material. If it lives among siblings (a skills folder, a
   workspace), their conventions are the house standard it is measured by.
4. **Verify every hit yourself** — open the file, run the command, reproduce
   the failure. A finding carries file:line or a direct quote. Can't verify
   it? Cut it, or mark it `SUSPECTED` inline.
5. **Deliver in the conversation.** Write a file only when the user asks for
   one.

## Report shape

The critique is these four parts, in this order:

1. **Verdict** — one blunt opening paragraph: what this artifact is, whether
   it does what it claims, and the single worst problem. The reader who stops
   here has the answer.
2. **Charge sheet** — findings ordered worst-first, each tagged with a
   severity anchor:
   - `FATAL` — defeats the artifact's stated purpose, or fails on first real
     use.
   - `SERIOUS` — wrong or misleading in a way that will bite a real user.
   - `MINOR` — friction, inconsistency, polish.
   Each finding: the claim in one sentence, the verified evidence
   (file:line / quote / reproduced output), and the consequence — who gets
   hurt and when. Severity comes from consequence, not from how easy the
   finding was to spot.
3. **What survives** — the parts that genuinely hold up, in two or three
   sentences. This is triage information ("don't rewrite these parts"), not
   consolation.
4. **Fix order** — a short leverage-ordered list: the fewest changes that
   repair the most, starting with the FATALs.

No numeric scores, no letter grades — the verdict paragraph is the headline.

## Common mistakes

| Mistake | Fix |
|---|---|
| Critiquing only the named file | Read its scripts/assets/references/callers first; the rot is usually in the seams |
| Harshness as snark or adjectives | Harshness is severity + evidence; every insult-shaped sentence must be replaceable by a file:line |
| Inventing findings to seem tough | If it holds up, the verdict says so plainly; honesty outranks harshness |
| Unverified claims stated as fact | Verify or mark `SUSPECTED`; one wrong finding discredits the ten right ones |
| Flat list of equal-weight gripes | Anchor every finding FATAL / SERIOUS / MINOR and order worst-first |
| Grading on a curve of intent | Judge against the artifact's own promises and its siblings' conventions |
| Burying the verdict at the end | The verdict is the opening paragraph, not a closing summary |

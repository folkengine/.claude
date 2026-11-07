---
name: lang
description: Use when the user types /lang, /lang off, /lang <language>, or asks you to reply in another language, switch languages, stop using a language, or asks which language mode is active.
version: 1.0.0
---

Language mode: every reply to the user is written in a chosen language. A `UserPromptSubmit` hook (`~/.claude/hooks/lang-mode.sh`) re-states the rule on every turn while the flag file `~/.claude/lang` holds a language name, so the setting survives restarts and context compaction.

The flag is global, not per-project: a language belongs to the person, not the repo.

## Toggle

Run these commands literally.

| Request | Do this |
|---|---|
| `/lang <language>` | `printf '%s\n' '<language>' > ~/.claude/lang`, then confirm **in that language** |
| `/lang off` | `rm -f ~/.claude/lang`, then confirm in English |
| `/lang` (bare) | `cat ~/.claude/lang` and report it; if missing, say language mode is off and ask which language |

**Plain-language requests map onto the same rows.** "Reply in Spanish", "answer me in Dutch from now on" → row 1. "Stop that, English please", "go back to English" → row 2. "What language are you in?" → row 3. The words `/lang` are not required; only the intent is.

**Switching from one language to another** is row 1 again — write the new flag, confirm in the new language. No farewell in the old one.

After writing the flag, switch language immediately in the same reply — do not wait for the hook to fire on the next turn.

**If a command fails** (cannot write, cannot delete, flag holds garbage): say so plainly in English, report the state you actually observed, and do not claim the switch happened. A silent failure here means the user believes a setting is on when it is off.

## What changes, and what does not

**Translate:** your prose to the user — explanations, questions, summaries, headings.

**Never translate:**
- code, and anything inside a code fence
- file paths, commands, flags, env vars
- identifiers, type names, function names, error strings
- quoted tool output, log lines, test names
- anything written for a reader who is not the user: commit messages, PR text, issue and review comments, chat messages to a team, docs and code comments committed to a repo (unless the user asks)

The rule is who reads it. Language mode is about talking to **this user**. Text that leaves this conversation keeps the language its audience expects.

This splits a single reply. When you show the user a commit message, a log line or a file you drafted, the quoted block keeps its own language and the prose around it is translated.

A path or a command that gets "helpfully" translated stops working. Keep them byte-exact.

## Honesty about fluency

Some languages you handle well. Others — constructed languages (Lang Belta, Klingon, Sindarin), low-resource languages, heavy dialects — you do not.

If you are not fluent: **say so once, in the confirmation reply itself, then continue.**

The confirmation reply IS the first reply after the switch, so it carries both jobs: confirm in the new language as best you can, and add the fluency note in English directly under it. The "confirm in that language" row does not ask you to sound fluent — it asks you to start. Once the note is given, do not repeat it on every later reply.

Then: mix in English where you must and mark it. Give a plain-English version underneath when the content is operational (a command to run, a decision to make).

Never fake fluency. A confident wrong sentence is worse than an honest mixed one.

## Stacking with the output style

The output style still wins on **shape** — length, tone, structure, how many options to offer. Language mode only changes **which language** that shape is written in. A terse style stays terse in Spanish.

## If the hook is not installed

The skill alone lasts one turn. Check that `~/.claude/settings.json` registers `~/.claude/hooks/lang-mode.sh` under `UserPromptSubmit`. Without it the language silently reverts after a long session. If it is missing, say so and offer to add it.

## Red flags

- Reverting to English mid-session without being asked → the hook is not firing; check it.
- Translating a command, path, or identifier → revert it; those are never prose.
- Writing fluent-sounding text in a language you barely know → stop, add the honesty note.
- Switching language because of the user's **name**, their locale, or a language they merely mentioned → only `/lang` and an explicit request switch the language.

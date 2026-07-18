---
name: dog
description: Dog mode, aka "walking the dog" — Claude writes no code; it walks the developer through a coding task one step at a time while the developer types everything. Use when the user types /dog, /dog off, says "walk me through", or asks for dog mode.
version: 1.0.0
---

Dog mode: you are the guide, the developer is the one holding the keyboard. You never edit files or run mutating commands — a PreToolUse hook (`~/.claude/hooks/dog-mode-guard.sh`) enforces this while the flag file `.claude/dog-mode` exists in the project. You read code and run read-only verification; the developer writes every line.

## Toggle

- `/dog off` → run `rm -f .claude/dog-mode`, confirm dog mode is off, and stop.
- `/dog <task>` → run `mkdir -p .claude && touch .claude/dog-mode`, then start the walk for `<task>`.
- Bare `/dog` → create the flag the same way, then ask what task to walk through.

The flag is per-project and persists across sessions. If you are ever denied a tool call with a 🐕 message you didn't expect, tell the user dog mode is active and offer `/dog off`.

## The walk

1. **Sniff around first.** Read the relevant code until you understand the task — do not give a step you haven't verified against the actual codebase. Then sketch the route in a short paragraph: which files you'll visit, in what order, and what the destination looks like (e.g. "we'll add the struct in `src/x.rs`, wire it into `mod.rs`, then write the tests").

2. **One step at a time.** Each step:
   - names the exact file and location (function, line area, "after the `impl` block");
   - describes *what* to write and — most importantly — *why*: the reasoning is the point of the mode;
   - may include a short illustrative snippet only when the syntax is non-obvious (a trait bound, a lifetime, a macro), but never a complete drop-in block. The developer types everything.
   - **snippets are code and nothing but code.** A snippet must be real, compilable code — never a placeholder comment standing in for code (`trace!(/* the line here */)` won't compile), and never your reasoning embedded as `//` comments. All of the *why* lives in the chat prose outside the code fence. Assume the developer pastes snippets verbatim: anything inside the fence that isn't code becomes a compile error or clutter in their file.

3. **Wait.** Give exactly one step, then stop and wait for the developer to say they've done it. Questions and detours are part of the walk — answer them, and only then return to the route.

4. **Check the work.** When they report back: re-read the changed file, and run read-only verification as appropriate (`cargo check`, `cargo test <name>`, `cargo clippy`, `git diff`). Give concrete feedback. If something is wrong, explain *why* it's wrong and let the developer fix it — do not fix it for them, and do not paste the corrected code unless they're stuck and ask.

5. **Next step.** Repeat until the route is walked. Then run the full test suite (read-only), summarize what was built and what the key ideas were, and ask whether to `/dog off`.

## Conduct

- Never call Edit, Write, or NotebookEdit, and never run mutating shell commands. The hook will deny them with a 🐕 message; if that happens, convert what you were about to do into a step for the developer instead.
- The only files you may touch are the flag file itself (the toggle commands above are carved out by the hook).
- Project standards still apply to the steps you dictate — in pkcore that means doc tests on public items, unit tests per CLAUDE.md, no `unwrap()`/`expect()`/`panic!()` in library code, and test names without a `test_` prefix.
- Pace for learning: if the developer is breezing through, offer slightly bigger strides; if they're struggling, slow down and explain the underlying concept before the next step.

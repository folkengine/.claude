# Tutorial template

Write the tutorial at the end of the walk (Phase 7), after dog mode is
off. Save it in the real checkout, not the worktree, at
`<docs-dir>/walkthrough/<feature-slug>.md`. Find `<docs-dir>` the way
`/epic` does (where design markdown already lives; default `docs/`).

Sources, in order of trust: the code at `T`, the route file, the design
doc, the conversation. A reader who never did the walk must be able to
follow it.

Rules:

- **Bullets first.** One idea per bullet. Paragraphs only for a chain of
  reasoning.
- **Pin every link to `T`:** `https://github.com/<owner>/<repo>/blob/<T>/<path>#Lx-Ly`.
  Never link to a branch; `main` moves on.
- **Excerpts come from `T`** (`git show <T>:<path>`), never from memory,
  and never from the developer's version. Keep each under 25 lines; mark
  cuts with the language's line comment and `…`.
- **Use the steps as walked.** If a step changed during the walk, write
  the version that worked, and say what changed.

````markdown
# Rebuilding <feature>

- **What it does:** <one or two bullets, in domain words>
- **Commit:** [`<short-T>`](https://github.com/<owner>/<repo>/commit/<T>) — <subject>
- **Design doc:** [<name>](<relative link>) <or "none">
- **Deep dive:** [<deconstruct pack>](<relative link>) <or drop this line>
- **Steps:** <N>, in the order <source of the order>

## Before you start

- Create a worktree at the parent commit:

  ```
  git worktree add --detach .claude/rewind/<short-T> <P>
  ```

- Run the tests there with `<test command>`.
- You type the core logic. The other files come in with the copy-in
  command at each step.

## Step <N> — <title>

- **You build:** <what, in which file>
- **Copy in first:**

  ```
  git -C .claude/rewind/<short-T> checkout <T> -- <paths>
  ```

- **Paste:** <each paste block from the route (test functions, no-decision
  hunks): its file, where it goes, and the code from `T`> <or drop this
  line>
- **Why:**
  - <reason>
  - <reason>
- **The real code** ([`<path>#Lx-Ly`](https://github.com/<owner>/<repo>/blob/<T>/<path>#Lx-Ly)):

  ```<lang>
  <excerpt from T>
  ```

- **Done when:** <tests | build | what to look for>

## Questions from the walk

- **Q:** <question the developer asked>
  - **A:** <answer, with a permalink if it points at code>

## Where my version differs

<Only if the developer asked for it. One bullet per meaningful difference
between their code and `T`, and why both work.>
````

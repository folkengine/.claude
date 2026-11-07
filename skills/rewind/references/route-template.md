# Route template

The route is the plan for one walk. Write it at setup (Phase 5), after the
developer has created the worktree and before dog mode goes on. Save it at
`<repo>/.claude/rewind/<short-T>.route.md`, beside the worktree, never in
it. Claude cannot edit it once dog mode is on; on resume, progress is
worked out from the worktree, not from this file.

Fill every `<…>`. Keep it bullets-first. Copy names and excerpts from `T`
(`git show <T>:<path>`), never from memory.

````markdown
# Rewind route — <feature title>

- **Repo:** `<absolute path to the real checkout>`
- **Target (T):** `<full SHA>` — <commit subject>
- **Parent (P):** `<full SHA>` — <commit subject>
- **Worktree:** `.claude/rewind/<short-T>/`
- **Design doc:** `<path at P, or "none">`
- **Deconstruct pack:** `<path, or "none">`
- **Order source:** <PR commits | design doc work items (<which section>) | data flow>
- **Build:** `<build command, run inside the worktree>`
- **Test:** `<test command, run inside the worktree; how to run one test by name>`

## Core files

The developer types these. A checkout never names them.

- `<path>` — <one line: which rule or logic of the feature lives here>

## Support files

Brought in by a copy-in command, at the step named.

- `<path>` — step <N> — <docs | book content | lock | config | fixture | test file | wiring only>

## Steps

### Step <N> — <title>

- **Check kind:** <tests | compiles | read> — <reason, required when not `tests`>
- **Copy in:**

  ```
  git -C .claude/rewind/<short-T> checkout <T> -- <path> <path>
  ```

  or "none".
- **Paste:** <for each block: file, symbol, and what it is (test functions
  from a `#[cfg(test)]` block, or a no-decision hunk such as a `mod` line,
  `use`, derive, field, variant, or forwarding match arm)>, or "none".
- **Build:** <core file> — <where in it (after which item, inside which
  `impl`)> — <what to write, in one or two lines>.
- **Names:** exact public signatures from `T`, one per bullet:
  - `<signature>`
- **Why:**
  - <reason, with a permalink: [`path#Lx-Ly`](https://github.com/<owner>/<repo>/blob/<T>/<path>#Lx-Ly)>
- **Done when:** <the test names that must pass | the build command | what
  Claude reads in the diff>.
````

# Critique: `/domain-kernel` skill

> Produced by `/critique` on 2026-08-18. Target: `skills/domain-kernel/` —
> SKILL.md, 5 reference docs, 5 assets, 1 script. All read; the script,
> clippy.toml, deny.toml, CI grep, and WIT asset were **executed against
> synthetic crates**; every finding below was reproduced, not eyeballed.

## Verdict

This is a genuinely well-conceived skill with an excellent prose layer — the invariants doc, the hexagonal comparison, and the charter material are honest, precise, and more actionable than the canonical published writing on this pattern's ancestors (see "Sources compared" below) — sitting on top of an enforcement layer that does not honor the skill's own thesis. SKILL.md:36-37 stakes everything on making the kernel constraint "**assessable and enforceable**, not aspirational," yet the shipped machinery is tuned to one specific codebase: a kernel that leaks `serde_json::Error` through its public API and writes files in production code passes *every automated gate this skill ships* — the checker script, the clippy config, the cargo-deny bans, and the CI job — while the niche fork `serde_yaml_bw` is banned in all four places. The worst problem is that the "deterministic checker" and the "testable definition of a kernel" both return green on crates that flagrantly violate the invariants they exist to enforce.

## Charge sheet

**FATAL — the enforcement stack shares one blind spot: it bans the author's dependencies, not the invariant.** `invariants.md:33-34` defines the violation class as "a concrete *format* crate (`serde_yaml`, **a specific JSON lib**)". But `serde_json` — the most common format crate in the Rust ecosystem — appears in none of the four ban lists: `check_purity.py:24-27`, `deny-bans.toml:16-31`, `kernel-purity.yml:17` (`BANNED=`), and clippy.toml (no format-crate bans at all, by design). Verified: a crate with non-optional `serde_json` and `pub fn to_json(&self) -> Result<String, serde_json::Error>` produced **zero findings** from the checker. Same gap for `serde_cbor`/`bincode`/`rmp`, and for the invariant-#1 "randomness" clause — no gate anywhere catches `rand`/`thread_rng` (clippy.toml bans only `SystemTime::now`; `Instant::now` also unbanned). The assets at least say "adapt the list" (clippy.toml:4, deny-bans.toml:9); the script hardcodes its list with no such instruction, and Mode A step 1 (SKILL.md:64-70) runs it as *the* deterministic check. Anyone outside the author's serde_yaml-flavored card-game stack gets a clean report on a dirty crate on first real use.

**SERIOUS — `check_purity.py` suppresses all I/O findings after the first `#[cfg(test)]` in a file.** Line 135: `in_test_mod = True` is set and **never reset** (the comment admits "crude: suppress the immediately following block" — it suppresses the rest of the file). Verified: `std::fs::write("generated/…")` and `std::env::var` in a public function *below* a test module produced no findings — and that hardcoded-path case is the exact failure mode `invariants.md:18-19` calls out. Any file with a mid-file test module, or `#[cfg(test)]` helpers above production code, goes dark.

**SERIOUS — the public-signature regex misses nested generics.** `check_purity.py:117`: `Result<[^>]*\b(...)::Error` — `[^>]*` cannot cross the `>` in an inner generic. Verified: `pub fn to_many(&self) -> Result<Vec<String>, serde_yaml::Error>` (line 9 of my test crate) was **not flagged** while the flat `Result<String, serde_yaml::Error>` on line 7 was. `Result<Vec<T>, FormatError>` is a completely ordinary shape; this is a false negative on hard leaks, the category the skill says to "spend effort on" (SKILL.md:162-164).

**SERIOUS — the exit-code contract green-lights flagrantly impure crates.** Docstring `check_purity.py:13`: "Exit code: 0 if no HARD findings, 1 otherwise (**so CI can gate on it**)." But direct I/O is only ever WARN (lines 143-145). Verified: a crate whose only public function does `std::fs::write` + `std::env::var` + `SystemTime::now` **exits 0**. A CI gate built on this script, as the docstring invites, passes a crate that violates invariant #1 — the invariant the whole skill leads with — in every line of its body.

**SERIOUS — the "testable definition of a domain kernel" does not test invariant #3.** SKILL.md:103-105 and rust-enforcement.md:69-70 call `kernel-purity.yml` the testable definition. Its tree assertion (lines 32-37) runs `cargo tree --no-default-features` — which strips default features *before* checking. Verified: with `default = ["serialization"]` pulling `serde_yaml` — the violation the skill itself calls "the most common and highest-impact" (invariants.md:49-51) — the purity job's check **passes**. The job proves purity is *achievable via a flag*, not that the crate is pure by default; a regression re-adding default features sails through. (The companion `lints` job's cargo-deny run does catch it — verified — but only if the user separately merged deny-bans.toml into a deny.toml, a manual step the workflow doesn't verify.)

**SERIOUS — deny-bans.toml makes a false factual claim.** Lines 33-34: "If any of these are legitimately needed behind an opt-in feature, cargo-deny **will still flag them in a default build** — which is exactly the signal you want." Verified false on cargo-deny 0.20.2: with `serde_yaml` optional behind a non-default feature, `cargo deny check bans` reports `bans ok`. The tool is feature-aware; the comment describes behavior that doesn't happen and will confuse anyone reasoning about what their green deny check actually proved.

**MINOR — the recommended opaque error is not `Send + Sync`.** rust-enforcement.md:79-81 and invariants.md:39: `CodecError(Box<dyn std::error::Error + 'static>)`. Without `+ Send + Sync`, downstream consumers can't use it with `anyhow`, `?` across threads, or any async framework — ironic for a kernel whose charter promises to back services. One-token fix.

**MINOR — clippy.toml's "drop at the crate (or workspace) root" advice (clippy.toml:1) will break workspace siblings.** With `-D warnings`, a workspace-root config bans `Path`/`std::fs` for the adapter crates too — the crates whose entire job is to own those. The file says "trim entries" but never warns about workspace blast radius.

**MINOR — assorted:** `hosts.md:51` "(omit `--no-nodejs-compat` for Node)" annotates a flag the shown command doesn't contain — unparseable as written. `hexagonal-comparison.md` devotes half its length to "ECC's `hexagonal-architecture` skill," an external artifact not present in this repo or environment — unverifiable for any reader who isn't the author. SKILL.md:66 `python scripts/check_purity.py` is a relative path in an environment where cwd is not the skill dir. The checker's `#[cfg(test)]` match (line 134) scans the raw line, so a comment mentioning it flips suppression on.

## What survives

The prose layer is the real asset and it holds up under adversarial reading: `invariants.md` (path-taking-as-I/O-policy, hard-vs-cosmetic grading), the hexagonal comparison's WIT-copy-semantics honesty (lines 80-84), and `charter.md`'s "search, don't assert from memory" self-dating discipline are all correct and unusually candid. Two non-obvious technical claims verified true: `cargo test --test <name>` with `required-features` **errors** under empty defaults exactly as SKILL.md:100-102 warns (reproduced), and `trick-taking.wit` parses clean under `wasm-tools` with a well-modeled hidden-info projection. clippy.toml works as advertised — all three planted violations caught. The README house rule is satisfied. Don't rewrite any of this.

## Fix order

1. **check_purity.py** — add `serde_json`/`serde_cbor`/`bincode`/`rmp-serde` and `rand`/`getrandom` to `BANNED_CRATES`; replace the `Result<[^>]*` regex with a match for `(BANNED)::Error` anywhere on a `pub fn` line; reset `in_test_mod` (or drop the flag and accept test-mod false positives, which the docstring already disclaims); either promote direct-I/O findings to HARD or delete the "CI can gate on it" sentence. This one file is four of the findings.
2. **kernel-purity.yml** — add a second tree assertion *without* `--no-default-features` (or grep `Cargo.toml` for a non-empty `default`), so the "testable definition" actually tests pure-by-default.
3. **deny-bans.toml:33-34** — replace the false claim with the truth: feature-gated optional deps pass a default-features deny check; run `cargo deny check bans --all-features` if you want them surfaced.
4. Add `Send + Sync` to the `CodecError` box in both docs; add a workspace-scope warning to clippy.toml; fix the jco parenthetical; make the ECC comparison self-contained or mark it as author-context.

## Sources compared

The verdict's "more actionable than the canonical published writing" claim was checked on 2026-08-18 against the three text ancestors of this pattern:

- Alistair Cockburn, *Hexagonal Architecture* (2005, alistair.cockburn.us/hexagonal-architecture/) — motivation, diagrams, port granularity advice; no machine-checkable invariants, no violation-detection tactics, no severity grading, no enforcement tooling.
- Robert C. Martin, *The Clean Architecture* (2012, blog.cleancoder.com) — the Dependency Rule and layer diagram; interpretive only, no detection tactics, no severity grading, no tooling, no stated limits.
- Mark Seemann, *Functional architecture is Ports and Adapters* (2016, blog.ploeh.dk) — the strongest of the three: real code examples and an honest limit ("it's up to you whether a particular function is pure or impure" outside Haskell); still no detection tactics, grading, or CI enforcement.

`invariants.md` supplies all three missing things: per-invariant detection tactics, hard-vs-cosmetic grading, and a lint + CI + sandbox enforcement path — that concreteness is the basis of the comparison (even though, per the charge sheet, the shipped implementations of those checks are buggy).

Not compared: Gary Bernhardt's *Functional Core, Imperative Shell* (2012) is a paywalled screencast; only its landing page is public, so no honest text comparison was possible.

---

# Addendum: critique of the name "domain kernel"

> Produced by `/critique` on 2026-08-18. Target: the **term itself**, not the
> skill. Sources read: `SKILL.md`, `references/charter.md`,
> `references/hexagonal-comparison.md`, `assets/kernel-purity.yml`,
> `scripts/check_purity.py`. Line counts and the prior-art claim were checked,
> not eyeballed; the search results below were run on 2026-08-18.

## Verdict

"Domain kernel" is a decent name wearing one big flaw. Both words are borrowed, and both point the reader somewhere else. The worst problem: in almost all of computing, a **kernel is the one part that is allowed to do I/O** — files, network, devices, privilege. This pattern's rule #1 (`SKILL.md:22-24`) is **no I/O at all**. The name's loudest meaning says the opposite of the pattern's loudest rule. That is why the docs must spend 147 lines telling readers what the thing is not, versus 14 lines saying what it is.

## Charge sheet

**FATAL — "kernel" means "the I/O part"; this pattern means "the no-I/O part".** `SKILL.md:22-24` mandates "no filesystem, network, clock, randomness, or environment access of its own." Compare the everyday meanings of *kernel*: OS kernel (owns devices and syscalls), Jupyter kernel (a live process that runs code), CUDA/GPU kernel (a function launched on a device), microkernel (still owns IPC and scheduling — and `charter.md:31-35` concedes microkernel is "the closest structural neighbor"). Every one of those is an *effect-doing* thing. Consequence: any reader who has not yet read the charter forms the inverted model on first contact, and the name must be undone before it can be used.

**SERIOUS — the name carries the two borrowed legs and drops the new one.** `charter.md:12-17` states the entire reason the term exists: the third leg — a language-neutral boundary where purity is enforced by the runtime ("purity-as-physics"). Neither "domain" nor "kernel" says pure, portable, or sandboxed. Both words name the part shared with the prior art. The name markets the unoriginal two-thirds.

**SERIOUS — the name needs a bodyguard of disclaimers.** Verified line counts: `references/hexagonal-comparison.md` is 122 lines, and `hexagonal-comparison.md:116-119` states it exists because "without an explicit entry they will collapse 'domain kernel' into 'hexagonal with new branding.'" Add `charter.md:22-46`, a 25-line defense against five look-alikes. That is ~147 lines of *not-that* against 14 lines of definition (`SKILL.md:21-34`). A name needing a ten-to-one defense is losing the argument before it starts.

**SERIOUS — the search space is fully occupied even though the exact phrase is not.** `charter.md:24` claims "The term is mostly unclaimed." Verified by search on 2026-08-18: querying `"domain kernel" software architecture pattern` returns DDD **Shared Kernel**, Core Domain, and **microkernel** — precisely the three neighbors the charter must fight — and nothing resembling this pattern. Querying outside software returns ML kernel methods and domain adaptation. The phrase is unclaimed the way an empty seat in a packed row is unclaimed. A reader who hears the term and looks it up lands on the wrong pattern, not on nothing.

**MINOR — the skill's own filenames vote for a different word.** The enforcement artifacts are named after *purity*, not *kernel*: `scripts/check_purity.py`, `assets/kernel-purity.yml`, and the job `Assert pure dependency tree is I/O-free` (`kernel-purity.yml:31`). When the tooling keeps reaching for "pure," that is the word doing the real work.

**MINOR — "domain" is DDD-loaded in both directions.** To a DDD reader, "domain" + "kernel" parses as a compound of two DDD terms, so the first guess is Shared Kernel. To a non-DDD reader, "domain" is either meaningless or means DNS.

## What survives

"Kernel" gets three things right: small, central, and *must not break* — and the pattern genuinely mandates a narrow boundary (`SKILL.md:31-34`; Mode C flags over-broad kernels). The term composes well in real use: "kernel purity," "kernel-shaped," "domain-kernel charter," and it is applied consistently across the toolbox (`skills/epic/references/methodology.md:12,43`). Two words, sayable, and no one owns the exact phrase in architecture. Do not discard it on style grounds.

## Fix order

1. **Decide: keep or rename** (see below).
2. **If keeping:** add one sentence to `SKILL.md` directly under the definition that kills the OS-kernel read head-on — e.g. *"Unlike an OS kernel, this kernel has no privileges: it is the one part that may not touch the outside world."* That single line does more work than the 147 defensive lines and permits shrinking them.
3. **Lead every definition with purity.** `SKILL.md:21` currently reads "one domain's logic, isolated." Make it "one domain's *pure* logic." The word doing the work should land before the word causing the confusion.
4. **Correct `charter.md:24`.** "Mostly unclaimed" is misleading. State that the exact phrase is free but the search results are owned by Shared Kernel and microkernel — which is *why* the positioning section exists.

## The decision

- **Option A — keep "domain kernel", add the anti-OS-kernel sentence.** Cheap. The term already spans 6 skills and the README. Keeps the brand and patches its worst read.
- **Option B — rename to "pure domain core"** (or "sealed domain core"). States the invariant out loud, collides with no OS/GPU/Jupyter meaning, and matches what the tooling is already called. Cost: renaming a skill, a slash command, a charter template, and cross-references in 6 other skills.

**Recommendation: A.** The flaw is real but it is a *first-contact* flaw, and one sentence fixes first contact. B buys clarity obtainable for one line and charges a full-toolbox rename for it.

## Sources checked

- [Shared Kernel Pattern in Domain-Driven Design](https://mehmetozkaya.medium.com/shared-kernel-pattern-in-domain-driven-design-ddd-21cba2a9f92a)
- [An Overview Of MicroKernel Architecture Pattern](https://www.c-sharpcorner.com/article/an-overview-of-microkernel-architecture-pattern/)
- [Open Group: DDD Strategic Patterns](https://pubs.opengroup.org/architecture/o-aa-standard/DDD-strategic-patterns.html)
- [An introduction to domain adaptation and transfer learning](https://arxiv.org/pdf/1812.11806)

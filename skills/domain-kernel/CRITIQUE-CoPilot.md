Domain-Kernel Skill Audit Memo

Scope
This memo evaluates the domain-kernel skill in `skills/domain-kernel/SKILL.md`, the supporting invariants in `skills/domain-kernel/references/invariants.md`, and the shipped enforcement assets and critique in `skills/domain-kernel/CRITIQUE.md`.

Summary
The domain-kernel concept is strong and unusually concrete. It is more disciplined than most architectural writing because it defines invariants, classifies leaks, and proposes enforceable boundaries. However, the shipped implementation does not yet satisfy the core promise of the skill: it is not reliably assessable or enforceable in real Rust crates. The risk is not conceptual drift; it is false confidence. The tooling can produce green results on crates that violate the very invariants it claims to enforce.

Findings
1. Critical — The enforcement stack does not enforce the invariant it claims to enforce.
The skill claims to make the kernel constraint assessable and enforceable, not aspirational. Yet the critique documents that the automation is tuned to a narrow dependency set and misses common format crates, notably serde_json. This is a direct mismatch between the invariant (“no format/transport crate in the public API”) and the shipped checks. The same issue applies to common randomness dependencies and other real-world violations.

2. Critical — The “testable definition of a kernel” is not testing the actual default build.
The workflow in `skills/domain-kernel/assets/kernel-purity.yml` checks the no-default-features tree, but the invariant in `skills/domain-kernel/references/invariants.md` states that the default crate should already be pure. A crate with default = ["serialization"] can pass the purity job while violating the pattern’s central “pure by default” rule.

3. High — The checker can exit green on impure crates.
The script in `skills/domain-kernel/scripts/check_purity.py` describes CI-gate behavior but assigns direct I/O findings to a warning class. Under the documented contract, a crate with filesystem, environment, and clock access can still exit successfully. This is incompatible with a “gate in CI” promise.

4. High — The checker suppresses broad classes of violations.
The script tracks an in_test_mod flag that is set and never reset; it suppresses all subsequent findings in the same file, allowing substantive I/O violations after a test module to disappear from the result. This creates large false negatives.

5. Medium — The signature check misses ordinary nested generic cases.
The regex used for public error leaks cannot cross an inner generic boundary. A common public signature like Result<Vec<T>, FormatError> can evade detection even though it is precisely the sort of coupling the skill says must be caught.

6. Medium — The naming creates an avoidable conceptual mismatch.
The term “domain kernel” is not wrong, but it collides strongly with the everyday meaning of kernel as the privileged I/O part of a system. This pattern is the opposite: the kernel is the no-I/O part. The docs must work harder to correct that first impression than they should need to.

Strengths
- The conceptual model is disciplined and unusually precise.
- The invariant set is more actionable than most architecture guidance.
- The distinction between hard leaks and cosmetic leaks is sound.
- The boundary/WIT discussion and the charter logic are better than generic “hexagonal” writing.

Assessment
This skill is conceptually promising but operationally premature. The prose layer is strong enough to teach the idea. The automation layer is not strong enough to protect the idea. At present, the skill risks creating false confidence rather than real enforcement.

Recommendation
The skill should not be shipped as an enforceable standard until the following are fixed:
- correctness of the checker
- default-build purity in CI
- removal of suppressed false negatives
- direct I/O findings as hard failures
- corrected naming language to kill the OS-kernel misread immediately

Conclusion
This is a valuable architecture skill with an untrustworthy enforcement implementation. The design idea deserves to live on; the current tooling does not yet merit confidence as a gate for real repositories.

Approval status
Not approved for production use as an enforcement skill.
Conditional approval only for conceptual guidance and architecture education, pending enforcement repair.


---

## Resolution — 2026-08-28

All six findings confirmed against the source, and all six were already recorded
in `CRITIQUE.md` (2026-08-18), which additionally found four the memo missed —
including a false factual claim in `assets/deny-bans.toml` about cargo-deny's
feature awareness. This memo is corroboration, not new information.

Findings 1–5 are fixed and covered by `scripts/test_check_purity.py`; see the
Resolution section of `CRITIQUE.md` for the per-finding detail and verification.

Finding 6 (naming) is addressed without a rename. The name "domain kernel" is
kept deliberately — it is load-bearing across six skills and the README, and the
flaw is a first-contact one. `SKILL.md` now leads with "one domain's *pure*
logic" and carries a "Not an OS kernel" callout under the definition, stating
that this kernel has no privileges and is the one part that may not touch the
outside world. `charter.md`'s misleading "mostly unclaimed" claim is corrected.

All five of the memo's stated conditions for approval as an enforcement skill are
met: checker correctness, default-build purity in CI, removal of the suppressed
false negatives, direct I/O as a hard failure, and corrected naming language.

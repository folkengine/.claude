# Decision record — `<kernel-name>` boundary

*One per kernel. It records why the boundary sits here, and which wider and
narrower boundaries were rejected. Borrowed terms are explained in the
domain-kernel skill's glossary.*

> Template — replace the bracketed parts; keep the structure.

| Field | Value |
|---|---|
| Kernel | `<kernel-name>` |
| Status | <Proposed / Accepted / Replaced by …> |
| Date | <YYYY-MM-DD> |
| Contract | `<namespace:pkg@x.y.z>` |

## 1. Boundary chosen

<The domain in three words.>

<One paragraph: what the kernel owns — its state, actions, events and
projections — and what it leaves to the shells.>

## 2. Wider boundary rejected

<The next-larger boundary you considered, e.g. "rules and play resolution in
one kernel".>

<Why it was rejected: which rules would then belong to more than one
domain.>

## 3. Narrower boundary rejected

<The next-smaller boundary you considered.>

<Why it was rejected: which rules consumers would then copy into their own
code, because the contract was too narrow to be worth calling.>

## 4. How special this logic is (DDD: *subdomain* type)

Pick one and say why:

- **Core** — it sets the business apart. Expect pressure to keep it vague.
- **Supporting** — needed and specific to us, but not what sets us apart.
- **Generic** — the same everywhere. The easiest kernel to justify.
- **An algorithm the domain uses** (DDD: *cohesive mechanism*) — not rules
  that mean something. Pure and packaged like a kernel, but labeled as not a
  *domain* kernel.

<Choice and reason.>

## 5. What must be all-or-nothing

<List the operations that must never half-happen.>

For each one: is it inside this kernel's single `apply`? If it crosses into
another kernel, name the in-between states that make the crossing safe
(invariant 7 in the domain-kernel skill).

**Intra-kernel decision.** <Does one `apply` change the whole state at once,
or one group of it — one account, one hand? Say which, and why.>

## 6. Contract change policy

<Link to this kernel's CONTRACT_POLICY.md.>

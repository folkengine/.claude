---
name: muratori
description: Alias for the `reusability` skill. Use ONLY when the user types `/muratori` or `/muratori <target>` verbatim. All other triggering — "how reusable is this API", "Muratori review", "evaluate this library's API design", "retained vs immediate mode" — belongs to `reusability`; do NOT trigger this skill for them.
---

# /muratori

This is an alias. The skill lives at `reusability`.

Invoke the `reusability` skill and follow it exactly, with one substitution:
treat `/muratori` and `/muratori <target>` as `/reusability` and
`/reusability <target>`.

The audit filename is `REUSABILITY_AUDIT.md` in every case. Do not write
`MURATORI_AUDIT.md` — one canonical filename, refreshed in place, is the
point of the audit family.

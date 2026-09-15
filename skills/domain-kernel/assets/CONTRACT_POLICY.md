# Contract change policy — `<namespace:pkg>`

*How this kernel's contract changes, and what consumers can count on. Ship
it next to the WIT package.*

> Template — replace the bracketed parts; keep the structure.

## 1. Package and version

`<namespace:pkg@x.y.z>`. The version is part of the package name in every
`.wit` file. A breaking change bumps the major version. An additive change
bumps the minor version.

## 2. What counts as breaking

Treat a change as **breaking** (major bump) if it:

- removes or renames an export, a type, a field, or an enum or variant case;
- narrows a type (e.g. `u32` → `u16`);
- adds a field to a record, or a case to an enum or variant — consumers see
  a new type;
- changes what an existing function returns for the same input.

The last point matters most for a kernel: **a rule change is a contract
change, even when no type changes.** <Say whether this project treats a rule
change with unchanged types as major or minor.>

A change is **additive** (minor bump) if it only adds a new function or a
new interface, and leaves every existing one unchanged.

## 3. Support window

<How long an old major version stays supported after a new one ships, e.g.
"two minor releases or 90 days, whichever is longer".>

Hosts pinned to different *minor* versions of one major version must work
together. A host on a different *major* version must fail loudly when it
loads the component — never silently.

## 4. Who decides

<The one party that approves contract changes. A kernel has one owner, not a
committee of consumers.>

<How a consumer asks for a change.>

## 5. How consumers hear about changes

<The channel: a changelog file, release notes, a mailing list.>

<How much notice comes before a breaking release.>

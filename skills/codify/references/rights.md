# Rights check — before you extract

Not legal advice. This is a checklist for establishing what a publisher's terms
actually say, so the user can make an informed call. When the answer is unclear,
the answer is **ask the user**, not **assume permissive**.

## Why this step exists

Parsing a specification into YAML is:

- a **modification** of the work, and
- a **derivative work** of it, and
- potentially a **substantial extraction** from a database of facts.

A licence that permits "reproduction without modification, for informational
purposes only" therefore does not obviously cover it — even though the PDF was
free to download.

## What to look for, in order

1. **The disclaimer page inside the document.** Usually page 2. Quote the
   operative sentence verbatim.
2. **The download page.** Often carries a narrower grant than the document.
3. **The site imprint / legal notice.** Frequently the strictest of the three,
   and the one people never read.
4. **A separate patent or IPR policy.** Copyright governs the *document*;
   patents govern *implementing* it. They are different questions with different
   answers.
5. **Trademark.** Names and logos are usually registered separately. Do not name
   the output after the standard in a way that implies endorsement.

## Classify the source

| Class | Signals | Output default |
|---|---|---|
| **open** | CC-BY / CC0 / public domain / an explicit right to create derivative works; IETF RFCs; most government-published regulations | normal repo file, committable |
| **restricted** | "informational purposes only", "without any modification", "private use only", "written permission from the publisher required", partnership or membership required for exploitation | gitignored path, local use only |
| **unknown** | no notice found, or an ambiguous one | treat as **restricted** |

## The distribution ladder

Risk rises sharply at the point of distribution, not at the point of parsing.

| Action | Exposure |
|---|---|
| Parse; keep the YAML on your own machine; use it in your own tests | lowest — no distribution |
| Same, inside an organisation that already licences the standard | usually already answered by an existing membership; check |
| Ship the **extractor**, not the extracted content — users run it against documents they downloaded themselves | low; the standard mitigation |
| Publish the extracted YAML publicly | highest — distribution of a derivative, plus possible substantial database extraction |
| Sell or build a commercial product on it | typically needs an explicit exploitation licence |

**Parser-not-data** is the architecture to reach for when the source is
restricted and the work needs to be shared: distribute the extraction recipe and
the checker, and let each user generate the YAML locally from their own copy.
`/codify` supports this directly — the extraction commands and the schema are the
shareable half.

## Facts versus expression

Copyright protects expression, not facts. In a spec, the split usually runs:

- **Closer to fact / interface**: identifiers, parameter names, enum literals,
  error and service ids, multiplicities, numeric limits, state names.
- **Clearly protected expression**: prose rationale, requirement wording,
  explanatory text, diagrams, examples, and the selection and arrangement of the
  whole.

A verbatim YAML mirror preserves the arrangement as well as the text, so it sits
on the protected side of that line even where individual data points do not.
Note also that an EU-published standards body brings the **sui generis database
right** into frame, which protects systematic extraction from a collection
regardless of whether the individual items are copyrightable.

This is context for the user's decision — never a justification for proceeding
without one.

## Record it

Put the finding in the ruleset file, verbatim:

```yaml
meta:
  rights:
    class: restricted
    holder: <publisher>
    notice: >-
      <verbatim quote of the operative sentence>
    source_url: https://<where the notice appears>
    checked: 2026-08-25
    distribution: >-
      Local use only. Not to be committed or published without written
      permission from the publisher.
```

Then, when the class is `restricted` or `unknown`:

- write the output under a gitignored path,
- add the ignore entry if it is missing,
- and tell the user, in one sentence, what the notice says and what you did.

## What to offer the user

- **The publisher's own machine-readable artefacts** (XML schema, meta-model,
  ABNF, JSON) as a cleaner source than the PDF, if any exist.
- **A written permission request** for a specific, narrow use. Cheap to send, and
  it changes the position completely.
- **A free or low tier of membership**, where one exists and the use is narrow.
- **Routing through their organisation's legal team**, when this is work for an
  employer — the question is often already answered by an existing membership.

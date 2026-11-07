# The <subsystem> in plain words

> A front door to this folder for anyone who has not read <project>'s code
> or its design documents.
>
> - The DECON epics and the vectors are the precise version.
> - This page tells the same story without the precision, then defines the
>   words the epics lean on.
> - Go to [`MANIFEST.md`](MANIFEST.md) once this page makes sense.

## What <project> is
<!-- 5–8 bullets. What the whole tool does, for someone who has never seen
it. Introduce only the words this pack needs. -->

## What the <subsystem> adds
<!-- Bullets. The gap it fills, then what it does, as a short numbered list
of user-visible effects. Clear up any misleading name. -->

## One <unit>, start to finish
<!-- Take ONE real example from the repo (link the file). Show its input
verbatim. Then walk it through every epic in order, one bold heading per
epic: "**Planning ([DECON-02](DECON-02_Name.md))**", each with 3–8 bullets
and, where it helps, the real artifact it produces (a config line, a
generated snippet). Point out anything stale or surprising you saw on the
way. -->

## <A second case>
<!-- Optional: a second real example that shows the non-trivial path the
first one skipped (e.g. a non-empty input, an error). Call out traps. -->

## The words
| Word | What it means here |
|---|---|
| **<word>** | <one or two plain sentences> |
<!-- Every word an epic uses without defining it. Include the pack's own
words: golden vector, normative / informative, spec decision, DECON, and
the design doc's ID. -->

## How to read a DECON epic
<!-- One bullet per section, in the epic's order, saying what that section
is for. Copy from the epic template's section list. -->

## Where to go next
- [`MANIFEST.md`](MANIFEST.md): the index. Reading order, coverage, out of
  scope, and every spec decision in one table.
- [`vectors/README.md`](vectors/README.md): how the vector files are laid
  out and how to use them.
- [`APPENDIX_Engineering_Constraints.md`](APPENDIX_Engineering_Constraints.md):
  how the original was built and tested.
- <design doc, linked>: the original design.

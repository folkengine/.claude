# Extraction tactics and failure modes

Rule zero: **the extraction is an artefact, not a step.** Save it. Step 4 needs
it, and a claim of "verbatim" without it is unverifiable.

```
docs/       # the original documents, untouched
extract/    # the raw machine extraction, one file per document
<name>.yaml # the structured result
```

## PDF

```bash
pdftotext -layout "docs/spec.pdf" "extract/spec.txt"      # preserves columns
pdftotext -layout -f 12 -l 40 "docs/spec.pdf" -           # page range, to stdout
pdfinfo "docs/spec.pdf"                                    # page count, producer
```

`-layout` is not optional. Without it, a two-column page interleaves left and
right columns line by line and the text becomes unreadable garbage that still
looks plausible in a diff.

Alternatives when `pdftotext` mangles a document:

| Tool | Good for |
|---|---|
| `pdftotext -raw` | reading order when `-layout` splits a single column oddly |
| `mutool draw -F txt` | different engine; try when pdftotext drops glyphs |
| `pdfplumber` (Python) | tables, with per-cell coordinates |
| `qpdf --decrypt` | documents with an owner password but no user password |

### Known PDF failure modes

- **Repeating page furniture.** Headers, footers, page numbers, and copyright
  bars appear *between and inside* rules — a footer lands mid-sentence in any
  rule that spans a page break. `verify_ruleset.py` strips lines that repeat
  three or more times before comparing, and reports how many it dropped. Furniture
  that varies per page survives that filter, so check it when a long rule fails
  the verbatim check.
- **Hyphenation across line breaks.** `imple-\nmentation`. The checker's
  normaliser rejoins these; do not "fix" them in the YAML by hand in a way that
  differs from the source's actual words.
- **Ligatures.** `ﬁ` `ﬂ` `ﬀ` arrive as single characters. Normalise them, and do
  it the same way in the YAML and in the comparison.
- **Smart punctuation.** Curly quotes, en/em dashes, and non-breaking spaces.
  Keep whichever the source uses; the checker normalises for comparison.
- **Soft hyphens and zero-width characters.** Invisible, and they break exact
  matching. Strip `­`, `​`, `﻿`.
- **Tables rendered as positioned text.** Columns become runs of spaces. Use
  `pdfplumber` rather than guessing at column boundaries from whitespace.
- **Scans with no text layer.** `pdftotext` returns nothing or gibberish. Stop
  and say so. Do not transcribe by eye, and do not OCR silently — OCR output is
  not verbatim, and if the user wants it, it must be labelled as OCR in `meta`.
- **Redlines and change bars.** Struck-through text often still extracts. Check
  whether the document marks deletions, and whether the extraction preserves that
  marking. If it does not, the deleted text will look current.

## HTML / web specs

```bash
curl -sL <url> -o "docs/spec.html"
pandoc -f html -t plain "docs/spec.html" -o "extract/spec.txt"
```

Prefer the publisher's own single-page or plain-text edition when one exists.
Keep the fetched HTML in `docs/` so the extraction stays reproducible; a live URL
changes under you.

## RFCs and plain text

Already text — copy it into `extract/` unchanged. Preserve the section numbering
exactly (`4.2.1`), and note that RFC 2119 keywords (MUST, SHOULD, MAY) are
load-bearing: never normalise their case.

## Word / OpenDocument

```bash
pandoc -f docx -t plain "docs/spec.docx" -o "extract/spec.txt"
```

Watch for content in tracked changes, comments, and footnotes — `pandoc` handles
them inconsistently. Check whether the document has any before trusting the
extraction.

## XML / schema sources

If the publisher ships a machine-readable artefact, prefer it. It is cleaner
input, it needs no verbatim-prose checking, and it is a smaller derivative
footprint. Say so to the user before spending effort on PDF scraping.

The extraction is then a transformation, not a text dump, but the same rules
hold: keep the original in `docs/`, record the transform command in `meta`, and
never rename an identifier.

## Before you structure anything

Read the whole extraction. Then answer these, out loud:

1. How many numbered rules does the document itself claim to have?
2. How many separate numbering series are there?
3. Where does the normative content start and stop — which pages are front
   matter, index, or change log?
4. Does the document have deleted or reserved ids?
5. Are there tables, and did they survive extraction?

Structuring before answering these is the most common way a ruleset ends up
missing a whole series.

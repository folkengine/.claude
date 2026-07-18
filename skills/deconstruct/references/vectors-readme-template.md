# Golden vectors — format contract

Every file under `vectors/` was machine-extracted from the source repo at
the commit pinned in `../MANIFEST.md`, by running `<dumper command>` in the
source repo. Values are never hand-written. Regenerating at the same commit
must reproduce every file byte-identically.

## Envelope

```json
{ "epic": "DECON-NN", "behavior": "<slug>", "data": {} }
```

## Determinism rules

UTF-8, LF, 2-space indent, trailing newline. No timestamps. Arrays in domain
order. Fixed seeds (listed in the owning epic). Byte-identical across runs.

## Consuming

An implementation passes a vector iff computing the described behavior
yields data deep-equal to the file's `data` field. Field names inside `data`
describe the domain (defined per-file in the owning epic's Domain map);
they do not prescribe your API.

## Files
| File | Epic | Behavior |
|---|---|---|
| `<epic-slug>/<file>.json` | DECON-NN | <one line> |

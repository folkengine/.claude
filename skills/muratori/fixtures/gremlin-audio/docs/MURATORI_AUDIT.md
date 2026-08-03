# Muratori Audit — gremlin-audio

| | |
|---|---|
| Subject | gremlin-audio 0.3.1 — one central `Mixer` (1 constructor + 5 methods), plain-data scene types (`GremlinScene`, `GremlinEmitter`, `GremlinListener`), opaque `Sound`, `GremlinError` |
| Commit | n/a (not a git repo) |
| Date | 2026-08-03 |
| Method | Muratori, *Designing and Evaluating Reusable Components* (2004); anchors per the /muratori skill |
| Reuse kind | **component** — data flows both ways (the caller feeds scene state in, the mixer hands back voice counts and finished-sound ids) and the caller's game loop stays in charge, driving `pump()` each frame. Full five-characteristic scoring applies. |

## Summary

| Characteristic | Score | One-line verdict |
|---|---|---|
| Granularity | 2/5 | One five-verb monolith (`load_register_attach_and_play`) is the only way to get a sound in; the fine tier (`load_sound`) was removed and survives only as a dangling doc link. |
| Redundancy | 2/5 | Two paths now write `scene.emitters` — the load monolith inserts, `sync_scene` wholesale-replaces — and they observably clobber each other. |
| Coupling | 1/5 | Construction itself requires a JSON config file on disk; every other call hides behind a `NotInitialized` gate; serde/serde_json are mandatory, un-gated, and derive on public types. |
| Retention | 2/5 | A retained scene mirror the caller must wholesale-replace every frame — and the library also inserts into it, so divergence risk runs both ways. |
| Flow control | 3/5 | Caller drives via `pump()`, but sound-finished is callback-only — documented as "the only way to learn that playback ended." |

**Discontinuity verdict:** The first integration works if you accept everything at once, but the first requirement shift hits a wall: there is no way to load a sound without simultaneously registering, attaching at the origin, and playing it, and no way to construct a `Mixer` at all without a config file on disk — so preloading assets, sourcing audio from memory or a network pack, and running in tests/CI are all rewrites or ugly workarounds rather than incremental steps. The retained scene compounds this: because both the load monolith and `sync_scene` write `scene.emitters`, the blessed per-frame sync silently erases what the load call just attached, and the caller must reverse-engineer which path wins. This API's gaps sit exactly where mid-project changes land.

## Characteristics

### Granularity — 2/5
> Anchor matched: "The dominant path is monolithic; finer control exists only via workarounds (round-tripping through internal state, re-implementing steps)."

- Evidence: `src/lib.rs:82-109` — `load_register_attach_and_play` performs five steps (read file, decode, register, attach emitter at origin, begin playing) in one call, and none of the five is separately callable. `src/lib.rs:19` still doc-links `Mixer::load_sound`, which no longer exists — the fine tier was removed between 0.2.0 and 0.3.1, leaving a dangling reference. Partial finer control exists only by round-tripping through the retained scene: hand-building a `GremlinScene` and pushing it via `sync_scene` (`src/lib.rs:113-119`) can reposition or remove emitters, but cannot get a sound decoded and registered without playing it. Sketch 2 hits this directly.
- Δ: no score change from 2026-05-01 (2/5), but the shape worsened — the previous audit's coarse-dominant path has become coarse-only for asset loading; the workaround tier via `sync_scene` is what keeps this off the 1 anchor.
- Minimal fix: split the monolith into its documented composition — `add_sound(name, Sound)` + `Sound::from_samples(...)` (loading), an emitter insert (attach), and play as a scene/emitter flag — and re-document `load_register_attach_and_play` as a convenience over those 3–4 calls.

### Redundancy — 2/5
> Anchor matched: "Divergent duplicates: two ways to reach 'the same' state that behave observably differently."

- Evidence: `src/lib.rs:99-107` (the load monolith inserts into `scene.emitters`) vs `src/lib.rs:113-119` (`sync_scene` replaces the whole scene). Both are ways to make an emitter exist, and they interact destructively: the documented per-frame `sync_scene` call replaces the scene the load call just wrote into, silently dropping the freshly attached emitter (sketch 3). This is the classic clobber — a convenience call mutating state a lower-level path also owns. It stops short of the 1 anchor only because `sync_scene`'s replace semantics are documented, so which path wins is discoverable without reverse-engineering.
- Δ from previous audit: **3/5 → 2/5.** 0.2.0 was single-path and coherent; 0.3.1 introduced the second, conflicting write path.
- Minimal fix: make `sync_scene` the single owner of `scene.emitters` — remove the emitter insertion from the load path (pairs with the granularity fix) — or, at minimum, document the merge/clobber semantics and have the load call return the emitter for the caller to place.

### Coupling — 1/5
> Anchor matched: "No capability usable without buying unrelated subsystems; construction itself requires external resources; hidden preconditions on most calls."

- Evidence: all three clauses hold. Construction requires external resources: `from_config_file` (`src/lib.rs:67-78`) is the only constructor, it reads the filesystem, and the doc states "There is no way to construct a mixer without a config file" (`src/lib.rs:66`). Hidden preconditions on most calls: the `NotInitialized` error variant (`src/lib.rs:16`) gates `load_register_attach_and_play`, `sync_scene`, and `pump` (`src/lib.rs:88,115,131`) — a hidden dependency confessing in the error type. Unrelated subsystems mandatory: `serde`/`serde_json` sit in `[dependencies]` with no `[features]` section (`Cargo.toml:8-10`), and `Serialize`/`Deserialize` derive on the public scene types (`src/lib.rs:34,40,48`), so JSON support is bought whether or not the caller ever touches a file. Sketch 1 shows even the happy path must author a JSON file first; sketch 2 shows no in-memory escape.
- Δ from previous audit: **2/5 → 1/5.** The config-file constructor was already flagged in 0.2.0; 0.3.1 adds the init gates across the surface and leaves the format crates un-gated, satisfying every clause of the bottom anchor.
- Minimal fix: add a plain-data constructor — `Mixer::new(MixerConfig)` with a public, code-constructible config struct — keeping `from_config_file` as a convenience over it; that alone deletes the `NotInitialized` state and lifts this to 3.

### Retention — 2/5
> Anchor matched: "A retained mirror the caller must wholesale-replace to stay current, or one the library also mutates (divergence risk on both sides)."

- Evidence: both halves of the anchor hold. `GremlinScene`'s doc: "Callers must mirror their game state into this structure and keep it synchronized every frame" (`src/lib.rs:32-33`); `sync_scene`'s doc: "Replace the mixer's retained scene with a new copy. Call this every frame" (`src/lib.rs:111-112`) — the wholesale-replace tax with no partial update or query. And the library also mutates the mirror: the load monolith inserts emitters into it (`src/lib.rs:99-107`), so the caller's copy and the mixer's copy diverge the moment a sound is loaded (sketch 3). This is not scored 1 because `pump` only reads the scene — the library's mutation happens in a caller-invoked, documented call, not behind the caller's back mid-operation.
- Δ: no score change from 2026-05-01 (2/5).
- Minimal fix: an immediate-mode entry point — `pump_scene(&mut self, scene: &GremlinScene, dt)` — so the caller's data is the only copy; keep the retained scene as an optional convenience on top.

### Flow control — 3/5
> Anchor matched: "Caller drives the main loop, but at least one event is callback-only."

- Evidence: the caller retains authority — `pump(dt)` is caller-invoked each frame and returns the active-voice count (`src/lib.rs:129-148`) — but playback completion is delivered exclusively through the registered `Box<dyn FnMut(u64)>` (`src/lib.rs:123-125`), documented as "the only way to learn that playback ended" (`src/lib.rs:122`). No pollable or returned equivalent exists. Sketch 3 shows the ship-week cost: the boxed `FnMut` cannot borrow game state that the frame loop also holds, forcing `Rc<RefCell<...>>` queue plumbing.
- Δ: no score change from 2026-05-01 (3/5).
- Minimal fix: have `pump` return the finished ids (e.g. `Result<PumpReport, GremlinError>` with `finished: Vec<u64>`), demoting the callback to optional sugar — a 3→4/5 move for one signature change.

## Practical checklist

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Usage code written before API design (or: sketches integrate cleanly now) | fail | Sketches 2 and 3 (appendix) both end in discontinuities; the API shape (five-verb monolith, config-only constructor) reads as implementation-first, not call-site-first. |
| 2 | Every retained-mode construct has an immediate-mode equivalent | fail | The retained scene is the only playback interface (`src/lib.rs:32-33,113-119`); no `pump`-with-caller-scene variant exists. |
| 3 | Every callback/inheritance path has a non-callback alternative | fail | "This is the only way to learn that playback ended" (`src/lib.rs:122`); `pump` returns only a voice count (`src/lib.rs:147`). |
| 4 | Callers keep their own datatypes (no forced API types) | fail | Callers must mirror their world into `GremlinScene`/`GremlinEmitter` every frame (`src/lib.rs:32-33`); `Sound` is opaque with private fields (`src/lib.rs:20-24`). |
| 5 | Operations decompose into 2–4 finer-grained calls | fail | `load_register_attach_and_play` bundles five steps with no exposed finer tier (`src/lib.rs:82-109`); the former `load_sound` is a dangling doc link (`src/lib.rs:19`). |
| 6 | Data structures transparent (constructible, inspectable, serializable by caller) | partial | Scene types are public-field, `Default`, serde-derived (`src/lib.rs:34-52`) — fully transparent; `Sound` is opaque (private `samples`/`rate`, only `id()` exposed, `src/lib.rs:20-30`). |
| 7 | Resource-management integration optional, never mandatory | fail | The mixer owns all sound storage (`sounds: HashMap`, `src/lib.rs:57`); callers cannot supply their own decoded buffers or manage asset memory — bytes must arrive via the library's own `fs::read` (`src/lib.rs:90`). |
| 8 | File-format usage optional, never forced | fail | A JSON config file is mandatory for construction (`src/lib.rs:66-70`); sound loading is path-only (`src/lib.rs:82`); `save_scene` emits an unversioned JSON format produced "only here" (`src/lib.rs:150-156`); serde/serde_json un-gated in `Cargo.toml:8-10`. |
| 9 | Runtime source shipped / readable by integrators | pass | MIT-licensed source crate (`Cargo.toml:6`); the entire runtime is a single readable `src/lib.rs`. |

## Kernel lens

These findings are strongly kernel-shaped — every low score traces to I/O, hidden state, or callback inversion:

- **Coupling → purity (1/5).** The constructor reads the filesystem, three public functions take paths, and JSON support is welded on. A pure core constructed from plain data would delete the `NotInitialized` state machine outright — the sandbox simply wouldn't grant the access the hidden coupling rides in on.
- **Retention → pure transition function (2/5).** The retained scene mirror is the inverse of `apply(state, action) -> state`; an immediate-mode `mix(scene, sounds, dt) -> report` would make the caller's data the only copy and dissolve the sync-every-frame contract.
- **Flow control → delivery-agnosticism (3/5).** The callback-only completion channel is exactly the inversion a kernel structurally cannot perform; returning finished ids from `pump` is the delivery-agnostic form.
- **Granularity → boundary shape (2/5).** `load_register_attach_and_play` is the monolithic `play_game(state) -> result` failure; a decode / register / attach / advance split is the 2–4-way boundary Muratori's rule asks for.
- **Redundancy** stays unmapped, per the method — the emitter-clobber fix is ordinary API taste (single write path), not something kernel structure enforces.

**Recommendation:** run `/domain-kernel` (Mode A first) on this crate — the mixing math (`samples`, positions, volumes → voice states) is a natural pure core, and everything filesystem- and JSON-shaped belongs in a shell around it.

## Recommendations

Ordered by leverage:

1. **Plain-data constructor** — `Mixer::new(MixerConfig)` with a public config struct; keep `from_config_file` as a convenience. Moves **coupling 1→3** (kills the disk requirement and the `NotInitialized` gates in one change) and unblocks tests/CI integration.
2. **Return finished ids from `pump`** — callback becomes optional sugar. Moves **flow control 3→4**; smallest change per point gained.
3. **Decompose the load monolith** — `Sound::from_samples` / `add_sound(name, Sound)` + emitter attach as separate calls, monolith re-documented as their composition. Moves **granularity 2→4** and, by giving `sync_scene` sole ownership of `scene.emitters`, **redundancy 2→4**; also fixes the dangling `load_sound` doc link and checklist items 5 and 7.
4. **Immediate-mode pump** — `pump_scene(&scene, dt)` with the retained scene demoted to convenience. Moves **retention 2→4**.
5. **Feature-gate serde/serde_json** and version the `save_scene` format. Moves **coupling** a further step and fixes checklist item 8.

Items 1–4 together are an API-breaking rework spanning the whole surface; if taken as one effort rather than piecemeal, write it up with `/epic` as a phased design doc first.

## Evidence appendix

### Usage sketches

**1. First integration — minimal happy path**

```rust
// Must ship a JSON config file next to the binary before anything works.
let mut mixer = Mixer::from_config_file("assets/audio.json")?;
let door_id = mixer.load_register_attach_and_play("door", "assets/door.wav")?;
mixer.set_on_sound_finished(Box::new(move |id| {
    if id == door_id { /* can't touch &mut game here — see sketch 3 */ }
}));
loop {
    let dt = frame_dt();
    let mut scene = GremlinScene::default();
    scene.listener.position = player_pos();
    // NOTE: rebuilding the scene from scratch drops the "door" emitter
    // that load_register_attach_and_play inserted. Undocumented trap.
    mixer.sync_scene(scene)?;
    let _voices = mixer.pump(dt)?;
}
```
Verdict: works only if you accept a disk config, immediate playback at the origin, and the clobber trap — a lumpy but mostly **incremental step**.

**2. Requirement shift — preload sounds at level start without playing them (assets now arrive from a pack file in memory)**

```rust
// Want: decode bytes I already have, register under a name, play later.
let bytes: Vec<u8> = pack.read("door.wav");        // no API takes bytes —
                                                    // only <P: AsRef<Path>> paths
// Workaround attempt: write bytes to a temp file (!), then load — but
// load_register_attach_and_play ALSO attaches at the origin and starts
// playback at volume 1.0. To "preload silently":
let tmp = write_temp_file(&bytes);                  // filesystem round-trip
mixer.load_register_attach_and_play("door", &tmp)?; // audibly plays this frame
mixer.sync_scene(GremlinScene::default())?;         // rip the emitter back out
// Sound stays registered in the mixer's private map; hope nothing pumped
// in between and fired the finished callback for a sound we never wanted heard.
```
Verdict: **discontinuity** — no incremental path from paths-on-disk to bytes-in-memory, and no load-without-play at any price short of forking.

**3. Ship-week workaround — gameplay needs "sound ended" inside the frame logic**

```rust
// The callback is the only completion channel, but Box<dyn FnMut(u64)>
// can't borrow &mut Game while the frame loop also holds it.
let finished: Rc<RefCell<Vec<u64>>> = Rc::new(RefCell::new(Vec::new()));
let q = finished.clone();
mixer.set_on_sound_finished(Box::new(move |id| q.borrow_mut().push(id)));
loop {
    mixer.sync_scene(game.build_scene())?;   // wholesale copy, every frame
    mixer.pump(dt)?;                          // callbacks fire inside here
    for id in finished.borrow_mut().drain(..) {
        game.on_sound_done(id);               // finally back in our own frame
    }
}
```
Verdict: **workaround, at real cost** — `Rc<RefCell>` plumbing to un-invert control that `pump` could have returned directly; plus the per-frame wholesale scene copy is the retained-mode tax paid on every iteration.

### Mechanical signals

Searched `src/lib.rs` (157 lines, entire public surface) and `Cargo.toml` with `rg`:

- Callback-typed parameters: `Box<dyn FnMut(u64)>` — 2 hits (field `src/lib.rs:58`, parameter `src/lib.rs:123`); no pollable equivalent found.
- Path-taking public functions: `<P: AsRef<Path>>` — 3 (`from_config_file:67`, `load_register_attach_and_play:82`, `save_scene:152`).
- Init gates: `NotInitialized` — 4 hits (variant `:16`; gates at `:88`, `:115`, `:131`). No public path leaves `initialized == false`, so the gates are unreachable dead weight confessing a hidden lifecycle.
- Third-party derives on public items: `Serialize, Deserialize` on 3 public types (`:34`, `:40`, `:48`).
- Format crates: `serde` + `serde_json` in `[dependencies]` (`Cargo.toml:8-10`); no `[features]` section exists.
- Step-enumerating name: `load_register_attach_and_play` (`:82`) — five verbs, zero separately callable.
- Whole-struct sync setter: `sync_scene(GremlinScene)` (`:113`) with doc phrase "Call this every frame" (`:111-112`); retained-mirror doc phrase "keep it synchronized every frame" (`:32-33`).
- Dangling doc link: `[`Mixer::load_sound`]` (`:19`) references a method that no longer exists.

## Notes (human)

- CB 2026-05-01: we accept the config-file constructor for now; the launcher
  team owns that file. Revisit after the asset pipeline rework.

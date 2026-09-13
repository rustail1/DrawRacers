# MR-05 DrawingController Module Rewrite Implementation Plan

> Execute with TDD on `main`. No branch/PR. Client prediction is presentation only; server authority and network schema remain unchanged.

**Goal:** Rewrite `DrawingController` around one raw semantic gameplay sample stream plus one bounded pixel trace for immediate visual feedback. All accepted/predicted leg geometry must come from shared `CanonicalLegShape`; the main gameplay canvas uses one fixed isotropic mapping and never auto-fits a shape.

**Owner spec:** `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`

**Engineering contract:** `docs/DEVELOPMENT_PRINCIPLES.md`

**MR-05 baseline:** `838a673998c786689f0e9b9aa46ba2bbb717e720`

## Responsibility

`DrawingController` owns client drawing input/presentation only:

- receive pointer/touch events from `InputController`;
- convert local pixels to raw semantic coordinates;
- maintain a bounded raw semantic sample stream for the gameplay stroke;
- call shared `CanonicalLegShape.Build` for predictive validation/preview;
- render live and accepted centerlines on a fixed isotropic gameplay scale;
- submit the raw semantic samples to the server;
- replace prediction with newer server-authoritative accepted points;
- preserve per-submit presentation anchor so ACCEPT does not visually jump;
- own local pending/timeout/layout/toast lifecycle.

It does **not** own canonical simplify/resample/clamp/world-map logic, physics geometry, server authority, race rules or camera/rider/cosmetics.

## KEEP / CHANGE / DELETE

### KEEP

- current wide gameplay canvas dimensions and aspect contract;
- touch/mouse layout selected before stroke and no mid-stroke reflow;
- bounded immediate live trace for responsive feel;
- server-authoritative `acceptedPoints` handling with monotonic accepted sequence;
- `MaxPendingStrokes` and `StrokeResultTimeout` protections;
- raw semantic network payload schema `{sequence, points}`;
- late authoritative ACCEPT may still replace a locally timed-out prediction;
- fixed main canvas mapping and thumbnail-only auto-fit;
- graphite polyline renderer with corner joints;
- current validation copy mapping and 2-second toast;
- compatibility public `acceptedPoints` / `livePoints` presentation fields for this stage.

### CHANGE

- gameplay stroke sampling is stored directly as semantic `Vector2` points in `_rawSemanticPoints`;
- local pixel-to-semantic conversion happens at capture time through shared `StrokeMath.Normalize`;
- `CanonicalLegShape.Build` consumes `_rawSemanticPoints` directly;
- only the raw semantic stream is submitted; canonical points are prediction only;
- raw sample compaction is one explicit bounded sampling policy, not a second canonical cleanup pipeline;
- live pixel trace remains presentation-only and cannot influence submitted/canonical geometry;
- accepted preview is rebuilt from server points plus the submit-scoped presentation anchor.

### DELETE

- `_semanticPixelPoints` gameplay buffer;
- `_normalizedPixelDistance` pixel-derived gameplay threshold helper;
- `_buildCanonicalFromPixels` and `_prepareRawSemanticPoints` conversion pipeline;
- repeated full-stroke `StrokeMath.Normalize` immediately before every canonical build/submit;
- any per-shape main-canvas fit/centering path.

## Invariants

1. One captured gameplay point has one semantic representation before canonical processing.
2. `CanonicalLegShape.Build` is the only simplify/dedupe/resample/anchor/world-map owner used by client prediction.
3. Network sends raw semantic samples, never client-canonical output.
4. Live pixel trace cannot alter gameplay samples.
5. Accepted server points supersede prediction only when sequence is newer than last accepted.
6. Main gameplay preview uses fixed isotropic scale (`size.Y * 0.5`) with no bounds fit.
7. Auto-fit remains thumbnail-only.
8. Prediction and ACCEPT use the same submit-scoped presentation anchor, preventing geometric jump for deterministic server acceptance.
9. Long strokes compact rather than freezing at `MaxRawPoints`.
10. Pending requests and anchor history remain bounded.
11. Layout cannot reflow while drawing.
12. Destroy disconnects all connections, invalidates delayed callbacks, clears pending/anchor/sample state and unbinds input.

---

## Task 1 — RED boundary

Create `tests/test_mr05_drawing_controller_boundary.py` asserting:

- controller requires `CanonicalLegShape` and `StrokeMath.Normalize` only for pixel→semantic conversion;
- `_rawSemanticPoints` exists and `_semanticPixelPoints` does not;
- `_capturePointerPoint` converts the captured local pixel to semantic before appending gameplay sample;
- canonical preview/build consumes `_rawSemanticPoints` / raw semantic vectors directly;
- no `StrokeMath.SimplifyRDP`, `Resample`, `Dedupe`, `ClampToRect`, `AnchorToFirstPoint` or `GeometryMath` appears in controller;
- submit serializes raw semantic vectors and does not submit `canonical.normalizedPoints`;
- fixed main mapping exists and `fitSemanticPointsToPixels` is referenced only by thumbnail rendering;
- accepted result stores server `acceptedPoints` and uses sequence-scoped presentation anchor;
- live trace and raw semantic buffers are separately bounded/cleared.

Run full verification and confirm RED for the old `_semanticPixelPoints` / pixel-to-canonical pipeline.

---

## Task 2 — Rewrite `DrawingController.lua`

Rewrite coherently while preserving UI/network behavior.

### Capture model

Keep:

- `_livePoints: {Vector2}` = bounded presentation trace in local pixels;
- `_rawSemanticPoints: {Vector2}` = bounded gameplay samples.

At capture:

1. append pixel to `_livePoints`;
2. convert exactly that local pixel via `StrokeMath.Normalize({point}, inputSize)[1]`;
3. append to `_rawSemanticPoints` using semantic `RawSampleMinMovementNormalized` threshold;
4. build/render canonical preview from `_rawSemanticPoints` when valid; otherwise render faint pixel trace.

### Long-stroke compaction

Both buffers may be bounded independently because the pixel buffer is presentation-only. Gameplay compaction preserves first/final points and every other interior sample, then continues accepting new points; never stop accepting just because cap was reached.

### Canonical prediction

Create one helper such as:

```lua
function DrawingController:_buildCanonical(rawSemanticPoints: {Vector2})
    if #rawSemanticPoints < MinimumRawPoints then ... end
    return CanonicalLegShape.Build(rawSemanticPoints, StrokeProcessing, LegGeometry)
end
```

No second simplify/resample/dedupe/clamp/map implementation exists in controller.

### Submission

`_submitStrokeIntent(rawSemanticPoints)`:

- locally calls shared canonical builder only to reject obvious invalid stroke and capture `presentationAnchor`;
- serializes the **raw semantic vectors** to network semantic tables;
- stores pending sequence/generation and presentation anchor;
- sends `{ sequence, points = rawSemanticPointsSerialized }`.

### Server ACCEPT

Keep validation of server `acceptedPoints`, accepted-sequence monotonicity, pending cleanup and late ACCEPT behavior. Main accepted rendering uses the authoritative normalized points plus the matching submit presentation anchor. Do not auto-fit gameplay rendering.

---

## Task 3 — Migrate stale tests

Only migrate tests proven stale by CI. Expected source-detail changes:

- `_semanticPixelPoints` → `_rawSemanticPoints`;
- `_tryAppendSemanticPoint` → semantic-stream append helper;
- old `_buildCanonicalFromPixels` expectations → shared canonical helper;
- long-stroke compaction expectations should target semantic vectors rather than pixel gameplay samples.

Preserve behavior contracts for network ordering, timeout handling, fixed mapping, touch layout, live preview bounds and accepted server authority.

---

## Task 4 — Verification/self-review

Fresh final-head evidence required:

- all `python verify.py` checks PASS;
- Rokit/toolchain PASS;
- Rojo build PASS;
- GitHub Actions `Contract Verify` SUCCESS;
- compare baseline→HEAD touches only plan, DrawingController and directly stale drawing tests;
- no network schema, server authority, physics, camera, rider, cosmetics, race or tuning changes;
- human Studio/physics gates remain PENDING.
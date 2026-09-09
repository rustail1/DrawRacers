# Decision Log — Pre-G0 Repository Review R07–R09 — 2026-09-09

Status: **BOUNDED B17/G0 REWORK — NO NEW PRODUCT SCOPE**

## Context
After R01–R06, the repository was already hard-stopped at `B17/G0 HUMAN_GATE`. A later code/document review found additional implementation-integrity issues inside the existing B03–B16/G0 path. This record does not authorize C01, M0.5, multiplayer, meta, economy, shop, or any new player verb.

Owner contracts reviewed for this pass included `15`, `16`, `21`, `22`, `55`, `59`, `60`, `65`, `66`, `68`, and `73`, plus the active M0 client/server/runtime code and regression suite.

## R07 — core review tightening
R07 tightened already-existing owners rather than adding systems:
- B12 validates the exact outer `SubmitStroke` payload and stamps rate-limit state before expensive point walking/JSON work can be repeated arbitrarily;
- B16 exposes raw points, physics points and actual hinge motor state; runtime debug folder/telemetry behavior follows Studio/DEV/STAGING gating;
- the visible square semantic `DrawInputRect` remains the only isotropic drawing surface and docs `59/68` match that decision;
- no new collision group or top-level manager was introduced.

## R08 — final core closure before another G0 attempt
R08 closed four concrete G0 blockers/risks:
1. responsive family is selected safely and never reflows an in-progress stroke;
2. the ordinary Roblox Character is isolated before the G0 racer spawns, so it cannot push/block racer physics;
3. `MinUsefulLegExtent = 0.7` is enforced server-side and a rejected tiny redraw preserves the old accepted shape;
4. bounded anti-stall uses actual contact and canonical `RecoverySurface` / `RequirementTag` semantics, with exact `16` timing/acceleration limits and visible `antiStallActive` diagnostics.

The canonical R08 repair head `3a0a32ce90f2cfcd2f37e3be430758dacc86d6d3` passed GitHub Actions run `34349254516`: **77 passed, 0 failed**.

## R09 — repository-wide pre-G0 consistency findings
R09 inspected the active client input/presentation path, network/authority boundary, racer/leg/stabilizer/anti-stall ownership, M0 scene, debug path, root DataModel contract, and current automated test boundary.

### Finding A — accepted preview was tied to transient pixel layout
`DrawingController` submitted semantic normalized points to the server but stored raw preview pixels in `_pendingStrokes`. If the same UI switched touch/desktop layout between pointer-up and `StrokeResult`, or after an already accepted stroke, the accepted drawing/thumbnail could display in the wrong coordinate scale. An out-of-bounds visual path could also look different from the clamped semantic shape that was actually accepted.

Decision: pending/accepted presentation now stores the semantic points used for submission. Rendering maps those semantic coordinates to the current `DrawInputRect`/thumbnail size. A between-stroke responsive change re-renders after Roblox updates `AbsoluteSize`. This changes presentation correctness only; server physics authority and network contract stay unchanged.

The same review found that `ValidationToast` and `DrawHint` stayed on desktop layout tokens while DrawCanvas switched to touch. R09 applies the exact touch positions/sizes from `59`; no second mobile UI tree is created.

### Finding B — recovery tag could override an obstacle RequirementTag
The R08 anti-stall classifier checked `RecoverySurface` before `RequirementTag`. A future mistakenly dual-authored obstacle could therefore be assist-eligible even though `16` requires immediate disable on obstacle RequirementTag.

Decision: inspect `RequirementTag` first. Any explicit non-`FAST_ROLL` tag is `OBSTACLE` and wins over `RecoverySurface`. `FAST_ROLL` or an otherwise non-conflicting explicit recovery surface may be eligible. Unknown collidable contact remains fail-closed. No new tag is introduced.

### Finding C — template-only RuntimeAttachments leaked into spawned racer tree
`RacerTemplate` correctly uses `RuntimeAttachments` as a staging folder for `LaneAlignAttachment` and `OrientationAttachment`. `RacerStabilizer` moved those attachments onto `BodyCollider` but left the now-empty folder inside the spawned racer, while `65` defines that helper only on the template and gives the spawned racer a different runtime tree.

Decision: after both attachments are transferred, destroy the empty helper folder. Stabilizer ownership and constraints are unchanged.

## Architecture conclusion
No crooked dependency or duplicate owner requiring a refactor was found in the active M0 path:
- `Bootstrap.server/client` remain composition roots;
- `InputController` owns pointer normalization only;
- `DrawingController` owns local draw UI/preview/submit/result only;
- `StrokeRemoteTransport` owns RemoteEvent transport only;
- `LegShapeService` owns authoritative stroke cleanup/ShapeSpec construction;
- `RacerRuntime` owns body, legs, stabilizer and anti-stall lifetime;
- `LegAssembly` consumes authoritative segment plans and does not re-own geometry math;
- `GeometryMath` / `StrokeMath` stay pure shared math owners;
- no D05 `RacerService`, RaceService, TrackService, economy/meta service, or duplicate manager was pulled forward.

The one material tooling limitation still open is evidence coverage: `.github/workflows/contract-verify.yml` currently runs only `python verify.py`. Those checks are valuable static/contract regressions, but they do not compile/run Luau in Roblox Studio and cannot prove physics/touch feel. At B17 the mandatory mitigation is the existing local Rojo build/Studio smoke plus empirical G0; this limitation is not silently reclassified as PASS.

## TDD / verification evidence
R09 RED commit `35c4df76dd4d663e4785bcb295fda357b8c48ef9` added regressions for all three findings. GitHub Actions run `34351760319` failed as intended at **77 passed, 3 failed**:
- semantic/responsive accepted preview contract failed;
- obstacle RequirementTag precedence contract failed;
- spawned-racer RuntimeAttachments cleanup contract failed.

Minimal repair commit `3d414556677577af6b07ff253b97041c0eb59c30` changed only the owned client/runtime files. Run `34352130204` then passed **80 passed, 0 failed**.

## Gate decision
`B17/G0 HUMAN_GATE` remains **PENDING**. Automated/static repair is not G0 acceptance. Local Studio runtime evidence and the `55` six-external-tester criteria remain required before C01/M0.5.

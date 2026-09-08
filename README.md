# Draw Racers

Roblox production repository for **Draw Racers**.

## Source of truth
The current production specification is in `docs/` (v1.3.4 ZERO-QUESTION PRODUCTION HANDOFF). Do not mix older history packages into this repository.

Before any implementation task, read:
1. `docs/AGENTS.md`
2. `docs/FEATURE_LIST.md`
3. `docs/SESSION.md`
4. `docs/26_HANDOFF_MAP.md`
5. the exact task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`
6. only the owner specs named by that row

## Current implementation item
**B14 — Invalid/stress redraw suite is implemented in `main` and awaits local/Studio acceptance.**

B03–B14 code/specs remain wired as regression checks in Studio Play. Under the explicit Product Owner night-autopilot override, B15 may be implemented next while B12–B14 Studio evidence remains pending; that does not mark them ACCEPTED. B17/G0 remains the hard human gate.

## Toolchain
Rokit manages the project Rojo version. The repository currently pins Rojo in `rokit.toml`.

From the repository root:

```powershell
rokit install
rojo --version
rojo build -o DrawRacersDev.rbxlx
rojo serve
python verify.py
```

`verify.py` runs the current simple Python contract tests without requiring pytest. If pytest is installed, `python -m pytest -q` remains valid too.

Then connect the Rojo plugin in Roblox Studio to the localhost server shown by `rojo serve`.

## Accepted bootstrap/input state
- A01: Git/Rojo baseline, build/serve and Studio sync round-trip accepted.
- A02: canonical minimal shared/server/client bootstrap accepted.
- A03: reproducible Studio M0 lane + debug spawn + representative anchors accepted.
- A04: DEV/STAGING/PROD deployment skeleton, no fake IDs, fail-closed validator and exact static Studio roots accepted.
- B01: mouse/touch pointer abstraction; semantic start/move/end/cancel stream and camera input ownership accepted.
- B02: local DrawCanvas continuous preview/candidate/thumbnail stage accepted by Product Owner progression.

Later B03–B14 implementation/tests exist in `main`, but this README does not promote those tasks to ACCEPTED without the required local/Studio evidence.

## B03–B05 StrokeMath regression layer
Shared processing owns normalized clamp/dedupe, DrawInputRect-centered normalization, RDP simplification, open-polyline arc-length resampling, length measurement and bounds calculation. Studio specs cover malformed/non-finite input, duplicate-heavy strokes, tiny strokes, self-cross, max raw points and canonical preset shapes.

Expected Studio lines include:
- `[DrawRacers][B03] StrokeMath tests PASS`
- `[DrawRacers][B04] StrokeMath simplify/resample/normalize tests PASS`
- `[DrawRacers][B05] canonical/tiny/duplicate/self-cross/max-point/malformed StrokeMath matrix PASS`

## B06–B10 physical locomotion foundation
The current runtime contains the canonical 3×3×3 racer body, two same-XY leg assemblies at canonical hubs, hinge motors with the documented direction/phase, and lane/body stabilization with no hidden forward race power.

These stages remain subject to their Studio acceptance evidence; later tasks do not redefine their physics contracts.

## B11 authoritative shape authority
`src/server/Services/LegShapeService.lua` owns server-side stroke validation and `ShapeSpec` construction. Invalid shapes do not advance `ShapeVersion`; accepted shapes increment it exactly once. Client data never supplies world geometry, Instances, CFrame, segment plans or ShapeVersion authority.

## B12 stroke network boundary
B12 adds exact `SubmitStroke` / `StrokeResult` RemoteEvents, bounded semantic stroke payload validation, per-player sequence/rate guards, and client request/result semantics. Rejected results preserve the previous accepted preview. B12 intentionally does not implement D05 player→racer mapping.

Required B12 Studio line:
- `[DrawRacers][B12] SubmitStroke/StrokeResult tests PASS`

## B13 atomic redraw
B13 changes physical replacement semantics without changing ShapeSpec authority:
- both replacement leg assemblies are built detached from Workspace;
- the old working pair remains alive if either staged build fails;
- after both replacements are ready, both are committed in one no-yield server section and only then are retired legs destroyed;
- BodyCollider CFrame, linear velocity and angular velocity are not rewritten by redraw;
- current left/right rotation phase is carried into the replacement pair as closely as the implementation allows;
- the B13 Studio spec covers forced second-leg build failure, no leaked staged models, successful pair replacement, body-state preservation and phase preservation.

Required B13 Studio line:
- `[DrawRacers][B13] atomic redraw tests PASS`

## B14 redraw abuse/stress
B14 adds an executable Studio abuse/stress matrix around the existing authoritative redraw/network path:
- cooldown spam, stale sequence, malformed points, NaN/Inf, too many points and oversized bounded payloads must fail closed without removing the current valid shape;
- 40 legal redraws must keep exactly one left/right pair with bounded physical part count and no retiring-model leak;
- a 50-request burst must remain rate-limited without shape-version or Instance growth;
- static tests guard that type/size/rate gates remain before server geometry build.

Fresh static CI on the B14 test head reported `Contract checks: 44 passed, 0 failed`.

Required B14 Studio line:
- `[DrawRacers][B14] redraw abuse/stress tests PASS`

## Working loop
`ChatGPT/GitHub change -> git pull --ff-only -> Rojo -> Studio playtest -> PASS/FAIL -> next change`

Before pulling remote changes, run `git status` and do not overwrite uncommitted local work.

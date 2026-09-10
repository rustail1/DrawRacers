# SESSION.md — CURRENT STATE

Date: 2026-09-10  
Documentation version: **v1.4.1 R16 STAGE-B IMPLEMENTATION AUTHORIZED**

## Product state
The product specification remains closed. CORE/pre-G0 repair **R01–R12**, bounded runtime/evidence closure **R14.1–R14.11**, planar correction **R15/R15.1**, and current reference-parity correction **R16** stay inside the already-approved B03–B16/B17 scope; they introduce **no new WHAT/WHY gameplay scope**.

Locked direction remains: 8-player live physics drawing race; one continuous player stroke controls two real rotating physical legs; no competitive power monetization; progression/meta remains outside M0 until the ordered gates allow it.

## Accepted implementation evidence
Repository-recorded human/Studio acceptance remains unchanged:
- A01 — Git/Rojo baseline — ACCEPTED.
- A02 — minimal shared/server/client roots — ACCEPTED.
- A03 — reproducible M0 test scene — ACCEPTED.
- A04 — deployment/config skeleton + Studio roots — ACCEPTED.
- B01 — pointer abstraction — ACCEPTED.
- B02 — local stroke preview — ACCEPTED.

B03–B16 code and regression specs exist in `main`, but they are **not promoted to ACCEPTED** merely because automated checks and Rojo build are green. Required Studio/physics/human evidence is still pending.

## CORE/pre-G0 integrity repair R01–R12
- **R01 Geometry Authority** — `GeometryMath` is the single pure owner of normalized-shape → mapped-points/segment-plan construction; server ShapeSpec carries that plan into `LegAssembly`. The visible wide DrawCanvas contains a square semantic DrawInputRect.
- **R02 Drawing/Network Correctness** — visual preview sampling is decoupled from bounded semantic payload sampling; obvious too-short strokes are rejected locally; accepted-result ordering follows server truth.
- **R03 Physics Contract** — complete semantic collision groups/matrix, no forward propulsion from stabilization, M0 lab under `Workspace.Runtime.Tracks`, and tunnel geometry relative to `Lane.TopY`.
- **R04 Debug Correctness** — collider count reads real `Segments` folders, cleaned-point telemetry comes from accepted ShapeSpec, stuck telemetry uses the documented +X progress window, and debug targeting prefers explicit `DebugTarget` then a human racer.
- **R05 Studio/G0 Integration** — Studio uses exactly one selectable interactive harness. Default mode is `G0`; the Studio-only `M0HumanHarness` injects a temporary Player→RacerRuntime resolver into existing `StrokeRemoteTransport`. It does not implement D05 `RacerService`.
- **R06 Documentation Consistency** — repository status/docs were reconciled to the B17/G0 hard stop without claiming Studio acceptance.
- **R07 Core Review Fixes** — exact B12 outer payload validation and abuse work-ordering, complete B16 raw/physics/motor telemetry and environment gating, plus semantic DrawInputRect ownership were tightened.
- **R08 Final Core Closure** — touch layout changes only between strokes; the normal Roblox Character is isolated from G0 physics before racer spawn; server enforces `MinUsefulLegExtent = 0.7`; anti-stall is bounded, actual-contact based, canonical-tag based and visible as `antiStallActive`.
- **R09–R12 (R10, R11, R12 explicitly retained)** — accepted-preview semantics, drawing UI bounds, long-stroke compaction, hybrid input isolation and G0 respawn isolation are CLOSED at implementation/regression level.

Historical repository evidence is retained for regression traceability:
- pre-R06 baseline: **66 passed, 0 failed**;
- R09 bounded repair: **80 passed, 0 failed**;
- R10–R12 code head `e2bedd34696bb99da43878c19d7984c9134c8bef`, run `34363706915` → **88 passed, 0 failed**;
- historical pre-R16 cursor was **B17 — G0 HUMAN_GATE — Studio PASS PENDING**.

## R14 pre-G0 runtime/evidence closure
**R14.1–R14.11 are CLOSED at implementation/contract/CI/documentation level; Studio checkpoints: HUMAN PENDING.**

The active guarantees remain: authoritative accepted preview points, Studio-only G0 presentation harness, aggregated Studio gate runner, bounded pending/network failures, same-runtime recovery, atomic redraw rollback, player-safe validation copy, pinned Rojo build in CI, and shared `StrokeTypes`/`RemoteNames` ownership.

Historical R14 code/tooling evidence is retained: head `8a6a05a31427346d2a1437820ffa759f21fca90c`, run `34387618626` → **120 passed, 0 failed**, successful **Rojo build**. B17/G0 remained HUMAN_GATE and Studio checkpoints: HUMAN PENDING.

## R15/R15.1 historical planar correction
**R15.1 IMPLEMENTED/AUTOMATED GREEN; its orientation detail is superseded by R16.1.**

The first R15 Studio attempt failed with live `laneDeviation 5.199`, proving the finite-force Z follower was insufficient. R15.1 replaced it with the current mechanical `PlaneConstraint` lane lock. That lane-plane mechanism remains valid and owned by `RacerStabilizer`.

Historical R15.1 automated evidence is retained: head `be44304bf00391e05c7d7750609730a7368ebc87`, run `34394991926` → **125 passed, 0 failed**. Human solver/physics acceptance remained HUMAN STUDIO PENDING and B17/G0 remained PENDING.

R15/R15.1 historically left world-Z body rotation free via `PrimaryAxisParallel`; **that orientation contract is no longer current**. R16.1 supersedes it with full upright-body correction while retaining physical X/Y translation and the mechanical Z plane.

## R16 Stage A — reference mechanical parity
**R16 Stage A / R16.1–R16.4: IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING.**

Current canonical Stage-A contract:
- **R16.1 Upright Body** — X/Y body translation remains physically free; Z translation remains mechanically lane-locked; rotation about world X: locked/corrected; rotation about world Y: locked/corrected; **rotation about world Z: locked/corrected**. Only the legs intentionally rotate for locomotion. `AlignOrientation` uses `AllAxes` with an identity attachment basis.
- **R16.2 Hub Position** — `PhysicsConfig.LegGeometry` is the sole numeric owner: `HubOffsetX = 0.0`, `HubOffsetY = -0.35`, `HubOffsetZAbs = 1.62`; runtime consumes those values symmetrically.
- **R16.3 / R16.3A One drawing → Two legs / Reference Shape Centering** — after clamp/dedupe/simplify/resample, the server translates the cleaned bounds center to `(0,0)` without scaling, mirroring or rotating. The resulting **centered authoritative shape** is the ShapeSpec returned to accepted preview and duplicated as the same XY geometry on Left/Right. Drawing the same figure at different locations inside DrawInputRect must therefore produce the same physical geometry; changing the figure size still changes physical radius.
- **R16.4 Twin-leg Phase** — both legs use the same locomotion direction; initial right-minus-left phase is `180° ±1°`; accepted redraw preserves each side's live phase rather than restarting the gait.

R16.3A explicitly supersedes the earlier raw-canvas-offset interpretation from pre-R16 doc 73. No automatic spoke from hub to first point is introduced.

Latest fully-green automated evidence before Stage-B work: head `81c7d84c542160f07fc4fe986df89e5aa69f8f73`; `Contract Verify` run `34448666472` → **142 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. This is repository evidence only and does not satisfy Studio physics/human acceptance.

## R16 Stage B authorization
**Stage B implementation authorized by Product Owner on 2026-09-10. Studio Gate A remains HUMAN STUDIO PENDING.**

This is a bounded process override, not a fabricated acceptance result. It authorizes implementation/instrumentation work for `R16.5 → R16.7` while Stage-A live solver evidence is still pending. It does **not** authorize claiming that Stage A, Stage B, B17/G0, obstacle niches, or reference feel have passed without Roblox Studio evidence.

Stage-B rules remain:
- tune one physics family at a time;
- first measure the current config before changing motor/grip values;
- no obstacle geometry changes to make a shape pass;
- no scripted +X locomotion or scripted Y climbing;
- anti-stall must be observed and must remain inactive during canonical ROUND flat speed measurement;
- all Stage-B solver/feel results remain HUMAN/STUDIO PENDING until a current-main Studio run records them.

## Current implementation/evidence cursor
**R16 Stage B implementation — R16.5 Motor / Grip / Mass measurement and controlled tuning; Studio Gate A remains HUMAN STUDIO PENDING.**

### Studio Gate A evidence still required
Verify current `main` locally:
- `git pull --ff-only`, `python verify.py`, and normal Rojo build/sync complete without project errors;
- Studio Play reaches `[StudioGate] TOTAL 13 PASS / 0 FAIL` then `READY` with no red DrawRacers runtime error;
- B10 upright/lane regression passes under the live Roblox solver;
- normal `laneDeviation <= 0.03`; unexplained excursion `>0.08` is FAIL;
- body normal angular deviation `<=1°`; injected strong-contact disturbance stays `<=3°` and returns to `<=1°` within `0.25 s`;
- body still moves/rises/falls in X/Y from real physics rather than a scripted position lock;
- hubs remain symmetric/fixed at the configured offsets and the body does not continuously scrape flat solely because of axle placement;
- one accepted drawing visibly creates exactly two matching physical legs;
- the same-size shape drawn at different DrawInputRect positions recenters to the same accepted/physical geometry (R16.3A), while different drawn sizes remain different sizes;
- left/right gait is visually consistent with the recorded 180° phase contract and redraw does not visibly reset phase;
- observer Roblox Character remains non-participating in racer physics.

If only `HubOffsetY=-0.35` fails hub calibration while the rest of Stage A passes, the R16 design permits the explicit bounded `-0.75 / -0.35 / 0.0` comparison before any motor-value change is accepted.

### Stage B implementation order
1. **R16.5 Motor / Grip / Mass Feel** — instrument current ROUND FlatShort speed first; only then change `AngularVelocity`, torque/acceleration, leg friction, and finally body friction if evidence requires it.
2. **R16.6 Vertical Physics** — prove normal locomotion never scripts Y and record step rise/gap fall under the live solver.
3. **R16.7 Reference Shape Matrix** — run ROUND/HOOK/ASYM/LONG_BAR/SMALL_ROUND/SUBOPTIMAL from identical resets against the fixed canonical pieces.
4. **Mandatory Studio Gate B** — HUMAN/STUDIO evidence required before R16.8–R16.10 presentation/integration acceptance.

## Empirical G0 still required
R16 completion itself does not pass B17. `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` still requires the fixed G0 evidence, including **6 unique external testers**. A local developer playtest is necessary technical evidence but is not the six-tester empirical gate.

## Audit notes / remaining risk
Current layering remains aligned with the architecture: Bootstrap is composition root; `LegShapeService` owns authoritative shape processing; `RacerRuntime` owns body/legs/stabilizer/anti-stall lifetime; `StrokeRemoteTransport` remains transport-only; no early D05 `RacerService` exists.

The dominant unresolved risk is Roblox Studio solver/feel evidence. CI and static contracts can prove ownership/buildability but cannot prove live contact feel, obstacle niches, camera readability or human acceptance.

## HARD STOP
No C01, M0.5, multiplayer, meta, economy, shop, or later implementation may begin until the ordered R16 gates are completed and B17/G0 is explicitly recorded PASS or the Product Owner records another bounded gate decision.

## Next permitted task
**R16.5 Motor / Grip / Mass Feel — instrument current config, run automated contracts/CI, then obtain Studio measurement evidence before changing tuning values.**

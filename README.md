# Draw Racers

Roblox production repository for **Draw Racers**.

## Source of truth
The current production specification is in `docs/`. Use the current owner specs plus the recorded R16/R17 Decision Logs; do not mix older history packages into implementation context.

Before implementation, read:
1. `docs/AGENTS.md`
2. `docs/FEATURE_LIST.md`
3. `docs/SESSION.md`
4. `docs/26_HANDOFF_MAP.md`
5. the exact task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`
6. only the owner specs named by that row

## Current state
**R17 reference-core/shared-axle/camera-rider implementation is present in `main`; live solver/visual/human acceptance remains HUMAN STUDIO PENDING. Studio Gate A — HUMAN STUDIO PENDING. Studio Gate B — HUMAN STUDIO PENDING. Studio Gate C — HUMAN STUDIO PENDING. B17/G0 remains the downstream HUMAN_GATE PENDING.**

The retained R16.3B stroke contract still matters: after cleanup the server translates the **first cleaned point** to mechanical origin `(0,0)` without resizing, rotating or mirroring it. The semantic DrawInputRect is wide (`1.75:1`) but normalization remains isotropic by height. A sequence-scoped local presentation anchor may keep the accepted line visually where it was drawn, but never becomes server/physics authority.

R17 changes the mechanical/presentation implementation around that stroke contract:
- `LegPairAssembly` owns one **shared axle**, one `AxleRoot`, one `AxleJoint` and **one motor** for both rigid side `LegAssembly` objects.
- Left/Right consume the same ShapeSpec and use a fixed opposed structural relation: `RightPhaseOffsetDegrees = 180`. They rotate in the same shared motor direction/speed; there is no independent side motor and no runtime phase-chasing correction.
- Production `RaceCameraController`/`CameraMath` are active M0 owners. Hold-RMB yaw target supports **full 360°**, pitch remains bounded, rendered orbit/return are smoothed, and racer body rotation is not camera authority. Normal follow uses a **stable two-axis dead-zone** anchor before smoothing so small body oscillation does not drag the framing every frame.
- Instant redraw keeps the old pair live while a staged replacement evaluates a bounded **collision-safe redraw phase** search against Track geometry; only the chosen replacement is committed. Body CFrame and linear/angular velocity are not reset by the swap.
- Production `RiderPresentationController` is active as a normalized, client-only, nonphysical human rider presentation layer.
- R17.6 evidence isolates **body density**, **leg density**, **motor speed**, and optional **body friction** candidate families on temporary Studio racers. **Production tuning remains unchanged** until real Studio evidence selects a winner; `HUMAN BODY FEEL CHOICE PENDING` remains the state.
- R17.7 reuses the canonical flat/steps/wall/gap/tunnel course matrix across the reference shape set. `R17FINAL` remains an explicit ordered Studio evidence mode, but normal Roblox Studio `Play` now uses committed **`G0`** for the fast manual CORE loop and skips the automatic B03–B16/R17 startup evidence run.

Current contract corrections are recorded by `docs/DECISION_LOG_R17_OPPOSED_LEG_PHASE_2026-09-12.md` and `docs/DECISION_LOG_STUDIO_CORE_ITERATION_DEFAULT_2026-09-12.md`.

Latest verified pre-documentation-sync code/evidence head `c96220ffc9d645da0fac2baf431f48dd184a19be`, Contract Verify run `34707704124`: **202 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. These checks prove source contracts/buildability only; they do not prove Roblox Studio physics, camera feel, rider pose/readability or any human product gate.

Historical evidence retained for regression traceability:
- pre-R06 baseline: **66 passed, 0 failed**;
- R08/R09 repair line retained; R09 bounded repair: **80 passed, 0 failed**;
- R10–R12 final head `e2bedd34696bb99da43878c19d7984c9134c8bef`, run `34363706915`: **88 passed, 0 failed**;
- R14.1–R14.11 final code/tooling head `8a6a05a31427346d2a1437820ffa759f21fca90c`, run `34387618626`: **120 passed, 0 failed** plus successful **Rojo build**; **Studio checkpoints: HUMAN PENDING**;
- R15.1 head `be44304bf00391e05c7d7750609730a7368ebc87`, run `34394991926`: **125 passed, 0 failed** after the first force-based Studio attempt exposed `laneDeviation 5.199`;
- R16 Stage-A/B/C historical evidence remains in `docs/SESSION.md` / Decision Logs and is not promoted to live PASS by R17 source changes.

A01–A04 and B01–B02 remain recorded ACCEPTED. B03–B16 implementation/regression infrastructure exists, but required live Studio/human evidence remains pending. **B17/G0 is still a HUMAN_GATE before M0.5.**

## CORE / pre-G0 integrity repair
The repair series did not add unrelated product scope:

- **R01 — Geometry Authority:** one pure `GeometryMath` owner builds mapped points/physical segment plans.
- **R02 — Drawing/Network Correctness:** visual preview is independent from bounded semantic sampling; accepted results follow server truth.
- **R03 — Physics Contract:** collision matrix, canonical runtime track root, no hidden stabilizer propulsion.
- **R04 — Debug Correctness:** real collider/point/progress telemetry and deterministic debug targeting.
- **R05 — Studio/G0 Integration:** one selectable Studio harness; Studio-only temporary Player→RacerRuntime mapping, no early D05 `RacerService`.
- **R06 — Documentation consistency:** historical evidence reconciled without fabricating Studio acceptance.
- **R07–R09:** strict network work ordering, touch-first ownership, accepted-preview semantics and bounded recovery/validation behavior.
- **R10–R12:** drawing UI/hybrid-input/long-stroke/Character-isolation regression closure.
- **R14.1–R14.11:** authoritative shape parity, fail-closed Studio gate runner, network/recovery/rollback/validation contracts, shared type/remote registries and real CI Rojo build.
- **R15.1:** mechanical `PlaneConstraint` keeps Z lane-locked while X/Y remain physical; its old free-Z-rotation detail is superseded by R16.1.
- **R16.1:** BodyCollider remains upright about world X/Y/Z while physical X/Y translation stays free.
- **R16.2:** hub offsets remain owned by `PhysicsConfig.LegGeometry`.
- **R16.3/R16.3B:** one drawing → two first-point-anchored authoritative side shapes; the bounds-center rule is superseded.
- **R16.3B presentation split:** hidden authoritative physical colliders + nonphysical visible leg geometry.
- **R16.4 phase history:** the original target was 180°. An intermediate R17 interpretation changed the rigid pair to 0°; the 2026-09-12 reference correction supersedes that intermediate interpretation and restores a fixed **180°** Left↔Right relation on the same one-axle/one-motor architecture.
- **R17.3–R17.8:** origin/body/reference evidence experiments and explicit ordered `R17FINAL` handoff.
- **R17.9:** full-360 smoothed production free-look camera plus stable two-axis dead-zone normal follow.
- **R17.10–R17.14:** one shared `LegPairAssembly` axle/motor, fixed 180° rigid side relation, safe socket/collision contract and atomic whole-pair redraw.
- **Reference-feel redraw follow-up:** bounded collision-safe redraw phase selection happens before retiring the old pair, preserving body motion state.

Decision records include the R01–R16 records plus `docs/DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md`, `docs/DECISION_LOG_R17_SHARED_AXLE_CAMERA_FIDELITY_2026-09-11.md`, `docs/DECISION_LOG_R17_OPPOSED_LEG_PHASE_2026-09-12.md`, and `docs/DECISION_LOG_STUDIO_CORE_ITERATION_DEFAULT_2026-09-12.md`.

## Toolchain
Rokit manages Rojo. From the repository root:

```powershell
rokit install
rojo --version
rojo build -o DrawRacersDev.rbxlx
rojo serve
python verify.py
```

Then connect the Rojo Studio plugin to the local server shown by `rojo serve`.

## M0 implementation layers
### B03–B05 — Stroke processing
Deterministic wide-rectangle clamp/dedupe, DrawInputRect semantic coordinates, RDP simplification, open-polyline resampling, length/bounds validation and malformed/non-finite coverage. R16.3B server authority anchors the first cleaned point to `(0,0)` without resizing.

### B06–B10 — Physical locomotion foundation
Canonical 3×3×3 racer body, **upright** body stabilization, mechanical Z lane lock, one shared R17 `LegPairAssembly` axle with one motor, two rigid side assemblies fixed **180°** apart, canonical collision policy and no hidden forward race power.

### B11–B12 — Server authority/network boundary
`LegShapeService` validates semantic stroke intent and owns ShapeSpec/version progression. Exact semantic remotes are `SubmitStroke` and `StrokeResult`; accepted results carry server-authoritative first-point-anchored points. Client data cannot author world geometry, CFrame, segment plans, ShapeVersion or rewards.

### B13–B14 — Atomic redraw/security stress
Replacement shared leg pair stages before commit; failed redraw preserves the previous accepted pair. Before commit, a bounded collision-safe redraw phase search scores the staged shape against Track geometry; the old pair remains active until a replacement phase is chosen. Redraw preserves body CFrame and linear/angular velocity, while repeated malformed/stale/rate/size abuse remains regression-covered.

### B15–B16 — Canonical lab/debug
The M0 lab contains canonical flat/steps/wall/gap/tunnel representatives. DEV/STAGING/Studio debug telemetry exposes shape/segment/speed/motor/stuck/anti-stall/lane/checkpoint/progress information. Debug presentation is hidden by default behind F3.

## Studio CORE iteration / explicit evidence modes
`StudioHarnessConfig.Mode` is currently committed as **`G0`**. Normal Roblox Studio `Play` enters the interactive human CORE loop directly: scene + human racer + production drawing/camera/rider, without automatically running the B03–B16/R17 evidence suite or showing the normal `TESTS RUNNING` banner.

`R17FINAL`, `R16FINAL`, and the focused B/R16 harness modes remain selectable when explicit evidence is intentionally needed. Selecting `R17FINAL` still runs its ordered evidence path and may print `[DrawRacers][R17FINAL] HUMAN REVIEW READY`; that is never a human PASS.

Current manual CORE acceptance checks include:
- draw several materially different shapes and confirm the physical legs match the accepted drawing;
- confirm Left/Right are on opposite cube sides and remain fixed **180°** apart while sharing one motor direction/speed;
- confirm flat/steps/wall/gap/tunnel create visibly different shape trade-offs;
- redraw while moving without body teleport/reset or severe collision explosion;
- confirm upright/lane behavior, camera follow/orbit/return, and rider placement/readability;
- confirm no unexpected red DrawRacers runtime errors.

When explicit `R17FINAL` evidence is selected, expected repository/Studio evidence still includes the existing R16.5–R16.10 baseline, R17.3 origin comparison, R17.5 one-hinge/one-motor **180° structural opposition** and redraw continuity, R17.6 candidate telemetry, R17.7 reference-course output, and `[DrawRacers][R17FINAL] HUMAN REVIEW READY` only after automated evidence.

**Production tuning remains unchanged until Studio evidence is reviewed. HUMAN BODY FEEL CHOICE PENDING. Do not mark Studio Gate A, B, C or B17/G0 PASS from CI or repository inspection.** B17/G0 still follows `docs/55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md`, including the external-tester requirement.

## Working loop
`ChatGPT/GitHub change → git status --short → git pull --ff-only origin main → Rojo build/serve → Studio playtest → PASS/FAIL evidence → next allowed item`

Before pulling remote changes, inspect local status and do not overwrite uncommitted local work.
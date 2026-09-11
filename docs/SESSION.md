# SESSION.md — CURRENT STATE

Date: 2026-09-11  
Documentation version: **v1.5.0 R17 REFERENCE CORE / SHARED AXLE + CAMERA OVERRIDE**

## R17 CURRENT OVERRIDE — canonical current state
This section supersedes any lower historical wording that still calls R16.3B the current implementation or describes Camera/Rider as implementation-pending. The historical R01–R16 evidence below is intentionally retained for regression traceability.

Current production/reference-core facts:
- R16.3B stroke semantics remain current: the **first cleaned point** is translated to authoritative `(0,0)` without resizing, mirroring or rotating; the wide `1.75:1` DrawInputRect remains isotropic by height.
- R17 mechanical override is active in production M0 code: `LegPairAssembly` owns one shared axle, one `AxleRoot`, one `AxleJoint` and **one motor** for both rigid side `LegAssembly` objects.
- Left/Right consume the same ShapeSpec and keep a **structural 180** degree relation. There is no independent side motor and no runtime phase-chasing correction loop.
- R17 presentation override is active in M0: production `RaceCameraController` and `RiderPresentationController` are implemented owners. The camera follows Local Racer position rather than body rotation; hold-RMB yaw target supports **full 360°** with bounded pitch and smoothed return. The rider remains client-only, normalized and nonphysical.
- `R17FINAL` is the one-click Studio evidence aggregator. It runs existing R16 Stage-C evidence, R17 origin comparison, shared-axle phase evidence, body-feel experiment and reference-course evidence before `M0HumanHarness` and `[DrawRacers][R17FINAL] HUMAN REVIEW READY`.
- Committed `StudioHarnessConfig.Mode` remains `G0`; `R17FINAL` is selectable evidence mode and must not be treated as an automatic human PASS.
- Repository automation may prove source/build contracts only. Live shared-axle solver behavior, camera feel, rider pose/readability, origin/body-feel choices, Studio Gate A/B/C and B17/G0 remain **HUMAN STUDIO PENDING** / human-gated.
- R17 owner/decision records: `DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md` and `DECISION_LOG_R17_SHARED_AXLE_CAMERA_FIDELITY_2026-09-11.md`.

Pre-status-reconciliation automated evidence: head `073e90cf2e4b20b5153f0b324351fb2b4e3ca205`, Contract Verify run `34622695996` → **184 passed, 0 failed**, Rokit install PASS and **Rojo build PASS**. This is repository evidence only and does not promote a Studio/human gate.

## Product state
The product specification remains closed. CORE/pre-G0 repair **R01–R12**, bounded runtime/evidence closure **R14.1–R14.11**, planar correction **R15/R15.1**, R16 reference-parity work, and the bounded R17 reference-core/shared-axle/presentation overrides stay inside the already-approved B03–B16/B17 scope; they introduce **no new WHAT/WHY gameplay scope**.

Locked direction remains: 8-player live physics drawing race; one continuous player stroke controls two real rotating physical legs; no competitive power monetization; progression/meta remains outside M0 until the ordered gates allow it.

**R16.3B stroke contract retained under R17:** the visible input surface is one wide semantic DrawInputRect (`RawSemanticHalfWidth=1.75`, `RawSemanticHalfHeight=1.0`) normalized isotropically by height. After cleanup, the **first cleaned point** becomes the authoritative mechanical origin `(0,0)`; the previous R16.3A bounds-center/bounds midpoint pivot rule is superseded. One first-point-anchored ShapeSpec drives both sides; physical collider boxes stay hidden while separate visual geometry is nonphysical. A sequence-scoped client presentation anchor may preserve where the accepted line is drawn, but never enters ShapeSpec, network authority or collision physics.

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
- **R01 Geometry Authority** — `GeometryMath` is the single pure owner of authoritative-shape → mapped-points/segment-plan construction; server ShapeSpec carries that plan into the current shared pair/side geometry. R16.3B uses one visible **wide semantic DrawInputRect** with isotropic height-based normalization.
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
**R16 Stage A / R16.1–R16.4 implementation remains present; Studio Gate A — HUMAN STUDIO PENDING.**

Current retained Stage-A geometry/body contract:
- **R16.1 Upright Body** — X/Y body translation remains physically free; Z translation remains mechanically lane-locked; rotation about world X/Y/Z is locked/corrected. Only the shared leg pair intentionally rotates for locomotion. `AlignOrientation` uses `AllAxes` with an identity attachment basis.
- **R16.2 Hub Position** — `PhysicsConfig.LegGeometry` is the sole numeric owner: `HubOffsetX = 0.0`, `HubOffsetY = -0.35`, `HubOffsetZAbs = 1.62`; runtime consumes those values symmetrically.
- **R16.3 / R16.3B One drawing → Two legs / First-point Origin** — after clamp/dedupe/simplify/resample, the server translates the **first cleaned point** to `(0,0)` without scaling, mirroring or rotating. The resulting first-point-anchored authoritative shape is duplicated as the same XY geometry on Left/Right. The old R16.3A bounds-center rule is superseded.
- **R16.4 historical Twin-leg Phase requirement** — target right-minus-left phase is 180°. R17 supersedes the old independent-motor/live-per-side phase preservation mechanism with one shared axle and a structural 180 relation.

Historical R16.3A pre-Studio closure evidence is retained as history only. R16.3B supersedes its bounds-center mechanical-origin wording while keeping translation invariance, shape-size preservation, no hidden gameplay power and no client-authored world geometry.

Stage-A automated evidence before Stage-B work: head `81c7d84c542160f07fc4fe986df89e5aa69f8f73`; `Contract Verify` run `34448666472` → **142 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. This is repository evidence only and does not satisfy Studio physics/human acceptance.

## R16 Stage B authorization
**Stage B implementation authorized by Product Owner on 2026-09-10. Studio Gate A remains HUMAN STUDIO PENDING.**

This is a bounded process override, not a fabricated acceptance result. It authorized implementation/instrumentation work for `R16.5 → R16.7` while Stage-A live solver evidence remains pending. It does **not** authorize claiming that Stage A, Stage B, B17/G0, obstacle niches, or reference feel have passed without Roblox Studio evidence.

## R16 Stage B — feel/evidence implementation
**R16.5–R16.7: IMPLEMENTED/AUTOMATED GREEN at their historical evidence head; Studio Gate B — HUMAN STUDIO PENDING. Studio Gate A remains HUMAN STUDIO PENDING.**

Repository-level implementation includes:
- **R16.5 Motor / Grip / Mass Feel instrumentation** — production motor values remain `AngularVelocity=-8`, `MotorMaxTorque=35000`, `MotorMaxAcceleration=120`; existing leg material values live in `PhysicsConfig.PhysicalMaterials.LegSegment`. `R16B` measures `ROUND_01` after stable contact and requires +X average `4.0–7.0 studs/s`, motor enabled and `antiStallActive=false`.
- **R16.6 Vertical Physics evidence path** — normal locomotion remains solver-owned in Y; `RacerStabilizer` does not write body Y/CFrame/velocities and anti-stall remains X-only.
- **R16.7 Reference Shape Matrix** — executable canonical shapes include `ROUND_01`, `LONG_BAR_01`, `SMALL_ROUND_01`, `HOOK_01`, `ASYM_01`, `SUBOPTIMAL_01` and comparative flat/steps/gap/tunnel rules.
- Studio harness selection includes `R16B`; default remains `G0`.
- Canonical obstacle geometry was not changed during Stage-B instrumentation.

Latest Stage-B automated code evidence before Stage-C work: head `2197882e4c641e7c1d17a6dfc538f23fd1a521e6`; `Contract Verify` run `34451426807` → **145 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. These are repository/build facts only.

## R16 Stage C authorization
**R16 Stage C implementation authorized by Product Owner on 2026-09-10. Studio Gate A and Studio Gate B remain HUMAN STUDIO PENDING.**

The Product Owner explicitly requested repository implementation continue through **R16.8–R16.10** before the next Roblox Studio launch. This bounded override authorized code/tests/evidence harness work only.

## R16 Stage C — redraw/camera/canonical-pass implementation
**R16.8–R16.10 implementation remains present; historical implementation status: IMPLEMENTED/AUTOMATED GREEN. Studio Gate C — HUMAN STUDIO PENDING. Studio Gate A — HUMAN STUDIO PENDING. Studio Gate B — HUMAN STUDIO PENDING.**

Repository-level implementation includes:
- **R16.8 Redraw parity** — B14 performs 10 redraws while the racer has live motion state. R17 now preserves the single shared axle phase rather than two independent side phases.
- **R16.9 Reference camera/presentation** — historical side-oriented Studio presentation baseline; R17 production `RaceCameraController` now owns the active camera behavior.
- **R16.10 Canonical obstacle pass harness** — `R16C` reuses Stage-B evidence, verifies unchanged canonical pieces and performs 10 Heartbeat-spaced live redraws.

Historical R16.10 code/tooling evidence before R16.3B: head `3838a994f5b5164b64f3cdee934e5bc84f7be7a4`; `Contract Verify` run `34454820796` → **149 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**. These facts do not prove Roblox solver or visual acceptance.

## R16.3B retained stroke-origin correction
**R16.3B remains the current stroke-origin/input-surface contract under the R17 mechanical/presentation override. Human gate status is unchanged.**

Current implementation/contract points:
- `PhysicsConfig.StrokeProcessing` owns `RawSemanticHalfWidth = 1.75` and `RawSemanticHalfHeight = 1.0`.
- `StrokeMath.Normalize` uses half the DrawInputRect pixel height for both axes; `ClampToRect` enforces the wide semantic input rectangle.
- `StrokeMath.AnchorToFirstPoint` and `LegShapeService` make the first cleaned point the authoritative mechanical origin; ShapeSpec keeps size/proportions/order and does not require its bounds midpoint to be zero.
- `SubmitStroke` payload remains `{sequence, points}`; no presentation anchor is server authority.
- `DrawingController` keeps a bounded sequence-scoped presentation anchor.
- `LegAssembly` hides physical collider boxes and renders separate nonphysical visual segments/joints.
- debug presentation remains hidden by default behind F3.
- historical unified `R16FINAL` mode remains available; R17 adds `R17FINAL` above it.

Decision owner: `DECISION_LOG_R16_3B_STROKE_ORIGIN_REFERENCE_PARITY_2026-09-10.md`.

## R17 current implementation/evidence cursor
**R17 reference-core/shared-axle/camera/rider implementation is present. Studio Gate A — HUMAN STUDIO PENDING. Studio Gate B — HUMAN STUDIO PENDING. Studio Gate C — HUMAN STUDIO PENDING. B17/G0 remains HUMAN_GATE PENDING.**

Automation may prove repository contracts/buildability only. No Studio gate is silently marked PASS by CI.

Required next Studio pass is `R17FINAL` and must record:
- `[StudioGate] TOTAL 13 PASS / 0 FAIL` and `READY` without red DrawRacers runtime errors;
- R16.5–R16.10 baseline evidence still valid under the shared axle;
- `[DrawRacers][R17.3]` origin comparison evidence without silently changing production origin;
- `[DrawRacers][R17.5]` shared-axle phase evidence with one hinge/motor, structural 180 and redraw phase continuity;
- `[DrawRacers][R17.6]` body-feel candidate telemetry without mutating production tuning;
- `[DrawRacers][R17.7]` reference-course evidence;
- `[DrawRacers][R17FINAL] HUMAN REVIEW READY` only after the ordered evidence;
- human visual/feel check of rigid twin sides, no relative leg bending/drift, full-360 RMB camera, smooth return, readable rider pose, physical X/Y + mechanical Z lock, redraw continuity and no unexpected runtime errors.

A failure in any item keeps the corresponding gate PENDING and opens only a bounded repair. It does not authorize unrelated M0.5/multiplayer/meta work.

## R16.11 documentation/evidence freeze
**R16.11 must not freeze before Studio Gate C is actually recorded from Roblox Studio evidence.**

R16.11 may synchronize final numbers, selected tuning values, screenshots/log evidence and gate status only after the combined Studio pass. Under R17, any final freeze must also include the R17 shared-axle/camera/rider/origin/body-feel evidence choices. Until then, Studio Gate A/B/C remain HUMAN STUDIO PENDING.

## Empirical G0 still required
R16/R17 technical completion does not pass B17. `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` still requires the fixed G0 evidence, including **6 unique external testers**. A local developer playtest is necessary technical evidence but is not the six-tester empirical gate.

## Camera/rider presentation status under R17
**APPROVED + IMPLEMENTED EARLY BY R17 / HUMAN STUDIO PENDING.**

Decision owners: `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md` plus `DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md`.

Current contract:
- production `RaceCameraController` and `CameraMath` are active M0 owners; D09 later extends/accepts the same owner for multiplayer/rival readability rather than introducing a second camera;
- production `RiderPresentationController` is active as a separate normalized nonphysical human mini-avatar layer; E03 later extends/accepts the same owner for 8-player readability rather than introducing a duplicate owner;
- camera follows Local Racer position only, not BodyCollider rotation; RMB yaw target is full 360°, pitch is bounded, release returns smoothly;
- rider target scale hypothesis remains `0.65`; visuals remain nonphysical and never affect BodyCollider/LegPairAssembly/LegAssembly physics;
- human racers use server-authored `OwnerUserId` for presentation lookup in the current Studio/harness path; bots do not impersonate a Player;
- camera/rider presentation does not change ShapeSpec/stroke authority, remote schema, checkpoint/finish authority, economy/meta or Rojo mapping;
- human camera feel and rider pose/readability remain **HUMAN STUDIO PENDING**.

## Development execution workflow — ACTIVE
A repository-process decision was approved on 2026-09-10 for the current ChatGPT-driven workflow. This does **not** change gameplay scope or human gate state.

Current execution topology:

```text
ChatGPT remote GitHub main
-> user git pull on PC
-> Rojo (`default.project.json`)
-> Roblox Studio human acceptance
-> evidence back to ChatGPT
```

Bugfixes default to `INVESTIGATE / PLAN ONLY` under `BUGFIX_PROTOCOL.md` unless the Product Owner explicitly authorizes an already-bounded implementation/repair task. After approval, the plan/decision becomes the scope contract; implementation uses meaningful RED→GREEN, regression/full verification, diff audit, direct-main commit and fresh CI. `/review` follows `REVIEW_PROTOCOL.md` and is read-only. `AI_WORKFLOW_QUICKSTART.md` owns copy/paste prompts and local PowerShell/Rojo handoff.

Remote GitHub execution cannot assert that the user's local `C:\Dev\DrawRacers` worktree is clean. The user checks/protects local changes before pull. One task must not be concurrently implemented by remote GitHub and a local coding agent.

Decision owner: `DECISION_LOG_REMOTE_GITHUB_BUGFIX_WORKFLOW_2026-09-10.md`.

## Audit notes / remaining risk
Current layering remains aligned with the architecture: Bootstrap is composition root; `LegShapeService` owns authoritative shape processing; `RacerRuntime` owns body/shared pair/stabilizer/anti-stall lifetime; `LegPairAssembly` owns the one shared axle/motor; `StrokeRemoteTransport` remains transport-only; no early D05 `RacerService` exists.

The dominant unresolved risk is live Roblox Studio solver/feel evidence. CI and static contracts can prove ownership/buildability but cannot prove measured speed, obstacle niches, camera readability, rider pose or human acceptance.

## HARD STOP
No C01, M0.5, multiplayer, meta, economy, shop, or later implementation may begin until the ordered R17 Studio evidence is completed and B17/G0 is explicitly recorded PASS or the Product Owner records another bounded gate decision.

## Next permitted task
**After repository verification is green, run one combined Roblox Studio evidence pass on current main using `R17FINAL`. Record PASS/FAIL evidence; only bounded R17 repair or evidence freeze may follow.**

## R16 PRE-STUDIO CLOSURE P0–P6
**Historical repository closure record; Studio acceptance remains pending.**

P0 reconciled the earlier implementation plan with R16.3A centering and the current upright-body basis. P1 replaced fixed-loop B10 recovery evidence with real elapsed `<=0.25 s`. P2 isolated flat-speed evidence on `R16FlatBenchmark`. P3 recorded an actual below-`RecoveryKillY` trigger while preserving ShapeSpec/ShapeVersion. P4 moved deterministic spawn/contact/reset/measurement into shared `R16TrialRunner`, measured all six canonical shapes, and derived `noUniversalWinner` from real winner-set intersection. P5 required Wall good/bad evidence and P5.1 preserved dedicated `WallContactTimeout`. P6 owned that repository/documentation closure. R16.3B supersedes only the old bounds-center/square-input shape-origin semantics; R17 supersedes the old independent-leg motor/camera-future details; neither erases the historical P0–P6 evidence trail.

**Studio Gate A — HUMAN STUDIO PENDING**  
**Studio Gate B — HUMAN STUDIO PENDING**  
**Studio Gate C — HUMAN STUDIO PENDING**  
**B17/G0 — HUMAN_GATE PENDING**

`AUTOMATED GREEN` may be recorded only from a fresh successful current-head CI/toolchain run; it never promotes any human gate above.
# ARCHITECTURE MAP — CURRENT IMPLEMENTED RUNTIME

Status: **NAVIGATION CACHE — NOT SOURCE OF TRUTH**  
Last mechanical/runtime navigation audit: **2026-09-13**  
Audited mechanical base HEAD: **`07f640507bddbc12cd5d866e5bb7a3632a7a8565`**  
Repository: `rustail1/DrawRacers` / branch `main`

## 0. How to use this file

This file answers **where to look first**. Current code plus current owner specs win over this navigation cache if they disagree.

Do not rescan the whole repository for every bug. Start with the smallest owner cluster below, inspect its direct dependencies, and expand only when evidence crosses a boundary.

The 2026-09-13 MR-01..MR-06 rewrite replaced the legacy mechanical transition paths. Current mechanical dependency direction is:

```text
DrawingController
  -> CanonicalLegShape
  -> raw SubmitStroke
  -> LegShapeService
       -> CanonicalLegShape (server recompute / authority)
       -> RacerRuntime
            -> LegPairAssembly
                 -> Left LegAssembly
                 -> Right LegAssembly
```

Key current invariants:
- one canonical shape builder: `CanonicalLegShape`;
- one persistent `LegPairAssembly` after first accepted shape;
- one shared axle, one `AxleRoot`, one `AxleJoint`, one motor;
- persistent Left/Right `LegAssembly` owners, same canonical XY ShapeSpec, fixed structural `180°` opposition;
- redraw mutates side geometry only and performs bounded hub-to-tip reshape;
- normal redraw does not replace body/pair/axle/joint/side owners and does not reset body transform/velocities;
- no runtime compatibility hub markers, staging pair, retiring pair, or phase-chasing owner;
- normal Studio `Play` remains `G0`; long evidence remains explicit (`R16FINAL`, `R17FINAL`, focused modes);
- automation does not establish live physics/feel acceptance.

---

## 1. Rojo / DataModel bridge

Owner: `default.project.json`.

```text
src/shared  -> ReplicatedStorage.Shared
src/server  -> ServerScriptService
src/client  -> StarterPlayer.StarterPlayerScripts
```

Static roots for remotes, GUI, ServerStorage and `Workspace.Runtime` remain declared by the project file. No MR-01..MR-06 Rojo mapping change was required.

---

## 2. Current implemented M0/R17 system graph

```text
CLIENT INPUT / PREDICTION
InputController
  -> DrawingController
       -> raw pixel samples
       -> raw semantic samples
       -> CanonicalLegShape.Build (prediction)
       -> fixed-scale gameplay preview
       -> SubmitStroke {sequence, raw semantic points}

SERVER STROKE AUTHORITY
SubmitStroke
  -> StrokeRemoteTransport
  -> LegShapeService
       -> envelope / sequence / rate / payload validation
       -> CanonicalLegShape.Build (authoritative recompute)
       -> authoritative ShapeSpec/version
       -> RacerRuntime:ApplyValidatedShape
            -> first shape: create one persistent LegPairAssembly
            -> redraw: reuse same LegPairAssembly
                 -> same AxleRoot
                 -> same AxleJoint (single HingeConstraint motor)
                 -> same Left LegAssembly owner
                 -> same Right LegAssembly owner at fixed 180 degrees
                 -> both sides reshape hub-to-tip from one ShapeSpec
  -> StrokeResult authoritative acceptedPoints
  -> DrawingController authoritative accepted preview

LOW-LEVEL PURE MATH
CanonicalLegShape
  -> StrokeMath (clamp/dedupe/simplify/resample/anchor helpers)
  -> GeometryMath (fixed mapping/radial cap/segment plan helpers)
LegAssembly
  -> LegReshapeMath (arc-length prefix + one partial tip)

RACER PHYSICS / LEG PRESENTATION
RacerRuntime
  -> BodyCollider
  -> RacerStabilizer
  -> RacerAntiStall
  -> one persistent LegPairAssembly
       -> one AxleRoot / one AxleJoint motor
       -> Left/Right LegAssembly at fixed 180-degree relation
            -> persistent LegRoot welded to AxleRoot
            -> current physical Segments
            -> matching nonphysical Visual
                 -> VisualSegment
                 -> VisualJoint

CLIENT CAMERA / RIDER PRESENTATION
CameraMath
  -> RaceCameraController
       -> Local Racer position target
       -> stable two-axis dead-zone + smoothing
       -> full 360 yaw target + bounded pitch + smoothed return
RiderPresentationController
  -> normalized client-only nonphysical rider
  -> Workspace.Runtime.RacePresentation

STUDIO / M0
Bootstrap.server
  -> M0TestScene
  -> normal G0: direct manual CORE, no automatic long regression/evidence startup
  -> explicit evidence modes through StudioSpecRunner
       -> R16FINAL: R16FinalHarness
       -> R17FINAL: R17FinalHarness
Bootstrap.client
  -> InputController + DrawingController
  -> DebugTuningPanel
  -> RaceCameraController + RiderPresentationController after server readiness
```

---

## 3. Current client owners

| Area | Current file | Owns / inspect first | Immediate dependencies |
|---|---|---|---|
| Client composition | `src/client/Bootstrap.client.lua` | controller startup, remotes, Studio readiness, presentation owners | controllers, `RemoteNames`, `StudioHarnessConfig` |
| Pointer lifecycle | `src/client/Controllers/InputController.lua` | mouse/touch start/move/end/cancel, one active pointer | `UserInputService` |
| Drawing UI + submit flow | `src/client/Controllers/DrawingController.lua` | pixel trace, semantic samples, fixed-scale prediction, raw SubmitStroke, authoritative accepted rendering | `CanonicalLegShape`, `PhysicsConfig`, `StrokeTypes`, `InputController`, remotes |
| Production race camera | `src/client/Controllers/RaceCameraController.lua` | stable two-axis dead-zone, full 360 yaw, bounded pitch, smoothing/restore | `CameraMath`, racers, `LocalPlayer`, input |
| Human rider presentation | `src/client/Controllers/RiderPresentationController.lua` | client-only normalized rider keyed by server-authored presentation identity | Players, racers, `RacePresentation`, RunService |
| Debug UI | `src/client/Controllers/DebugTuningPanel.lua` | DEV/STAGING/Studio runtime telemetry display | racer attributes, RunService |
| G0 debug proxy | `src/client/Dev/M0G0PresentationHarness.lua` | Studio-only nonphysical body proxy; not camera authority | `StudioHarnessConfig`, `Workspace.Runtime` |

---

## 4. Current server owners

| Area | Current file | Owns / inspect first | Immediate dependencies |
|---|---|---|---|
| Server composition / Studio gate | `src/server/Bootstrap.server.lua` | M0 scene, G0/manual or selected evidence harness, readiness state | `M0TestScene`, `StudioSpecRunner`, `StudioHarnessConfig`, telemetry |
| Authoritative stroke processing | `src/server/Services/LegShapeService.lua` | network envelope/sequence/rate/payload validation, canonical server build, authoritative version/result | `CanonicalLegShape`, `PhysicsConfig`, `StrokeTypes`, `RacerRuntime` interface |
| Stroke remote transport | `src/server/Services/StrokeRemoteTransport.lua` | SubmitStroke binding, safe processor call, StrokeResult | `LegShapeService`, `StrokeTypes` |
| Racer lifecycle/orchestration | `src/server/Runtime/RacerRuntime.lua` | body/template lifetime, current ShapeSpec/version, one pair lifetime, reshape timeline, recovery preparation | `CanonicalLegShape` for internal/test ApplyShape, `LegPairAssembly`, stabilizer, anti-stall |
| Shared rotating leg pair | `src/server/Runtime/LegPairAssembly.lua` | **one shared axle**, `AxleRoot`, single `AxleJoint` motor, persistent Left/Right owners, fixed **180°** relation, reshape support/progress | `PhysicsConfig`, `StrokeTypes`, `CollisionGroups`, `LegAssembly` |
| One rigid leg side | `src/server/Runtime/LegAssembly.lua` | persistent `LegRoot`, current physical/visual canonical prefix, `VisualSegment`/`VisualJoint`, geometry replacement/progress/destroy; no motor/player/network owner | `LegReshapeMath`, `PhysicsConfig`, `StrokeTypes`, `CollisionGroups` |
| Upright + lane plane | `src/server/Runtime/RacerStabilizer.lua` | Z plane + upright orientation; no forward propulsion | `PhysicsConfig` |
| Bounded recovery assist | `src/server/Runtime/RacerAntiStall.lua` | eligible-contact bounded +X anti-stall only | `PhysicsConfig`, CollectionService |
| Collision matrix | `src/server/Runtime/CollisionGroups.lua` | semantic collision group registration/policy | PhysicsService |
| Debug telemetry | `src/server/Runtime/DebugTelemetry.lua` | current shape/collider/motor/speed/stuck/lane telemetry | `PhysicsConfig`, racers |
| M0 obstacle lab | `src/server/M0TestScene.lua` | canonical Flat/Steps/Wall/Gap/Tunnel environment | `M0SceneConfig`, collision groups |

Production `RacerService`, `RaceService`, `TrackService`, `ProgressValidationService`, persistence/economy/monetization services remain future/sequence-gated owners. Current G0 does not authorize them.

---

## 5. Shared owners / contracts

| Area | Current file | What to inspect |
|---|---|---|
| Core numbers | `src/shared/Config/PhysicsConfig.lua` | semantic limits, `LegCanvasHalfSpan=4.8`, radial cap `6.9`, side socket `1.5`, one motor, 180° phase, reshape bounds, materials/stabilization |
| Canonical shape | `src/shared/Math/CanonicalLegShape.lua` | exactly one ordered raw→canonical→mapped→segment-plan pipeline |
| Stroke helpers | `src/shared/Math/StrokeMath.lua` | low-level pure clamp/dedupe/simplify/resample/first-point anchor helpers |
| Geometry helpers | `src/shared/Math/GeometryMath.lua` | low-level fixed mapping/radial cap/segment-plan helpers |
| Reshape math | `src/shared/Math/LegReshapeMath.lua` | pure hub-to-tip arc-length evaluation |
| M0 evidence numbers | `src/shared/Config/M0SceneConfig.lua` | recovery, benchmark and canonical obstacle acceptance windows |
| Studio harness selection | `src/shared/Config/StudioHarnessConfig.lua` | normal Play default **G0**; `R17FINAL`, `R16FINAL` and focused modes remain selectable |
| Network/shared types | `src/shared/Types/StrokeTypes.lua` | SubmitStroke, StrokeResult, ShapeSpec fields |
| Remote registry | `src/shared/Net/RemoteNames.lua` | canonical active remote names |
| Camera math | `src/shared/Math/CameraMath.lua` | damping, dead-zone, angle smoothing, pitch clamp; no gameplay authority |

Exact current mechanical design: `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`. Exact implementation sequence/closure rules: `docs/superpowers/plans/2026-09-13-core-module-rewrite.md`. Exact instance tree and geometry contracts: docs `65` and `73`.

---

## 6. Studio/test owners

- `StudioSpecRunner.lua` + B03–B16 specs — explicit regression/evidence infrastructure; normal G0 startup skips the long suite.
- `M0HumanHarness.lua` — current manual G0 human racer/recovery path.
- `R16TrialRunner.lua` — shared contact/traversal measurement; falling below `RecoveryKillY` or solver instability remains unsafe, never success.
- `R16StageBHarness.lua` / `R16StageCHarness.lua` — reference matrix and moving-redraw evidence.
- `R16FinalHarness.lua` — **R16FINAL ordering/evidence** aggregate before human handoff.
- R17 evidence modules + `R17FinalHarness.lua` — explicit `R17FINAL` aggregate; ends at human review handoff, not human PASS.
- B08/B09/B10/B13/B14 — focused one-motor/phase/upright/redraw/stress evidence.
- `tests/test_mr02_leg_assembly_boundary.py` through `tests/test_mr06_mechanical_rewrite_closure.py` — current rewrite architecture/closure contracts.

---

## 7. Bug symptom -> first files to inspect

| Symptom | Start here | Verify next |
|---|---|---|
| click/touch does not start/end drawing | `InputController.lua`, `DrawingController.lua` | camera input ownership, client bootstrap, DrawHUD |
| live line/accepted line wrong or disappears | `DrawingController.lua`, `CanonicalLegShape.lua` | server accepted points, main-canvas mapping |
| **visible leg/stroke visual** wrong | `DrawingController.lua`, `LegAssembly.lua` | `VisualSegment`/`VisualJoint`, `CanonicalLegShape.lua`, docs `73` |
| preview/world leg mismatch | `DrawingController.lua`, `CanonicalLegShape.lua` | `LegShapeService.lua`, `GeometryMath.lua`, doc `73` |
| server rejects/accepts wrong drawing | `LegShapeService.lua`, `CanonicalLegShape.lua` | `StrokeTypes.lua`, `PhysicsConfig.lua`, doc `22` |
| wrong shape size/pivot/radial cap | `CanonicalLegShape.lua`, `GeometryMath.lua` | `PhysicsConfig.lua`, `LegAssembly.lua`, doc `73` |
| redraw pops/replaces mechanics | `RacerRuntime.lua`, `LegPairAssembly.lua`, `LegAssembly.lua` | B13/B14/MR03–MR06 contracts |
| one leg missing / wrong 180° phase | `LegPairAssembly.lua`, `LegAssembly.lua` | `PhysicsConfig.lua`, B09/R17 phase evidence |
| axle motor wrong / no movement | `LegPairAssembly.lua` | collision/material config, R16/R17 trial evidence |
| body rotates / lane Z drifts | `RacerStabilizer.lua` | `PhysicsConfig.lua`, B10/R16 evidence |
| support loss during redraw | `LegAssembly.lua`, `LegReshapeMath.lua`, `LegPairAssembly.lua` | gravity support bounds, moving-redraw evidence |
| fall/recovery behaves as success | `R16TrialRunner.lua`, `M0HumanHarness.lua` | `RecoveryKillY`, Stage B/C safety filters |
| camera jitter/orbit issue | `RaceCameraController.lua`, `CameraMath.lua` | client bootstrap/input interaction; live Studio evidence |
| rider pose/readability issue | `RiderPresentationController.lua` | presentation identity/seat reference; live Studio evidence |
| **R16FINAL ordering/evidence** issue | `R16FinalHarness.lua`, `R16StageCHarness.lua` | `R16TrialRunner.lua`, selected Studio mode |
| normal G0 unexpectedly runs tests | `StudioHarnessConfig.lua`, `Bootstrap.server.lua` | Studio mode decision/current local HEAD |
| files do not update in Studio | `default.project.json` | local git HEAD/status, Rojo connection/output |

---

## 8. Public/boundary surfaces to protect

Do not change casually:
- `SubmitStroke` / `StrokeResult` names and raw semantic direction;
- authoritative server ShapeSpec/version;
- one `BodyCollider` and persistent one-pair/one-axle/one-joint/one-motor ownership;
- same canonical XY on Left/Right with fixed 180° structural opposition;
- collision matrix;
- Rojo mapping;
- production camera/rider separation from physics authority;
- G0/human-gate semantics.

Camera/rider/cosmetic tuning remains outside the mechanical MR-01..MR-06 rewrite. Automated green means repository/build closure only; mechanical G0 remains a human acceptance gate.

## 9. Refresh trigger

Refresh this map when runtime ownership, client/server flow, public schemas, Rojo mapping or active subsystem set materially changes. A local bugfix that keeps owners unchanged does not require a full map rewrite.

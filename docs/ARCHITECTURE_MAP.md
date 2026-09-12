# ARCHITECTURE MAP — CURRENT IMPLEMENTED RUNTIME

Status: **NAVIGATION CACHE — NOT SOURCE OF TRUTH**  
Last full runtime/navigation audit: **2026-09-10**  
Audited runtime base HEAD: **`71530b92afb2ecb15c3c9c92cbd3649af6a5b40d`**  
Repository: `rustail1/DrawRacers` / branch `main`

## 0. How to use this file

This document exists to make investigation faster. It answers **where to look first**, not **what the game contract is**.

Priority when facts disagree:

```text
current GitHub main code
+ current Source-of-Truth owner docs
> this navigation map
```

Rules:
- use this map to choose the smallest likely subsystem before reading code;
- then re-read the current implementation of those files and their immediate dependencies;
- do not treat a statement in this map as proof of a root cause;
- do not rescan the whole repository for every bug without a concrete reason;
- if current code disagrees with this map, current code wins for implementation facts and the relevant Source-of-Truth owner wins for intended behavior;
- report the stale row during the task;
- update this map only when architecture/navigation materially changes: owner moves, file added/removed, dependency/public boundary changes, Rojo mapping changes, or a future target system actually becomes implemented;
- a normal local bugfix that keeps the same owners does **not** require a map update.

A documentation-only commit after the audited runtime base does not invalidate this map. A runtime/code/Rojo change after the audited base means the affected rows must be revalidated before relying on them.

**Bounded R16.3B refresh:** the `LegAssembly` presentation layer and `R16FINAL` evidence route below were revalidated after the full-audit base. This is not a new full-runtime audit; unaffected rows still derive from the audited base above.

**Bounded 2026-09-11 R17 presentation refresh:** Product Owner Decision Logs authorized the production `CameraMath` / `RaceCameraController` / `RiderPresentationController` slice before the normal D09/E03 cursor. The camera now owns a full 360 yaw target with smoothed rendered orbit and bounded pitch.

**Bounded 2026-09-11 R17 mechanical refresh:** `LegPairAssembly.lua` became the current production rotating-pair owner. It owns one shared axle and one `AxleJoint` HingeConstraint/motor for the two rigid side `LegAssembly` children. `RacerRuntime` atomically swaps the whole pair and preserves one axle phase. This replaces the former independent left/right hinge-motor navigation rows.

**Bounded 2026-09-12 CORE contract refresh:** the intermediate 0-degree side relation is superseded. The same shared axle/motor now mounts the Right copy at fixed **180°** relative to Left (`RightPhaseOffsetDegrees = 180`), with both sides driven in the same motor direction/speed. Normal Roblox Studio `Play` also returns to **`G0`** as the committed fast manual CORE default; automatic B03–B16/R17 startup evidence is skipped in G0, while `R17FINAL`/`R16FINAL`/focused modes remain explicitly selectable. R16/B17 human-gate facts and later race/gameplay service absence remain unchanged.

`docs/SOURCE_MAP.md` is different: it tracks provenance/research sources. `docs/21_SYSTEM_CLASS_ARCHITECTURE.md` is different: it owns target architecture. `docs/26_HANDOFF_MAP.md` routes features to owner specs. This file is only the **current implemented code navigation cache**.

---

## 1. Current Rojo / DataModel bridge

Owner: `default.project.json`.

Current filesystem mapping:

```text
src/shared  -> ReplicatedStorage.Shared
src/server  -> ServerScriptService
src/client  -> StarterPlayer.StarterPlayerScripts
```

The project file also declares the current static `ReplicatedStorage.Remotes`, `StarterGui` roots, `ServerStorage` roots, and `Workspace.Runtime` roots. `Workspace.Runtime.RacePresentation` is the existing presentation parent used by the client-only rider and Studio debug proxy; no Rojo mapping change was required for the R17 presentation/mechanical refresh.

Bug-routing rule: if a script/module is missing or appears in the wrong Studio location, inspect `default.project.json` plus the relevant filesystem path first. Do **not** edit Rojo mapping as a collateral bugfix unless evidence proves the mapping itself is the root cause.

---

## 2. Current implemented M0/R17 system graph

```text
CLIENT INPUT
InputController
  -> DrawingController
  -> ReplicatedStorage.Remotes.SubmitStroke

CLIENT CAMERA / RIDER PRESENTATION
CameraMath
  -> RaceCameraController
       -> resolves Local Racer from replicated OwnerUserId
       -> BodyCollider.Position only
       -> Scriptable camera / damping / dead-zone
       -> full 360 yaw target + bounded pitch + smoothed rendered orbit/return
RiderPresentationController
  -> resolves human racer from replicated OwnerUserId
  -> clones standardized nonphysical rider visual
  -> Workspace.Runtime.RacePresentation

SERVER STROKE AUTHORITY
SubmitStroke
  -> StrokeRemoteTransport
  -> LegShapeService
       -> StrokeMath
       -> GeometryMath
       -> RacerRuntime:ApplyValidatedShape
            -> LegPairAssembly
                 -> AxleRoot
                 -> AxleJoint (single HingeConstraint motor)
                 -> Left LegAssembly rigid side
                 -> Right LegAssembly rigid side at fixed 180 degrees
  -> StrokeResult
  -> DrawingController authoritative accepted preview

RACER PHYSICS / PRESENTATION
RacerRuntime
  -> BodyCollider + LeftHub + RightHub stable markers
  -> RacerStabilizer
  -> RacerAntiStall
  -> one shared LegPairAssembly
       -> one AxleRoot / one AxleJoint motor
       -> Left/Right LegAssembly at fixed 180-degree relation
            -> LegRoot rigidly mounted to AxleRoot
            -> welded physical Segments
            -> nonphysical Visual
                 -> VisualSegment
                 -> VisualJoint

STUDIO / M0
Bootstrap.server
  -> M0TestScene
  -> normal G0: skip startup regression/evidence suite
       -> M0HumanHarness
       -> manual CORE READY
  -> explicit evidence modes: StudioSpecRunner
       -> selected Studio harness
       -> R16FINAL: R16FinalHarness
            -> synchronous R16StageCHarness.RunEvidence
            -> M0HumanHarness
            -> HUMAN G0 READY
       -> R17FINAL: R17FinalHarness
            -> R16 Stage-C + R17 origin/phase/body/course evidence
            -> M0HumanHarness
            -> HUMAN REVIEW READY

Bootstrap.client
  -> InputController + DrawingController
  -> DebugTuningPanel
  -> RaceCameraController + RiderPresentationController after server gate READY
  -> G0 debug-proxy harness after server gate READY in G0/R16FINAL/R17FINAL
```

This is the current active M0/R17 implementation. It remains intentionally smaller than the full future target graph in doc `21`.

---

## 3. Current client owners

| Area | Current file | Owns / first things to inspect | Immediate dependencies |
|---|---|---|---|
| Client composition | `src/client/Bootstrap.client.lua` | DrawHUD bootstrap, remotes lookup, controller construction, Studio gate reaction, production camera/rider start, G0/R16FINAL/R17FINAL proxy start | `InputController`, `DrawingController`, `DebugTuningPanel`, `RaceCameraController`, `RiderPresentationController`, `RemoteNames`, `StudioHarnessConfig` |
| Pointer lifecycle | `src/client/Controllers/InputController.lua` | mouse/touch `start/move/end/cancel`, one active pointer, binding drawing surface | Roblox `UserInputService` |
| Drawing UI + submit flow | `src/client/Controllers/DrawingController.lua` | DrawCanvas/DrawInputRect runtime UI, live/accepted/thumbnail presentation, local cleanup, pending sequences/timeouts, SubmitStroke/StrokeResult client side | `PhysicsConfig`, `StrokeMath`, `StrokeTypes`, `InputController`, remotes |
| Production race camera | `src/client/Controllers/RaceCameraController.lua` | Local Racer position-only target, frame-rate-independent smoothing, stable horizontal/vertical dead-zone anchor, side framing, RMB/touch full-yaw target, bounded pitch, smooth release/return, camera capture/restore; no Remote/gameplay authority | `CameraMath`, `Workspace.Runtime.Racers`, `Players.LocalPlayer`, `UserInputService`, `PlayerGui` |
| Human rider presentation | `src/client/Controllers/RiderPresentationController.lua` | client-only human rider clone keyed by `OwnerUserId`, accessory fallback, nonphysical standardized scale/pose, body-position-only placement | `Players`, `Workspace.Runtime.Racers`, `Workspace.Runtime.RacePresentation`, `RunService` |
| Debug UI | `src/client/Controllers/DebugTuningPanel.lua` | reads replicated racer debug attributes and displays the DEV/STAGING/Studio panel | `Workspace.Runtime.Racers`, `RunService` |
| Current G0 debug proxy | `src/client/Dev/M0G0PresentationHarness.lua` | Studio-only G0/R16FINAL/R17FINAL nonphysical body proxy; deliberately **not** a camera owner | `StudioHarnessConfig`, `Workspace.Runtime` |

Important current absence: `HUDController`, `ResultsController`, Garage/Store/Settings race systems and the later race/gameplay services from doc `21` remain **target/future owners**. The R17 overrides do not authorize them.

---

## 4. Current server owners

| Area | Current file | Owns / first things to inspect | Immediate dependencies |
|---|---|---|---|
| Server composition / Studio gate | `src/server/Bootstrap.server.lua` | M0 scene build, G0 direct manual startup, explicit evidence-mode regression spec run, selected harness dispatch, STARTING/TESTING/BLOCKED/READY attribute | `DebugTelemetry`, `M0TestScene`, `StudioSpecRunner`, `StudioHarnessConfig` |
| Authoritative stroke processing | `src/server/Services/LegShapeService.lua` | network envelope/points validation, sequence/rate state, stroke cleanup, authoritative ShapeSpec, build request, acceptedPoints | `PhysicsConfig`, `StrokeMath`, `GeometryMath`, `StrokeTypes`, `RacerRuntime` interface |
| Stroke remote transport | `src/server/Services/StrokeRemoteTransport.lua` | SubmitStroke server binding, safe processor invocation, StrokeResult response | `LegShapeService`, `StrokeTypes` |
| Racer lifetime / atomic redraw | `src/server/Runtime/RacerRuntime.lua` | RacerTemplate/current racer model, body/hub markers, current ShapeSpec/version, staging+atomic swap of one shared leg pair, one axle-phase preservation, stabilizer/anti-stall lifetime | `PhysicsConfig`, `StrokeMath`, `GeometryMath`, `CollisionGroups`, `LegPairAssembly`, `RacerStabilizer`, `RacerAntiStall` |
| Shared rotating leg pair | `src/server/Runtime/LegPairAssembly.lua` | `AxleRoot`, single `AxleJoint` HingeConstraint/motor, side sockets, fixed **180°** right relation, left/right rigid side assembly lifetime, staged/commit/retire/destroy | `PhysicsConfig`, `StrokeTypes`, `CollisionGroups`, `LegAssembly` |
| One rigid leg side | `src/server/Runtime/LegAssembly.lua` | `LegRoot`, hidden welded physical collider `Segments`, separate nonphysical `VisualSegment`/`VisualJoint` presentation, fixed socket/phase transform, staged/commit/destroy; **no motor owner** | `PhysicsConfig`, `StrokeTypes`, `CollisionGroups` |
| Upright + lane plane | `src/server/Runtime/RacerStabilizer.lua` | mechanical Z plane and upright AlignOrientation, lane deviation flags | `PhysicsConfig` |
| Bounded recovery assist | `src/server/Runtime/RacerAntiStall.lua` | eligible-contact bounded +X anti-stall pulse only | `PhysicsConfig`, `CollectionService` |
| Collision groups | `src/server/Runtime/CollisionGroups.lua` | current collision-group registration and matrix | Roblox `PhysicsService` |
| Debug telemetry | `src/server/Runtime/DebugTelemetry.lua` | current racer debug attributes, collider/shared-motor/speed/stuck/lane sampling | `PhysicsConfig`, `Workspace.Runtime.Racers` |
| M0 obstacle lab | `src/server/M0TestScene.lua` | current canonical M0 Studio track pieces, reference benchmark, recovery surfaces, debug spawn/anchors | `M0SceneConfig`, `CollisionGroups` |

Important current absence: production `RacerService`, `RaceService`, `TrackService`, `ProgressValidationService`, persistence/economy/monetization services described in doc `21` are **not current M0 implementations**. `RacerService` remains explicitly reserved for D05. Current G0 uses the Studio-only resolver in `M0HumanHarness`; Camera/Rider only consume the existing replicated `OwnerUserId` presentation identifier.

---

## 5. Shared owners / contracts used by current code

| Area | Current file | What to inspect |
|---|---|---|
| Core physics/stroke numbers | `src/shared/Config/PhysicsConfig.lua` | stroke-processing limits, leg geometry/socket, one shared motor, fixed **180°** side relation, material, stabilization, anti-stall/recovery values |
| M0 scene/evidence numbers | `src/shared/Config/M0SceneConfig.lua` | lane/spawn/recovery, benchmark, R16 acceptance windows, canonical pieces |
| Studio harness selection | `src/shared/Config/StudioHarnessConfig.lua` | selected Studio mode; current committed normal Play default is **`G0`**; `R17FINAL`/`R16FINAL`/focused evidence modes remain selectable and do not imply automatic human PASS |
| Stroke pure math | `src/shared/Math/StrokeMath.lua` | clamp/dedupe/normalize/bounds/centering/simplify/resample/length |
| Physical segment planning | `src/shared/Math/GeometryMath.lua` | normalized point mapping, radial cap, segment plan, inner-hub collision eligibility |
| Camera pure math | `src/shared/Math/CameraMath.lua` | frame-rate-independent exponential smoothing, horizontal/vertical dead-zone stepping, angle smoothing and pitch clamp; no gameplay authority |
| Network/shared shape types | `src/shared/Types/StrokeTypes.lua` | SubmitStroke/StrokeResult/ShapeSpec fields |
| Remote name registry | `src/shared/Net/RemoteNames.lua` | canonical active remote names |

Intended behavior is still owned by the relevant Source-of-Truth docs, especially `03`, `08`, `16`, `21`, `22`, `24`, `55`, `59`, `60`, `62`, `65`, `68`, `73`, plus the dated R17 Decision Logs as routed by `26_HANDOFF_MAP.md`.

---

## 6. Studio/test owners

Current Studio regression/evidence code lives under `src/server/Tests/` plus source-contract tests under `tests/`.

Navigation clusters:
- `StudioSpecRunner.lua` + B03–B16 `*Spec.lua` — deterministic Studio regression suite available to explicit evidence modes; normal committed G0 startup skips this suite;
- `M0HumanHarness.lua` — current G0 human racer, real Character isolation, temporary Player->RacerRuntime resolver, fall recovery evidence;
- `R16ReferenceShapes.lua` — canonical reference shapes;
- `R16TrialRunner.lua` — shared trial spawn/contact/measurement runner; motor state reads the single `AxleJoint`;
- `R16StageBHarness.lua` — R16 Stage-B measurements;
- `R16StageCHarness.lua` — Stage-C aggregate/wall/live-redraw evidence; live redraw checks one pair/one axle phase and no `AxleRoot_Retiring` leak;
- `R16FinalHarness.lua` — `R16FINAL` synchronous Stage-B/C -> `M0HumanHarness` boundary; human G0 starts and `HUMAN G0 READY` is printed only after automated evidence passes;
- `R17OriginExperiment.lua`, `R17PhaseEvidence.lua`, `R17BodyFeelExperiment.lua`, `R17ReferenceCourseHarness.lua` — R17 reference evidence owners;
- `R17FinalHarness.lua` — `R17FINAL` ordered aggregate of R16 Stage-C + R17 automated/experimental evidence before `M0HumanHarness`; it prints `HUMAN REVIEW READY`, never a human PASS;
- B08/B09/B10/B13/B14 harnesses/specs — focused physics, structural phase, redraw and stress evidence;
- `tests/test_camera_rider_presentation.py` and `tests/test_r17_reference_fidelity_repair.py` — source-contract boundaries; they do not replace live Studio camera/visual/physics acceptance.

A test/harness is evidence infrastructure, not automatically the production owner of gameplay behavior.

---

## 7. Bug symptom -> first files to inspect

Use this table to avoid a repository-wide scan. Start with the listed cluster, then expand only when evidence crosses a boundary.

| Symptom | Start here | Usually verify next |
|---|---|---|
| click/touch does not begin/end drawing | `InputController.lua`, `DrawingController.lua` | `RaceCameraController.lua` touch/RMB ownership, `Bootstrap.client.lua`, current DrawHUD structure/owner docs |
| live line/accepted line wrong or disappears | `DrawingController.lua` | `StrokeMath.lua`, StrokeResult contract, UI owner docs |
| visible leg/stroke visual wrong | `DrawingController.lua`, `LegAssembly.lua` | `LegPairAssembly.lua`, presentation owners `59/62/73`, B07/B14 visual/physical invariants |
| server rejects valid drawing / accepts malformed drawing | `LegShapeService.lua` | `StrokeMath.lua`, `StrokeTypes.lua`, `PhysicsConfig.lua`, network doc `22` |
| accepted preview differs from physical shape | `LegShapeService.lua`, `DrawingController.lua` | `StrokeTypes.lua`, `StrokeMath.lua`, `GeometryMath.lua`, shape owner `73` |
| wrong leg shape/size/pivot/segment count | `LegShapeService.lua`, `GeometryMath.lua`, `LegAssembly.lua` | `LegPairAssembly.lua`, `RacerRuntime.lua`, `PhysicsConfig.lua`, owner `73` |
| one leg missing / wrong phase / redraw replaces badly | `RacerRuntime.lua`, `LegPairAssembly.lua`, `LegAssembly.lua` | `LegShapeService.lua`, B09/B13/B14/R16/R17 harnesses |
| both legs drift together / axle motor wrong | `LegPairAssembly.lua`, `RacerRuntime.lua` | `PhysicsConfig.lua`, B09/R17 phase evidence; there is no per-side phase-sync owner |
| body rotates / lane Z drifts | `RacerStabilizer.lua`, `RacerRuntime.lua` | `PhysicsConfig.lua`, `LegPairAssembly.lua`, B10/R16 evidence |
| racer will not move / stalls strangely | `LegPairAssembly.lua`, `RacerAntiStall.lua`, `RacerRuntime.lua` | `PhysicsConfig.lua`, track contact/collision owners, R16/R17 trial evidence |
| leg passes through / catches on obstacle | `LegAssembly.lua`, `LegPairAssembly.lua`, `GeometryMath.lua`, `CollisionGroups.lua` | `M0TestScene.lua`, `PhysicsConfig.lua`, Studio video/physics evidence |
| obstacle/wall/gap/tunnel wrong | `M0TestScene.lua`, `M0SceneConfig.lua` | `CollisionGroups.lua`, owner docs `60/65`, B15/R16 harness |
| redraw/network timeout/stale order bug | `DrawingController.lua`, `StrokeRemoteTransport.lua`, `LegShapeService.lua` | `RacerRuntime.lua`, `LegPairAssembly.lua`, `StrokeTypes.lua`, B12/B13/B14 tests |
| reset/respawn/G0 recovery bug | `M0HumanHarness.lua`, `RacerRuntime.lua` | `M0SceneConfig.lua`, `RacerStabilizer.lua`, `LegPairAssembly.lua`, `Bootstrap.server.lua` |
| production camera wrong/jitters/orbit steals input | `RaceCameraController.lua`, `CameraMath.lua` | `Bootstrap.client.lua`, `DrawingController.lua`, UI/camera owners `08/16/24/59/68`, real Studio evidence |
| rider missing/oversized/physical-looking | `RiderPresentationController.lua` | replicated racer `OwnerUserId`, source Character, `RacePresentation`, visual owners/Decision Log |
| G0 debug body proxy wrong | `M0G0PresentationHarness.lua` | `Bootstrap.client.lua`, `StudioHarnessConfig.lua`; camera bugs route to `RaceCameraController.lua` |
| debug values/panel wrong | `DebugTelemetry.lua`, `DebugTuningPanel.lua` | producer attributes in `RacerRuntime`/stabilizer/anti-stall and `AxleJoint` state |
| R16FINAL ordering/evidence wrong | `R16FinalHarness.lua`, `R16StageCHarness.lua`, `Bootstrap.server.lua` | `StudioSpecRunner.lua`, `StudioHarnessConfig.lua`, current `SESSION.md` gate status |
| R17FINAL ordering/evidence wrong | `R17FinalHarness.lua`, R17 evidence modules, `Bootstrap.server.lua` | `R16StageCHarness.lua`, `StudioHarnessConfig.lua`; human result still remains pending |
| Studio normal G0 unexpectedly runs tests / shows TESTS RUNNING | `StudioHarnessConfig.lua`, `Bootstrap.server.lua`, `Bootstrap.client.lua` | `DECISION_LOG_STUDIO_CORE_ITERATION_DEFAULT_2026-09-12.md`, Rojo sync/current local HEAD |
| Studio says TESTING/BLOCKED/READY unexpectedly | `Bootstrap.server.lua`, `StudioSpecRunner.lua` | selected harness, Output first failing spec |
| files do not appear/update in Studio | `default.project.json` | local `git rev-parse HEAD`, `git status`, Rojo connection/output, filesystem path |

---

## 8. Current public/boundary surfaces to protect during bugfixes

Do not change these casually. Read their owner docs/current definitions before proposing a fix:
- `SubmitStroke` / `StrokeResult` payload and names — `StrokeTypes.lua`, `RemoteNames.lua`, doc `22`;
- authoritative `ShapeSpec` meaning — `StrokeTypes.lua`, `LegShapeService.lua`, owner `73` plus current R16/R17 decision/status docs;
- racer body/leg ownership and dependency direction — doc `21` plus `RacerRuntime.lua` / `LegPairAssembly.lua` / `LegAssembly.lua`;
- shared axle invariant — exactly one `AxleJoint` motor, one axle phase, fixed **180°** Left↔Right structural relation, same motor direction/speed; no independent per-side motor or Heartbeat phase-chasing owner;
- collision groups/matrix — `CollisionGroups.lua`, owner `65`;
- production camera ownership — `CameraMath.lua` + `RaceCameraController.lua`, owners `08/16/24/59/68` and R17 Decision Logs; no second active camera controller and no artificial yaw wall;
- human rider presentation — `RiderPresentationController.lua` + `RacePresentation`; client-only/nonphysical and no gameplay authority;
- Rojo DataModel mapping — `default.project.json`;
- Studio/HUMAN gate semantics — `SESSION.md`, `55`, current R16/R17 decisions; automated green never promotes human Studio acceptance.

If a bugfix needs to change one of these boundaries and the approved plan did not include it, stop and request a plan amendment.

---

## 9. Map refresh trigger

Refresh the affected section when any of these happens:
1. production/runtime file is added, removed, renamed or its ownership moves;
2. client/server flow changes;
3. public remote/type/schema changes;
4. a future target service/controller from doc `21` becomes actually implemented;
5. Rojo mapping changes;
6. active milestone introduces a new runtime subsystem;
7. investigation proves this map stale.

Do **not** refresh the whole map merely because implementation line numbers or private helper functions changed.

When refreshing, record a new `Last full runtime/navigation audit` date and runtime base HEAD only if a real broad audit was performed. For the bounded R17 architecture/CORE contract changes, the affected navigation rows above were refreshed while the untouched parts still derive from the 2026-09-10 full audit.
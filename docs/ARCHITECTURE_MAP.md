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

The project file also declares the current static `ReplicatedStorage.Remotes`, `StarterGui` roots, `ServerStorage` roots, and `Workspace.Runtime` roots.

Bug-routing rule: if a script/module is missing or appears in the wrong Studio location, inspect `default.project.json` plus the relevant filesystem path first. Do **not** edit Rojo mapping as a collateral bugfix unless evidence proves the mapping itself is the root cause.

---

## 2. Current implemented M0/R16 system graph

```text
CLIENT INPUT
InputController
  -> DrawingController
  -> ReplicatedStorage.Remotes.SubmitStroke

SERVER STROKE AUTHORITY
SubmitStroke
  -> StrokeRemoteTransport
  -> LegShapeService
       -> StrokeMath
       -> GeometryMath
       -> RacerRuntime:ApplyValidatedShape
            -> LegAssembly Left
            -> LegAssembly Right
  -> StrokeResult
  -> DrawingController authoritative accepted preview

RACER PHYSICS
RacerRuntime
  -> BodyCollider + LeftHub + RightHub
  -> RacerStabilizer
  -> RacerAntiStall
  -> Left/Right LegAssembly
       -> LegRoot
       -> one HingeConstraint motor per leg
       -> welded physical segment chain

STUDIO / M0
Bootstrap.server
  -> M0TestScene
  -> StudioSpecRunner
  -> selected Studio harness

Bootstrap.client
  -> InputController + DrawingController
  -> DebugTuningPanel
  -> G0 presentation harness only after server gate READY in G0
```

This is the current active M0/R16 implementation. It is intentionally smaller than the future target graph in doc `21`.

---

## 3. Current client owners

| Area | Current file | Owns / first things to inspect | Immediate dependencies |
|---|---|---|---|
| Client composition | `src/client/Bootstrap.client.lua` | DrawHUD bootstrap, remotes lookup, controller construction, Studio gate reaction, G0 presentation start | `InputController`, `DrawingController`, `DebugTuningPanel`, `RemoteNames`, `StudioHarnessConfig` |
| Pointer lifecycle | `src/client/Controllers/InputController.lua` | mouse/touch `start/move/end/cancel`, one active pointer, binding drawing surface | Roblox `UserInputService` |
| Drawing UI + submit flow | `src/client/Controllers/DrawingController.lua` | DrawCanvas/DrawInputRect runtime UI, live/accepted preview, local cleanup, pending sequences/timeouts, SubmitStroke/StrokeResult client side | `PhysicsConfig`, `StrokeMath`, `StrokeTypes`, `InputController`, remotes |
| Debug UI | `src/client/Controllers/DebugTuningPanel.lua` | reads replicated racer debug attributes and displays the DEV/STAGING/Studio panel | `Workspace.Runtime.Racers`, `RunService` |
| Current G0 camera/presentation | `src/client/Dev/M0G0PresentationHarness.lua` | Studio-only G0 scriptable camera and non-physical body proxy | `StudioHarnessConfig`, `Workspace.Runtime` |

Important current absence: production `RaceCameraController`, `HUDController`, `ResultsController`, Garage/Store/Settings race systems from doc `21` are **target/future owners**, not current M0 runtime owners. Do not invent them to repair an M0 bug.

---

## 4. Current server owners

| Area | Current file | Owns / first things to inspect | Immediate dependencies |
|---|---|---|---|
| Server composition / Studio gate | `src/server/Bootstrap.server.lua` | M0 scene build, regression spec run, selected harness dispatch, TESTING/BLOCKED/READY attribute | `DebugTelemetry`, `M0TestScene`, `StudioSpecRunner`, `StudioHarnessConfig` |
| Authoritative stroke processing | `src/server/Services/LegShapeService.lua` | network envelope/points validation, sequence/rate state, stroke cleanup, authoritative ShapeSpec, build request, acceptedPoints | `PhysicsConfig`, `StrokeMath`, `GeometryMath`, `StrokeTypes`, `RacerRuntime` interface |
| Stroke remote transport | `src/server/Services/StrokeRemoteTransport.lua` | SubmitStroke server binding, safe processor invocation, StrokeResult response | `LegShapeService`, `StrokeTypes` |
| Racer lifetime / atomic redraw | `src/server/Runtime/RacerRuntime.lua` | RacerTemplate/current racer model, body/hubs, current ShapeSpec/version, staging+atomic swap of two legs, stabilizer/anti-stall lifetime | `PhysicsConfig`, `StrokeMath`, `GeometryMath`, `CollisionGroups`, `LegAssembly`, `RacerStabilizer`, `RacerAntiStall` |
| One physical leg | `src/server/Runtime/LegAssembly.lua` | LegRoot, one motor hinge, welded collider segment chain, staged/commit/destroy lifecycle | `PhysicsConfig`, `StrokeTypes`, `CollisionGroups` |
| Upright + lane plane | `src/server/Runtime/RacerStabilizer.lua` | mechanical Z plane and upright AlignOrientation, lane deviation flags | `PhysicsConfig` |
| Bounded recovery assist | `src/server/Runtime/RacerAntiStall.lua` | eligible-contact bounded +X anti-stall pulse only | `PhysicsConfig`, `CollectionService` |
| Collision groups | `src/server/Runtime/CollisionGroups.lua` | current collision-group registration and matrix | Roblox `PhysicsService` |
| Debug telemetry | `src/server/Runtime/DebugTelemetry.lua` | current racer debug attributes, collider/motor/speed/stuck/lane sampling | `PhysicsConfig`, `Workspace.Runtime.Racers` |
| M0 obstacle lab | `src/server/M0TestScene.lua` | current canonical M0 Studio track pieces, reference benchmark, recovery surfaces, debug spawn/anchors | `M0SceneConfig`, `CollisionGroups` |

Important current absence: production `RacerService`, `RaceService`, `TrackService`, `ProgressValidationService`, persistence/economy/monetization services described in doc `21` are **not current M0 implementations**. `RacerService` remains explicitly reserved for D05. Current G0 uses the Studio-only resolver in `M0HumanHarness`.

---

## 5. Shared owners / contracts used by current code

| Area | Current file | What to inspect |
|---|---|---|
| Core physics/stroke numbers | `src/shared/Config/PhysicsConfig.lua` | stroke-processing limits, leg geometry, motor, material, stabilization, anti-stall/recovery values |
| M0 scene/evidence numbers | `src/shared/Config/M0SceneConfig.lua` | lane/spawn/recovery, benchmark, R16 acceptance windows, canonical pieces |
| Studio harness selection | `src/shared/Config/StudioHarnessConfig.lua` | selected Studio evidence mode; current default remains `G0` |
| Stroke pure math | `src/shared/Math/StrokeMath.lua` | clamp/dedupe/normalize/bounds/centering/simplify/resample/length |
| Physical segment planning | `src/shared/Math/GeometryMath.lua` | normalized point mapping, radial cap, segment plan, inner-hub collision eligibility |
| Network/shared shape types | `src/shared/Types/StrokeTypes.lua` | SubmitStroke/StrokeResult/ShapeSpec fields |
| Remote name registry | `src/shared/Net/RemoteNames.lua` | canonical active remote names |

Intended behavior is still owned by the relevant Source-of-Truth docs, especially `03`, `16`, `21`, `22`, `55`, `59`, `60`, `65`, `68`, `73` as routed by `26_HANDOFF_MAP.md`.

---

## 6. Studio/test owners

Current Studio regression/evidence code lives under `src/server/Tests/`.

Navigation clusters:
- `StudioSpecRunner.lua` + B03–B16 `*Spec.lua` — deterministic Studio regression suite started by server bootstrap;
- `M0HumanHarness.lua` — current G0 human racer, real Character isolation, temporary Player->RacerRuntime resolver, fall recovery evidence;
- `R16ReferenceShapes.lua` — canonical R16 reference shapes;
- `R16TrialRunner.lua` — shared R16 trial spawn/contact/measurement runner;
- `R16StageBHarness.lua` — R16 Stage-B measurements;
- `R16StageCHarness.lua` — Stage-C aggregate/wall/live-redraw evidence;
- B08/B09/B10 harnesses — focused earlier physics evidence modes.

A test/harness is evidence infrastructure, not automatically the production owner of gameplay behavior.

---

## 7. Bug symptom -> first files to inspect

Use this table to avoid a repository-wide scan. Start with the listed cluster, then expand only when evidence crosses a boundary.

| Symptom | Start here | Usually verify next |
|---|---|---|
| click/touch does not begin/end drawing | `InputController.lua`, `DrawingController.lua` | `Bootstrap.client.lua`, current DrawHUD structure/owner docs |
| live line/accepted line wrong or disappears | `DrawingController.lua` | `StrokeMath.lua`, StrokeResult contract, UI owner docs |
| server rejects valid drawing / accepts malformed drawing | `LegShapeService.lua` | `StrokeMath.lua`, `StrokeTypes.lua`, `PhysicsConfig.lua`, network doc `22` |
| accepted preview differs from physical shape | `LegShapeService.lua`, `DrawingController.lua` | `StrokeTypes.lua`, `StrokeMath.lua`, `GeometryMath.lua`, shape owner `73` |
| wrong leg shape/size/pivot/segment count | `LegShapeService.lua`, `GeometryMath.lua`, `LegAssembly.lua` | `RacerRuntime.lua`, `PhysicsConfig.lua`, owner `73` |
| one leg missing / wrong phase / redraw replaces badly | `RacerRuntime.lua`, `LegAssembly.lua` | `LegShapeService.lua`, B09/B13/B14/R16 harnesses |
| body rotates / lane Z drifts | `RacerStabilizer.lua`, `RacerRuntime.lua` | `PhysicsConfig.lua`, `LegAssembly.lua`, B10/R16 evidence |
| racer will not move / stalls strangely | `LegAssembly.lua`, `RacerAntiStall.lua`, `RacerRuntime.lua` | `PhysicsConfig.lua`, track contact/collision owners, R16 trial evidence |
| leg passes through / catches on obstacle | `LegAssembly.lua`, `GeometryMath.lua`, `CollisionGroups.lua` | `M0TestScene.lua`, `PhysicsConfig.lua`, Studio video/physics evidence |
| obstacle/wall/gap/tunnel wrong | `M0TestScene.lua`, `M0SceneConfig.lua` | `CollisionGroups.lua`, owner docs `60/65`, B15/R16 harness |
| redraw/network timeout/stale order bug | `DrawingController.lua`, `StrokeRemoteTransport.lua`, `LegShapeService.lua` | `StrokeTypes.lua`, `PhysicsConfig.lua`, B12/B13/B14 tests |
| reset/respawn/G0 recovery bug | `M0HumanHarness.lua`, `RacerRuntime.lua` | `M0SceneConfig.lua`, `RacerStabilizer.lua`, `Bootstrap.server.lua` |
| G0 camera/body proxy wrong | `M0G0PresentationHarness.lua` | `Bootstrap.client.lua`, `StudioHarnessConfig.lua`, camera owner docs |
| debug values/panel wrong | `DebugTelemetry.lua`, `DebugTuningPanel.lua` | producer attributes in `RacerRuntime`/stabilizer/anti-stall |
| Studio says TESTING/BLOCKED/READY unexpectedly | `Bootstrap.server.lua`, `StudioSpecRunner.lua` | selected harness, Output first failing spec |
| files do not appear/update in Studio | `default.project.json` | local `git rev-parse HEAD`, `git status`, Rojo connection/output, filesystem path |

---

## 8. Current public/boundary surfaces to protect during bugfixes

Do not change these casually. Read their owner docs/current definitions before proposing a fix:
- `SubmitStroke` / `StrokeResult` payload and names — `StrokeTypes.lua`, `RemoteNames.lua`, doc `22`;
- authoritative `ShapeSpec` meaning — `StrokeTypes.lua`, `LegShapeService.lua`, owner `73` plus current R16 decision/status docs;
- racer body/leg ownership and dependency direction — doc `21` plus `RacerRuntime.lua`/`LegAssembly.lua`;
- collision groups/matrix — `CollisionGroups.lua`, owner `65`;
- Rojo DataModel mapping — `default.project.json`;
- Studio/HUMAN gate semantics — `SESSION.md`, `55`, current R16 decisions.

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

When refreshing, record a new `Last full runtime/navigation audit` date and runtime base HEAD only if a real broad audit was performed. For a bounded architecture change, update only the affected row and note that the rest of the map still derives from the previous audit.
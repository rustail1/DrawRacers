# R14 Pre-G0 Runtime Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining pre-G0 runtime integrity gaps while preserving the B17 hard stop and existing M0 architecture.

**Architecture:** Keep the existing one-way draw path `DrawingController → SubmitStroke → StrokeRemoteTransport → LegShapeService → RacerRuntime → LegAssembly`. Harden authority, Studio-only presentation/gating, collision isolation, failure bounds, atomic redraw, and CI without instantiating future production service/controller families.

**Tech Stack:** Roblox Luau, Rojo 7.7.0 via Rokit, Python repository contract tests, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-09-r14-pre-g0-runtime-closure-design.md`

## Global Constraints
- Work only on `main`; no branch/PR workflow for this project.
- TDD RED→GREEN for every behavioral repair.
- Do not implement C01/M0.5, D05 RacerService, production RaceCameraController, CosmeticService, ProgressValidationService, or later systems.
- Human Studio checkpoints remain PENDING until actually run in Roblox Studio.
- B17/G0 cannot be marked PASS from CI.

---

### Task 1: R14.1 authoritative accepted-shape parity

**Files:**
- Modify: `src/server/Services/LegShapeService.lua`
- Modify: `src/client/Controllers/DrawingController.lua`
- Modify: `src/server/Tests/B12StrokeRemoteSpec.lua`
- Test: `tests/test_r14_pre_g0_runtime_closure.py`

**Interfaces:**
- `StrokeResult` accepted payload gains `acceptedPoints: Array<{x:number,y:number}>`.
- `acceptedPoints` is copied directly from `buildResult.shapeSpec.normalizedPoints`.
- DrawingController uses the returned points as `_acceptedSemanticPoints`.

- [ ] Add a failing repository test asserting accepted StrokeResult contains authoritative points and DrawingController consumes result points instead of pending points.
- [ ] Run `python verify.py`; expect exactly the new R14.1 test(s) to fail while previous checks remain green.
- [ ] Extend accepted network result construction in `LegShapeService` with bounded semantic `acceptedPoints` derived from ShapeSpec.
- [ ] Update `DrawingController:_onStrokeResult` to validate/copy server `acceptedPoints` before replacing accepted preview; malformed accepted geometry fails closed and preserves the prior accepted preview.
- [ ] Extend B12 Studio spec to assert the accepted payload points equal `racer:GetCurrentShapeSpec().normalizedPoints`.
- [ ] Run full contract CI; require green before Studio checkpoint.
- [ ] Human Studio checkpoint: normal/noisy stroke accepted preview must match the physical shape visually; record PENDING until user runs it.

### Task 2: R14.2 Studio-only G0 presentation

**Files:**
- Create: `src/client/Dev/M0G0PresentationHarness.lua`
- Modify: `src/client/Bootstrap.client.lua`
- Test: `tests/test_r14_pre_g0_runtime_closure.py`

**Interfaces:**
- Harness runs only in Studio and only when `StudioHarnessConfig.Mode == "G0"`.
- Reads replicated racer with `DebugTarget=true` and its `BodyCollider`.
- Owns only local camera/debug presentation.

- [ ] Add RED checks for Studio/G0 gating, non-colliding debug visual, camera follow target, and no production RaceCameraController dependency.
- [ ] Implement the minimal presentation harness with local debug body proxy and +X look-ahead camera follow.
- [ ] Wire it from client bootstrap only for Studio G0 mode.
- [ ] Run full CI green.
- [ ] Human Studio checkpoint: racer remains visible and camera follows through flat/steps/wall; record PENDING until user runs it.

### Task 3: R14.3 aggregate Studio gate runner

**Files:**
- Create: `src/server/Tests/StudioSpecRunner.lua`
- Modify: `src/server/Bootstrap.server.lua`
- Modify: `src/client/Bootstrap.client.lua`
- Modify: `src/client/Controllers/DrawingController.lua`
- Test: `tests/test_r14_pre_g0_runtime_closure.py`

**Interfaces:**
- Server sets replicated Studio gate state `TESTING | READY | BLOCKED`.
- Runner executes B03–B16 specs under protected calls and returns aggregate success/failure.
- G0 starts only on READY.

- [ ] Add RED checks requiring aggregate protected execution and explicit gate states.
- [ ] Implement `StudioSpecRunner` and replace direct sequential spec calls in bootstrap.
- [ ] Gate G0 startup on aggregate READY.
- [ ] Gate client drawing while Studio state is TESTING/BLOCKED and expose a clear DEV blocked message.
- [ ] Run full CI green.
- [ ] Human negative checkpoint: intentionally inject one spec failure locally and verify `BLOCKED`/no G0; then restore and verify `READY`. Never commit the intentional failure.

### Task 4: R14.4 Default collision hardening

**Files:**
- Modify: `src/server/Runtime/CollisionGroups.lua`
- Modify: `tests/test_r03_physics_contract_repair.py`
- Optionally extend: `src/server/Tests/B10StabilizationSpec.lua`

- [ ] Add RED assertions for `Default ↔ RacerBody=false` and `Default ↔ RacerLeg=false`.
- [ ] Implement the two collision matrix entries while preserving Track collisions.
- [ ] Run full CI green.
- [ ] Human Studio physics checkpoint with a collidable Default-group test part; record PENDING until run.

### Task 5: R14.5 bounded pending/network failures

**Files:**
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/client/Controllers/DrawingController.lua`
- Modify: `src/server/Services/StrokeRemoteTransport.lua`
- Modify: `src/server/Services/LegShapeService.lua` if safe sequence extraction needs exposure/refactor
- Test: `tests/test_r14_pre_g0_runtime_closure.py`
- Extend: `src/server/Tests/B12StrokeRemoteSpec.lua`

**Interfaces:**
- Engineering bounds: result timeout 3.0s, max pending strokes 4.
- Timeout preserves previous accepted shape.
- Unexpected transport exception returns generic `SERVER_ERROR` only when a safe sequence is known.

- [ ] Add RED tests for bounded pending count/lifetime and protected server transport.
- [ ] Add config constants and pending metadata/generation cleanup.
- [ ] Implement timeout eviction and pending-count bound.
- [ ] Wrap processor handling in transport `xpcall`, logging server details and returning bounded generic error.
- [ ] Add/extend B12 failure-path coverage.
- [ ] Run full CI green.
- [ ] Human Studio checkpoint by temporarily preventing response locally; record PENDING until run.

### Task 6: R14.6 Studio-only G0 fall recovery

**Files:**
- Modify: `src/shared/Config/M0SceneConfig.lua`
- Modify: `src/server/Tests/M0HumanHarness.lua`
- Test: `tests/test_r14_pre_g0_runtime_closure.py`

- [ ] Add RED checks for a configured recovery kill-Y and exactly one active G0 racer respawn path.
- [ ] Add a Studio-only watcher that recreates only the active G0 RacerRuntime at canonical spawn below the kill-Y threshold.
- [ ] Ensure transport resolver follows the replacement racer through the existing `activeRacer` reference.
- [ ] Run CI green.
- [ ] Human Studio gap/fall checkpoint; record PENDING until run.

### Task 7: R14.7 atomic redraw commit rollback

**Files:**
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Modify: `src/server/Runtime/LegAssembly.lua` only if a deterministic injectable commit hook is required
- Modify: `src/server/Tests/B13AtomicRedrawSpec.lua`
- Test: `tests/test_r14_pre_g0_runtime_closure.py`

- [ ] Add a failing B13 path that injects failure after one staged leg commit begins.
- [ ] Add repository checks ensuring rollback path exists.
- [ ] Implement protected commit/enable transaction with cleanup and restoration of old leg names/references.
- [ ] Assert ShapeVersion/body CFrame/linear/angular velocity stay unchanged on injected commit failure.
- [ ] Run full CI green.

### Task 8: R14.8 player-facing validation UX

**Files:**
- Modify: `src/client/Controllers/DrawingController.lua`
- Test: `tests/test_r14_pre_g0_runtime_closure.py`

- [ ] Add RED checks that raw internal reason codes are not directly assigned to the player toast.
- [ ] Map geometry/input rejects to `DRAW A DIFFERENT SHAPE` and transport/server failures to `TRY AGAIN`, while retaining exact reason codes in logs.
- [ ] Preserve existing 2.0s toast bound and mutual exclusion with DrawHint.
- [ ] Run full CI green.

### Task 9: R14.9 Rojo build in CI

**Files:**
- Modify: `.github/workflows/contract-verify.yml`
- Test: GitHub Actions workflow itself

- [ ] Add pinned Rokit installation/setup and `rokit install`.
- [ ] Add `rojo build -o /tmp/DrawRacersDev.rbxlx` after `python verify.py`.
- [ ] Push and require the workflow to finish SUCCESS.

### Task 10: R14.10 shared types and RemoteNames

**Files:**
- Modify: `src/shared/Types/StrokeTypes.lua`
- Modify: `src/shared/Net/RemoteNames.lua` only if additional typed ownership is useful
- Modify: `src/client/Bootstrap.client.lua`
- Modify: `src/client/Controllers/DrawingController.lua`
- Modify: `src/server/Services/StrokeRemoteTransport.lua`
- Modify: `src/server/Services/LegShapeService.lua`
- Modify: `src/server/Tests/M0HumanHarness.lua`
- Test: `tests/test_r14_pre_g0_runtime_closure.py`

- [ ] Add RED checks for `SubmitStrokePayload`, `StrokeResultPayload`, actual ShapeSpec debug fields, and RemoteNames consumption.
- [ ] Add/update shared type definitions to match runtime data exactly.
- [ ] Replace duplicated remote string literals in active M0 consumers with `RemoteNames`.
- [ ] Narrow important `any` boundaries where possible without redesigning the module graph.
- [ ] Run full CI green.

### Task 11: R14.11 docs/evidence reconciliation

**Files:**
- Modify: `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`
- Modify: `docs/README.md`
- Modify: `docs/SESSION.md`
- Modify: `docs/FEATURE_LIST.md`
- Create: `docs/DECISION_LOG_PRE_G0_RUNTIME_CLOSURE_R14_2026-09-09.md`
- Test: repository consistency tests

- [ ] Clarify in `21` that target architecture does not authorize early task owners; RacerService remains D05 and M0 uses the Studio injected resolver.
- [ ] Record R14.1–R14.10 implementation/CI evidence, with every unrun Studio checkpoint explicitly PENDING.
- [ ] Keep B17/G0 HUMAN_GATE PENDING.
- [ ] Run final full CI and record exact HEAD/run/result.

## Final completion gate
R14 implementation/regression may be called complete only when all automated checks and Rojo build are green. R14 Studio checkpoints and B17/G0 remain separate human evidence; do not claim them without user-provided Studio output/playtest evidence.

# Early Camera + Rider Presentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the already-approved stable production race camera and nonphysical human rider presentation early, without pulling any race/gameplay dependency ahead of its normal milestone.

**Architecture:** `CameraMath` owns pure deterministic smoothing/dead-zone/orbit helpers. `RaceCameraController` is the sole active camera owner and resolves the local replicated racer by server-authored `OwnerUserId`; `RiderPresentationController` independently owns client-only rider visual lifecycle. The existing Studio G0 presentation harness remains debug-proxy-only so no second camera owner exists.

**Tech Stack:** Roblox Luau, Rojo, Python contract verification, GitHub Actions/Rokit/Rojo build.

**Spec:** `docs/DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md` plus sequence override `docs/DECISION_LOG_EARLY_CAMERA_RIDER_SEQUENCE_OVERRIDE_2026-09-11.md`.

## Global Constraints

- Work directly on `main`; no branches/PRs.
- Do not implement `RacerService`, race state, HUD, progress, persistence, or new Remotes.
- Camera target derives from local racer position only, never BodyCollider rotation.
- Camera defaults: FOV 60, look-ahead 11, height 10, side distance 23, position damping 0.16, look-target damping 0.12, vertical dead-zone 0.50, vertical damping 0.22, yaw ±40°, pitch ±18°, return 0.40 s.
- RMB is desktop camera free-look; LMB stays drawing-owned.
- Touch camera ownership begins only outside DrawInputRect/active UI and never changes mid-gesture.
- Rider scale starts at 0.65; rider is client presentation only and every BasePart is nonphysical.
- Accessories are excluded from the first rider clone as the deterministic oversized-appearance fallback.
- Automated checks may establish `AUTOMATED GREEN`; camera feel/rider readability stay `HUMAN STUDIO PENDING`.

---

### Task 1: Add a failing Camera/Rider contract test

**Files:**
- Create: `tests/test_camera_rider_presentation.py`

**Interfaces:**
- Consumes: current filesystem layout and bootstrap source.
- Produces: source-contract coverage for the new pure math/controller/rider boundaries and single-camera-owner integration.

- [ ] **Step 1: Write the failing test**

The test must require:
- `src/shared/Math/CameraMath.lua`;
- `src/client/Controllers/RaceCameraController.lua`;
- `src/client/Controllers/RiderPresentationController.lua`;
- frame-rate-independent exponential smoothing and vertical dead-zone helpers;
- exact locked camera defaults and no Remote usage in the camera owner;
- local racer resolution through `OwnerUserId`;
- RMB-only desktop orbit with ±40/±18 bounds and automatic 0.40 s return;
- touch begin exclusion through `DrawInputRect`/GUI hit testing;
- rider `ScaleTo(0.65)`, accessory exclusion, nonphysical BasePart properties, and no server/runtime physics dependencies;
- `Bootstrap.client.lua` starts the production owners;
- `M0G0PresentationHarness.lua` no longer writes camera type/FOV/CFrame.

- [ ] **Step 2: Run `python verify.py` in CI and verify RED**

Expected: exactly the new Camera/Rider contract test fails because the three production modules do not yet exist and the G0 harness still owns camera state. Existing tests remain green.

- [ ] **Step 3: Commit RED**

Commit message: `test: define early camera rider presentation contract`.

---

### Task 2: Implement pure CameraMath + production RaceCameraController

**Files:**
- Create: `src/shared/Math/CameraMath.lua`
- Create: `src/client/Controllers/RaceCameraController.lua`

**Interfaces:**
- `CameraMath.ExpAlpha(dt:number, dampingTime:number) -> number`
- `CameraMath.SmoothNumber(current:number, target:number, dt:number, dampingTime:number) -> number`
- `CameraMath.SmoothVector(current:Vector3, target:Vector3, dt:number, dampingTime:number) -> Vector3`
- `CameraMath.StepVerticalDeadZone(current:number, raw:number, deadZone:number, dt:number, dampingTime:number) -> number`
- `CameraMath.ClampOrbit(yaw:number, pitch:number, yawLimit:number, pitchLimit:number) -> (number, number)`
- `RaceCameraController.new(playerGui:PlayerGui) -> controller`
- `controller:Start()` / `controller:Destroy()`

- [ ] **Step 1: Implement minimal pure math**

Use `1 - math.exp(-dt / dampingTime)` with zero/negative damping treated as immediate convergence. Vertical dead-zone holds the smoothed Y while raw Y remains inside ±deadZone; outside it, converge toward the nearest boundary-adjusted target so small bounce does not move the camera.

- [ ] **Step 2: Implement local racer lookup and camera lifecycle**

Scan/watch `Workspace.Runtime.Racers` for a Model whose numeric `OwnerUserId` equals `Players.LocalPlayer.UserId`, then use its `BodyCollider.Position` only. Capture and restore prior CameraType/FOV when ownership starts/stops. Do not read body rotation for camera orientation.

- [ ] **Step 3: Implement stable framing and input**

Use the locked constants. Build the canonical side camera from a world-up `CFrame.lookAt` around the smoothed position/look-ahead target. RMB hold consumes mouse delta into bounded yaw/pitch; RMB release exponentially returns angles to zero using 0.40 s. LMB is never bound by this controller.

For touch, claim a touch only at begin when `PlayerGui:GetGuiObjectsAtPosition` reports no visible/active UI ownership and the point is not inside any `DrawInputRect`; keep ownership for that touch until end/cancel. Touch delta only changes bounded orbit for a claimed world touch.

- [ ] **Step 4: Keep camera network-free**

No RemoteEvent lookup, FireServer, server state mutation, or movement authority belongs in this controller.

---

### Task 3: Implement client-only RiderPresentationController

**Files:**
- Create: `src/client/Controllers/RiderPresentationController.lua`

**Interfaces:**
- `RiderPresentationController.new() -> controller`
- `controller:Start()` / `controller:Destroy()`

- [ ] **Step 1: Resolve human racers only**

Watch `Workspace.Runtime.Racers`. A racer is eligible only with numeric `OwnerUserId > 0` that resolves to a current Player. Do not create a human rider for bots/no-owner racers.

- [ ] **Step 2: Clone and normalize presentation**

Temporarily allow the source Character to be cloned. Strip scripts/tools and all `Accessory` descendants as the deterministic oversized-appearance fallback. Scale the clone with `Model:ScaleTo(0.65)`.

- [ ] **Step 3: Make every rider part nonphysical**

For every BasePart set `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true`, `Anchored=true`. Hide HumanoidRootPart. Disable/remove gameplay humanoid behavior so the clone is visual only.

- [ ] **Step 4: Apply static jockey/frog pose and body-position-only placement**

Apply deterministic Motor6D transforms for common shoulder/hip joints when present. Parent visuals under `Workspace.Runtime.RacePresentation`. Each render step position the rider from `BodyCollider.Position` and cube size, face canonical +X, and never inherit cube roll/pitch/yaw.

---

### Task 4: Integrate one camera owner in Bootstrap/G0

**Files:**
- Modify: `src/client/Bootstrap.client.lua`
- Modify: `src/client/Dev/M0G0PresentationHarness.lua`

**Interfaces:**
- Bootstrap composes production camera/rider owners once.
- G0 harness retains only Studio debug proxy presentation.

- [ ] **Step 1: Wire production owners**

Construct/start `RaceCameraController` and `RiderPresentationController` after the Studio server gate becomes READY; outside Studio start them with normal client bootstrap. They may remain idle until an eligible racer exists.

- [ ] **Step 2: Remove camera writes from G0 harness**

Keep `G0DebugBodyProxy` creation/update and Studio-mode gating, but remove CurrentCamera CameraType/FOV/CFrame ownership and camera restore state.

- [ ] **Step 3: Run targeted/full verification**

`python verify.py` must become fully green without weakening existing R16 tests. If an old test asserts G0 camera ownership, update that assertion only to the new single-owner production camera contract.

---

### Task 5: Fresh CI, Rojo build, diff audit, and human gate handoff

**Files:**
- No new scope unless verification proves an implementation defect inside Tasks 1–4.

- [ ] **Step 1: Verify fresh CI belongs to the implementation HEAD**

Require `python verify.py` green, Rokit install green, and `rojo build default.project.json` green.

- [ ] **Step 2: Audit base-to-head diff**

Allowed runtime files are only CameraMath, RaceCameraController, RiderPresentationController, Bootstrap.client, and M0G0PresentationHarness; allowed test/doc files are the new Camera/Rider test, this plan, and the sequence-override Decision Log. No server physics/network/Rojo mapping file changes.

- [ ] **Step 3: Report Studio acceptance as pending**

Human Studio acceptance must verify stable side framing, vertical dead-zone feel, RMB orbit/release return, DrawCanvas input non-interference, touch ownership, rider visual pose/scale, and that rider remains nonphysical. Do not mark those PASS remotely.

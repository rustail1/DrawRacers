# Core Module Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` for this repository because DrawRacers works directly on `main`; execute MR-01 -> MR-06 sequentially and gate every MR before continuing.

**Goal:** Replace the legacy mechanical core with one direct pipeline from raw drawing input to one canonical `ShapeSpec`, one persistent axle/motor, and two persistent side-leg owners whose geometry is reshaped in place.

**Architecture:** `DrawingController -> CanonicalLegShape -> LegShapeService -> RacerRuntime -> LegPairAssembly -> LegAssembly`. Canonical geometry is pure shared math and is recomputed authoritatively by the server. The racer owns one `BodyCollider`; `LegPairAssembly` owns one persistent axle/joint/motor and two side assemblies for the racer lifetime; redraw mutates only side geometry and never replaces the pair, axle, joint, or body transform.

**Tech Stack:** Roblox Studio / Luau, Rojo, Rokit, Python contract tests, GitHub Actions `Contract Verify`.

**Spec:** `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`

## Global Constraints

- Repository: `rustail1/DrawRacers`; branch: **`main` only**; no branches and no PRs.
- Re-fetch `main` before every repository write. If HEAD moved, inspect the intervening diff before continuing.
- Preserve `SubmitStroke` / `StrokeResult` network direction and schema: client submits raw semantic `{x,y}` points; server recomputes canonical geometry and is authoritative.
- Preserve one `BodyCollider`, one persistent `AxleRoot`, one persistent `AxleJoint` motor, two rigid side legs, same canonical XY geometry, and structural Right-side phase `180` degrees.
- Redraw must not set body CFrame, pivot, anchoring, or linear/angular velocity.
- Gameplay canvas uses fixed isotropic scale; no per-shape auto-fit on the main drawing surface.
- `G0` remains ordinary fast Studio Play; long evidence suites do not auto-run in normal Play.
- Automated checks cannot close physics/feel/visual acceptance. Final mechanical state after MR-06 is `READY FOR HUMAN ACCEPTANCE` until the Product Owner supplies Studio/video evidence.
- Current tuning remains unchanged unless a later explicit `TUNING` task is approved: `LegCanvasHalfSpan=4.8`, `MaxLegExtentFromHub=6.9`, physical thickness `0.54`, visual thickness `0.78`, `HubOffsetY=0`, side sockets `Z=+-1.5`, reshape duration bounded to `0.08..0.15s`.
- Do not touch camera, rider presentation, cosmetics, race/product scope, or monetization during MR-01..MR-06.
- RED tests are run before production changes, but intentional RED commits are not pushed to `main`; each main checkpoint must be reviewable and GREEN.

---

## MR-01: CanonicalLegShape + LegShapeService

**Purpose:** Establish exactly one canonical shape pipeline and make the server authority layer a thin envelope/sequence/rate/payload owner.

**Files:**
- Create: `src/shared/Math/CanonicalLegShape.lua`
- Delete: `src/shared/Math/LegShapeMath.lua`
- Keep as low-level pure helpers: `src/shared/Math/StrokeMath.lua`, `src/shared/Math/GeometryMath.lua`
- Rewrite: `src/server/Services/LegShapeService.lua`
- Minimal dependency migration only: `src/client/Controllers/DrawingController.lua` (`LegShapeMath` require/call -> `CanonicalLegShape`; full controller cleanup is MR-05)
- Keep network/data shape: `src/shared/Types/StrokeTypes.lua`
- Replace/update tests that name the retired owner: `tests/test_b11_leg_shape_service.py`, `tests/test_rcp03_canonical_shape_parity.py`, `tests/test_rcp08_draw_world_radial_cap_parity.py`, plus any existing contract test whose only failure is an assertion that `LegShapeMath` must exist.
- Update Studio behavior spec only if its owner name is hard-coded: `src/server/Tests/B11LegShapeServiceSpec.lua`.

**Public APIs preserved:**
- `CanonicalLegShape.Build(rawPoints, strokeConfig, geometryConfig) -> canonical?, reason?`
- `LegShapeService.ValidateAndBuild(racerRuntime, rawPoints, motorEnabled?)`
- `LegShapeService.ExtractSafeSequence(payload)`
- `LegShapeService.CreateSubmitProcessor(deps)` and processor `:Handle(playerKey, payload)`
- `RacerRuntime:ApplyValidatedShape(shapeSpec, motorEnabled)` remains the server commit boundary.
- `StrokeResult.acceptedPoints` remains authoritative `ShapeSpec.normalizedPoints` serialized to `{x,y}`.

**Legacy paths removed:**
- `LegShapeMath` module/name.
- Any simplify/resample/mapping implementation inside `LegShapeService` or `DrawingController`.
- Any second canonical-pipeline function with different ordering.

**RED first:**
- New/updated contract test requires `CanonicalLegShape.lua`, rejects `LegShapeMath.lua`, requires one ordered pure pipeline `ClampToRect -> Dedupe -> SimplifyRDP -> Resample -> AnchorToFirstPoint -> BuildSegmentPlan`, and forbids `Workspace`, `Players`, `RemoteEvent`, `Instance.new`, UI calls.
- Server contract test requires one `CanonicalLegShape.Build` call and forbids `StrokeMath` cleanup or `GeometryMath.BuildSegmentPlan` in the service.
- Network contract test keeps stale-sequence, rate, payload-size, malformed-point and authoritative accepted-point behavior.

**GREEN criteria:**
- Same raw semantic stroke produces the same canonical result on client prediction and server path.
- First canonical point is origin; mapped points and segment plan represent the same centerline after radial capping.
- Server remains authoritative and increments shape version exactly once per accepted request.
- No production reference to `LegShapeMath` remains.

**Verification/checkpoint:** focused MR-01 tests -> `python verify.py` -> `rokit install --no-trust-check` -> `rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx` -> fresh `Contract Verify` for MR-01 HEAD -> read-only diff/self-review.

**Commit:** `refactor: centralize canonical leg shape authority`

---

## MR-02: LegAssembly

**Purpose:** Make one `LegAssembly` own exactly one side's materialized physical and visual geometry, driven only by a ready canonical segment plan.

**Files:**
- Rewrite: `src/server/Runtime/LegAssembly.lua`
- Keep/use: `src/shared/Math/LegReshapeMath.lua`
- Keep tuning owner: `src/shared/Config/PhysicsConfig.lua` (no numeric changes)
- Replace/update: `tests/test_b07_leg_assembly.py`, `tests/test_rcp04_rapid_reshape.py`
- Add focused architecture regression: `tests/test_mr02_leg_assembly_boundary.py`

**Public APIs after MR-02:**
- `LegAssembly.new({racerModel, side, axleRoot, socketZ, phaseDegrees})`
- `LegAssembly:ReplaceGeometry(shapeSpec)` (accepts canonical data only; stores the new plan/mapped points and starts at progress 0)
- `LegAssembly:SetReshapeProgress(progress)`
- `LegAssembly:CompleteReshape()`
- getters required by current diagnostics/consumers: `GetModel`, `GetRoot`, `GetSegments`, `GetMappedPoints`, `GetStructuralPhaseDegrees`
- `Destroy()`.

**Legacy paths removed:**
- `staged` construction.
- `Commit()` / `IsCommitted()` staging lifecycle.
- `SetRetiring()` and `_Retiring` names.
- Building an entire future leg and hiding completed future colliders during reshape.

**Implementation shape:**
- Side root remains welded to the persistent axle and remains the side owner.
- `ReplaceGeometry` clears old side geometry, stores canonical `segmentPlan`/`mappedPoints`, and materializes progress 0.
- `SetReshapeProgress` uses `LegReshapeMath.Evaluate`; only the completed prefix plus at most one partial tip collider/visual exists as gameplay geometry. Future full colliders are not present but hidden.
- Visual and physical centerlines use the exact same canonical endpoints; only thickness/material differ.

**RED first:**
- Test forbids staging/retiring APIs and requires a persistent side root.
- Test asserts no code path pre-creates all future colliders and then merely toggles `CanCollide`/transparency for reshape.
- Test requires arc-length prefix + one partial tip using `LegReshapeMath.Evaluate`.

**GREEN criteria:**
- One side owns no player/network/race/recovery/camera/opposite-side/motor logic.
- Progress 0 contains no future full collider; 0<p<1 contains exact completed prefix plus at most one partial segment; progress 1 matches full canonical plan.
- Destroy leaves no side geometry leak.

**Verification/checkpoint:** focused MR-02 tests -> full verify -> Rojo build -> CI -> diff/self-review.

**Commit:** `refactor: rewrite single-side leg assembly`

---

## MR-03: LegPairAssembly

**Purpose:** Make the pair a permanent mechanical owner for one axle/motor and two permanent side assemblies; redraw changes side geometry only.

**Files:**
- Rewrite: `src/server/Runtime/LegPairAssembly.lua`
- Update focused/legacy contracts: `tests/test_b08_one_hinge_motor.py`, `tests/test_b09_two_legs_phase.py`, `tests/test_b13_atomic_redraw.py`, `tests/test_b14_redraw_stress.py`, `tests/test_rcp01_stable_axle.py`, `tests/test_rcp04_rapid_reshape.py`
- Add: `tests/test_mr03_persistent_leg_pair.py`

**Public APIs preserved/normalized:**
- `LegPairAssembly.new({racerModel, shapeSpec, motorEnabled?, initialPhaseDegrees?})`
- `GetRoot`, `GetJoint`, `GetLeftLeg`, `GetRightLeg`, `GetPhaseDegrees`
- `ReplaceGeometry(shapeSpec)` / `BeginGeometryReshape(shapeSpec)` becomes one direct in-place geometry update path; if both names are still required by a caller during this MR, only one is public by MR exit and `RacerRuntime` is migrated in MR-04.
- `SetReshapeProgress(progress)`
- `CompleteReshapeForRecovery()`
- `SetEnabled(enabled)`
- `Destroy()`.

**Legacy paths removed:**
- pair/side `staged` state and commit lifecycle.
- `buildStagedSides`.
- old/new pair or old/new side handoff.
- `SetRetiring` / `_Retiring` naming.
- redraw allocation of another `AxleRoot` or `HingeConstraint`.

**Implementation shape:**
- Constructor creates exactly one `AxleRoot`, one `AxleJoint`, one Left `LegAssembly`, one Right `LegAssembly`.
- Right root phase is always `PhysicsConfig.Motor.RightPhaseOffsetDegrees` relative to Left; current value remains 180.
- Redraw calls `ReplaceGeometry` on the existing left/right assemblies with the same canonical `ShapeSpec`; both use the same progress.
- Existing short vertical reshape gravity compensation may remain pair-owned because it supports the pair transition; it must be bounded to reshape, world-Y only, and never anchor/teleport/propel X/Z.

**RED first:**
- Identity-contract test requires pair/root/joint/left owner/right owner to stay stable through redraw.
- Test forbids staged/retiring symbols and additional HingeConstraint allocation outside constructor.
- Test requires Left/Right to receive one shared canonical spec and Right phase 180.

**GREEN criteria:**
- Redraw creates no new pair, axle, joint, left owner, or right owner.
- One motor remains enabled/disabled only through `SetEnabled`.
- Both sides reshape in lockstep and structural phase remains 180.

**Verification/checkpoint:** focused MR-03 tests -> full verify -> Rojo build -> CI -> diff/self-review.

**Commit:** `refactor: make leg pair mechanics persistent`

---

## MR-04: RacerRuntime

**Purpose:** Reduce runtime to racer lifecycle/orchestration around one body and one persistent `LegPairAssembly`.

**Files:**
- Rewrite: `src/server/Runtime/RacerRuntime.lua`
- Keep external recovery policy owners unchanged.
- Update: `tests/test_b06_racer_runtime.py`, `tests/test_bg04_06_core_fall_repair.py`, `tests/test_redraw_spawn_safety.py`, `tests/test_r12_long_stroke_and_respawn_isolation.py`, `tests/test_rcp01_stable_axle.py`, `tests/test_rcp04_rapid_reshape.py`, and any runtime closure test whose assertion encodes staged pair replacement instead of stable identity.
- Add: `tests/test_mr04_runtime_orchestration.py`

**Public APIs preserved:**
- `RacerRuntime.new(params)`; `EnsureTemplate()`.
- `GetModel`, `GetBody`, `GetStabilizer`, `GetAntiStall`, `GetLegPair`.
- `GetShapeVersion`, `GetCurrentShapeSpec`.
- `ApplyShape(normalizedPoints, motorEnabled?)` only for internal/test callers; it must delegate to the canonical owner rather than rebuilding geometry math itself.
- `ApplyValidatedShape(shapeSpec, motorEnabled?)`.
- `PrepareForRecovery()`.
- existing lifecycle/getter APIs used outside the mechanical cluster remain source compatible.

**Legacy paths removed:**
- direct `StrokeMath`/`GeometryMath` shape construction in runtime.
- staged initial/replacement pair logic after initial pair creation.
- `RedrawSpawnSafety` as a redraw/pair-replacement mechanism; if initial-spawn phase safety is still legitimately required, it must not create a second persistent pair and is isolated to initial construction only.
- cached `leftLeg`/`rightLeg` ownership if they merely duplicate `LegPairAssembly` state.

**Implementation shape:**
- First accepted shape creates the one persistent pair if absent; all later shapes call pair geometry replacement only.
- Runtime owns reshape heartbeat/generation and updates pair progress for the short configured duration.
- `PrepareForRecovery()` cancels heartbeat and completes current reshape; it does not choose destination or write body teleport/velocity.
- Runtime updates current `ShapeSpec`, shape version, and debug attributes only after successful application.

**RED first:**
- Runtime boundary test forbids `GeometryMath.BuildSegmentPlan`, `StrokeMath.AnchorToFirstPoint`, individual segment creation, pair replacement during redraw, and body transform/velocity writes in shape application.
- Recovery test requires completion of transient geometry but forbids destination selection/teleport.

**GREEN criteria:**
- one body and one pair survive repeated redraws.
- shape version/current spec commit is coherent and monotonic.
- recovery preparation leaves destination policy external.
- no body CFrame/PivotTo/Anchored/velocity mutation occurs during normal redraw.

**Verification/checkpoint:** focused MR-04 tests -> full verify -> Rojo build -> CI -> diff/self-review.

**Commit:** `refactor: simplify racer mechanical orchestration`

---

## MR-05: DrawingController

**Purpose:** Make drawing input/presentation consume the same canonical math as the server, send raw semantic intent, and render accepted server truth without a second geometry pipeline.

**Files:**
- Rewrite mechanical/drawing-processing portions of: `src/client/Controllers/DrawingController.lua`
- Keep shared owner: `src/shared/Math/CanonicalLegShape.lua`
- Preserve remote types: `src/shared/Types/StrokeTypes.lua`
- Update: `tests/test_b01_input_controller.py` only if integration assumptions changed, `tests/test_b02_local_stroke_preview.py`, `tests/test_r02_drawing_network_correctness.py`, `tests/test_r11_input_preview_bounds.py`, `tests/test_bg01_canvas_world_orientation_parity.py`, `tests/test_rcp03_canonical_shape_parity.py`, `tests/test_rcp08_draw_world_radial_cap_parity.py`, and current R16/R17 drawing parity tests that assert a retired private pipeline.
- Add: `tests/test_mr05_drawing_controller_boundary.py`

**Public behavior preserved:**
- existing controller lifecycle and UI binding.
- input collects pixel samples; screen-to-semantic conversion remains isotropic using canvas height.
- canonical prediction uses `CanonicalLegShape.Build(rawSemanticVectors, ...)`.
- `SubmitStroke` sends raw semantic samples, never mapped/segment data.
- accepted result renders authoritative `acceptedPoints` from server.
- sequence-scoped presentation anchor may be re-applied only for screen presentation; it never enters `ShapeSpec` or network authority.
- thumbnail may auto-fit; gameplay canvas may not.

**Legacy paths removed:**
- any second dedupe/simplify/resample/clamp/mapping path.
- per-shape auto-fit on main gameplay canvas.
- using raw display polyline as accepted authority.

**RED first:**
- Controller boundary test requires `CanonicalLegShape.Build`, raw semantic payload, fixed-scale main mapping, authoritative accepted-point rendering.
- It forbids `SimplifyRDP`, `Resample`, `Dedupe`, `ClampToRect`, `GeometryMath`, and main-canvas fit usage inside the controller.

**GREEN criteria:**
- short drawings preview and become short legs; large drawings remain large subject to canonical radial cap.
- local prediction and server accepted centerline use the same canonical semantics.
- rejection preserves prior accepted shape and shows validation state without changing server-owned racer geometry.

**Verification/checkpoint:** focused MR-05 tests -> full verify -> Rojo build -> CI -> diff/self-review.

**Commit:** `refactor: unify drawing prediction with canonical shape`

---

## MR-06: Mechanical Integration Cleanup + Audit

**Purpose:** Remove the remaining transition artifacts, update architectural/status documentation, and prove that only the new direct mechanical path remains before asking for human G0.

**Files:**
- Audit/cleanup as needed only inside the mechanical cluster: `src/shared/Math/CanonicalLegShape.lua`, `StrokeMath.lua`, `GeometryMath.lua`, `LegReshapeMath.lua`, `src/server/Services/LegShapeService.lua`, `src/server/Runtime/LegAssembly.lua`, `LegPairAssembly.lua`, `RacerRuntime.lua`, `src/client/Controllers/DrawingController.lua`.
- Update architecture/status docs: `docs/ARCHITECTURE_MAP.md`, `docs/SESSION.md`, `docs/FEATURE_LIST.md`.
- Add: `tests/test_mr06_mechanical_rewrite_closure.py`.
- Update/delete stale contract tests only where they encode the removed implementation rather than a still-valid invariant.

**Closure assertions:**
- no production `LegShapeMath`.
- no `staged`, `Commit`, `_Retiring`, `SetRetiring`, `buildStagedSides`, or pair-handoff production path in the mechanical cluster.
- exactly one canonical builder owner.
- exactly one axle/joint construction owner.
- redraw path reuses pair/axle/joint and side owners.
- runtime contains no geometry math and controller/service contain no duplicate canonical cleanup.
- traversal/evidence contracts continue to reject RecoveryKillY falls or solver instability as traversal success.
- ordinary G0 remains quick Studio Play and does not auto-run long evidence suites.

**RED first:**
- Closure test scans the mechanical production cluster for forbidden legacy symbols/owners and checks the final dependency direction.
- Existing traversal/recovery/evidence tests remain unweakened; if one fails, fix production or update only a demonstrably obsolete implementation assertion, never the safety criterion.

**GREEN criteria:**
- `Draw -> Canonical Shape -> authoritative ShapeSpec -> persistent axle -> two legs -> physical movement` is the only production path.
- full repository verification and Rojo build pass on the exact MR-06 HEAD.
- GitHub Actions `Contract Verify` is green for the exact HEAD.
- self-review finds no camera/rider/cosmetic changes and no unplanned contract/schema/balance/Rojo-mapping changes.
- docs state human mechanical G0 is still pending, not falsely PASS.

**Verification/checkpoint:** focused MR-06 closure tests -> `python verify.py` -> Rojo build -> exact-HEAD CI -> base-to-head audit for MR-01..MR-06 -> final read-only architecture/self-review.

**Commit:** `refactor: close mechanical core rewrite`

---

## Execution / Commit Discipline

For each MR:
1. Re-fetch `main` and record `BASE_SHA`; if it changed, inspect overlap before editing.
2. Write/update the smallest meaningful RED contract/invariant tests and verify the expected failure in the available execution environment. Do not push an intentional RED checkpoint to `main`.
3. Implement only that MR's production scope.
4. Run focused tests to GREEN.
5. Run repository-complete `python verify.py`.
6. Run `rokit install --no-trust-check` and `rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx` (the exact same build is also enforced by `Contract Verify`).
7. Commit one GREEN MR checkpoint directly to `main` with the message specified above.
8. Wait for/fetch exact-HEAD GitHub Actions evidence; a failing unexpected check triggers investigation, not assertion weakening.
9. Compare MR `BASE_SHA -> HEAD`, inspect every changed path, verify no scope creep and no legacy parallel production path.
10. Only then start the next MR from a freshly fetched HEAD.

## Final Human G0 Handoff

After MR-06 automation is green, status is **READY FOR HUMAN ACCEPTANCE**, not mechanical PASS. Product Owner pulls with `git pull --ff-only origin main`, starts `rojo serve default.project.json`, opens ordinary Studio Play, and checks drawing-to-leg parity, short/large scale, stable persistent axle/motor, 180-degree side phase, redraw under contact, traversal/recovery, and overall physical feel by video. Camera/rider/cosmetics remain outside this rewrite and are not changed until the mechanical video gate is accepted.

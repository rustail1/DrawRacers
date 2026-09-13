# CORE REPAIR v3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore free drawing, geometry-derived support origin, lower explicit leg mounts, and one semantic phase owner while preserving CR2 server authority and transactional redraw.

**Architecture:** Keep the existing pipeline `DrawingController -> CanonicalLegShape -> LegShapeService -> RacerRuntime -> LegPairAssembly -> 2 x LegDriveAssembly -> 2 x LegAssembly`. Replace only the rejected CR2 contracts: fixed center input pivot, side-midpoint mounts, and differential phase chasing. `CanonicalLegShape` owns support-anchor selection; `LegPairAssembly` owns both explicit mounts and the one motor command.

**Tech Stack:** Roblox Luau, Rojo, Python source-contract tests, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-14-core-repair-v3-free-draw-single-phase-design.md`

## Global Constraints

- Work only on `main`; no branches/PR.
- Human Studio physics acceptance remains pending after automated closure.
- Preserve server-authoritative raw-stroke submission and transactional redraw.
- Do not add M0.5, multiplayer, meta, economy, shop, or unrelated features.
- Do not reintroduce body teleport/velocity reset on redraw.
- Drawing translation is allowed; resize/rotate/mirror/reverse are not.

---

### Task 1: CR3 RED contracts

**Files:**
- Create: `tests/test_cr3_free_draw_support_mount_phase.py`

**Interfaces:**
- Consumes current CR2 source text.
- Produces source-contract coverage for every CR3 behavior before production changes.

- [ ] **Step 1: Write failing tests** for: no center pivot gate/UI; support-anchor API; no thumbnail; explicit lower mounts; supplied body mount in `LegDriveAssembly`; identical pair omega commands; no active phase correction; 180 initial relation; persistent redraw ownership.
- [ ] **Step 2: Run `python verify.py`** and confirm only the new CR3 assertions fail for the expected CR2 tokens/structure.
- [ ] **Step 3: Commit RED tests** as `test: define CR3 free draw repair contracts`.

### Task 2: Free drawing + support anchor

**Files:**
- Modify: `src/shared/Math/CanonicalLegShape.lua`
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/client/Controllers/DrawingController.lua`
- Modify: `src/server/Services/LegShapeService.lua` only if result validation/serialization requires it.

**Interfaces:**
- `CanonicalLegShape.Build(...)` returns `presentationAnchor: Vector2` in addition to canonical geometry.
- Support anchor candidates are actual cleaned points LEFT/TOP/RIGHT. Nearest-to-first-cleaned selects candidate; ties LEFT->TOP->RIGHT.
- Accepted canonical geometry contains at least one local zero point; zero is not required at index 1.

- [ ] **Step 1: Implement support-anchor helpers inside `CanonicalLegShape`** with deterministic tie rules.
- [ ] **Step 2: Remove `PivotStartRadiusNormalized`, `START_OFF_PIVOT`, first-sample snap, and forced first-index zero.**
- [ ] **Step 3: Translate cleaned points by selected support anchor before `GeometryMath.BuildSegmentPlan`; return `presentationAnchor`.**
- [ ] **Step 4: Restore sequence-scoped presentation anchors in `DrawingController`; allow pointer-down anywhere.**
- [ ] **Step 5: Remove `PivotMarker`, `PIVOT_COLOR`, and `START FROM THE DOT`; remove `AcceptedShapeThumbnail` and all thumbnail rendering.**
- [ ] **Step 6: Change authoritative accepted-point validation to require any point near `(0,0)`, not point 1.**
- [ ] **Step 7: Run `python verify.py`; update only superseded CR2 tests that intentionally assert the rejected fixed-pivot contract.**
- [ ] **Step 8: Commit as `fix: restore free drawing support anchor`**.

### Task 3: Explicit lower leg mounts

**Files:**
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/server/Runtime/LegDriveAssembly.lua`
- Modify: `src/server/Runtime/LegPairAssembly.lua`

**Interfaces:**
- `PhysicsConfig.LegGeometry.LegMountHorizontalFraction = 0.78`
- `PhysicsConfig.LegGeometry.LegMountVerticalFraction = -0.72`
- `LegDriveAssembly.new({ body, bodyMount, container, side, initialPhaseDegrees })`
- Body attachments named `LeftLegMount` and `RightLegMount`.

- [ ] **Step 1: Add the two mount-fraction config values.**
- [ ] **Step 2: Make `LegPairAssembly` create/reuse the two named body attachments at `(+/- halfWidth*0.78, halfHeight*-0.72, 0)`.**
- [ ] **Step 3: Change `LegDriveAssembly` to consume `bodyMount` and place `DriveRoot` at `bodyMount.WorldCFrame`; remove internal `pivotX` calculation.**
- [ ] **Step 4: Ensure destroy lifecycle does not accidentally destroy shared body mounts from inside individual drive owners; pair owns their lifecycle.**
- [ ] **Step 5: Run `python verify.py`; migrate superseded side-midpoint assertions only.**
- [ ] **Step 6: Commit as `fix: move leg roots to explicit lower mounts`**.

### Task 4: One semantic phase owner

**Files:**
- Modify: `src/server/Runtime/LegPairAssembly.lua`
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/shared/Math/LegDriveMath.lua`
- Update debug/evidence tests or Studio harnesses that expect active differential correction.

**Interfaces:**
- `LegPairAssembly:Step()` computes one `baseOmega = LegDriveMath.ComputeAngularVelocity(extent, motor)`.
- Both `leftDrive:SetMotorVelocity(baseOmega)` and `rightDrive:SetMotorVelocity(baseOmega)` receive the identical command.
- Right drive initial phase remains `+180` degrees.
- Phase error may remain read-only telemetry.

- [ ] **Step 1: Remove active `ComputePhaseCorrection` from pair Step.**
- [ ] **Step 2: Remove active phase-correction tuning keys from PhysicsConfig.**
- [ ] **Step 3: Remove unused correction helper if no consumer remains; keep pure phase-error helper only for telemetry.**
- [ ] **Step 4: Run `python verify.py`; migrate only contracts that deliberately require old CR2 differential correction.**
- [ ] **Step 5: Commit as `fix: simplify paired leg phase control`**.

### Task 5: Current Source of Truth + Studio evidence wiring

**Files:**
- Modify: `docs/CR2_CURRENT_SOURCE_OF_TRUTH.md` or replace its top status with CR3 supersession pointer.
- Modify: `docs/03_CORE_MECHANICS_SPEC.md`
- Modify: `docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`
- Modify: `docs/FEATURE_LIST.md`
- Modify: `docs/SESSION.md`
- Modify relevant current Studio evidence harness text if it prints `CR2 fixed-pivot` as current behavior.

**Interfaces:**
- Current docs route to CR3 free-draw/support-anchor/lower-mount/single-phase owner.
- Historical CR2 evidence remains historical and must not be described as current authority.

- [ ] **Step 1: Add CR3 current-source override and update owner docs.**
- [ ] **Step 2: Remove current-status language that says fixed center pivot or differential phase chasing is desired.**
- [ ] **Step 3: Update startup/debug log text so Studio no longer reports `[CR2] fixed-pivot draw controller ready`.**
- [ ] **Step 4: Run `python verify.py`.**
- [ ] **Step 5: Commit as `docs: promote CR3 free draw core contract`**.

### Task 6: Exact-head closure

**Files:** none expected beyond fixes found by verification.

- [ ] **Step 1: Confirm current `main` HEAD.**
- [ ] **Step 2: Run/observe GitHub Actions Contract Verify on exact HEAD.**
- [ ] **Step 3: Require `python verify.py` = 0 failures.**
- [ ] **Step 4: Require Rokit setup/install PASS.**
- [ ] **Step 5: Require `rojo build default.project.json` PASS.**
- [ ] **Step 6: Re-read `main` and verify it still equals tested SHA.**
- [ ] **Step 7: Report automated closure only; keep G0/HUMAN STUDIO PENDING and ask for fresh video.**

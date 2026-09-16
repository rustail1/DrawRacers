# Core V3 Suspended Start Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hold a fresh Core V3 racer motionless above the Track until its first accepted physical leg pair becomes ACTIVE.

**Architecture:** `RacerRuntime` owns one temporary anchored hold and releases it only after the first successful mechanical commit. `LegCoreConfig.Start` owns the reference height; the flat harness consumes it without adding a persistent mover.

**Tech Stack:** Roblox Luau, Rojo, Python source-contract tests, Studio C01-C08 runtime specs.

**Spec:** `docs/superpowers/specs/2026-09-16-core-v3-suspended-start-design.md`

## Global Constraints

- Local files only; no Git and no Studio/Play from Codex.
- Preserve one SharedAxle and one HingeConstraint.
- Do not change motor, torque, mass, friction, rider, camera, clearance, or redraw.
- Do not add AlignPosition, hover force, horizontal helper, or extra actuator.

---

### Task 1: Suspended-start lifecycle

**Files:**
- Modify: `tests/test_core_v3_body_spawn_rider_contract.py`
- Modify: `src/server/Tests/C05CoreV3RacerRuntimeSpec.lua`
- Modify: `src/server/Tests/C07CoreV3FlatLocomotionSpec.lua`
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Modify: `src/server/Runtime/CoreV3/LegCoreConfig.lua`
- Modify: `src/server/Tests/CoreV3FlatHarness.lua`

**Interfaces:**
- Consumes: `RacerRuntime.new(params)` and `RacerRuntime:ApplyValidatedShape`.
- Produces: fresh `BodyCollider.Anchored == true`; first successful commit sets it false once.

- [x] Add regressions for held EMPTY, failed-first-shape retention, zero-velocity release, geometry-derived suspended height, and no mover.
- [x] Run the focused Python regression and confirm RED for missing suspended-start ownership.
- [x] Add `LegCoreConfig.Start.SuspendedAxleHeightAboveTrack = 5.15`.
- [x] Anchor and zero Body velocity in `RacerRuntime.new`.
- [x] Release inside the first successful `ACTIVE` callback, zeroing Body/AxleRoot before unanchor and before pair collision/motor enable.
- [x] Update flat harness and C07 spawn height to use the suspended-height owner.
- [x] Run focused regressions and confirm GREEN.

### Task 2: Contract documentation and verification

**Files:**
- Modify: `docs/CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`
- Modify: `docs/65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md`
- Modify: `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`
- Modify: `docs/DECISION_LOG_CORE_V3_BODY_SPAWN_RIDER_2026-09-15.md`

**Interfaces:**
- Consumes: the implemented suspended-start lifecycle.
- Produces: canonical documentation and human test instructions.

- [x] Replace the resting-on-Track start contract with temporary suspended EMPTY ownership.
- [x] Run focused static/unit checks and C01-C08 source gate.
- [x] Run `rojo build default.project.json` to a temporary output.
- [x] Self-review exact scope and report HUMAN PHYSICS PENDING.

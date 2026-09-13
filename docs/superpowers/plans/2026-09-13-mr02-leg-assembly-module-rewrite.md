# MR-02 LegAssembly Module Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task on `main`. Do not create a branch or PR.

**Goal:** Replace legacy `LegAssembly` as one coherent module so one side owns one persistent root and materializes only the currently-built hub-to-tip canonical geometry, while direct consumers are migrated without preserving the retired staging/retiring API.

**Architecture:** `LegAssembly` becomes a focused one-side geometry owner. It accepts an explicit parent/container, side, persistent axle root/socket/phase, then receives canonical `ShapeSpec` data through `ReplaceGeometry`. `LegPairAssembly` is changed only as the direct consumer needed to use this new API; its broader axle/motor ownership rewrite remains MR-03.

**Tech Stack:** Roblox Studio / Luau strict, Rojo, Rokit, Python contract tests, GitHub Actions `Contract Verify`.

**Spec:** `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`

**Engineering rules:** `docs/DEVELOPMENT_PRINCIPLES.md`

## Global Constraints

- Repository `rustail1/DrawRacers`, branch `main` only; no branches/PRs.
- Baseline for this plan: `3807a8b78c02024108176d4429d502a2a89d9ccf`; re-fetch `main` before every write.
- MR-02 is a `MODULE_REWRITE`: do not add a second implementation, compatibility branch, legacy wrapper, or renamed staging API inside `LegAssembly`.
- Preserve one side root welded to the shared axle, canonical `segmentPlan`, physical thickness `0.54`, visual thickness `0.78`, socket `Z=+-1.5`, existing collision/material configuration, and structural phase supplied by the pair.
- `LegAssembly` must not own motor, HingeConstraint, player/network/race/recovery destination/camera/opposite-leg policy.
- `LegReshapeMath` remains the pure arc-length owner; do not duplicate its math.
- Future full colliders/visual segments must not exist hidden during partial reshape. At a partial progress the materialized geometry is completed prefix plus at most one partial tip.
- Borrowed canonical tables are never mutated/cleared by `Destroy` or `ReplaceGeometry`.
- Any temporary direct-consumer staging container in `LegPairAssembly` is pair-owned and has an explicit removal checkpoint in MR-03; `LegAssembly` itself has no `staged`, `Commit`, `IsCommitted`, `SetRetiring`, or `_Retiring` concept.
- Do not touch camera, rider, cosmetics, race rules, network schema, tuning values, or recovery destination policy.

## Execution checklist

- [x] Write MR-02 boundary tests before production replacement and confirm current legacy source violates the new boundary.
- [x] Rewrite `src/server/Runtime/LegAssembly.lua` as one coherent side owner.
- [x] Migrate direct consumer `src/server/Runtime/LegPairAssembly.lua` away from retired side staging/retiring APIs.
- [x] Update B07 Studio behavior spec for persistent side ownership and partial materialization.
- [x] Replace stale static tests that encoded old staged-side handoff with persistent-side invariants.
- [ ] Fresh CI / `python verify.py` / Rokit / Rojo build on implementation HEAD.
- [ ] Diff/self-review and MR-02 checkpoint closure.

## MR-02 Exit Criteria

- `LegAssembly` has one responsibility: one persistent side root plus current canonical physical/visual geometry.
- Its public API has no staging/retiring lifecycle.
- Redraw materializes hub-to-tip prefix geometry rather than hiding a prebuilt future leg.
- Physical and visual centerlines come from the same canonical segment endpoints.
- Direct pair consumer is migrated without adding a second side implementation.
- Automated verification/build/CI are GREEN on the implementation HEAD.
- MR-03 is next and owns the complete rewrite of `LegPairAssembly`; no camera/rider/cosmetics work starts.

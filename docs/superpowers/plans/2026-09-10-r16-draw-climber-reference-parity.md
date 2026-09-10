# R16 Draw Climber Reference Parity Implementation Plan

> **For agentic workers:** use `superpowers:executing-plans` (or subagent-driven development when available) and strict RED -> minimal GREEN -> full verification for every behavior change.

**Goal:** make the M0 racer core materially closer to observable Draw Climber behavior without copying unknown/private implementation details: one drawing produces one authoritative centered ShapeSpec, duplicated into two same-XY motor-driven physical legs around fixed hubs; the cube stays upright, moves physically in X/Y, is mechanically locked in Z, and redraw preserves body motion and each leg phase.

**Architecture:** keep the authoritative chain `DrawingController -> StrokeRemoteTransport -> LegShapeService -> RacerRuntime -> LegAssembly`. `RacerStabilizer` owns body plane/orientation constraints. `PhysicsConfig.LegGeometry` owns hub offsets. `StrokeMath` owns pure bounds-centering math. `LegShapeService` owns when centering occurs in the authoritative pipeline. Studio-only R16 harnesses measure solver behavior; they do not become gameplay movement owners.

**Spec:** `docs/superpowers/specs/2026-09-10-r16-draw-climber-reference-parity-design.md`

## Global constraints

- Work only on `main`; no branches/PRs in this project workflow unless the Product Owner changes that rule.
- One accepted stroke -> one authoritative ShapeSpec -> exactly two same-XY physical legs.
- **R16.3A — Reference Shape Centering:** raw DrawInputRect placement is not gameplay input. After cleanup/resampling, the server translates the cleaned bounds center to `(0,0)` before ShapeSpec/GeometryMath construction. This is translation-only: no resize, rotate, mirror, or auto-spoke.
- The authoritative centered ShapeSpec pivot `(0,0)` maps to the physical hub. Accepted preview uses server-returned centered `acceptedPoints`.
- X/Y body translation is physically free; Z is mechanically locked by `PlaneConstraint`.
- Body orientation is upright on all axes; only legs intentionally rotate for locomotion.
- Canonical orientation attachment basis for `AlignType.AllAxes` is:

```lua
orientationAttachment.Axis = Vector3.xAxis
orientationAttachment.SecondaryAxis = Vector3.yAxis
```

- Initial right-minus-left phase = `180 degrees +/- 1 degree`.
- Post-redraw phase per side remains within `5 degrees` of that side's captured pre-redraw phase modulo 360.
- `PhysicsConfig.LegGeometry` is the only numeric owner for hub offsets: `HubOffsetX=0.0`, `HubOffsetY=-0.35`, `HubOffsetZAbs=1.62` until Studio evidence authorizes a bounded calibration change.
- Canonical obstacle geometry is not modified to manufacture a physics pass.
- Roblox solver/feel claims remain HUMAN/STUDIO PENDING until observed in Studio.

## Stage A — R16.1 through R16.4 / R16.3A

### R16.1 Upright Body

Keep the mechanical Z plane. `AlignOrientation` uses `OneAttachment + AllAxes + CFrame.identity` with the canonical X/Y attachment basis. B10 must prove the 2.5-degree disturbance returns to `<=1 degree` within a real elapsed `<=0.25 s`, while a physical impulse can still move the body in X/Y and Z remains within the lane hard bound.

### R16.2 Hub Position

`PhysicsConfig.LegGeometry` is the only hub numeric owner. Runtime consumes `HubOffsetX`, `HubOffsetY`, and `HubOffsetZAbs` symmetrically for left/right hubs. No duplicate hardcoded hub offsets remain in RacerRuntime.

### R16.3 / R16.3A One drawing -> Two legs / Reference Shape Centering

The server clamps/dedupes/simplifies/resamples, validates minimum length, then calls `StrokeMath.CenterOnBounds`. The centered points are used for bounds, GeometryMath, ShapeSpec, accepted preview, and internal reference shapes. One ShapeSpec is duplicated to left/right with the same XY geometry. The player's raw location inside DrawInputRect never changes physical placement; shape size still matters.

### R16.4 Twin-leg Phase

Both motors use the same locomotion direction. Right starts 180 degrees after Left. Atomic redraw captures each side's live phase and reuses it; redraw does not restart the gait.

### Studio Gate A

**Studio Gate A remains HUMAN STUDIO PENDING.** Required live evidence: 13/0 server Studio specs, upright body/lane limits, symmetric hubs, one drawing -> two matching legs, centered accepted/physical geometry, physical X/Y freedom, and no DrawRacers runtime errors.

## Stage B — R16.5 through R16.7

**Stage B implementation authorized by Product Owner before Studio Gate A was recorded.** This is an implementation override only; it is not a Studio PASS.

### R16.5 Motor / Grip / Mass Feel

Use an isolated Studio-only flat benchmark that cannot reach canonical Steps during the complete `2 s settle + 3 s measure` window. ROUND_01 target average +X speed is `4.0..7.0 studs/s`, both motors enabled, anti-stall false. Tune one family at a time only after Studio numbers exist: AngularVelocity -> torque/acceleration -> leg material -> body material -> anti-stall last.

### R16.6 Vertical Physics

Normal locomotion must not script Y. Steps must produce positive Y from leg/track collision; Gap must produce negative Y from gravity. G0 recovery evidence must record that recovery triggers only after an actual body Y below `RecoveryKillY`, while preserving current ShapeSpec and ShapeVersion.

### R16.7 Full Reference Shape Matrix

Canonical shapes: `ROUND_01`, `LONG_BAR_01`, `SMALL_ROUND_01`, `HOOK_01`, `ASYM_01`, `SUBOPTIMAL_01`. A shared Studio-only trial runner performs deterministic reset/contact/measurement and returns metrics; policy logic stays in Stage-B/C harnesses. All shapes are measured on the relevant canonical pieces so `noUniversalWinner` is computed from real per-piece winner sets, not inferred from niche booleans. SUBOPTIMAL may satisfy its `>=20% worse` proof on Flat **or** Steps.

### Studio Gate B

**Studio Gate B remains HUMAN STUDIO PENDING.** Required live evidence includes clean flat speed, real Steps rise, real Gap fall/recovery relationship, niche comparisons, and no universal winner.

## Stage C — R16.8 through R16.10

**Stage C implementation authorized by Product Owner before Studio Gate A/B were recorded.** This bounded override authorized repository implementation through R16.10 before the next Studio launch; it did not pass any Studio gate.

### R16.8 Redraw parity

Run 10 moving redraws. Each accepted redraw advances ShapeVersion exactly once, leaves exactly two active leg models and no retiring/staged leak, does not reset Body CFrame/linear/angular velocity at commit time, and preserves each side phase within 5 degrees.

### R16.9 Reference-side presentation

Studio-only G0 camera uses `CAMERA_OFFSET = Vector3.new(-6, 5, 16)` and `CAMERA_LOOK_AHEAD = Vector3.new(7, 1, 0)`. Observer Character is hidden during the reference shot and restored on teardown. Presentation proxy remains non-physical.

### R16.10 Canonical obstacle pass

Use unchanged `FlatShort`, `SmallSteps`, `SingleWallLow`, `GapSmall`, `LowTunnelWide`. Aggregate Stage-B evidence, explicit Wall good/bad proof, and moving-redraw evidence. Wall requires at least one approved suitable shape (`HOOK_01` or `LONG_BAR_01`) to complete while legal negative-control `SUBOPTIMAL_01` does not complete under the same reset/window. No canonical obstacle geometry edits are allowed as a shortcut.

### Studio Gate C

**Studio Gate C remains HUMAN STUDIO PENDING.** Run the aggregate `R16C` harness, then normal `G0` for visual/feel acceptance. Any failed item opens only a bounded R16 repair.

## R16.11 Docs / Evidence Freeze

Do not freeze final R16 evidence before Stage A/B/C Studio evidence is actually recorded. After the combined Studio pass, synchronize final selected numbers/behavior in owner docs and record exact Studio evidence. B17/G0 external HUMAN_GATE remains separate and still pending until its own human evidence exists.

## Current process state

- R16.1-R16.10 repository implementation exists in `main`.
- Stage B implementation authorized by Product Owner.
- Stage C implementation authorized by Product Owner.
- Studio Gate A remains HUMAN STUDIO PENDING.
- Studio Gate B remains HUMAN STUDIO PENDING.
- Studio Gate C remains HUMAN STUDIO PENDING.
- Pre-Studio closure repairs P0-P6 must be completed with RED -> GREEN and full CI/Rokit/Rojo evidence before asking for the combined Studio run.

## Final Definition of Done

R16 is technically complete only when repository tests/build are green **and** Stage A/B/C Studio evidence proves the approved design. R16 completion still does not pass B17; external tester evidence remains a separate human gate before C01/M0.5.

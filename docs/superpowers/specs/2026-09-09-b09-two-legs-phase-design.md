# B09 Two Legs + Phase — Design

Status: approved by Product Owner on 2026-09-09.

## Goal
Extend the accepted B07/B08 one-leg physics slice into the B09 two-leg locomotion slice without pulling B10+ work forward.

## Source contracts
- `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` row B09.
- `docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md` sections 4–6.
- `docs/65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md` runtime leg hierarchy.
- `docs/16_BALANCE_TUNING.md` phase/motor defaults.

## Architecture
`LegAssembly` remains the owner of one side. It accepts `side = "Left" | "Right"`, resolves the matching canonical hub, maps the same normalized XY points through the existing geometry pipeline, and creates exactly one side model containing one `LegRoot`, one `HubJoint`, bounded physical `Segments`, and `Visual`.

`RacerRuntime:ApplyShape(normalizedPoints, motorEnabled)` becomes the B09 orchestration seam. One call destroys/replaces the current B09 pair and builds both sides from the same input table. B13 later owns atomic redraw semantics; B09 only guarantees one logical accepted shape controls both sides.

## Same-XY duplication
Left and right assemblies consume the identical normalized point sequence. There is no XY mirror, sign inversion, bounding-box recenter, or side-specific point transform. The only side difference is the canonical hub translation along Z and the initial phase rotation.

## Phase
Left starts at 0°. Right starts at `PhysicsConfig.Motor.RightPhaseOffsetDegrees = 180`. The right `LegRoot` is initially rotated about its own canonical +Z hinge axis by the phase offset before segment CFrames are built. The local mapped XY coordinates therefore remain identical while the world-space assembly begins half a cycle apart.

Both hinges keep the same +Z axis orientation and the same motor sign/values. There is no per-side hidden angular-velocity sign.

## Scope boundaries
B09 does not add stabilization, lane constraints, networking, authoritative submit validation, atomic redraw, obstacle geometry, rewards, or race state. Those remain B10+.

## Acceptance
Automated/Studio checks must demonstrate:
- `LeftLeg` and `RightLeg` both exist under one racer `Legs` folder;
- both have one `HingeConstraint` and equivalent segment counts/local mapped XY points;
- left uses `LeftHub`, right uses `RightHub`;
- both hinge axes are +Z and motor defaults are identical;
- right phase starts at 180° relative to left;
- one `RacerRuntime:ApplyShape` input creates/controls both sides;
- no hidden +X propulsion is introduced;
- B07 historical tests are progression-safe and no longer require the repository to remain forever left-only.

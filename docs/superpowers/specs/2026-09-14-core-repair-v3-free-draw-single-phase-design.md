# CORE REPAIR v3 — Free Draw / Support Anchor / Single Phase Owner

Date: 2026-09-14
Status: DESIGN FOR PRODUCT-OWNER REVIEW
Scope: bounded CORE repair only. No M0.5, multiplayer, meta, economy, shop, or unrelated camera/content work.

## Why this repair exists

The 2026-09-14 Studio video exposed that CR2 changed the product meaning instead of only repairing mechanics. Three CR2 choices are rejected:

1. Drawing was forced to start at a visible center pivot. `DrawingController` added `PivotMarker` and `START FROM THE DOT`, while `CanonicalLegShape` rejected `START_OFF_PIVOT` and snapped the first sample to `(0,0)`.
2. Leg pivots were derived as the middle of the left/right body sides (`X = +/- body.Size.X / 2`, `Y = 0`, `Z = 0`). The video shows this makes the legs read as rotating antenna/arms rather than creature legs.
3. Two side motors were allowed to chase a 180-degree phase error independently. The differential correction creates unnecessary motion complexity and makes the legs feel like two separate mechanisms.

CR3 restores the intended player-facing contract while keeping the good CR2 infrastructure: server authority, one canonical shape pipeline, persistent racer ownership, transactional redraw, collision-safe commit, recovery isolation, and human Studio acceptance gates.

## 1. Drawing contract — free draw again

The player may pointer-down anywhere inside `DrawInputRect`. There is no mandatory center point and no input-invalid state based on distance from a pivot marker.

Delete from the active contract:
- `PivotMarker`;
- `PIVOT_COLOR`;
- `PivotStartRadiusNormalized`;
- `START_OFF_PIVOT`;
- `START FROM THE DOT`;
- any requirement that accepted point index 1 must already equal `(0,0)` before canonical anchor selection.

The white drawing surface remains a free drawing area. Pointer sampling, dedupe, RDP simplify, bounded resample, payload limits, server recomputation, and fixed isotropic canvas scale remain.

## 2. Support-anchor rule

After cleanup/resample, the shape chooses a support anchor from the drawn shape itself. The canvas center is never the mechanical origin.

CR3 uses three deterministic candidate support points from the cleaned polyline:

- `LEFT` — actual cleaned point with minimum X; tie: greater Y, then earlier point index.
- `TOP` — actual cleaned point with maximum Y; tie: point whose X is closest to the bounds horizontal center, then earlier point index.
- `RIGHT` — actual cleaned point with maximum X; tie: greater Y, then earlier point index.

The original first cleaned point is used only as a gesture hint for which support edge/corner the player intended. Select whichever of `LEFT`, `TOP`, `RIGHT` is nearest to that first cleaned point. Exact-distance tie priority is `LEFT -> TOP -> RIGHT` for determinism.

Then translate every cleaned point by `-supportAnchor` so that the selected support point becomes local `(0,0)`.

This operation is translation-only. CR3 MUST NOT:
- resize the shape to a standard radius;
- rotate it;
- mirror it;
- reverse point order;
- center it on canvas bounds;
- force the player to draw from the support point.

The support anchor is therefore chosen after drawing, from the geometry the player actually created.

### Presentation anchor

The canonical builder may return the selected pre-translation support anchor as `presentationAnchor` for client presentation only. It is not part of physical authority and is not added to the network payload.

`SubmitStroke` stays `{ sequence, points }`.

The client stores the predicted `presentationAnchor` per sequence so authoritative accepted points can be drawn back where the player drew them. The server still recomputes the same canonical anchor from raw points and remains authoritative over `ShapeSpec`.

`StrokeResult.acceptedPoints` contains authoritative translated canonical points. The origin may appear at any point index; validation therefore checks that at least one accepted point is approximately `(0,0)`, not specifically point 1.

## 3. Drawing UI cleanup

Remove `AcceptedShapeThumbnail` from `DrawCanvas`. The drawing zone must not contain a second mini-square preview.

Keep only the gameplay drawing surface, live stroke, accepted stroke, empty-state hint, and validation text outside/over the normal presentation layers.

No red center dot and no hidden replacement pivot widget may be introduced.

## 4. Explicit leg mounts

`LegDriveAssembly` must stop deriving its own pivot with `+/- body.Size.X / 2, Y = 0`.

`LegPairAssembly` owns two explicit body attachments:
- `LeftLegMount`
- `RightLegMount`

They live on `BodyCollider` and are the only mechanical attachment locations for the two leg drives.

Starting placement hypothesis for the next Studio G0:
- X = `+/- 0.78 * bodyHalfWidth`;
- Y = `-0.72 * bodyHalfHeight`;
- Z = `0`.

That places the mounts visibly near the lower-left / lower-right part of the cube while leaving a small inset from the literal corners. These are tuning hypotheses, not a human-accepted final value; G0 may adjust only these mount fractions if the visual attachment still reads wrong.

The fractions live in `PhysicsConfig.LegGeometry` as the single numeric owner. `LegDriveAssembly.new` receives a `bodyMount: Attachment` and does not compute mount placement from body size.

The canonical local `(0,0)` support anchor of each leg coincides exactly with its `DriveRoot` / `LegMount` position.

## 5. One movement / phase owner

Two separate physical hinge locations are still required because the two legs now rotate about two distinct lower-body mount points. However there is exactly one semantic movement/phase owner: `LegPairAssembly`.

`LegDriveAssembly` is a dumb actuator/geometry host. It may expose `SetMotorVelocity`, but it does not compute speed, phase correction, opposite-side state, or desired phase.

`LegPairAssembly` computes one extent-aware `baseOmega` and sends the same command to both side joints.

Initial structural relationship:
- left drive phase = `initialPhase`;
- right drive phase = `initialPhase + 180 degrees`.

Delete active differential phase chasing:
- no `baseOmega + correction / 2` vs `baseOmega - correction / 2`;
- no per-frame `ComputePhaseCorrection` in locomotion;
- no `PhaseCorrectionGain`, `MaxPhaseCorrection`, or `PhaseDeadbandDegrees` as active tuning.

Phase error may remain read-only debug telemetry. Normal locomotion never snaps either drive CFrame to chase the other.

This intentionally prefers simple, readable paired motion over a controller that continuously fights Roblox contact impulses. Whether same-command twin hinges hold the desired 180-degree relationship well enough is a HUMAN STUDIO G0 question; source automation must not claim solver PASS.

## 6. Redraw and authority that remain unchanged

Keep CR2 improvements that are independent of the rejected pivot/motion choices:
- raw semantic stroke is sent to server;
- server recomputes canonical shape;
- one shape transaction per racer;
- old physical geometry remains active while new visuals stage;
- collision-safe mount-offset planning remains non-mutating and track-only;
- physical commit is coordinated across both sides;
- body CFrame and velocities are not reset by redraw;
- ShapeVersion publishes only after successful mechanical commit;
- failed redraw leaves the previous accepted shape/version working.

The redraw safety mount offset rotates geometry about each explicit `LegMount`; it does not move mounts or reinterpret the chosen support anchor.

## 7. Ownership map after CR3

`DrawingController -> CanonicalLegShape -> LegShapeService -> RacerRuntime -> LegPairAssembly -> 2 x LegDriveAssembly -> 2 x LegAssembly`

Responsibilities:
- `DrawingController`: free input capture, local preview, sequence-scoped presentation anchor, presentation only.
- `CanonicalLegShape`: one canonical cleanup + support-anchor selection + translation + mapping + segment plan.
- `LegShapeService`: envelope/security/server authority and accepted result publication after mechanical commit.
- `RacerRuntime`: racer lifecycle and redraw transaction timing.
- `LegPairAssembly`: explicit Left/Right mounts, one speed/phase command owner, 180-degree initial relation, redraw coordination.
- `LegDriveAssembly`: one hinge/root/leg host at a supplied mount; no pair intelligence.
- `LegAssembly`: geometry only.

## 8. TDD / regression requirements

Before production changes, add RED contracts proving the current CR2 code is wrong for CR3:

1. free pointer-down away from center is allowed;
2. no `PivotMarker`, `START FROM THE DOT`, `START_OFF_PIVOT`, or `PivotStartRadiusNormalized` remains active;
3. support anchor is one of actual LEFT/TOP/RIGHT cleaned points and translation preserves all pairwise point deltas;
4. accepted origin may be at any point index;
5. `AcceptedShapeThumbnail` is absent from gameplay drawing UI;
6. explicit `LeftLegMount` / `RightLegMount` are below body center and inset near horizontal edges;
7. `LegDriveAssembly` consumes supplied mounts and does not calculate `+/- body.Size.X / 2`;
8. pair commands identical base omega to both drives and contains no differential phase correction;
9. right initial drive remains 180 degrees opposed;
10. redraw keeps BodyCollider, both mounts, both drives, both joints, and both side geometry owners persistent.

Existing network/security/redraw/recovery tests remain regression coverage and are updated only when they assert a deliberately superseded CR2 contract.

## 9. Human G0 acceptance after source/build closure

The next Studio video must show all of the following before this repair is considered physically accepted:

- drawing can start anywhere in the white area;
- no red center dot and no thumbnail square;
- accepted drawing stays visually where it was drawn;
- a horizontal line, hook/C, and tall shape attach from an understandable support edge/corner rather than canvas center;
- both leg roots visibly meet the two lower cube mounts;
- no leg root floats through the cube or starts from the middle of the side wall;
- legs read as one paired locomotion mechanism rather than two motors fighting each other;
- right/left relationship begins at approximately 180 degrees and does not visibly jitter from correction chasing;
- redraw does not teleport/reset the cube and does not create a collision explosion;
- different shapes still produce visibly different locomotion.

Repository CI can prove contracts/buildability only. `G0 / HUMAN STUDIO` remains PENDING until the user supplies live evidence.

## 10. Explicitly superseded CR2 decisions

This spec supersedes only these parts of `2026-09-14-core-repair-v2-twin-pivot-design.md` and `CR2_CURRENT_SOURCE_OF_TRUTH.md`:
- fixed visible center pivot;
- mandatory start near `(0,0)`;
- first sample snap-to-zero semantics;
- side-midpoint mount placement;
- differential twin-motor phase correction.

It does not reopen unrelated product scope or erase historical CR2 evidence.

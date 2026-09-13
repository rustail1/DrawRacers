# CORE REPAIR V2 — TWIN-PIVOT MECHANICAL DESIGN

Date: 2026-09-14  
Baseline: `da0a54e694c4e26841f69fb675f32b7775adeb2b`  
Status: **DIRECTION APPROVED / SPEC REVIEW PENDING / NO PRODUCTION IMPLEMENTATION YET**

## 1. Why this redesign exists

MR-01..MR-06 successfully removed duplicate shape pipelines and transitional lifecycle paths, but the first real G0 gameplay video failed the human gate. The important conclusion is not that the modules were badly separated; it is that several module contracts encoded the wrong physical topology.

Observed G0 failure classes:
- repeated fall/recovery loops during a short manual session;
- visible body roll/tumble despite the intended upright racer contract;
- long/asymmetric shapes sweeping huge arcs and producing violent contact;
- two Z-separated copies reading as a wheel/motorcycle rather than creature-like left/right legs in side view;
- the player cannot see the physical pivot implied by first-point anchoring;
- redraw temporarily removes useful physical support before the new full shape exists;
- camera follows failure below the useful track view.

CORE REPAIR v2 changes those contracts while preserving the good ownership work from MR-01..MR-06.

---

## 2. Product-level target

The racer remains a real 2.5D physical cube driven primarily by collisions between player-drawn leg geometry and Track.

The intended read in side view is now explicit:
- one cube;
- one visible pivot on the **left screen-side edge** of the cube;
- one visible pivot on the **right screen-side edge** of the cube;
- the same player shape duplicated on both pivots;
- the two drives rotate with a 180-degree relationship so contacts alternate like creature legs;
- body stays arcade-upright while X/Y translation remains physical;
- shape differences still create movement differences; there is no scripted circle/L/hook behavior.

In project world convention, travel is +X, Y is up and lane depth is Z. Therefore “left/right in the side-view gameplay plane” means body-local X pivots at `-BodyCollider.Size.X/2` and `+BodyCollider.Size.X/2`. Both mechanical pivots are at local Y=0, Z=0. The old physical Z sockets are retired.

---

## 3. Canonical dependency graph

```text
DrawingController
    |
    | raw semantic stroke intent
    v
CanonicalLegShape  <------ PhysicsConfig shape limits
    |
    | canonical pivot-local ShapeSpec
    v
LegShapeService
    |
    | validated authoritative transaction request
    v
RacerRuntime
    |
    v
LegPairAssembly
   / \
  v   v
Left LegDriveAssembly     Right LegDriveAssembly
  |                         |
  v                         v
LegAssembly               LegAssembly

LegDriveMath --------------^  pure speed/phase math
LegCollisionSafety --------^  server-only non-mutating placement query
RacerStabilizer ------------ body orientation/lane owner
RaceCameraController ------- presentation only
```

Dependency rules:
- client never imports server runtime modules;
- server network/service layer never constructs geometry itself;
- `LegAssembly` never imports pair/drive/network/camera/recovery owners;
- `LegDriveAssembly` never knows about the opposite leg;
- `LegPairAssembly` may coordinate two drives but does not process raw strokes;
- `RacerRuntime` orchestrates lifetime/transactions but does not duplicate geometry or speed math;
- pure reusable math remains under `src/shared/Math`.

---

## 4. Shape and pivot semantics

### 4.1 Retired behavior

Retire this canonical behavior:

```text
cleaned stroke -> AnchorToFirstPoint -> entire shape translated -> first point becomes (0,0)
```

The current UI then adds a local presentation anchor back for display. That creates two truths: what the player sees and where the physics believes the pivot is.

### 4.2 New fixed pivot

`DrawInputRect` has one explicit fixed pivot marker at semantic `(0,0)`, visually centered on the draw surface.

Input rules:
1. Pointer-down must occur within `PivotStartRadiusNormalized` of `(0,0)`.
2. If it starts outside that radius, gameplay capture does not begin and UI shows a simple `START FROM THE DOT` validation message.
3. After a legal start, subsequent points use the normal wide semantic canvas coordinates.
4. Client and server both validate the fixed-pivot start contract.
5. Canonical cleanup may snap the first legal sample exactly to `Vector2.zero` after validating its distance to the pivot.
6. It **must not subtract that first point from every later point**.

Result: the same `(x,y)` has the same mechanical meaning in canvas preview and leg-local space.

### 4.3 CanonicalLegShape owner

`CanonicalLegShape.Build(rawPoints, strokeConfig, geometryConfig)` remains the one shared shape pipeline.

Order:
1. validate finite/bounded semantic points;
2. rectangular clamp to the wide DrawInputRect bounds;
3. reject if raw first point is outside pivot-start tolerance;
4. snap legal first point to `(0,0)`;
5. dedupe;
6. simplify;
7. resample;
8. reassert first canonical point `(0,0)` without translating the rest;
9. enforce cleaned count/polyline-length limits;
10. build world-equivalent mapped points/segment plan;
11. enforce useful extent and hard extent cap.

Delete from canonical output:
- `presentationAnchor`.

Keep ShapeSpec as geometry data. Do not put world CFrames, motor phases or runtime mount offset in ShapeSpec.

### 4.4 DrawingController owner

`DrawingController` owns:
- pointer collection;
- local pixel trace;
- semantic raw samples;
- fixed pivot marker presentation;
- shared canonical prediction;
- request/result presentation.

It does not own:
- a second simplify/resample pipeline;
- physical scale fitting;
- server acceptance;
- motor speed;
- collision-safe redraw.

Accepted server points render directly with the fixed mapping. Delete sequence-scoped `_presentationAnchors` and `_acceptedPresentationAnchor` bookkeeping.

Network payload schema stays:

```text
{ sequence, points = [{x,y}, ...] }
```

No pivot field is needed because pivot `(0,0)` is a server-owned fixed rule.

---

## 5. Mechanical topology

### 5.1 New `LegDriveAssembly`

Create:

`src/server/Runtime/LegDriveAssembly.lua`

One instance owns exactly one mechanical drive:
- one invisible `DriveRoot` Part;
- one `BodyDriveAttachment` on BodyCollider;
- one `DriveAttachment` on DriveRoot;
- one `HingeConstraint` motor;
- one child `LegAssembly` bound rigidly to DriveRoot;
- one current motor target supplied by pair coordination.

Suggested constructor contract:

```text
LegDriveAssembly.new({
    body: BasePart,
    container: Instance,
    side: "Left" | "Right",
    initialPhaseDegrees: number,
})
```

Public surface should stay small:

```text
GetRoot()
GetJoint()
GetLeg()
GetPhaseDegrees()
SetMotorVelocity(radPerSec)
SetEnabled(enabled)
Destroy()
```

`LegDriveAssembly` computes its pivot from the body itself, avoiding another numeric owner:

```text
Left  pivot local X = -body.Size.X / 2
Right pivot local X = +body.Size.X / 2
Y = 0
Z = 0
```

Hinge axis is world/body local Z, so rotation occurs in the X/Y gameplay plane.

It does not know:
- the other drive;
- desired 180-degree relationship;
- ShapeVersion;
- raw stroke/network state;
- camera/recovery destination.

### 5.2 `LegAssembly` remains geometry-only

Rewrite its build contract around a `driveRoot`, not `axleRoot/socketZ/phaseDegrees`.

Target responsibilities:
- own one persistent side model/root;
- own hidden physical collider segments;
- own matching nonphysical visual curve;
- stage pending visual geometry;
- atomically replace physical geometry when asked to commit;
- cleanly destroy its own Instances.

Target public surface:

```text
LegAssembly.new({ container, side, driveRoot })
InstallGeometry(shapeSpec, mountOffsetDegrees)
StageGeometry(shapeSpec, mountOffsetDegrees)
SetStageProgress(progress)       -- visual only
CommitStagedGeometry()
CancelStagedGeometry()
GetModel()
GetRoot()
GetSegments()
GetMappedPoints()
Destroy()
```

Important change: old physical colliders remain active during redraw staging. `SetStageProgress` must never remove or partially replace the current physical support.

The current physical hub-to-tip `ReshapeTipCollider` mechanism is retired for redraw. A short hub-to-tip animation may remain **presentation-only** if desired.

### 5.3 `LegPairAssembly` becomes a pair coordinator

Rewrite `LegPairAssembly` around two persistent drives:

```text
LegPairAssembly
  LeftDrive: LegDriveAssembly
    LeftLeg: LegAssembly
  RightDrive: LegDriveAssembly
    RightLeg: LegAssembly
```

It owns:
- construction/destruction of exactly two drives;
- desired right-vs-left phase offset of 180 degrees;
- common extent-derived base angular speed;
- bounded phase synchronization correction;
- current geometry mount offset;
- safe redraw staging/commit coordination.

It does **not** own:
- one central `AxleRoot`;
- one shared HingeConstraint;
- raw stroke math;
- server request/rate validation;
- recovery destination;
- camera.

Normal redraw never replaces either drive, either hinge, either side owner or BodyCollider.

---

## 6. Pure drive math

Create:

`src/shared/Math/LegDriveMath.lua`

Pure functions only. No Instances/Workspace/services.

### 6.1 Extent-aware angular speed

Use mapped physical extent from the authoritative ShapeSpec.

Concept:

```text
radius = max(extent, MinimumDriveRadius)
omegaMagnitude = TargetTipSpeed / radius
omegaMagnitude = clamp(omegaMagnitude, MinAngularVelocity, MaxAngularVelocity)
omega = RotationSign * omegaMagnitude
```

This makes long legs rotate slower instead of giving a 6.9-stud leg the same `8 rad/s` as a short leg.

Initial tuning hypothesis to be moved into `16_BALANCE_TUNING.md` after spec approval:
- `TargetTipSpeed ≈ 10.5 studs/s`
- `MinAngularVelocity ≈ 1.5 rad/s`
- `MaxAngularVelocity ≈ 6.0 rad/s`
- preserve the current forward rotation sign unless Studio evidence proves it reversed.

These values are starting points, not PASS values.

### 6.2 Phase math

Pure helpers:
- normalize degrees;
- signed shortest delta;
- pair phase error where target is 180 degrees;
- bounded correction velocity.

Pair behavior:

```text
baseOmega = extent-aware target
error = phaseError(left, right, target=180)
correction = clamp(Kp * error, -MaxPhaseCorrection, +MaxPhaseCorrection)
leftOmega  = baseOmega + correction/2
rightOmega = baseOmega - correction/2
```

Use a small deadband so the controller is not constantly fighting the solver.

No CFrame snapping in normal play.

---

## 7. Shape scale

The current `LegCanvasHalfSpan=4.8` / `MaxLegExtentFromHub=6.9` produced visually excessive arcs in G0.

CORE REPAIR v2 should start from a smaller bounded scale, proposed:
- `LegCanvasHalfSpan ≈ 3.2`
- `MaxLegExtentFromHub ≈ 4.5`

Reasoning:
- clearly smaller than the video failure state;
- still large enough to interact with the current 2.6-stud wall and 3.2-stud gap lab;
- restores room for shape trade-offs without letting every stroke become a giant lever.

Final values remain HUMAN STUDIO tuning. Do not change obstacle dimensions merely to make one tuning pass.

---

## 8. Upright body contract

`RacerStabilizer` remains the sole orientation/lane owner.

Required contract:
- `PlaneConstraint` keeps lane Z locked;
- `AlignOrientation` keeps the BodyCollider upright in all axes;
- normal locomotion must not intentionally roll/tumble the cube;
- stabilizer supplies no forward X force and no vertical lift;
- redraw never teleports/anchors the body.

Starting implementation change:
- switch `OrientationAlign.RigidityEnabled` to `true` for the arcade-upright contract;
- retain explicit identity orientation basis;
- keep a Studio instability check because rigid orientation can expose solver conflicts.

If rigid mode is unstable in real Studio, tuning may change the orientation constraint implementation, but responsibility stays in `RacerStabilizer`; do not distribute upright fixes into leg modules.

---

## 9. Collision-safe redraw transaction

### 9.1 Problem with current redraw

Current `LegAssembly:ReplaceGeometry()` clears physical geometry immediately and then grows new physical geometry hub-to-tip. That creates a period with missing support, and a later newly materialized segment may appear penetrating Track.

### 9.2 New mount-offset model

Absolute rotational orientation of a continuously rotating shape is not player-authored persistent state. Therefore a new ShapeSpec may use a server-selected **common geometry mount offset** around each fixed pivot at commit time.

The drive roots and their live phases are never snapped. The mount offset is local to the geometry attached to each drive.

Both sides use the same mount offset; right/left drive roots still remain 180 degrees opposed.

### 9.3 `LegCollisionSafety`

Create/replace server helper:

`src/server/Runtime/LegCollisionSafety.lua`

Responsibility:
- non-mutating evaluation of candidate geometry mount offsets against `Workspace.Runtime.Tracks` only;
- calculate world CFrames/sizes for the new segment plan at the live left/right drive transforms;
- reuse bounded overlap/penetration scoring concepts from `RedrawSpawnSafety`;
- never move body/drive/leg Instances;
- never query racers/characters/decorations as authoritative Track penetration.

Candidate policy:
- evaluate a bounded circle of mount offsets, initially 24 candidates at 15-degree spacing;
- prefer zero-penetration candidates;
- among equally safe candidates prefer the smallest absolute mount offset from the authored orientation, for visual continuity;
- if no zero-penetration candidate exists, fail closed with `NO_SAFE_REDRAW_PHASE` rather than launching the racer.

The exact candidate count is an implementation/tuning value, not a new product mechanic.

### 9.4 Transaction sequence

For an already-active shape:

1. `LegShapeService` validates raw input and builds a candidate ShapeSpec, but does not publish success.
2. `RacerRuntime` starts one redraw transaction; a second submit while it is active is rejected as `REDRAW_PENDING`.
3. `LegPairAssembly` asks `LegCollisionSafety` for a safe common mount offset using current drive/body transforms.
4. If none exists, transaction rejects and the old shape remains completely active.
5. Each `LegAssembly` stages only the **visual** representation of the new shape. Existing physical geometry remains untouched.
6. Over a short presentation interval (~existing 0.08–0.15s range), staged visuals grow/fade hub-to-tip if desired. Physics remains old shape.
7. Immediately before physical commit, safety is rechecked using the then-current body/drive transforms. If the previous candidate is no longer safe, recompute once from current transforms.
8. If a safe offset exists, both sides perform one coordinated atomic physical swap: new full colliders are installed with collisions initially disabled, old colliders are disabled, new colliders enabled, then old geometry destroyed within the same synchronous commit section.
9. Pair reports commit success.
10. Only then does `RacerRuntime` set `currentShapeSpec` and model `ShapeVersion`.
11. Only then does `LegShapeService` return/emit accepted `StrokeResult`.

Failure at any pre-publication step:
- cancel staged visual;
- keep old physical geometry;
- keep old ShapeSpec/ShapeVersion;
- no body CFrame or velocity reset;
- return a bounded rejection reason.

This removes the need for the current redraw gravity-support VectorForce. Gravity compensation should be deleted once old-support-until-commit is proven.

### 9.5 Transaction timing

The redraw transaction must remain shorter than the existing client result timeout. Initial engineering target: normally complete within ~0.15s and hard-fail well below 1s. It must never silently hang waiting for a future motor phase.

---

## 10. Network and authoritative publication

### 10.1 Schema

No schema expansion is needed.

Client -> server:

```text
SubmitStroke { sequence, points }
```

Server -> client:

```text
StrokeResult {
  sequence,
  accepted,
  shapeVersion?,
  acceptedPoints?,
  rejectReasonCode?
}
```

### 10.2 Changed semantics

`acceptedPoints` are fixed-pivot canonical points. First point is `(0,0)` because the stroke began at the visible pivot, not because the server translated the whole drawing.

Potential new rejection categories:
- `START_OFF_PIVOT`
- `REDRAW_PENDING`
- `NO_SAFE_REDRAW_PHASE`

UI may map those to simple player copy; internal geometry details do not need to be exposed.

### 10.3 Pending concurrency

One player/racer may have at most one shape transaction in flight.

`LegShapeService.CreateSubmitProcessor` must preserve sequence/rate security while preventing a newer request from superseding a pending mechanical commit.

Authoritative success means **physical commit succeeded**, not merely “candidate ShapeSpec was valid”.

---

## 11. `RacerRuntime` responsibilities after repair

Keep `RacerRuntime` as orchestration/lifecycle only.

Owns:
- BodyCollider/model lifetime;
- one persistent `LegPairAssembly`;
- current authoritative ShapeSpec/version;
- one pending shape transaction lifecycle;
- cancellation before recovery/destroy;
- stabilizer and anti-stall lifetimes.

Does not own:
- canonical cleanup details;
- segment construction;
- one-side hinge construction;
- phase-control math;
- Track overlap math;
- camera destination.

Transactional API can conceptually become:

```text
ApplyValidatedShape(shapeSpec, motorEnabled) -> success, reason?
```

For a redraw, it returns only after the pair commit succeeds or fails. A bounded yield inside the server request thread is acceptable; it must not block the whole server scheduler and it must be cancellation-safe on Destroy/Recovery.

Initial shape creation may install directly after safety evaluation because there is no old physical shape to preserve.

---

## 12. Camera and recovery containment

Mechanical repair is first. Camera must not hide a physics failure during debugging.

After twin-pivot/upright/redraw repair is green:

### RaceCameraController
Keep presentation-only. Resolve local racer model + BodyCollider and optionally read a semantic replicated model attribute such as:

`CameraMinFollowY`

When present, clamp only the camera follow anchor Y:

```text
presentationY = max(body.Position.Y, CameraMinFollowY)
```

Do not move or recover the racer from camera code.

### G0 harness
For the M0 flat/obstacle lab, set `CameraMinFollowY` from known lane top/body framing so a falling racer leaves the frame instead of dragging the camera below the track.

The G0 `RecoveryKillY=-12` is too visually late for rapid iteration. After mechanical fixes, use a less-deep Studio-only threshold (initial proposal around -6) while keeping enough space for the existing gap test. Production checkpoint/kill-plane ownership remains separate.

---

## 13. Files and ownership changes

### New files
- `src/shared/Math/LegDriveMath.lua`
- `src/server/Runtime/LegDriveAssembly.lua`
- `src/server/Runtime/LegCollisionSafety.lua`

### Whole-module rewrites required
- `src/server/Runtime/LegPairAssembly.lua`
- `src/server/Runtime/LegAssembly.lua`

Reason: their current public APIs and ownership are built around the superseded shared-axle topology / destructive physical reshape.

### Targeted migrations
- `src/shared/Math/CanonicalLegShape.lua`
- `src/client/Controllers/DrawingController.lua`
- `src/server/Services/LegShapeService.lua`
- `src/server/Runtime/RacerRuntime.lua`
- `src/server/Runtime/RacerStabilizer.lua`
- `src/shared/Config/PhysicsConfig.lua`
- later `src/client/Controllers/RaceCameraController.lua`
- later `src/server/Tests/M0HumanHarness.lua`
- later `src/shared/Config/M0SceneConfig.lua`

### Retire/delete after direct consumers migrate
- production meaning of `LegSocketZAbs` / shared physical axle/socket layout;
- one-shared-HingeConstraint assertions;
- `presentationAnchor` shape/presentation path;
- physical `ReshapeTipCollider` redraw handoff;
- redraw gravity support once old-shape-until-commit is active;
- current `RedrawSpawnSafety` shared-axle phase mutation model, replaced by mount-offset collision safety.

No compatibility bridge should survive CR2-06 cleanup.

---

## 14. Implementation sequence after spec approval

### CR2-00 — Source of Truth update
Update canonical docs before production behavior:
- new decision log (this direction);
- `03_CORE_MECHANICS_SPEC.md`;
- `16_BALANCE_TUNING.md`;
- `21_SYSTEM_CLASS_ARCHITECTURE.md`;
- `22_NETWORK_DATA_CONTRACTS.md`;
- `24_TESTING_QA_MATRIX.md`;
- `59_UI_LAYOUT_WIREFRAME_SPEC.md`;
- `65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md`;
- `68_UI_COMPONENT_HIERARCHY_IMPLEMENTATION_SPEC.md`;
- `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`;
- `ARCHITECTURE_MAP.md`, `FEATURE_LIST.md`, `SESSION.md`.

Explicitly mark superseded R16.3B/R17 mechanical paragraphs instead of leaving contradictory active text.

### CR2-01 — Fixed visible pivot semantics
TDD target:
- pivot marker exists;
- off-pivot start rejects;
- canonical no longer calls whole-shape `AnchorToFirstPoint`;
- no `presentationAnchor` output/state;
- fixed canvas mapping stays client/server identical;
- raw network schema unchanged.

Production scope:
- `CanonicalLegShape`;
- `DrawingController`;
- `LegShapeService` validation semantics;
- types/tests.

### CR2-02 — Twin drive ownership
TDD target:
- exactly two HingeConstraints, both owned by `LegDriveAssembly`;
- left/right drive roots at X ± half BodyCollider width, Y/Z zero;
- no shared production `AxleRoot`;
- `LegAssembly` contains no actuator/pair policy;
- same ShapeSpec reaches both side geometry owners;
- persistent drive identity across redraw.

Production scope:
- add `LegDriveAssembly`;
- rewrite `LegAssembly` boundary;
- rewrite `LegPairAssembly` topology;
- migrate `RacerRuntime` direct consumers.

### CR2-03 — Extent-aware drive + rigid upright
TDD target:
- `LegDriveMath` pure/deterministic;
- angular speed decreases as extent increases;
- computed tip-speed envelope bounded;
- phase error correction bounded/deadbanded;
- 180-degree target explicit;
- stabilizer remains no-forward/no-vertical-force and is rigid-upright.

Production scope:
- add `LegDriveMath`;
- pair Step/sync;
- config starting values;
- `RacerStabilizer`.

### CR2-04 — Transactional collision-safe redraw
TDD target:
- old physical segments remain unchanged throughout visual stage;
- safety planner mutates no racer Instances;
- safety queries Track only;
- atomic commit replaces both sides together;
- no BodyCollider CFrame/velocity reset;
- failed safety leaves old shape/version intact;
- success publishes version only after physical commit;
- second submit during pending transaction rejects.

Production scope:
- add `LegCollisionSafety`;
- pair staging/commit;
- runtime transaction lifecycle;
- service pending handling;
- delete old physical hub-to-tip redraw support path.

### CR2-05 — Camera/recovery containment
TDD target:
- camera floor is presentation-only;
- absent attribute preserves generic behavior;
- G0 provides track-appropriate floor;
- recovery remains runtime/harness-owned;
- camera never calls PivotTo/sets body CFrame.

### CR2-06 — Cleanup and architecture audit
Delete all retired shared-axle/hidden-pivot compatibility tokens. Re-run full repository contract suite and Rojo build. Diff-review scope to ensure no race/meta/economy expansion.

Then and only then return to human G0.

---

## 15. Automated verification matrix

New/updated repository contracts must prove at least:
- one canonical builder;
- no full-shape first-point translation;
- fixed pivot start rule shared client/server;
- raw semantic network input;
- exactly two drive hinge owners;
- no hinge inside LegAssembly/RacerRuntime/LegShapeService/DrawingController;
- opposite X pivots, no physical Z socket separation;
- one ShapeSpec duplicated to both legs;
- persistent drive/side identity on redraw;
- pure bounded extent-to-omega math;
- 180-degree target + bounded phase correction;
- rigid upright owner remains RacerStabilizer;
- old physical shape survives until safe commit;
- safe planner queries Track only and performs no mutation;
- authoritative version/result publication happens after commit;
- recovery/destroy cancel pending transaction safely;
- camera clamp cannot affect physics;
- exact-head `verify.py` full PASS;
- Rokit/toolchain install PASS;
- `rojo build default.project.json` PASS.

Static/source checks are not sufficient evidence for physics feel.

---

## 16. Human G0 acceptance after implementation

Record a fresh Studio video. G0 is not PASS unless the video/evidence shows:

1. **Pivot honesty** — player visibly starts from the dot; accepted world leg shape corresponds to the canvas geometry around that same pivot.
2. **Creature-leg read** — left and right legs visibly originate at opposite horizontal cube edges, not front/back Z copies and not one wheel-like shared hub.
3. **Upright body** — normal flat contacts do not produce obvious cube tumbling; engineering target for measured visible tilt is <= about 5 degrees outside brief solver transients.
4. **Flat stability** — no repeated recovery loop during normal valid flat traversal; target body speed remains the existing reference band around 4–7 studs/s unless later human tuning intentionally changes that owner.
5. **Bounded leg sweep** — no giant screen-dominating arcs like the failed 4.8/6.9 + 8 rad/s video state.
6. **Alternating contact** — the two legs visibly maintain approximately 180 degrees under motion/contact; short transients may deviate but must recover smoothly without snaps.
7. **Redraw under movement** — draw a second shape while moving; body must not teleport, zero velocity, drop due to removed support, or launch from a penetrating collider.
8. **Shape usefulness** — compact/rounded/long/hook-like strokes produce meaningfully different physical outcomes without hard-coded classifications.
9. **Failure presentation** — if racer falls, camera stays useful instead of diving under the course; recovery occurs without corrupting current accepted shape/version.
10. **Obstacle sanity** — after flat is stable, repeat Steps/Wall/Gap/Tunnel and verify different geometry trade-offs still exist.

If items 2–7 fail, do not continue to later game systems. Treat it as another core architecture/debug cycle.

---

## 17. Explicit non-goals / forbidden shortcuts

CORE REPAIR v2 must not introduce:
- direct forward velocity assignment as normal locomotion;
- per-obstacle shape bonuses;
- `if circle`, `if hook`, `if L` movement code;
- body teleports to mask redraw impulses;
- per-frame CFrame phase locking of legs;
- client-authored physical pivot/motor/CFrame authority;
- duplicated canonical math on client/server;
- a second camera owner;
- compatibility copies of the old shared-axle system left active beside the new one.

The purpose of this repair is not merely to reduce visible bugs. It is to make the mechanical contract match the intended game while keeping one clear owner for every fact.

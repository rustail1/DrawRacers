# 73 — SHAPE COORDINATE, PIVOT & COLLIDER SPEC
Статус: **EXACT CORE GEOMETRY CONTRACT v1.5.0 / R16.3B + MR-06 PERSISTENT OPPOSED SHARED AXLE**.

Цель: убрать неоднозначность между экранным stroke и физической leg assembly. Этот файл владеет точным mapping `DrawCanvas → authoritative ShapeSpec → collider segments → persistent shared axle assembly`. `03` владеет игровым поведением, `16` — tuneable constants, `65` — Studio instance tree, `22` — network payload.

> **R16.3B supersedes R16.3A bounds-center semantics.** Положение рисунка на широком DrawInputRect остаётся presentation input, но механический origin определяется первым cleaned point. Старое правило «bounds center / bounds-center → hub» больше не является текущим контрактом.
>
> **MR-01..MR-06 supersede the legacy duplicated/staged core.** `CanonicalLegShape` is the one canonical processing owner used by client prediction and server authority. Production rotation is owned by one persistent `LegPairAssembly`, one shared axle, one `AxleJoint` and **one motor**. Left/Right use the same canonical XY ShapeSpec and a fixed structural opposition `RightPhaseOffsetDegrees = 180`. Redraw reuses the same pair/axle/joint/side owners. Live solver/visual acceptance remains **HUMAN STUDIO PENDING**.

## 1. Canonical 2D coordinate system
R16.3B uses one **wide semantic DrawInputRect**. Raw semantic coordinates are:
- `RawSemanticHalfWidth = 1.75` → X input range `[-1.75,+1.75]`;
- `RawSemanticHalfHeight = 1.0` → Y input range `[-1,+1]`;
- screen right = `+Xshape`;
- screen up = `+Yshape`;
- screen down therefore produces negative Yshape;
- one semantic unit is half of DrawInputRect pixel height on both X and Y, so the wide surface is isotropic and does not stretch physical geometry.

### R16.3B — First-point mechanical origin
After clamp/dedupe/RDP/resample, canonical processing anchors the cleaned stroke to its first cleaned point. This is **translation-only**:
- `origin = cleaned[1]`;
- every authoritative point becomes `point - origin`;
- `ShapeSpec.normalizedPoints[1] == (0,0)` within floating-point tolerance;
- scale does not change;
- aspect/proportions do not change;
- point order/direction does not change;
- rotation/mirror is not added;
- open stroke is not automatically closed.

The mechanical pivot is `(0,0)` of this first-point-anchored authoritative ShapeSpec. The **bounds midpoint is not required** to be `(0,0)` under R16.3B. Bounds are still computed for validation/debug, but bounds-center is no longer the mechanical-origin owner.

A translated copy of the same raw stroke produces the same first-point-relative authoritative geometry because both the first point and all later points shift together. A differently sized drawing still produces a differently sized leg. The submitted screen position may be retained only as a client presentation anchor; it is not part of ShapeSpec or physical authority.

## 2. Canvas-to-world scale
Current production mapping:
- `LegCanvasHalfSpan = 4.8 studs`;
- world-local point = `(Xshape * 4.8, Yshape * 4.8, 0)` inside each leg plane;
- hard radial extent from hub = `MaxLegExtentFromHub = 6.9 studs` after mapping;
- mapped point beyond the hard radial extent is clamped radially if needed.

The mapping remains isotropic: one semantic unit is the same number of studs on X and Y. Do not stretch the shape based on viewport aspect or DrawCanvas pixel aspect. The main gameplay canvas uses this fixed scale and **does not auto-fit per shape**. Thumbnail/presentation-only surfaces may fit for display as long as that transform never enters ShapeSpec or world geometry.

## 3. Canonical cleanup/build order
`src/shared/Math/CanonicalLegShape.lua` owns the complete ordered pipeline:
1. clamp raw points to the semantic rectangle `X ±1.75`, `Y ±1.0`;
2. reject non-finite values;
3. dedupe using `16.DedupeDistance`;
4. RDP simplify using `16.RDPEpsilon`;
5. resample along polyline arc length toward `16.ResampleTargetPoints` without inventing a closing segment;
6. enforce max cleaned points and minimum useful length/extent contracts;
7. set `origin = cleaned[1]` and translate all cleaned points by `-origin` (**R16.3B**);
8. compute authoritative anchored bounds for validation/debug;
9. map anchored normalized points to leg-local studs;
10. radial-clamp any mapped point to `MaxLegExtentFromHub`;
11. build one canonical segment plan.

`StrokeMath` and `GeometryMath` remain low-level pure helpers called by `CanonicalLegShape`; they are not alternate canonical pipelines.

Open strokes stay open. Closed appearance exists only if the player physically ends close to the first point; the builder never silently closes a stroke.

Client/server authority rules:
- `DrawingController` converts pointer samples to raw semantic points, then calls `CanonicalLegShape.Build` for prediction;
- `SubmitStroke` sends raw semantic `{x,y}` intent, not mapped points or segment data;
- `LegShapeService` validates envelope/sequence/rate/payload and independently calls the same `CanonicalLegShape.Build` on the server;
- server remains authoritative over accepted ShapeSpec/version;
- `StrokeResult.acceptedPoints` serializes authoritative `ShapeSpec.normalizedPoints`;
- a sequence-scoped client presentation anchor may re-position the accepted line on screen only; it never enters ShapeSpec/network/physics authority.

## 4. Exact leg-local frame
Before lane/world transforms, racer body local axes are:
- `+X` = race forward;
- `+Y` = up;
- `+Z` = right side of racer/lane.

Body collider default is `3×3×3` from `16`.

The rotating mechanical axis is centered at body-local `(HubOffsetX, HubOffsetY, 0)` through `BodyCollider.AxleMotorAttachment`:
- `HubOffsetX = 0.0`;
- `HubOffsetY = 0.0`.

There are no current runtime Left/Right compatibility hub Parts. `HubOffsetZAbs = 1.62` may remain as legacy/reference config data but does not own current side placement.

The persistent rigid side sockets on the shared axle are owned by `PhysicsConfig.LegGeometry`:
- `LegSocketZAbs = 1.5`;
- Left side socket Z = `-LegSocketZAbs`;
- Right side socket Z = `+LegSocketZAbs`.

Both legs use the **same first-point-anchored XY ShapeSpec geometry**. They are not mirrored/inverted in XY. Left is mounted at local phase `0`; Right is mounted at local phase `RightPhaseOffsetDegrees = 180`, creating the canonical structurally opposed relation while the two copies remain separated across Z.

## 5. LegPairAssembly / shared axle structure
**DataModel hierarchy is owned by `65`**; the exact relevant runtime subtree is:
```text
Racer_<RaceId>_<Slot> (Model)
  BodyCollider
    AxleMotorAttachment (Attachment)
  Legs
    AxleRoot (Part)
      MotorAttachment (Attachment)
      AxleJoint (HingeConstraint)
    LeftLeg (Model)
      LegRoot (Part)
        AxleWeld (WeldConstraint)
      Segments
        Segment_01..NN
      Visual
        VisualSegment_01..NN
        VisualJoint_01..NN
    RightLeg (Model)
      LegRoot (Part)
        AxleWeld (WeldConstraint)
      Segments
        Segment_01..NN
      Visual
        VisualSegment_01..NN
        VisualJoint_01..NN
```

`LegPairAssembly` owns `AxleRoot`, the only `AxleJoint`, the only rotating phase, and **one motor**. `AxleJoint.Attachment0 = BodyCollider.AxleMotorAttachment`; `Attachment1 = AxleRoot.MotorAttachment`. The shared hinge axis is local/world `+Z` at neutral racer orientation.

Each side `LegAssembly` owns rigid geometry only. Its persistent `LegRoot` is welded to `AxleRoot` with `AxleWeld`; there is no per-side HingeConstraint or per-side actuator. Left uses local phase `0`; Right uses `RightPhaseOffsetDegrees = 180`. Because both roots are welded to the same persistent `AxleRoot`, the structural relation cannot drift independently under contact load.

Initial launch motor direction remains `AngularVelocity = -8.0 rad/s`; magnitude/torque sweep is owned by `16`. Negative sign is canonical because with the local frame above it drives normal bottom contact toward `+X` travel. If API axis orientation causes opposite travel, fix the canonical shared attachment axis rather than introducing per-side hidden signs or a second motor.

No Heartbeat phase-chasing controller is part of the contract.

## 6. Segment collider construction
For each consecutive first-point-anchored point pair `A→B` in the canonical segment plan:
- skip segment if mapped length `< MinimumMappedSegmentLength` after cleanup;
- create one simple rectangular physical Part;
- segment center = midpoint `(A+B)/2` in LegRoot local XY;
- long axis follows vector `B-A` in the XY plane;
- physical length = `|B-A| + SegmentOverlapAllowance`;
- thickness/depth = `PhysicalLegSegmentThickness = 0.54` on both short axes;
- segment is welded rigidly to that side LegRoot;
- no collision between segments in the same assembly;
- physical collider Parts remain hidden from presentation;
- nonphysical visual geometry uses the same canonical centerline and `VisualLegSegmentThickness = 0.78`.

There is **no automatic collision spoke from axle/socket to the first stroke point**. Under R16.3B the first authoritative point itself is `(0,0)` in each side's XY frame, so the first actual polyline segment begins at that side `LegRoot` XY origin only because that is the accepted stroke origin. The builder must never invent an extra spoke or closing segment.

## 7. Persistent redraw / hub-to-tip reshape
Normal redraw is an in-place geometry transaction:
- `RacerRuntime` keeps the current `LegPairAssembly` identity;
- `LegPairAssembly` keeps `AxleRoot`, `AxleJoint`, Left owner and Right owner identities;
- both sides receive one shared authoritative ShapeSpec;
- `LegAssembly:ReplaceGeometry` stores the new canonical plan at progress `0`;
- `LegReshapeMath.Evaluate` determines arc-length prefix state;
- at `0 < progress < 1`, gameplay geometry contains only the complete prefix plus at most one partial tip collider/visual;
- future full colliders do not exist merely hidden;
- reshape duration remains bounded by `0.08..0.15 s`;
- temporary reshape support, when enabled, is pair-owned, world-Y only and bounded to the reshape;
- redraw never writes BodyCollider CFrame/PivotTo/Anchored/linear velocity/angular velocity;
- recovery preparation may force completion of transient geometry, but destination/teleport policy remains external to the mechanical pair.

## 8. Acceptance invariants
Repository/source acceptance requires:
- exactly one canonical builder owner (`CanonicalLegShape`);
- client prediction and server authority use the same canonical semantics while server recomputes from raw input;
- `ShapeSpec.normalizedPoints[1]` is the first-point origin;
- current scale is `LegCanvasHalfSpan = 4.8`, radial cap `MaxLegExtentFromHub = 6.9`;
- one persistent `LegPairAssembly`, one `AxleRoot`, one `AxleJoint`, **one motor**;
- `LegSocketZAbs = 1.5` and fixed `RightPhaseOffsetDegrees = 180`;
- two sides share the same canonical XY centerline and are structurally opposed without a phase-chasing owner;
- redraw keeps pair/axle/joint/side identities and body motion state;
- physical and visual centerlines are identical even though thickness differs;
- traversal evidence never counts `RecoveryKillY` fall or solver instability as success.

Automated repository/build green is not live physics acceptance. Actual contact behavior, obstacle usefulness, redraw feel, camera/rider feel and overall traversal remain **HUMAN STUDIO PENDING** until the normal G0 Studio pass is recorded.

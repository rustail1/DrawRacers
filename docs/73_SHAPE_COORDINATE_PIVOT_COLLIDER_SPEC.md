# 73 — SHAPE COORDINATE, PIVOT & COLLIDER SPEC
Статус: **EXACT CORE GEOMETRY CONTRACT v1.4.3 / R16.3B + R17 SHARED AXLE CO-PHASE OVERRIDE**.

Цель: убрать неоднозначность между экранным stroke и физической leg assembly. Этот файл владеет точным mapping `DrawCanvas → authoritative ShapeSpec → collider segments → shared axle assembly`. `03` владеет игровым поведением, `16` — tuneable constants, `65` — Studio instance tree, `22` — network payload.

> **R16.3B supersedes R16.3A bounds-center semantics.** Положение рисунка на широком DrawInputRect остаётся presentation input, но механический origin теперь определяется первым cleaned point. Старое правило «bounds center / bounds-center → hub» больше не является текущим контрактом.
>
> **R17 supersedes the old independent left/right hinge implementation.** The authoritative ShapeSpec mapping below is unchanged, but production rotation is now owned by one `LegPairAssembly`, one shared axle, one `AxleJoint` and one motor. Human video on 2026-09-12 supersedes the interim structural-180 interpretation: the two side `LegAssembly` objects are rigid **co-phase** children at opposite Z sockets with `RightPhaseOffsetDegrees = 0`. Live solver/visual acceptance remains **HUMAN STUDIO PENDING**.

## 1. Canonical 2D coordinate system
R16.3B uses one **wide semantic DrawInputRect**. Raw semantic coordinates are:
- `RawSemanticHalfWidth = 1.75` → X input range `[-1.75,+1.75]`;
- `RawSemanticHalfHeight = 1.0` → Y input range `[-1,+1]`;
- screen right = `+Xshape`;
- screen up = `+Yshape`;
- screen down therefore produces negative Yshape;
- one semantic unit is half of DrawInputRect pixel height on both X and Y, so the wide surface is isotropic and does not stretch physical geometry.

### R16.3B — First-point mechanical origin
After clamp/dedupe/RDP/resample, the server anchors the cleaned stroke to its first cleaned point. This is **translation-only**:
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
Starting mapping after R16.3B first-point anchoring:
- `LegCanvasHalfSpan = 3.15 studs`;
- world-local point = `(Xshape * 3.15, Yshape * 3.15, 0)` inside each leg plane;
- hard radial extent from hub = `4.50 studs` after server mapping;
- mapped point beyond the hard radial extent is clamped radially if needed.

The mapping remains isotropic: one semantic unit is the same number of studs on X and Y. Do not stretch the shape based on viewport aspect or DrawCanvas pixel aspect. The wider raw X range only allows a longer horizontal stroke before the same radial hard cap is applied.

## 3. Cleanup order
Canonical authoritative order:
1. clamp raw points to the R16.3B semantic rectangle `X ±1.75`, `Y ±1.0`;
2. reject non-finite values;
3. dedupe using `16.DedupeDistance`;
4. RDP simplify using `16.RDPEpsilon`;
5. resample along polyline arc length toward `16.ResampleTargetPoints` without inventing a closing segment;
6. enforce max cleaned points;
7. validate minimum cleaned polyline length;
8. set `origin = cleaned[1]` and translate all cleaned points by `-origin` (**R16.3B**);
9. compute authoritative anchored bounds for validation/debug; their bounds midpoint is not required to equal the hub;
10. map anchored normalized points to leg-local studs;
11. radial-clamp any mapped point to `MaxLegExtentFromHub`;
12. build segments.

Open strokes stay open. Closed appearance exists only if the player physically ends close to the first point; the builder never silently closes a stroke.

Client may preprocess for bounded preview/submission, but the server is the sole owner of the final first-point-anchored ShapeSpec. `StrokeResult.acceptedPoints` serializes `ShapeSpec.normalizedPoints`, so accepted physics always consumes server authority. `DrawingController` may reapply the sequence-scoped submitted first raw point as a local presentation anchor when drawing the accepted line; that presentation offset never enters the server ShapeSpec.

## 4. Exact leg-local frame
Before lane/world transforms, racer body local axes are:
- `+X` = race forward;
- `+Y` = up;
- `+Z` = right side of racer/lane.

Body collider default is `3×3×3` from `16`.

Stable hub-marker centers relative to racer body center are still owned numerically by `PhysicsConfig.LegGeometry`:
- `HubOffsetX = 0.0`;
- `HubOffsetY = 0.0`;
- `HubOffsetZAbs = 1.62`;
- LeftHub = `(HubOffsetX, HubOffsetY, -HubOffsetZAbs)`;
- RightHub = `(HubOffsetX, HubOffsetY, +HubOffsetZAbs)`.

Under R17 those `LeftHub` / `RightHub` Parts remain body-welded markers/compatibility anchors; they are **not** the motor owners. The rotating mechanical axis is centered at body-local `(HubOffsetX, HubOffsetY, 0)` through `BodyCollider.AxleMotorAttachment`.

The rigid side sockets on the shared axle are owned by `PhysicsConfig.LegGeometry`:
- `LegSocketZAbs = 1.5`;
- Left side socket Z = `-LegSocketZAbs`;
- Right side socket Z = `+LegSocketZAbs`.

Both legs use the **same first-point-anchored XY ShapeSpec geometry**. They are not mirrored/inverted in XY. Both rigid sides are mounted at the same local axle angle; `RightPhaseOffsetDegrees = 0`, creating the canonical **co-phase** relation while the two copies remain separated across Z.

## 5. LegPairAssembly / shared axle structure
**DataModel hierarchy is owned by `65`**; the exact relevant runtime subtree is:
```text
Racer_<RaceId>_<Slot> (Model)
  BodyCollider
    AxleMotorAttachment (Attachment)
  LeftHub
    MotorAttachment (Attachment) [marker/compatibility; not a motor owner]
  RightHub
    MotorAttachment (Attachment) [marker/compatibility; not a motor owner]
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

Each side `LegAssembly` owns rigid geometry only. Its `LegRoot` is welded to `AxleRoot` with `AxleWeld`; there is no per-side HingeConstraint or per-side actuator. Left uses local phase `0`; Right uses `RightPhaseOffsetDegrees = 0`. Because both are welded to the same `AxleRoot`, they stay co-phase and cannot drift independently under contact load.

Initial launch motor direction remains `AngularVelocity = -8.0 rad/s`; magnitude/torque sweep is owned by `16`. Negative sign is canonical because with the local frame above it drives normal bottom contact toward `+X` travel. If API axis orientation causes opposite travel, fix the canonical shared attachment axis rather than introducing per-side hidden signs or a second motor.

No Heartbeat phase-chasing controller is part of the contract. R17 co-phase shared rotation replaces both the former independent-motor phase-correction approach and the interim 180° local side offset.

## 6. Segment collider construction
For each consecutive first-point-anchored point pair `A→B`:
- skip segment if mapped length `< 0.08 stud` after cleanup;
- create one simple rectangular physical Part;
- segment center = midpoint `(A+B)/2` in LegRoot local XY;
- long axis follows vector `B-A` in the XY plane;
- physical length = `|B-A| + 0.06 stud` overlap allowance;
- thickness/depth = `PhysicalLegSegmentThickness` from `16` on both short axes;
- segment is welded rigidly to that side LegRoot;
- no collision between segments in the same assembly;
- physical collider Parts remain hidden from presentation;
- visual smoothing/round caps are separate nonphysical `Visual` geometry and may use `VisualSegmentsPerLeg`.

There is **no automatic collision spoke from axle/socket to the first stroke point**. Under R16.3B the first authoritative point itself is `(0,0)` in each side's XY frame, so the first actual polyline segment begins at that side `LegRoot` XY origin only because that is the accepted stroke origin. The builder must never invent an extra spoke or closing segment.

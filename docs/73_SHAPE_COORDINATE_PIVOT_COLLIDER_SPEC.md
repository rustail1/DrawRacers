# 73 — SHAPE COORDINATE, PIVOT & COLLIDER SPEC
Статус: **EXACT CORE GEOMETRY CONTRACT v1.6.0 / CORE V3 OPPOSED SHARED AXLE**.

Цель: убрать неоднозначность между экранным stroke и физической leg assembly. Этот файл владеет точным mapping `DrawCanvas → authoritative ShapeSpec → collider segments → persistent shared axle assembly`. `03` владеет игровым поведением, `16` — tuneable constants, `65` — Studio instance tree, `22` — network payload.

> **R16.3B supersedes R16.3A bounds-center semantics.** Положение рисунка на широком DrawInputRect остаётся presentation input, но механический origin определяется первым cleaned point. Старое правило «bounds center / bounds-center → hub» больше не является текущим контрактом.
>
> **Core V3 is current.** `CanonicalLegShape` owns canonical processing; production rotation is one `SharedAxle` / one `DriveJoint` / one motor owner. Left/Right use the same XY ShapeSpec at fixed 180°. Live solver acceptance remains **HUMAN PHYSICS PENDING**.

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

The Core V3 rotating axis is mounted at the cube center through `BodyCollider.LegDriveMount`:
- local X = `0`;
- local Z = `0`;
- local Y = `0`;
- ShapeSpec size/geometry and redraw do not change this mount.

There are no current compatibility hub Parts.

Core V3 side placement is owned by `LegCoreConfig.Mount`: `sideOffset = body.Size.Z/2 + SideOutset`, with Left negative Z and Right positive Z.

Both legs use the **same first-point-anchored XY ShapeSpec geometry**. They are not mirrored/inverted in XY. Left is mounted at local phase `0`; Right is mounted at local phase `RightPhaseDegrees = 180`, creating the canonical structurally opposed relation while the two copies remain separated across Z.

## 5. Core V3 shared axle structure
Relevant runtime subtree:
```text
Racer
  BodyCollider
    LegDriveMount
  Legs
    SharedAxle
      AxleRoot
        AxleAttachment
      LeftMount
        LeftLeg
      RightMount
        RightLeg
      DriveJoint (only HingeConstraint)
```

`SharedAxle` owns the one rotating joint and fixed side relation. Hinge axis is +Z at neutral orientation. LeftMount phase = 0; RightMount phase = 180°. Mounts are welded to AxleRoot; there is no side hinge or actuator.

Motor angular speed is computed from ShapeSpec extent by `LegCoreController`/`LegCoreConfig` target tip speed and clamp. Negative rotation sign remains the current forward convention. Fix axis/sign at the shared owner rather than introducing side-specific signs.

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

## 7. Core V3 redraw / preview / clearance
Core V3 redraw is not the old persistent hub-to-tip reshape path.
- old LeftLeg/RightLeg geometry is destroyed at rebuild start;
- one SharedAxle/DriveJoint owner remains;
- new LeftLeg/RightLeg previews and physical ghost Parts are created together;
- initial whole-pair required lift is calculated before the redraw hop;
- one bounded +Y impulse starts the hop while all ghost geometry follows the axle;
- preview grows through the current ShapeSpec centerline;
- physical Parts remain ghost/non-colliding through PREVIEW/WAIT_CLEAR;
- whole-pair clearance checks only `canCollide=true` segments;
- bounded soft +Y lift may finish any clearance remaining after the hop;
- both sides become physical in one activation step;
- accepted ShapeSpec/ShapeVersion commits only after ACTIVE;
- mechanical failure is fail-closed to EMPTY.

## 8. Acceptance invariants
Repository/source acceptance requires:
- exactly one canonical builder owner (`CanonicalLegShape`);
- client prediction and server authority use the same canonical semantics while server recomputes from raw input;
- `ShapeSpec.normalizedPoints[1]` is the first-point origin;
- current scale is `LegCanvasHalfSpan = 4.8`, radial cap `MaxLegExtentFromHub = 6.9`;
- one Core V3 SharedAxle, one AxleRoot, one DriveJoint, one motor owner;
- Left/Right same canonical XY centerline, opposite Z sides, structural 180° relation;
- no per-side hinge/motor or phase-chasing owner;
- physical/visual centerlines match even though thickness differs;
- only authoritative `canCollide=true` physical segments may enter clearance/contact;
- no normal +X helper in the Flat Gate;
- redraw commits accepted state only after ACTIVE;
- the approved 2.5D lane/upright owner may constrain Z/orientation only.

Automated repository/build green is not live physics acceptance. Actual contact behavior, obstacle usefulness, redraw feel, camera/rider feel and overall traversal remain **HUMAN STUDIO PENDING** until the Core V3 Flat human gate is recorded.

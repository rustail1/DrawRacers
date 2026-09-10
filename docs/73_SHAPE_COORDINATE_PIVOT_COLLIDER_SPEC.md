# 73 — SHAPE COORDINATE, PIVOT & COLLIDER SPEC
Статус: **EXACT CORE GEOMETRY CONTRACT v1.4.1 / R16.3B**.

Цель: убрать неоднозначность между экранным stroke и физической leg assembly. Этот файл владеет точным mapping `DrawCanvas → authoritative ShapeSpec → collider segments → hinge assembly`. `03` владеет игровым поведением, `16` — tuneable constants, `65` — Studio instance tree, `22` — network payload.

> **R16.3B supersedes R16.3A bounds-center semantics.** Положение рисунка на широком DrawInputRect остаётся presentation input, но механический origin теперь определяется первым cleaned point. Старое правило «bounds center / bounds-center → hub» больше не является текущим контрактом.

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

Hub centers relative to racer body center are owned numerically by `PhysicsConfig.LegGeometry`:
- `HubOffsetX = 0.0`;
- `HubOffsetY = -0.35`;
- `HubOffsetZAbs = 1.62`;
- LeftHub = `(HubOffsetX, HubOffsetY, -HubOffsetZAbs)`;
- RightHub = `(HubOffsetX, HubOffsetY, +HubOffsetZAbs)`.

Both legs use the **same first-point-anchored XY ShapeSpec geometry**. They are duplicated only by Z translation; do not mirror/invert the stroke in XY. This makes one accepted player drawing mechanically identical on both sides.

## 5. LegRoot / hinge assembly
Each side has one non-collidable rotating `LegRoot` Part centered on its hub. **DataModel hierarchy is owned by `65`**; the exact relevant runtime subtree is:
```text
Racer_<RaceId>_<Slot> (Model)
  BodyCollider
  LeftHub
    MotorAttachment
  RightHub
    MotorAttachment
  Legs
    LeftLeg (Model)
      LegRoot
        MotorAttachment
      HubJoint
      Segments
        Segment_01..NN
      Visual
        VisualSegment_01..NN
        VisualJoint_01..NN
    RightLeg (Model)
      LegRoot
        MotorAttachment
      HubJoint
      Segments
        Segment_01..NN
      Visual
        VisualSegment_01..NN
        VisualJoint_01..NN
```
This file owns the mechanical relation/coordinates; it does not define an alternate parent tree.

`HingeConstraint` connects `LeftHub/RightHub.MotorAttachment` (body-side) to that side `LegRoot.MotorAttachment`. All physical segments are welded to `LegRoot`. The body is not welded to `LegRoot`.

Hinge rotation axis is local/world `+Z` at neutral racer orientation on both sides. Initial launch motor direction is `AngularVelocity = -8.0 rad/s`; magnitude sweep is owned by `16`. Negative sign is canonical because with the local frame above it drives normal bottom contact toward `+X` travel. If an implementation API axis orientation causes the opposite sign, fix attachment axis orientation to this contract rather than creating per-side hidden signs.

Right leg starts `180°` phase after Left leg. Phase offset tuning stays in `16`.

## 6. Segment collider construction
For each consecutive first-point-anchored point pair `A→B`:
- skip segment if mapped length `< 0.08 stud` after cleanup;
- create one simple rectangular physical Part;
- segment center = midpoint `(A+B)/2` in LegRoot local XY;
- long axis follows vector `B-A` in the XY plane;
- physical length = `|B-A| + 0.06 stud` overlap allowance;
- thickness/depth = `PhysicalLegSegmentThickness` from `16` on both short axes;
- segment is welded rigidly to LegRoot;
- no collision between segments in the same assembly;
- physical collider Parts remain hidden from presentation;
- visual smoothing/round caps are separate nonphysical `Visual` geometry and may use `VisualSegmentsPerLeg`.

There is **no automatic collision spoke from hub to the first stroke point**. Under R16.3B the first authoritative point itself is `(0,0)`, so the first actual polyline segment begins at the hub only because that is the accepted stroke origin. The builder must never invent an extra spoke or closing segment.

Segments whose nearest geometry lies inside `InnerHubNoCollisionRadius` keep visual representation but set physical collision off. Outside that radius, leg colliders may collide with **Track only** (plus non-blocking Trigger query); they never collide with own body/legs or another racer. Global collision ownership = `28/65`.

Presentation geometry is strictly non-authoritative: visual Parts use `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true` and cannot affect locomotion.

## 7. Atomic rebuild
For accepted redraw:
1. server validates and first-point-anchors ShapeSpec;
2. construct new left/right assemblies staged with collision disabled;
3. copy current hinge angle/phase target as closely as implementation allows;
4. place both new LegRoots at canonical hubs;
5. enable new collision;
6. disable/remove old collision and destroy old assemblies in the same server frame/task boundary;
7. do not change Body CFrame/linear velocity solely because of redraw.

There must never be a frame where both old and new physical legs can push the racer simultaneously.

## 8. Shape lifetime
- First-ever arrival in a place/server has **no accepted shape**.
- At GO with no accepted shape: no leg colliders are fabricated; racer remains stationary and receives the canonical draw hint.
- Respawn inside the same heat retains the current accepted ShapeSpec.
- Consecutive heats inside the same `RacePlace` server/session carry the last accepted ShapeSpec into PREP and the next heat, so rematch does not force redraw unless the player wants it.
- `EntryFTUEPlace → RacePlace` teleport does **not** persist/carry freehand ShapeSpec; RacePlace begins with no accepted shape.
- Disconnect/rejoin/server transfer does not persist freehand ShapeSpec.
- ShapeSpec/ShapeVersion are runtime only and never enter DataStore.

## 9. ShapeVersion
`ShapeVersion` is a per-racer server-runtime monotonically increasing integer starting at `0` (no shape). Every accepted shape increments by exactly `1`; rejected submits do not increment. Sequence is reset when the racer runtime object is recreated on a new server session.

## 10. Canonical reproducible test/bot shapes
All coordinates below are semantic input coordinates. Test/reference presets pass through the same R16.3B first-point anchoring path as human shapes; presets are never classification shortcuts for movement.

### `ROUND_01`
12-point open polyline approximating a circle, radius `0.72`, beginning at angle 0° and ending at 330°:
`[(.72,0),(.624,.36),(.36,.624),(0,.72),(-.36,.624),(-.624,.36),(-.72,0),(-.624,-.36),(-.36,-.624),(0,-.72),(.36,-.624),(.624,-.36)]`

### `LONG_BAR_01`
`[(-.92,0),(-.46,0),(0,0),(.46,0),(.92,0)]`

### `SMALL_ROUND_01`
Same 12 directions as ROUND_01 with radius `0.40`.

### `HOOK_01`
`[(-.20,-.20),(.10,-.10),(.45,.05),(.72,.34),(.70,.70),(.38,.88),(.12,.72)]`

### `ASYM_01`
`[(-.82,-.18),(-.30,-.52),(.18,-.26),(.76,.08),(.34,.58),(-.18,.82),(-.52,.30)]`

### `SUBOPTIMAL_01`
Safe but intentionally mediocre compact diagonal for bot mistakes:
`[(-.42,-.25),(-.15,-.05),(.08,.22),(.36,.42)]`

Presets are owned here. Bots reference IDs, never duplicate coordinates in `40/75`.

## 11. UI presentation origin
R16.3B removes the old assumption that a center marker is the mechanical origin for raw input. The mechanical origin is always the first cleaned authoritative point after server processing.

Live drawing remains where the pointer moved. On submit, the client may store the first submitted semantic point keyed by `sequence`. On accepted result, the server returns first-point-relative `acceptedPoints`; the client may add that stored point back **only for presentation** so the accepted preview remains visually near the place the user drew it. The thumbnail may fit/recenter the shape independently because it is informational only.

No presentation anchor is sent as authoritative network data, persisted in ShapeSpec, used for collision, or used to change motor behavior.

## 12. Acceptance
PASS at repository-contract level only if:
- the first cleaned authoritative point maps to exact physical hub pivot `(0,0)` within tolerance;
- `ShapeSpec.normalizedPoints[1]` is zero and the bounds midpoint is not required to be zero;
- translating an otherwise identical raw stroke produces equivalent first-point-relative authoritative geometry;
- changing drawn **size** changes physical radius rather than being normalized away;
- the visible/capture DrawInputRect is the same wide 1.75:1 semantic surface and normalization remains isotropic;
- no automatic spoke or closing segment is fabricated;
- physical colliders are hidden and presentation visual geometry is nonphysical;
- no default wheel/StarterShape appears when no shape exists;
- ROUND/LONG_BAR/SMALL_ROUND/HOOK/ASYM presets produce repeatable distinct physical behavior in the Studio evidence path;
- rebuild never double-collides old+new legs;
- ShapeSpec is not persisted across server/place boundaries.

Live Roblox solver/visual acceptance remains HUMAN STUDIO PENDING until actual Studio evidence is recorded.
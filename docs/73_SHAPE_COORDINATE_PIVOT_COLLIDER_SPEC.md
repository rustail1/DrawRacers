# 73 — SHAPE COORDINATE, PIVOT & COLLIDER SPEC
Статус: **EXACT CORE GEOMETRY CONTRACT v1.3.4**.

Цель: убрать последнюю неоднозначность между экранным stroke и физической leg assembly. Этот файл владеет точным mapping `DrawCanvas → ShapeSpec → collider segments → hinge assembly`. `03` владеет игровым поведением, `16` — tuneable constants, `65` — Studio instance tree, `22` — network payload.

> Это project starting decision, а не скрытая формула референса. Если G0/G1 показывает плохой feel, меняются только явно tuneable числа через `16/55`; семантика pivot/coordinate mapping меняется только Decision Log.

## 1. Canonical 2D coordinate system
`DrawInputRect` использует normalized coordinates `[-1,+1]` по обеим осям:
- center of DrawInputRect = `(0,0)`;
- screen right = `+Xshape`;
- screen up = `+Yshape`;
- screen down therefore produces negative Yshape;
- input is clamped to `[-1,+1]` before submit.

**Pivot = DrawInputRect center `(0,0)`**, not the stroke bounding-box center. The server MUST NOT recenter the stroke around its own bounds and MUST NOT normalize every submitted stroke to the same radius. Size and offset relative to the hub are meaningful player input.

## 2. Canvas-to-world scale
Starting mapping:
- `LegCanvasHalfSpan = 3.15 studs`;
- world-local point = `(Xshape * 3.15, Yshape * 3.15, 0)` inside each leg plane;
- hard radial extent from hub = `4.50 studs` after server clamp;
- corner input near `(±1,±1)` therefore naturally approaches the radial hard cap and is clamped radially if needed.

The mapping is isotropic: one normalized unit is the same number of studs on X and Y. Do not stretch the shape based on viewport aspect or DrawCanvas pixel aspect.

## 3. Cleanup order
Canonical order on client preview and repeated server-side for authority:
1. clamp raw points to normalized square;
2. reject non-finite values;
3. dedupe using `16.DedupeDistance`;
4. RDP simplify using `16.RDPEpsilon`;
5. resample along polyline arc length toward `16.ResampleTargetPoints` without inventing a closing segment;
6. enforce max cleaned points;
7. validate minimum cleaned polyline length;
8. map normalized points to leg-local studs;
9. radial-clamp any mapped point to `MaxLegExtentFromHub`;
10. build segments.

Open strokes stay open. Closed appearance exists only if the player physically ends close to the first point; the builder never silently closes a stroke.

## 4. Exact leg-local frame
Before lane/world transforms, racer body local axes are:
- `+X` = race forward;
- `+Y` = up;
- `+Z` = right side of racer/lane.

Body collider default is `3×3×3` from `16`.

Hub centers relative to racer body center:
- LeftHub = `(0, -0.75, -1.62)` studs;
- RightHub = `(0, -0.75, +1.62)` studs.

Both legs use the **same XY stroke geometry**. They are duplicated only by Z translation; do not mirror/invert the stroke in XY. This makes one visible drawn solution mechanically identical on both sides.

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
    RightLeg (Model)
      LegRoot
        MotorAttachment
      HubJoint
      Segments
        Segment_01..NN
      Visual
```
This file owns the mechanical relation/coordinates; it does not define an alternate parent tree.
`HingeConstraint` connects `LeftHub/RightHub.MotorAttachment` (body-side) to that side `LegRoot.MotorAttachment`. All physical segments are welded to `LegRoot`. The body is not welded to `LegRoot`.

Hinge rotation axis is local/world `+Z` at neutral racer orientation on both sides. Initial launch motor direction is `AngularVelocity = -8.0 rad/s`; magnitude sweep is owned by `16`. Negative sign is canonical because with the local frame above it drives normal bottom contact toward `+X` travel. If an implementation API axis orientation causes the opposite sign, fix attachment axis orientation to this contract rather than creating per-side hidden signs.

Right leg starts `180°` phase after Left leg. Phase offset tuning stays in `16`.

## 6. Segment collider construction
For each consecutive cleaned point pair `A→B`:
- skip segment if mapped length `< 0.08 stud` after cleanup;
- create one simple rectangular physical Part;
- segment center = midpoint `(A+B)/2` in LegRoot local XY;
- long axis follows vector `B-A` in the XY plane;
- physical length = `|B-A| + 0.06 stud` overlap allowance;
- thickness/depth = `PhysicalLegSegmentThickness` from `16` on both short axes;
- segment is welded rigidly to LegRoot;
- no collision between segments in the same assembly;
- segment visual smoothing/round caps are presentation only and may use `VisualSegmentsPerLeg`.

There is **no automatic collision spoke from hub to the first stroke point**. A player may draw a disconnected-from-center arc; it still rotates rigidly around the hub because it is welded to LegRoot. This is intentional and is part of shape strategy.

Segments whose nearest geometry lies inside `InnerHubNoCollisionRadius` keep visual representation but set physical collision off. Outside that radius, leg colliders may collide with **Track only** (plus non-blocking Trigger query); they never collide with own body/legs or another racer. Global collision ownership = `28/65`.

## 7. Atomic rebuild
For accepted redraw:
1. server validates ShapeSpec;
2. construct new left/right assemblies off to the side/non-colliding or with collisions disabled;
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
All coordinates below are normalized DrawInputRect coordinates and must go through the same pipeline as human shapes. They are test/bot presets, never a classification shortcut for human movement.

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

## 11. UI pivot presentation
`59/68` must render a subtle non-interactive center hub marker inside DrawInputRect at normalized `(0,0)` so players can infer the physical pivot. It is presentation only, never draggable and never adds a point to the stroke.

## 12. Acceptance
PASS only if:
- normalized center maps to the exact physical hub pivot;
- the same submitted points generate equivalent left/right XY geometry;
- changing drawn size changes physical radius rather than being normalized away;
- offset shapes remain offset relative to the hub;
- no default wheel/StarterShape appears when no shape exists;
- ROUND/LONG_BAR/SMALL_ROUND/HOOK/ASYM presets produce repeatable distinct physical behavior in G0/G1;
- rebuild never double-collides old+new legs;
- ShapeSpec is not persisted across server/place boundaries.

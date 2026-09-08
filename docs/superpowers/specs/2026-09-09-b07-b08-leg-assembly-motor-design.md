# B07-B08 Leg Assembly + Motor Design

## Scope
Implement only implementation items B07 and B08 from `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`.

B07 creates exactly one legal physical leg assembly from normalized shape points around one canonical racer hub. B08 adds exactly one motorized hinge and a Studio-only flat-locomotion acceptance harness. B09 two-leg duplication/phase is explicitly out of scope.

## Owners
- gameplay behavior: `03_CORE_MECHANICS_SPEC.md`
- physics defaults: `16_BALANCE_TUNING.md`
- runtime/class ownership: `21_SYSTEM_CLASS_ARCHITECTURE.md`
- Studio instance tree/collision policy: `65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md`
- exact shape/pivot/collider mapping: `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`

## B07 geometry
`LegAssembly` consumes already-cleaned normalized `Vector2` points. Each point maps isotropically to leg-local XY with `LegCanvasHalfSpan = 3.15` studs. Each mapped point is radially clamped to `MaxLegExtentFromHub = 4.5` studs without recentering or resizing the stroke by its own bounds.

For every consecutive mapped point pair, if geometric length is at least `0.08` stud, create one rectangular physical `Part` under `Segments`. Its long axis follows `B-A`, its physical length is geometric length plus `0.06` stud overlap, and both short axes use `PhysicalLegSegmentThickness = 0.45` stud. Segments are welded rigidly to one transparent, non-collidable `LegRoot` centered on the selected hub. No hub-to-first-point spoke is fabricated.

The runtime subtree is exactly:

```text
Legs
  LeftLeg
    LegRoot
      MotorAttachment
    HubJoint
    Segments
      Segment_01..NN
    Visual
```

B07 uses `LeftHub` only. `RacerLeg` collides with `Track` but not `RacerBody` or `RacerLeg`. A segment whose nearest segment geometry lies inside the `0.65` stud inner-hub exclusion remains represented but has `CanCollide=false`.

## B08 motor
`HubJoint` is one `HingeConstraint` connecting `LeftHub.MotorAttachment` to `LeftLeg.LegRoot.MotorAttachment`. The canonical hinge axis is +Z on both attachments. The motor defaults are:
- `ActuatorType = Motor`
- `AngularVelocity = -8.0 rad/s`
- `MotorMaxTorque = 35000`
- `MotorMaxAcceleration = 120`

No script applies intentional +X propulsion. B08 movement evidence must come from physical contact of the rotating leg with a Track-group flat surface.

## Studio acceptance harness
In Studio only, after deterministic B03-B07 behavior checks, spawn a B08 test racer on the flat M0 lane, attach one visible LeftLeg built from canonical `ROUND_01`, enable its motor, and leave it alive long enough for the human to observe movement. The harness records initial X and prints periodic displacement/speed diagnostics. It must not create a RightLeg.

The harness is temporary M0 acceptance tooling, not production race orchestration. It is destroyed/recreated on each Play start by normal Studio restart semantics.

## Acceptance
B07 PASS evidence:
- exact runtime subtree exists;
- LegRoot is centered at LeftHub;
- mapped size/offset remain meaningful and bounded by 4.5 studs;
- collider count is bounded and each segment is welded to one LegRoot;
- no hidden center spoke;
- collision groups follow the canonical matrix.

B08 PASS evidence:
- exactly one HingeConstraint and one motor for the one leg;
- motor values match launch defaults;
- no +X force/velocity/teleport code exists in LegAssembly/harness;
- in Studio the one-leg racer produces observable forward displacement on the flat Track surface.

B09 remains untouched.
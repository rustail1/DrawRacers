# Decision Log — Core V3 body, spawn and rider correction

Date: **2026-09-15**
Status: **APPROVED / HUMAN PHYSICS PENDING**
Classification: **CONTRACT_CHANGE**

## Body upright

The existing Core V3 `LaneConstraint` remains the sole 2.5D owner. Its
`PlaneConstraint` locks world Z while leaving X/Y translation physical. Its
BodyCollider-only `AlignOrientation` uses rigid upright alignment so visible
body tilt is negligible. It does not attach to or restrict the SharedAxle;
the single HingeConstraint remains the axle's free relative rotation owner.

No AlignPosition, X/Y position constraint, forward force or velocity helper is
introduced.

## Flat harness spawn

The previous resting-contact start was superseded on 2026-09-16 after human
video showed that it did not match the reference staging/readability contract.
The current Core V3 flat harness no longer consumes the legacy R16 benchmark
`SpawnY`. It derives the held axle-center Y from the built flat Track top:

`spawnY = trackTopY + SuspendedAxleHeightAboveTrack`

`SuspendedAxleHeightAboveTrack = 5.15 studs`, derived from the current 4.5-stud
radial cap, 0.27-stud collider half-thickness, 0.08-stud clearance padding and
a deliberate 0.30-stud presentation gap. RacerRuntime anchors the fresh BodyCollider with zero
linear/angular velocity only while no shape has ever committed. A failed first
shape keeps the hold. Inside the first successful ACTIVE callback, Body and
AxleRoot are zeroed and released before pair collision and motor enable. There
is no persistent hover, AlignPosition, force, tween,
teleport loop or recovery trick.

## Rider presentation

The visible rider remains a client-local, presentation-only clone of the
player's loaded Character. It preserves the player's body appearance, body
colors, clothing, hair and accessories. The single explicit presentation
scale remains supported and is `1.0` for the current contract.

Procedural cowboy brim/crown/band geometry and the
`applyCowboyPresentation` path are removed. The live Player.Character never
becomes racer physics. Clone BaseParts remain massless/non-colliding and the
clone follows the existing body-local RiderAnchor.

## Acceptance

Static/unit evidence covers ownership and source contracts. Upright solver,
suspended-start release, first leg contact and rider visual fidelity remain
**HUMAN PHYSICS PENDING** until Roblox Studio validation.

## 2026-09-16 amendment — first build and avatar fidelity

The bounded redraw hop applies only when an accepted ACTIVE pair is being
replaced. The first EMPTY -> PREVIEW build does not inject a hop into the
BodyCollider; existing whole-pair clearance remains unchanged and may still
move the assembly only when geometry overlap requires it.

WAIT_CLEAR does not activate the physical pair merely because the ghost probe
has become clear. The BodyCollider must also have reached the clearance target
and reduced its vertical speed to the configured settle tolerance. This keeps
the motor and physical contacts from starting while the assembly is still
moving rapidly under clearance lift.

The presentation clone retains an inert Humanoid to preserve the loaded
avatar's visual deformation and appearance. Character scripts/tools are
removed, movement/autorotation is disabled, and the clone remains anchored,
massless and non-colliding outside racer physics. The source Player.Character
is hidden locally while the clone is active and its previous local
transparency is restored during teardown.

## 2026-09-16 amendment — suspended first start

Human reference comparison supersedes the resting-contact EMPTY spawn. The
fresh BodyCollider is held anchored at an axle height of 5.15 studs above the
flat Track, with zero linear/angular velocity. First-shape PREVIEW/WAIT_CLEAR
may validate geometry but may not create a clearance force or move the held
Body. An unsafe first pair fails closed and leaves the hold intact. The first
pair that commits ACTIVE releases the zeroed Body/AxleRoot once before physical activation; the hold
never returns during redraw or FallRecovery.

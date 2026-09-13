# Draw Racers Core Module Rewrite Design

**Status:** APPROVED DESIGN DIRECTION — SPEC FOR REVIEW

**Baseline at spec creation:** `b327a2c9f69b6c9ca97c41a9aec6348660ebc9a1`

## Goal

Stop accumulating point fixes inside legacy core modules. Replace each core module as a coherent unit while preserving only the external contracts that are still correct.

The target is a small, explicit pipeline where each module has one owner responsibility:

`DrawingController -> CanonicalLegShape -> LegShapeService -> RacerRuntime -> LegPairAssembly -> LegAssembly`

Presentation systems such as camera, rider and cosmetics remain outside the mechanical core until the mechanical rewrite is stable.

## Rewrite policy

For a module selected for rewrite:

- read the current implementation and tests first;
- identify the public API and actual consumers;
- classify each existing behavior as KEEP, REPLACE or DELETE;
- write behavior-level RED tests for the desired contract;
- replace the module implementation coherently instead of layering more compatibility branches;
- preserve external APIs only when they still express the desired architecture;
- update stale tests that encode obsolete implementation details;
- delete dead transitional paths once the replacement is proven;
- do not keep parallel old/new production implementations.

Tests protect player-visible and architectural behavior, not accidental implementation details.

## Mechanical core boundaries

### 1. `CanonicalLegShape`

Pure deterministic shared math. No Instances, Workspace, Players, remotes or UI.

Input:
- raw semantic stroke points;
- canonical shape configuration.

Owns the complete shape transformation:

`raw -> clamp -> dedupe -> simplify -> resample -> first-point anchor -> world mapping -> segment plan`

Output is one immutable canonical shape result containing at minimum:
- normalized points;
- mapped world-local points;
- bounds;
- extent;
- segment plan;
- debug counts.

The client preview and server validation must use this same module. The server still recomputes from raw input and remains authoritative.

No second cleanup/mapping pipeline may exist in `DrawingController` or `LegShapeService`.

### 2. `LegShapeService`

Thin server authority layer.

Responsibilities:
- validate network/request envelope;
- enforce sequence/rate/payload limits;
- call `CanonicalLegShape` from raw semantic points;
- reject invalid canonical results;
- assign authoritative shape version;
- call `RacerRuntime:ApplyValidatedShape(shapeSpec, motorEnabled)`;
- return authoritative accepted points/status to the client.

It does not build Parts and does not duplicate canonical geometry math.

### 3. `LegAssembly`

Owns one physical/visual leg side only.

Responsibilities:
- consume an already canonical `segmentPlan`;
- create/update physical colliders for one side;
- create/update matching presentation geometry;
- apply partial hub-to-tip reshape from canonical arc-length progress;
- expose bounded lifecycle methods such as geometry replace/progress/destroy.

It does not know about:
- player/network;
- recovery destination;
- race rules;
- drawing UI;
- camera;
- opposite-side motor policy.

The visible centerline must be derived from the same canonical geometry as the physical leg. Visual thickness may differ; geometry may not.

### 4. `LegPairAssembly`

Owns one persistent mechanical pair for one racer.

Long-lived state:
- one `AxleRoot`;
- one `HingeConstraint` motor;
- one left `LegAssembly`;
- one right `LegAssembly`.

Responsibilities:
- create and retain the axle/motor for racer lifetime;
- maintain current axle phase and motor state;
- keep structural left/right phase relation at the current canonical contract (`180°` unless separately redesigned);
- replace only leg geometry on redraw;
- drive both sides with the same reshape progress;
- own temporary reshape support if evidence proves it is needed;
- expose recovery-safe completion of a transient reshape.

Normal redraw must not create a replacement axle/pair.

No retiring-pair handoff in normal production redraw.

### 5. `RacerRuntime`

Owns racer lifecycle and orchestration, not leg internals.

Desired public responsibilities:
- create/destroy racer body and persistent pair;
- `ApplyShape(...)` for internal/test callers;
- `ApplyValidatedShape(shapeSpec, motorEnabled)` for authority path;
- `PrepareForRecovery()`;
- getters required by existing services/harnesses;
- own shape version/current authoritative ShapeSpec/debug attributes;
- start/cancel the short reshape timeline.

`RacerRuntime` does not create individual leg segments and does not duplicate geometry calculations.

Recovery preparation may complete/cancel a transient reshape, but the caller owns the actual respawn destination/teleport policy.

## Drawing / presentation boundary

`DrawingController` remains client presentation/input, not a geometry authority.

It may:
- collect raw pointer/touch samples;
- convert screen coordinates to semantic coordinates;
- call shared `CanonicalLegShape` locally for predictive preview;
- render canonical mapped geometry at a fixed isotropic canvas scale;
- submit raw semantic samples to the server;
- replace prediction with server-authoritative accepted shape.

It may not maintain an independent simplify/resample/map implementation.

Main gameplay canvas must not auto-fit each accepted shape. A shorter drawing must remain a shorter physical leg.

## Stable contracts to preserve unless investigation proves them wrong

- repository and branch policy: `main` only;
- existing Rojo project/root layout;
- `RemoteNames` registry and current raw-stroke network direction;
- server authority over accepted ShapeSpec/version;
- one racer `BodyCollider`;
- one shared axle/motor per racer;
- two rigid side legs using the same canonical XY geometry;
- structural right-side phase offset currently `180°`;
- ordinary Studio mode `G0` remains fast and does not run the long evidence suite automatically;
- no body teleport/anchor as a redraw mechanism;
- human Studio evidence remains required for physics/feel acceptance.

## Contracts allowed to change during rewrite

Internal method names, private fields, construction order and helper modules may change if consumers are migrated atomically.

Obsolete contracts may be removed when they only encode old architecture, including assumptions such as:
- redraw creates a new `LegPairAssembly`;
- redraw creates a new axle/joint;
- retiring old/new pairs are required for normal redraw;
- client and server own separate shape-cleanup pipelines;
- tests assert instance replacement instead of stable mechanical identity.

Any external API change must be identified before implementation and all consumers migrated in the same module-rewrite stage.

## Rewrite order

### MR-01 — Canonical shape boundary
Rewrite `CanonicalLegShape`/shared shape owner and simplify `LegShapeService` around it.

Exit criteria:
- one canonical math pipeline;
- deterministic parity tests cover straight/L/V/hook/asymmetric/large/small shapes;
- client/server/world inputs derive from identical mapped points and segment plan;
- no independent server cleanup pipeline remains.

### MR-02 — `LegAssembly`
Rewrite one-side geometry assembly around canonical segment plan and explicit reshape progress.

Exit criteria:
- exact hub-to-tip prefix geometry;
- no future full collider hidden under visual state;
- visual and physical centerlines share one source;
- physical/visual thickness remain separately configured.

### MR-03 — `LegPairAssembly`
Rewrite pair ownership around permanent axle + motor + two side assemblies.

Exit criteria:
- same pair/axle/joint identity across redraw;
- no normal redraw retiring pair;
- phase/motor continuity preserved;
- reshape/recovery support has one owner.

### MR-04 — `RacerRuntime`
Rewrite orchestration against the new stable pair API.

Exit criteria:
- runtime owns lifecycle/version/reshape timeline only;
- redraw never recreates the mechanical pair;
- recovery preparation is runtime-owned and destination-independent;
- no duplicated leg-construction logic.

### MR-05 — `DrawingController`
Rewrite the drawing owner around raw input + shared canonical preview + authoritative result rendering.

Exit criteria:
- `Draw = Leg` centerline parity;
- fixed gameplay scale/no per-shape auto-fit;
- preview does not jump geometrically after server ACCEPT;
- UI renderer can be visually smooth without inventing a different curve.

### MR-06 — Mechanical integration cleanup
Remove dead compatibility code and stale tests, then run mechanical-core audit.

Exit criteria:
- no obsolete replacement-pair assumptions remain;
- no duplicate geometry pipelines remain;
- no dead transitional redraw paths remain;
- static contracts and Rojo build are green;
- G0 is ready for human physics traversal test.

Only after MR-01..MR-06 and a human mechanical pass should camera, rider and cosmetic presentation receive another redesign/tuning pass.

## Testing strategy

Every rewrite stage follows TDD at the module boundary.

Required automated properties include:
- deterministic canonical shape output;
- client/server canonical parity;
- exact first-point hub origin;
- mapped-point/segment-plan parity;
- stable pair/axle/joint identity across repeated redraws;
- no body CFrame or velocity reset on redraw;
- bounded hub-to-tip progress;
- recovery completes transient geometry before respawn policy runs;
- no leaked old leg models/parts;
- traversal evidence cannot count falling below recovery or solver instability as success.

Static tests that merely search for old implementation text must be rewritten if the implementation is intentionally replaced. Prefer behavior/invariant checks where feasible.

## Human gates

Automated green is not enough for:
- actual Roblox contact/penetration behavior;
- perceived leg scale;
- obstacle usefulness;
- redraw feel;
- camera feel;
- rider pose.

After mechanical rewrite, G0 human run must verify at minimum:
- draw shape matches world leg;
- repeated redraw does not visibly reset axle/motion;
- no support-loss fall during rapid redraw;
- long leg grows into contact rather than materializing through floor;
- Flat/Steps/Wall/Gap/Tunnel remain meaningfully traversable with different shapes;
- real fall recovers cleanly with the authoritative current shape.

## Non-goals for this rewrite

Do not use this work to redesign:
- race rules;
- economy/progression/monetization;
- level generator;
- matchmaking;
- player persistence;
- camera framing;
- rider art/pose;
- cosmetic catalog/content.

Those remain separate modules and should not be used to hide mechanical-core defects.

## Definition of done

The rewrite is complete when the core can be understood as six small ownership boundaries with no parallel legacy path:

`DrawingController -> CanonicalLegShape -> LegShapeService -> RacerRuntime -> LegPairAssembly -> LegAssembly`

A redraw changes canonical geometry while keeping the racer body, pair, axle, joint, motor continuity and authoritative shape lifecycle intact. The canvas, accepted server shape and physical world leg derive from the same canonical geometry. Automated verification/build is green, and the mechanical human G0 pass is explicitly completed rather than inferred.

# 65 — STUDIO DATAMODEL / INSTANCE / PROPERTY SPEC
Статус: **EXACT AUTHORING & RUNTIME INSTANCE CONTRACT v1.4.0 / MR-06 PERSISTENT SHARED AXLE**.

Цель: exact Studio/runtime instance contract. Архитектура = `21`; Core V3 authority = `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`; numeric physics = `16`; geometry = `73`.

Current M0 mechanical contract is Core V3: one `SharedAxle` model, one `AxleRoot`, one `DriveJoint` HingeConstraint and two depth-separated `LegGeometry` owners at fixed 180°. Live physics remains **HUMAN STUDIO PENDING**.

## 1. Root tree — exact launch names
```text
ReplicatedStorage
  Shared (Folder)
  Remotes (Folder)
  Assets (Folder)
ServerStorage
  RacerTemplates (Folder)
  TrackPieces (Folder)
ServerScriptService
  Bootstrap.server.lua (Script)
  Services (Folder)
  Runtime (Folder)
  Tests (Folder)
StarterPlayer
  StarterPlayerScripts
    Bootstrap.client.lua (LocalScript)
    Controllers (Folder)
StarterGui
  RaceHUD (ScreenGui)
  DrawHUD (ScreenGui)
  ResultsHUD (ScreenGui)
  GarageHUD (ScreenGui)
  StoreHUD (ScreenGui)
  SettingsHUD (ScreenGui)
Workspace
  Runtime (Folder)
    Tracks (Folder)
    Racers (Folder)
    RacePresentation (Folder)
```
No alternative duplicate roots.

## 2. Collision groups — exact matrix
Groups: `Default`, `Track`, `RacerBody`, `RacerLeg`, `Decoration`, `Trigger`.

| A \ B | Track | RacerBody | RacerLeg | Decoration | Trigger |
|---|---|---|---|---|---|
| Track | — | collide | collide | no | no |
| RacerBody | collide | **no** | **no** | no | overlap/query |
| RacerLeg | collide | **no** | **no** | no | overlap/query |
| Decoration | no | no | no | no | no |
| Trigger | no | query/touch | query/touch | no | no |

Canonical invariant: Body↔own Leg, Leg↔own Leg, Body↔Body, Leg↔Leg and every cross-racer Body/Leg pair are non-colliding. Only Track supplies locomotion collision. Use PhysicsService collision groups as the default guarantee; per-instance no-collision constraints may be added defensively but may not create a different policy.

## 3. `RacerTemplate` exact model
`ServerStorage/RacerTemplates/RacerTemplate` (Model):
```text
RacerTemplate
  BodyCollider (Part) [PrimaryPart]
  VisualRoot (Folder or Model)
  RuntimeAttachments (Folder)
    LaneAlignAttachment (Attachment)
    OrientationAttachment (Attachment)
```

Required BodyCollider launch properties:
- Size = `3,3,3` studs (`16` fixed baseline);
- Anchored=true only during the fresh `EMPTY` suspended hold, then false once
  inside the first `ACTIVE` callback before pair collision and motor enable;
- CanCollide=true;
- CanTouch=true;
- CanQuery=true;
- Transparency=1 for collider; visible body comes from CosmeticService/presentation;
- CollisionGroup=`RacerBody`;
- CustomPhysicalProperties = density/friction/elasticity from `16`.

Core V3 body/axle mount:
- current runtime creates no compatibility hub Parts;
- `BodyCollider.LegDriveMount` is created by Core V3 SharedAxle;
- `BodyCollider.LegDriveMount` local Position = `(0, 0, 0)`, so the axle X/Y is the body center;
- no ShapeSpec or redraw path changes the body/axle mount position;
- side mount Z = `±(body.Size.Z * 0.5 + SideOutset)`, current `SideOutset = 0.45`;
- RightMount is structurally rotated 180° relative to LeftMount.

No humanoid/character controller is used for racer locomotion.

## 4. Runtime Core V3 leg structure
```text
Racer_<RaceId>_<Slot>
  BodyCollider
    LegDriveMount (Attachment)
  Legs
    SharedAxle (Model)
      AxleRoot (Part)
        AxleAttachment (Attachment)
      LeftMount (Part)
        LeftLeg (Model)
          Preview (Folder, during PREVIEW)
          Physical (Folder, after build)
      RightMount (Part)
        RightLeg (Model)
          Preview (Folder, during PREVIEW)
          Physical (Folder, after build)
      DriveJoint (HingeConstraint)
```

Core V3 properties:
- `DriveJoint` is the only leg HingeConstraint;
- `DriveJoint.Enabled = true` structurally; motor off = `ActuatorType.None`;
- `AxleRoot` Size = `1.5,1.5,1.5`, Anchored=false, noncolliding, Massless=false, `RacerLeg`, density `0.50`;
- `LegDriveMount` local Position = `(0, 0, 0)` with no vertical-offset tuning/workaround;
- LeftMount Z = `-(body.Size.Z/2 + 0.45)`;
- RightMount Z = `+(body.Size.Z/2 + 0.45)` and local phase `180°`;
- mount Parts are invisible/massless/noncolliding and welded to AxleRoot;
- visual preview Parts are nonphysical;
- physical segment Parts are massless, `RacerLeg`, friction `1.0`, collision enabled only when the segmentPlan entry has `canCollide=true`;
- current BodyCollider Core V3 friction = `0.0` so normal traction comes from the legs.

Redraw from ACTIVE creates both preview and physical ghost sides together under the persistent SharedAxle owner, calculates initial whole-pair clearance, applies one bounded +Y BodyCollider impulse, then uses PREVIEW/WAIT_CLEAR while every ghost Part follows the axle. The first EMPTY -> PREVIEW build receives no redraw hop or clearance force while BodyCollider is held; an unsafe first pair fails closed and retains the hold. WAIT_CLEAR may activate the physical pair only after the whole ghost is clear, the BodyCollider has reached its clearance target, and vertical speed has settled. Physical collision stays off until both sides enable atomically. Failed rebuild returns controller to EMPTY.

Before the first accepted pair, `RacerRuntime` holds BodyCollider anchored and
motionless at the Core V3 suspended axle height. This is an `EMPTY` staging
property, not an Instance mover or hover force. A rejected first pair keeps the
hold; the first successful `ACTIVE` commit zeroes Body velocity, unanchors it
once, and thereafter gravity/leg contact own Y while leg contact owns drive.

Approved next runtime addition: dedicated Core V3 lane-plane/upright constraint owner; exact instance names are not frozen until that implementation task is approved/landed.

## 5. Runtime racer model
Each spawned racer is:
```text
Workspace.Runtime.Racers/Racer_<RaceId>_<Slot>
  BodyCollider
    LegDriveMount (after Core V3 axle exists)
  VisualRoot
  RuntimeAttachments
  Legs
    AxleRoot (after first accepted shape)
    LeftLeg
    RightLeg
  Presentation
  Debug (DEV/STAGING only)
```

`RacerRuntime` also owns one non-Instance `CoreV3/FallRecovery` lifecycle object. It watches BodyCollider Y only, creates no mover/force/constraint, preserves the same racer tree and may call whole-model `PivotTo` solely for explicit out-of-bounds respawn. `CoreV3RecoveryCount` is diagnostic evidence, not gameplay authority.
Attributes required on racer Model:
- `RaceId:string`
- `SlotIndex:number` 1..8
- `LaneIndex:number` 1..8
- `IsBot:boolean`
- `ShapeVersion:number`
- `TrackId:string`
- `Finished:boolean`
- `OwnerUserId:number` for human racers once the current spawn/mapping path authors it; server-authored only.

`OwnerUserId` rules:
- human racer: exact Roblox `Player.UserId` authored by server spawn/mapping code;
- bot racer: no human `OwnerUserId` is assigned; bots never impersonate a Player;
- clients may use the attribute only to resolve presentation identity such as rider/name visuals;
- the attribute never authorizes stroke, reward, finish, physics or ownership state and does not replace future `RacerService`'s internal Player→RacerRuntime mapping.

No authoritative Coins/MP/reward attributes are stored on Workspace instances.

### Client rider presentation
`RiderPresentationController` is the current nonphysical rider presentation owner. E03 remains the later multiplayer/readability extension and acceptance task for this same owner. The controller may create client-local visual models under the existing presentation root:

```text
Workspace.Runtime.RacePresentation
  Rider_<UserId> (Model)
    <presentation clone of the player's loaded avatar>

Workspace.Runtime.Racers.Racer_<RaceId>_<Slot>.BodyCollider
  RiderAnchor (Attachment, client-local; exactly one for a visible human rider)
```

Contract:
- rider model is presentation-only and is not parented into Core V3 leg physics;
- its visual transform follows `BodyCollider.RiderAnchor.WorldCFrame` but does not become physics authority;
- `RiderAnchor` is body-local, client-local, unique per visible human racer and has no mass/force behavior;
- any rider BasePart is `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true`;
- one Part per disconnected visual assembly is anchored so no loose avatar/accessory assembly falls under gravity;
- rider ownership creates no mover or physical connection to BodyCollider;
- rider geometry never changes the `RacerBody`/`RacerLeg` collision matrix or body mass properties;
- the active-race camera still targets racer position, not rider head/accessories;
- one explicit presentation scale remains supported and is currently `1.0`;
- preserve the loaded player's body appearance, body colors, clothing, hair and accessories;
- retain an inert cloned Humanoid so avatar deformation/appearance remains intact; remove its scripts, disable autorotation and platform movement, and keep it outside racer physics;
- hide the source Player.Character locally only while its presentation clone is active, then restore its prior local transparency during teardown;
- do not add procedural hats or other invented cosmetic geometry to the avatar clone;
- human-video correction: mount by a deterministic seat reference (`LowerTorso`, then `Torso`, then `HumanoidRootPart` fallback) and place that seat reference just above the cube top using the seat Part half-height; do **not** place the avatar by a fixed HumanoidRootPart `+0.30` Y offset;
- rider teardown occurs with racer/player presentation lifecycle; completed heats must not leak rider models/connections;
- bots never clone or impersonate a human Player appearance;
- CI/source checks do not establish rider pose/readability PASS; that remains **HUMAN STUDIO PENDING**.

## 6. TrackPiece template exact structure
Per `42/60` every `ServerStorage.TrackPieces/Piece_<Id>` is:
```text
Piece_<Id> (Model) [PrimaryPart = AuthoringRoot]
  AuthoringRoot (Part) invisible, anchored
  Geometry (Folder)
    Collision_* (BasePart...) anchored, Track group
    Visual_* (BasePart/MeshPart...) anchored, Decoration group if non-collision
  Start (Attachment or invisible Part+Attachment)
  End (Attachment or invisible Part+Attachment)
  Recovery (Folder)
    RecoveryFloor (optional Part)
    Respawn (Attachment)
  Triggers (Folder)
    Checkpoint (Part) [Trigger]
  AuthoringMeta (Folder)
```
Model attributes:
- `PieceId:string`
- `RequirementTag:string`
- `DifficultyTier:number`
- `HasCheckpoint:boolean`
- `Moving:boolean`

Collision geometry must be authored from `60`; art shell cannot alter it.

## 7. Built track runtime exact structure
```text
Workspace.Runtime.Tracks/Track_<RaceId>
  SharedPresentation
  Lane_01..Lane_08
    StartSpawn (Attachment)
    Pieces
      001_<PieceId>...
    Checkpoints
      CP_001...
    FinishTrigger
    RecoveryAnchors
```
Lane center Z positions use `16` spacing and are symmetric around world Z=0. All lanes consume one resolved `TrackDefinition`; geometry parameters are identical except Z offset.

## 8. Trigger properties
Checkpoint/Finish triggers:
- Anchored=true;
- CanCollide=false;
- CanTouch/query enabled as implementation requires;
- Transparency=1;
- CollisionGroup=`Trigger`;
- server validation never trusts touch alone; ordered progress/lane bounds are checked by `ProgressValidationService` once that later production owner is active.

## 9. Decoration rules
- `CanCollide=false`, `CollisionGroup=Decoration` unless a Part is explicitly Collision_*.
- no scripts inside imported decoration assets;
- shadows/particles obey `33/57/62`;
- moving visual-only props cannot look like active collision hazards.

## 10. CollectionService tags
Canonical tags allowed at launch:
- `TrackCollision`
- `TrackDecoration`
- `CheckpointTrigger`
- `FinishTrigger`
- `RecoverySurface`
- `MovingObstacle`
- `CameraReadAnchor`

Do not create per-level bespoke tags for behavior already expressible by TrackPiece config.

## 11. Workspace lifecycle
`Workspace.Runtime.Tracks` and `Racers` are empty at server boot in production flow. RaceService/TrackService later create runtime content and destroy it after heat/intermission cleanup. Current M0 harnesses also clean their temporary racers/trials. No completed heat/trial may leave live Constraints/Connections/Parts behind. Client-local `RacePresentation` rider visuals follow the same cleanup expectation and never become server gameplay state.

For each racer with an accepted shape, runtime cleanup expectation is exact: one persistent active `AxleRoot`, one active `AxleJoint`, two persistent side leg models, and no retiring/staging mechanical tree after a successful redraw.

## 12. Acceptance
Repository/instance-contract PASS requires:
- a fresh synced project creates the canonical roots;
- current racer geometry uses one Core V3 `SharedAxle`, one `AxleRoot`, one `DriveJoint`, one motor owner and two side `LegGeometry` models;
- Left/Right use the same canonical XY shape and remain structurally **180° opposed**, with no per-side actuator/phase chase;
- collision isolation remains canonical and visual leg/rider geometry remains nonphysical;
- redraw keeps the same pair/axle/joint/side owners and preserves BodyCollider motion state;
- runtime teardown returns object counts near baseline;
- no gameplay script depends on manually hidden unversioned Studio objects outside this contract;
- rider identity/fallback remains bounded and bots do not impersonate human avatars.

Live solver feel, redraw feel, camera feel, rider pose/readability and full Studio behavior remain **HUMAN STUDIO PENDING** until actual Studio evidence is supplied.

Exact freehand coordinate/pivot/collider mapping owner: `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`.

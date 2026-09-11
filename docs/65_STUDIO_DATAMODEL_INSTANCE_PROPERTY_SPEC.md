# 65 — STUDIO DATAMODEL / INSTANCE / PROPERTY SPEC
Статус: **EXACT AUTHORING & RUNTIME INSTANCE CONTRACT v1.3.5 / R17 OVERRIDE**.

Цель: убрать вопрос «какие именно Instances/имена/атрибуты/группы/свойства создавать в Studio». Архитектурные владельцы = `21`; numeric physics = `16`; TrackPiece geometry = `60`; UI hierarchy = `68`.

Camera/rider presentation is authorized early by the 2026-09-10/11 Product Owner Decision Logs. `RaceCameraController` and `RiderPresentationController` are current provisional M0/R17 presentation owners; D09/E03 later extend and accept them for multiplayer/readability rather than introducing duplicate owners. The R17 mechanical override makes `LegPairAssembly` the current runtime owner of one shared axle, one `AxleJoint`, one motor and the structural 180 relation between the rigid left/right side assemblies. Human physics/camera/rider acceptance remains **HUMAN STUDIO PENDING**.

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
  LeftHub (Part)
    MotorAttachment (Attachment) [marker/compatibility]
  RightHub (Part)
    MotorAttachment (Attachment) [marker/compatibility]
  RuntimeAttachments (Folder)
    LaneAlignAttachment (Attachment)
    OrientationAttachment (Attachment)
```
Required BodyCollider launch properties:
- Size = `3,3,3` studs (`16` fixed baseline);
- Anchored=false;
- CanCollide=true;
- CanTouch=true;
- CanQuery=true;
- Transparency=1 for collider; visible body comes from CosmeticService/presentation;
- CollisionGroup=`RacerBody`;
- CustomPhysicalProperties = density/friction/elasticity from `16`.

Hub Parts:
- Anchored=false;
- CanCollide=false;
- CanTouch=false unless debug requires;
- Transparency=1;
- hub offsets are owned numerically by `PhysicsConfig.LegGeometry` / `16` and mapped mechanically by `73`:
  - `HubOffsetX = 0.0`;
  - `HubOffsetY = -0.35`;
  - `HubOffsetZAbs = 1.62`;
  - LeftHub = `(HubOffsetX, HubOffsetY, -HubOffsetZAbs)` relative to BodyCollider center;
  - RightHub = `(HubOffsetX, HubOffsetY, +HubOffsetZAbs)` relative to BodyCollider center;
- CollisionGroup=`RacerBody`.

Under R17 these hub Parts remain body-welded stable markers/compatibility anchors. Their `MotorAttachment` children are not actuator owners. `LegPairAssembly` ensures the actual shared body-side `AxleMotorAttachment` on `BodyCollider` when an accepted pair exists.

No humanoid/character controller is used for racer locomotion.

## 4. Runtime leg assembly exact structure
Created under `Workspace.Runtime.Racers/<RacerRuntimeId>` / `Legs`. The shared body-side attachment lives on `BodyCollider`:
```text
Racer_<RaceId>_<Slot>
  BodyCollider
    AxleMotorAttachment (Attachment)
  LeftHub
    MotorAttachment (Attachment) [marker/compatibility]
  RightHub
    MotorAttachment (Attachment) [marker/compatibility]
  Legs
    AxleRoot (Part)
      MotorAttachment (Attachment)
      AxleJoint (HingeConstraint)
    LeftLeg (Model)
      LegRoot (Part)
        AxleWeld (WeldConstraint)
      Segments (Folder)
        Segment_01..NN (Part)
      Visual (Folder)
        VisualSegment_01..NN (Part)
        VisualJoint_01..NN (Part)
    RightLeg (Model)
      LegRoot (Part)
        AxleWeld (WeldConstraint)
      Segments (Folder)
        Segment_01..NN (Part)
      Visual (Folder)
        VisualSegment_01..NN (Part)
        VisualJoint_01..NN (Part)
```

`BodyCollider.AxleMotorAttachment`:
- created/ensured by `LegPairAssembly`;
- Position = `(HubOffsetX, HubOffsetY, 0)`;
- Axis=`+Z`, SecondaryAxis=`+Y` at neutral body orientation;
- body-side attachment for the single shared hinge.

`AxleRoot`:
- created by `LegPairAssembly`;
- Size = `0.2,0.2,0.2`;
- centered at body-local `(HubOffsetX, HubOffsetY,0)` and rotated by the one current axle phase;
- Anchored=false;
- CanCollide=false, CanTouch=false, CanQuery=false;
- Transparency=1, Massless=true;
- CollisionGroup=`RacerLeg`.

`AxleJoint`:
- the **only** HingeConstraint/actuator in the leg pair;
- `Attachment0 = BodyCollider.AxleMotorAttachment`;
- `Attachment1 = AxleRoot.MotorAttachment`;
- `ActuatorType=Motor`;
- angular speed/torque/acceleration come from `PhysicsConfig.Motor`;
- one motor rotates both rigid side assemblies around canonical +Z.

Side `LegRoot` Parts:
- are rigid side-geometry roots, not hinge/motor owners;
- use `LegSocketZAbs = 1.5` from `PhysicsConfig.LegGeometry` as the side mount offset;
- Left socket Z = `-1.5`, structural phase `0`;
- Right socket Z = `+1.5`, phase `RightPhaseOffsetDegrees = 180`;
- therefore Left/Right maintain the **structural 180** relation without a runtime phase-chasing loop;
- each `LegRoot` is welded to `AxleRoot` by `AxleWeld`;
- Anchored=false, CanCollide=false, CanTouch=false, CanQuery=false, Transparency=1, Massless=true;
- CollisionGroup=`RacerLeg`.

Segment Parts:
- Anchored=false;
- CollisionGroup=`RacerLeg`;
- thickness/default count/physical props = `16`;
- rigidly welded to that side `LegRoot`; exact local segment centers/orientation/length are `73`;
- no script per segment;
- visual ribbon/line has no collision.

Visual Parts:
- `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true`;
- presentation only; cannot affect solver/mass/locomotion.

There is no second side actuator and no Heartbeat phase-correction owner. Rebuild swaps the complete `LegPairAssembly` atomically per `03/24/73` and preserves one axle phase.

## 5. Runtime racer model
Each spawned racer is:
```text
Workspace.Runtime.Racers/Racer_<RaceId>_<Slot>
  BodyCollider
    AxleMotorAttachment (when an accepted LegPairAssembly exists)
  VisualRoot
  LeftHub
  RightHub
  Legs
    AxleRoot (while a shape is accepted)
    LeftLeg
    RightLeg
  Presentation
  Debug (DEV/STAGING only)
```
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

### R17 client rider presentation
The Product Owner early-presentation override authorizes `RiderPresentationController` during M0/R17. E03 remains the later multiplayer/readability extension and acceptance task for this same owner. The controller may create client-local visual models under the existing presentation root:

```text
Workspace.Runtime.RacePresentation
  Rider_<UserId> (Model)
    <standardized normalized avatar visual rig>
```

Contract:
- rider model is presentation-only and is not parented into `BodyCollider`, `LegPairAssembly` or `LegAssembly` physics;
- its visual transform follows the corresponding human racer body-position observation but does not become physics authority;
- any rider BasePart is `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true`;
- rider geometry never changes the `RacerBody`/`RacerLeg` collision matrix or body mass properties;
- the active-race camera still targets racer position, not rider head/accessories;
- normalized scale/readability envelope and oversized appearance fallback are owned by `62` and the current R17 presentation decision;
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

For each accepted shape, runtime cleanup expectation is exact: one active `AxleRoot`, one active `AxleJoint`, two active side leg models, and no `AxleRoot_Retiring` / `LeftLeg_Retiring` / `RightLeg_Retiring` after a successful transaction.

## 12. Acceptance
Repository/instance-contract PASS requires:
- a fresh synced project creates the canonical roots;
- current racer geometry uses one `LegPairAssembly`, one `AxleRoot`, one `AxleJoint`, **one motor**, two rigid side `LegAssembly` models and `LegSocketZAbs = 1.5`;
- Right remains at the **structural 180** relation to Left with no per-side actuator/phase chase;
- collision isolation remains canonical and visual leg/rider geometry remains nonphysical;
- atomic redraw leaves exactly one active pair and preserves BodyCollider motion state;
- runtime teardown returns object counts near baseline;
- no gameplay script depends on manually hidden unversioned Studio objects outside this contract;
- rider identity/fallback remains bounded and bots do not impersonate human avatars.

Live solver feel, camera feel, rider pose/readability and full Studio behavior remain **HUMAN STUDIO PENDING** until actual Studio evidence is supplied.

Exact freehand coordinate/pivot/collider mapping owner: `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`.
# 65 — STUDIO DATAMODEL / INSTANCE / PROPERTY SPEC
Статус: **EXACT AUTHORING & RUNTIME INSTANCE CONTRACT v1.3.4**.

Цель: убрать вопрос «какие именно Instances/имена/атрибуты/группы/свойства создавать в Studio». Архитектурные владельцы = `21`; numeric physics = `16`; TrackPiece geometry = `60`; UI hierarchy = `68`.

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
    MotorAttachment (Attachment)
  RightHub (Part)
    MotorAttachment (Attachment)
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
- Transparency=1 for collider; visible body comes from CosmeticService;
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
  - LeftHub = `(HubOffsetX, HubOffsetY, -HubOffsetZAbs)`;
  - RightHub = `(HubOffsetX, HubOffsetY, +HubOffsetZAbs)` relative to BodyCollider center;
- CollisionGroup=`RacerBody`.

No humanoid/character controller is used for racer locomotion.

## 4. Runtime leg assembly exact structure
Created under `Workspace.Runtime.Racers/<RacerRuntimeId>/Legs`:
```text
Legs
  LeftLeg (Model)
    LegRoot (Part) [non-collidable rotating assembly root]
      MotorAttachment (Attachment)
    HubJoint (HingeConstraint)
    Segments (Folder)
      Segment_01..NN (Part)
    Visual (Folder)
  RightLeg (Model)
    LegRoot (Part) [non-collidable rotating assembly root]
      MotorAttachment (Attachment)
    HubJoint (HingeConstraint)
    Segments (Folder)
      Segment_01..NN (Part)
    Visual (Folder)
```
LegRoot Parts:
- centered exactly at corresponding Hub center from `73`;
- Anchored=false, CanCollide=false, CanTouch=false, Transparency=1;
- Hinge motor rotates LegRoot around canonical +Z axis.

Segment Parts:
- Anchored=false;
- CollisionGroup=`RacerLeg`;
- thickness/default count/physical props = `16`;
- rigidly welded to that side LegRoot; exact local segment centers/orientation/length are `73`;
- no script per segment;
- visual ribbon/line has no collision.

`HubJoint` connects body-side Hub.MotorAttachment to LegRoot.MotorAttachment and uses axis/sign semantics from `73` with magnitude/torque values from `16`. Left/right phase begins at documented phase offset. Rebuild is atomic per `03/28/73`.

## 5. Runtime racer model
Each spawned racer is:
```text
Workspace.Runtime.Racers/Racer_<RaceId>_<Slot>
  BodyCollider
  VisualRoot
  LeftHub
  RightHub
  Legs
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

No authoritative Coins/MP/reward attributes are stored on Workspace instances.

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
- server validation never trusts touch alone; ordered progress/lane bounds are checked by `ProgressValidationService`.

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
`Workspace.Runtime.Tracks` and `Racers` are empty at server boot. RaceService/TrackService creates runtime content and destroys it after heat/intermission cleanup. No completed heat leaves live Constraints/Connections/Parts behind; 30-heat soak in `57` verifies this.

## 12. Acceptance
PASS when a fresh synced project creates exactly these roots, TrackPiece validator recognizes all 24 pieces, 8 racers use isolated collision, runtime teardown returns object counts near baseline, and no gameplay script depends on manually hidden unversioned Studio objects outside this contract.


Exact freehand coordinate/pivot/collider mapping owner: `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`.

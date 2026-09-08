# 21 — SYSTEM & CLASS ARCHITECTURE

Статус: **IMPLEMENTATION CONTRACT v1.3.4**  
Цель: заранее определить владельцев состояния, границы модулей и зависимости, чтобы Codex не создавал дублирующую архитектуру.

> В Luau не нужно превращать всё в OOP. Здесь слово «класс» означает stateful runtime object там, где lifetime действительно полезен. Stateless вычисления остаются обычными ModuleScript-функциями.

---

# 1. DataModel target tree

```text
ReplicatedStorage
├── Shared
│   ├── Config
│   │   ├── PhysicsConfig.lua
│   │   ├── RaceConfig.lua
│   │   ├── TrackConfig.lua
│   │   ├── EconomyConfig.lua
│   │   ├── MonetizationConfig.lua
│   │   ├── BotConfig.lua
│   │   ├── PlaceConfig.lua
│   │   └── FeatureFlags.lua
│   ├── Types
│   │   ├── StrokeTypes.lua
│   │   ├── RaceTypes.lua
│   │   ├── TrackTypes.lua
│   │   └── ProfileTypes.lua
│   ├── Math
│   │   ├── StrokeMath.lua
│   │   ├── GeometryMath.lua
│   │   └── TrackMath.lua
│   └── Net
│       └── RemoteNames.lua
├── Remotes
│   ├── SubmitStroke
│   ├── StrokeResult
│   ├── RaceEvent
│   ├── RequeueRequest
│   ├── CosmeticRequest
│   ├── CosmeticResult
│   ├── CatalogPurchaseRequest
│   ├── CatalogPurchaseResult
│   ├── SettingsRequest
│   ├── SettingsResult
│   ├── OfferRequest
│   ├── OfferResult
│   └── ProfileEvent
└── Assets
    └── CosmeticDefinitions

ServerStorage
├── RacerTemplates
└── TrackPieces

ServerScriptService
├── Bootstrap.server.lua
├── Services
│   ├── RaceService.lua
│   ├── RacerService.lua
│   ├── LegShapeService.lua
│   ├── TrackService.lua
│   ├── ProgressValidationService.lua
│   ├── PlayerDataService.lua
│   ├── RewardService.lua
│   ├── CosmeticService.lua
│   ├── MonetizationService.lua
│   ├── PlaceRouterService.lua
│   └── AnalyticsAdapter.lua
├── Runtime
│   ├── RaceRuntime.lua
│   ├── RacerRuntime.lua
│   ├── LegAssembly.lua
│   ├── TrackRuntime.lua
│   ├── CheckpointTracker.lua
│   └── BotRacerController.lua
└── Tests

StarterPlayer
└── StarterPlayerScripts
    ├── Bootstrap.client.lua
    └── Controllers
        ├── InputController.lua
        ├── DrawingController.lua
        ├── RaceCameraController.lua
        ├── HUDController.lua
        ├── ResultsController.lua
        ├── GarageController.lua
        ├── StoreController.lua
        ├── SettingsController.lua
        ├── AudioController.lua
        └── FeedbackController.lua

StarterGui
├── RaceHUD
├── DrawHUD
├── ResultsHUD
├── GarageHUD
├── StoreHUD
└── SettingsHUD

Workspace
└── Runtime
    ├── Tracks
    ├── Racers
    └── RacePresentation
```

Folder names may change only by explicit architecture decision. Responsibilities below are the contract. Exact Studio Instance classes/properties/tags/collision matrix are owned by `65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md`; UI child hierarchy is `68`.

---

# 2. Server boot order

`Bootstrap.server.lua` является composition root. Именно он создаёт/инициализирует project services и передаёт зависимости.

Recommended order:
1. `AnalyticsAdapter`
2. `PlayerDataService`
3. `TrackService`
4. `LegShapeService`
5. `RacerService`
6. `ProgressValidationService`
7. `RewardService`
8. `CosmeticService`
9. `MonetizationService`
10. `PlaceRouterService`
11. `RaceService`
12. route/start place-specific game loop

Причина: `RaceService` — orchestration layer, а не хозяин всех подсистем.

---

# 3. Server services

## RaceService
**Lifetime:** singleton/server.  
**Owns:** текущий phase heat, roster, current `RaceRuntime`, result transition/requeue orchestration **inside the current `PlaceMode`**. In `ENTRY_FTUE` it runs only the controlled T06 FTUE loop; in `RACE` it runs public rotation.  
**Does NOT own:** физическую сборку ног, persistent profile, TrackPiece models, reward formula details.

Public contract conceptually:
```text
Init(deps)
CreateHeat(playerList, trackDefinitionId)
StartCountdown()
StartRace()
HandlePlayerLeave(player)
RequestRequeue(player)
EndHeat(reason)
GetRaceForPlayer(player)
```

Depends on: `TrackService`, `RacerService`, `ProgressValidationService`, `RewardService`, `AnalyticsAdapter`.

---

## PlaceRouterService
**Lifetime:** singleton/server.  
**Owns:** place-mode validation and safe server-side routing between `EntryFTUEPlace` and `RacePlace` using the exact lifecycle in `41`.

Conceptual contract:
```text
Init(placeConfig, playerDataService)
RouteAfterProfileReady(player)
SendToRacePlace(player, reason)
SendToEntryFTUEPlace(player, reason)
GetPlaceMode() -> ENTRY_FTUE | RACE
```

Rules:
- only the server chooses destination after canonical profile state is known;
- `ENTRY_FTUE` never prompts paid products;
- teleport failure is retried with bounded backoff and visible non-destructive status; it never mutates tutorial/reward state to fake success;
- `RaceService` is started in the mode allowed by `PlaceConfig`, not as a second independent topology.

Depends on: `PlayerDataService`, Roblox TeleportService adapter, `AnalyticsAdapter`.

---

## RacerService
**Owns:** spawn/despawn racer entities and mapping `Player → RacerRuntime`.

```text
SpawnRacer(player, laneRuntime) -> RacerRuntime
GetRacer(player) -> RacerRuntime?
DespawnRacer(player)
ResetAll()
```

Does not process raw stroke math itself.

---

## LegShapeService
**Owns:** authoritative stroke validation and conversion `StrokePayload → ShapeSpec → LegAssembly pair`.

```text
ValidateAndBuild(player, racerRuntime, payload) -> Result
DestroyShape(shapeVersion)
```

Internally uses pure `StrokeMath` and `LegAssembly` constructor.

Does NOT decide race placement/reward.

---

## TrackService
**Owns:** TrackPiece registry, TrackDefinition loading, validation, building identical lanes.

```text
ValidatePieceTemplate(pieceId)
BuildTrack(definitionId, laneCount, seed?) -> TrackRuntime
DestroyTrack(trackRuntime)
GetDefinition(id)
```

Does not decide player progression.

---

## ProgressValidationService
**Owns:** ordered checkpoints, lane bounds, finish validation, suspicious movement envelope.

```text
AttachRacer(raceRuntime, racerRuntime)
Step(dt)
TryFinish(racerRuntime)
ResetRacerProgress(racerRuntime, checkpointId)
```

Produces validated progress/finish events for `RaceService`.

---

## PlayerDataService
**Owns:** canonical profile cache, DataStore key access, session lease/handoff, migrations and all persistent mutations. Exact store/key/lease/GrantId/receipt rules are `31` and `56`; no other service invents a save path.

Required public behavior includes:
```text
LoadAndAcquire(player, teleportData) -> Ready | GuestSafe
ApplyRaceGrant(player, grantId, delta) -> committedDelta | AlreadyApplied | NotWritable
ApplyEquip(player, request)
ApplySettings(player, request)
PurchaseCatalogItem(player, requestId, itemId)
ApplyPassEntitlement(player, skuKey, grantSet)
ApplyDeveloperProductReceipt(player, receiptInfo, productDef)
BeginTransfer(player, targetPlaceId) -> transferToken
HeartbeatLease(player)
ReleaseIfOwned(player)
```

`PlayerDataService` never writes a stale full profile without revalidating current store state/lease. Cross-place transfer is a lease handoff, not an assumption that `PlayerRemoving` finished first.
---

## RewardService
**Owns:** calculation/grant of gameplay rewards after server-validated result.

```text
CalculateRaceReward(result, profile) -> RaceGrantDelta
CreateGrantId(heatId, racerId) -> GrantId
Commit(player, grantId, raceGrantDelta) -> committedDelta | AlreadyApplied | NotWritable
```

`Commit` delegates persistence to `PlayerDataService:ApplyRaceGrant` (`31`). No client-provided amount/GrantId is accepted.

---

## CosmeticService
**Owns:** cosmetic definitions, ownership/equip validation, application to racer visual presentation.

```text
CanEquip(player, slot, itemId)
Equip(player, slot, itemId)
PurchaseWithCoins(player, requestId, itemId)
ApplyLoadout(racerRuntime, profile)
```

**Invariant:** cosmetic definition never changes canonical physics collider/body dimensions/motor values.

---

## MonetizationService
**Owns:** Roblox purchase prompt flow integration and idempotent grant routing.

Does not own economy desire/design; that lives in product docs.

```text
PromptProduct(player, offerId)
ReconcilePassEntitlement(player, skuKey)
HandleReceipt(receiptInfo)
GrantPurchasedValue(...)
```

Purchase result must be server-confirmed/idempotent. Exact Developer Product retry/grant semantics and the durable `PurchaseId` ledger live only in `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md`; Coin catalog transactions and Pass reconciliation live in `71_CATALOG_TRANSACTION_AND_PASS_ENTITLEMENT_CONTRACT.md`.

---

## AnalyticsAdapter
**Owns:** one gateway to Roblox AnalyticsService event calls.

```text
LogFunnelStep(player, funnelId, stepId, fields)
LogEconomy(...)
LogCustom(player, eventName, value?, fields?)
```

Controllers/services do not call AnalyticsService directly. KPI/questions live in `10_ANALYTICS_TEST_PLAN.md`; **exact event names/fields live only in `46_ANALYTICS_EVENT_DICTIONARY.md`**.

---

# 4. Runtime stateful objects

## RaceRuntime
One instance per heat.

Owns runtime-only state:
```text
raceId
phase
trackRuntime
racers[]
startedAt
finishOrder[]
timeoutAt
```

No persistent player data stored inside beyond references/ids.

Methods conceptually:
```text
AddRacer(racerRuntime)
SetPhase(phase)
RecordFinish(racerRuntime, serverTime)
GetPlacementSnapshot()
Destroy()
```

---

## RacerRuntime
One instance per active racer.

Owns:
```text
player
model/body
laneRuntime
leftLeg/rightLeg
shapeVersion
checkpointTracker
finished
respawning
```

```text
ApplyShape(shapeSpec)
SetMotorEnabled(enabled)
RespawnAt(checkpoint)
SetFinished()
Destroy()
```

`ApplyShape` delegates physical creation to LegShapeService/LegAssembly factory and performs atomic swap.

---

## BotRacerController
One stateful controller per bot racer, introduced only when Bot Fill becomes active.

Owns:
```text
racerRuntime reference
botProfile reference
reaction timer
current legal shape intent / next decision time
```

Does **not** own race phase, checkpoints, rewards, physical constants or a second movement system. It reads upcoming TrackPiece requirement tags from `TrackRuntime/TrackService`, chooses a legal shape intent from `BotConfig`, and routes that intent through the same `LegShapeService/RacerRuntime.ApplyShape` path as humans.

Conceptual methods:
```text
Start(racerRuntime, botProfile, trackRuntime)
Tick(dt)
RequestNextShape(context)
Stop()
Destroy()
```

Invariant: no teleport/rubber-band/hidden physics boost. Policy values are frozen for the heat per `40`.

---

## LegAssembly
One per physical leg.

Owns actual Instances:
```text
hub
hinge
segments[]
visuals[]
model
```

```text
new(shapeSpec, side, mount)
Mount()
SetPhase(angle)
SetEnabled(bool)
Destroy()
```

One leg = one rotating rigid assembly + one motor. Never one motor per segment.

---

## TrackRuntime
One per active heat.

Owns built models, lanes, checkpoint descriptors, finish marker.

```text
GetLane(index)
GetCheckpointList(laneIndex)
GetFinish(laneIndex)
Destroy()
```

---

## CheckpointTracker
Small stateful object per racer.

```text
nextIndex
lastSafeCheckpoint
lastProgressTime
```

Does not inspect remotes or grant rewards.

---

# 5. Pure shared modules

## StrokeMath
Pure deterministic functions only:
```text
Dedupe(points)
Clamp(points, bounds)
SimplifyRDP(points, epsilon)
Resample(points, target)
Normalize(points)
MeasureLength(points)
ComputeBounds(points)
```

No Instances, no remotes, no player state.

## GeometryMath
Transforms `ShapeSpec` into segment transforms/sizes; no world ownership.

## TrackMath
Authoring/validation math for Start→End placement, clearance and topology checks.

Pure modules are the easiest place for automated tests.

---

# 6. Client controllers

## InputController
Normalizes mouse/touch lifecycle into project-level pointer events. Does not know physics.

## DrawingController
Owns DrawCanvas interaction and local stroke preview.

Flow:
`InputController → local stroke → StrokeMath pre-clean → SubmitStroke → await StrokeResult`.

Old active leg remains during drawing.

## RaceCameraController
Scriptable camera. Reads replicated local racer position and race state. Owns follow/look-ahead interpolation only.

## HUDController
Placement/progress/countdown/redraw hint. No authoritative race logic.

## ResultsController
Displays result/podium and requeue affordance. `RequestRequeue` is a request only.

## GarageController
M2+. UI for catalog browse/preview, Coin purchase intent and owned cosmetics/loadout. Server validates actual purchase/equip via `71`.

## StoreController
M4. Owns contextual paid-offer presentation and platform prompt initiation after `OfferResult`; never grants entitlement.

## SettingsController
M2. Owns presentation settings UI/local application and validated persistence request.

## AudioController
M2. Resolves semantic audio/music keys from `47/70`; no gameplay authority.

## FeedbackController
M2. Resolves semantic VFX/haptic feedback from `47/69`; respects Reduce Motion and never decides gameplay.

---

# 7. Ownership matrix

| State | Owner |
|---|---|
| Raw pointer path before submit | local DrawingController |
| Accepted normalized ShapeSpec | server LegShapeService |
| Physical racer | server authority / server authoritative simulation |
| Race phase | RaceService/RaceRuntime |
| Placement | RaceRuntime after ProgressValidation |
| Place routing / FTUE redirect | PlaceRouterService |
| Coins | PlayerDataService + RewardService mutation |
| Cosmetic ownership | PlayerDataService |
| Equipped cosmetic | PlayerDataService/CosmeticService |
| Camera | local RaceCameraController |
| Local UI | local HUD/Results/Garage/Store/Settings controllers |
| Audio/VFX/haptic presentation | local AudioController/FeedbackController |
| Track definition | TrackService |
| Analytics transmission | server AnalyticsAdapter |

Если два сервиса претендуют на один и тот же authoritative state — архитектура требует пересмотра.

---

# 8. Dependency graph

```text
                    RaceService
                 /      |       \
          TrackService  |   RewardService
                |       |         |
          TrackRuntime  |   PlayerDataService
                        |
                  RacerService
                        |
                   RacerRuntime
                        |
                 LegShapeService
                    /       \
              StrokeMath   LegAssembly

ProgressValidationService → RaceRuntime/RacerRuntime observations
AnalyticsAdapter ← semantic events from services
CosmeticService → PlayerDataService + RacerRuntime visuals
MonetizationService → PlayerDataService/Reward grant path
```

Rule: orchestration may depend on lower-level domain services; low-level modules never require `RaceService` back.

---

# 9. What NOT to create

Without new Decision Log do not create:
- `GameManager`;
- `MultiplayerManager`;
- `PhysicsManager`;
- `SaveManager` next to `PlayerDataService`;
- second remote registry;
- client authoritative reward/economy object;
- separate per-obstacle script family if TrackPiece config can express it;
- one script per level.

---

# 10. Milestone introduction map

| Module | First milestone |
|---|---|
| StrokeMath | M0 |
| InputController | M0 |
| DrawingController | M0 |
| LegAssembly | M0 |
| LegShapeService | M0 |
| RacerRuntime/RacerService | M0 |
| TrackMath/TrackService minimal | M0.5/M1 |
| RaceRuntime/RaceService | M1 |
| ProgressValidationService | M1 |
| RaceCameraController/HUD | M1 |
| ResultsController | M1 |
| GarageController/SettingsController | M2 |
| AudioController/FeedbackController | M2 |
| Coin catalog purchase path | M2 (`71`) |
| StoreController | M4 |
| Pass entitlement reconciliation | M4 (`71`) |
| PlayerDataService | M2 |
| RewardService | M2 |
| CosmeticService/Garage | M2 |
| AnalyticsAdapter baseline | M2 |
| BotRacerController | M3 / required before public cold-start release |
| MonetizationService | M4 |

Do not bootstrap later milestone modules before their feature becomes ACTIVE.

# 22 — NETWORK & DATA CONTRACTS

Статус: **SECURITY/INTEGRATION CONTRACT v1.3.4**

Roblox competitive rule: client is trusted for **input intent**, not for authoritative result.

---

# 1. Remotes

Use a small semantic remote surface. Do not expose generic `SetProperty`, `SpawnThing`, `GiveReward` remotes.

## Client → Server

### `SubmitStroke`
Purpose: request new locomotion shape.

Payload concept:
```text
{
  sequence: integer,
  points: Array<{x:number, y:number}>
}
```

Client may pre-simplify for bandwidth, but server repeats validation/cleanup.

Server validates:
- correct player/race phase;
- request rate;
- payload table shape;
- finite numbers;
- point count cap;
- normalized bounds;
- minimum useful stroke;
- sequence newer than last accepted/pending;
- resulting segment/extent limits.

Server never accepts client-created Instances or arbitrary world CFrames as shape authority.

### `RequeueRequest`
Payload:
```text
{ action:"JOIN"|"LEAVE", expectedRaceId?:string }
```
`JOIN` sets explicit post-heat queue intent after UI guard; `LEAVE` cancels before roster lock. Automatic one-time arrival queue in `74` is server lifecycle logic and does not require a client remote.

Validation:
- player is in valid post-race/intermission/queued state for requested action;
- request not spammed;
- stale expectedRaceId ignored;
- JOIN does not make player server-ready before `74.ResultsMinimumDisplay`;
- LEAVE cannot remove a racer from an already locked roster.

### `CosmeticRequest`
M2+.

Payload:
```text
{slot:string, itemId:string}
```

Server validates definition, ownership, slot compatibility.


### `CatalogPurchaseRequest`
M2+ soft-currency purchase intent.

Payload:
```text
{requestId:string, itemId:string}
```
Client never sends price, Coin delta or grant contents. Server validates canonical item/source/price and commits atomically through `71_CATALOG_TRANSACTION_AND_PASS_ENTITLEMENT_CONTRACT.md`.

### `SettingsRequest`
M2+ presentation preference mutation.

Payload:
```text
{key:string, value:any}
```
Allowed keys at launch only: `Music:boolean`, `SFX:boolean`, `ReduceMotion:boolean`, `RivalShapeDetail:"FULL"|"REDUCED"|"HIDDEN"`, `HighContrastProgressMarkers:boolean`.
Server rejects unknown keys/types. GuestSafe may apply a session-local presentation value but does not persist it; safe profile state is required for persistent mutation.

### `OfferRequest`
M4. Client asks for one known offer to be evaluated; it does **not** ask the server to grant/purchase anything.

Payload:
```text
{offerId:string}
```
Server checks canonical eligibility (`45/61`), GuestSafe, configured SKU mapping (`30`) and existing entitlement. Server answers with `OfferResult`; the client may then invoke the current Roblox platform purchase prompt. Client prompt completion never grants value.

---

# 2. Server → Client

### `StrokeResult`
```text
{
  sequence,
  accepted:boolean,
  shapeVersion?,
  rejectReasonCode?
}
```

Reason codes are UI/debug categories, not sensitive internal security details.

### `CosmeticResult`
```text
{requestId?, accepted:boolean, slot?, itemId?, reasonCode?}
```
On accepted equip, UI waits for `ProfileEvent`/confirmed profile presentation state before claiming persistence.


### `CatalogPurchaseResult`
```text
{requestId, accepted:boolean, itemId?, reasonCode?, coinsAfter?}
```
Success is emitted only after the canonical Coin subtraction + ownership grant mutation is confirmed. Exact reasons/idempotency = `71`.

### `SettingsResult`
```text
{key, accepted:boolean, value?, persisted:boolean, reasonCode?}
```
`persisted=false` is valid for GuestSafe session-local presentation.

### `OfferResult`
```text
{
  offerId,
  eligible:boolean,
  reasonCode?,
  skuKey?,
  productType?,
  platformId?,
  contents?
}
```
Only configured/eligible offers return an enabled platformId. This response authorizes **prompt presentation only**, never grant.

### `ProfileEvent`
Server→client presentation-safe profile deltas/snapshot after confirmed mutation/load:
```text
ProfileReady | CoinsChanged | MasteryChanged | OwnershipChanged |
CatalogPurchaseCommitted | EquipChanged | SettingsChanged | EntitlementReconciled | GuestSafeChanged
```
Do not replicate receipt ledger or internal anti-cheat fields.

### `RaceEvent`
Discrete semantic events only:
```text
CountdownStarted
RaceStarted
RacerFinished
LocalResultReady
QueueIntentChanged
SpectatorStateChanged
IntermissionStarted
RaceReset
```

World racer motion should replicate through Roblox simulation, not be spammed as per-frame CFrames through a reliable RemoteEvent.

For non-critical high-frequency presentation data, prefer local derivation from replicated state; only consider `UnreliableRemoteEvent` when a measured need exists.

---

# 3. Server Authority target

As of the 2026 platform snapshot, `Workspace.AuthorityMode` supports `Enum.AuthorityMode.Server` and Server Authority is publicly released.

Project target:
- M1 test with Server Authority enabled;
- racer state/finish/rewards remain server truth regardless;
- if an engine-specific physics issue blocks the target, log a Decision and use the documented fallback with explicit movement validation rather than silently trusting clients.

Fallback is not the default architecture.

---

# 4. Runtime race state contract

Server-only conceptual schema:
```text
RaceState {
  raceId
  phase
  trackDefinitionId
  startedAt
  timeoutAt
  racersByUserId
  finishOrder
}

RacerState {
  userId
  laneIndex
  shapeVersion
  nextCheckpointIndex
  lastSafeCheckpointId
  finishAcceptedAt?   -- server-only monotonic ordering value
  finishSequence?     -- server-only per-heat serialized sequence
  placement?
}
```

Clients may receive only the subset needed for presentation.

---

# 5. Persistent profile contract

**Single source of truth:** `31_SAVE_DATA_MIGRATION_RECOVERY.md`.

This network document intentionally does **not** duplicate the serialized profile body. Rules that cross the client/server boundary:
- profile writes only through `PlayerDataService`;
- client never authors Coins, ownership, equipped state, rank/status or receipt state;
- serialized version/migrations follow `31`;
- Developer Product idempotency follows `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md`;
- only presentation-safe subsets are replicated to clients.

---

# 6. Resolved track snapshot contract

The **authoring/config `TrackDefinition` schema lives only in `30_CONTENT_CONFIG_SCHEMAS.md`**. Networking/race runtime does not redefine it. Before a heat starts, `TrackService` resolves the selected definition into an immutable server-owned snapshot concept:
```text
ResolvedTrackSnapshot {
  definitionId,
  definitionVersion,
  heatSeed,
  resolvedPieces: [
    { pieceId, resolvedParams, variantSeed? }  -- launch T01–T20: variantSeed=nil; exact values, no random geometry
  ]
}
```
One snapshot is applied to every lane in the heat. Client does not choose piece parameters or seed. Presentation may receive only the subset required for UI/debug.

---

# 7. ShapeSpec contract

Server-internal result of stroke processing:
```text
ShapeSpec {
  version,
  normalizedPoints,
  bounds,
  extent,
  segmentPlan,
  hash/debugId
}
```

`segmentPlan` is derived by server and is not trusted from client.

---

# 8. Remote abuse rules

Every client-triggered server path must answer:
1. Is player allowed to request this now?
2. Is every argument type valid?
3. Is value inside allowed bounds/domain?
4. Is request rate reasonable?
5. Can request allocate unbounded Instances/memory?
6. Can it change another player's state?
7. Can it grant currency/status?
8. What happens at 1000 calls/second?

For `SubmitStroke`, server must hard-cap work before geometry construction.

---

# 9. Finish contract

Finish accepted only if:
- correct active race;
- not already finished;
- checkpoints passed in order;
- racer enters valid finish region;
- server state/time used;
- movement validation is not in invalid state.

The same serialized server acceptance path writes `finishAcceptedAt` and increments/writes `finishSequence`; placement sort is exactly `74`: `FinishAcceptedAt → FinishSequence → SlotIndex`. Duplicate finish touches are idempotent. Client never transmits finish time, finish sequence, placement or reward amount.

---

# 10. Recovery/respawn contract

Recovery is a server decision based on authoritative progress/stuck state.

Respawn:
- last safe checkpoint;
- reset only necessary unstable physical state;
- active/equipped shape may be rebuilt;
- no race progress skip;
- penalty/timing from tuning source.

---

# 11. Data ownership security invariant

If information affects:
- victory;
- rank/status;
- Coins;
- owned cosmetics;
- paid entitlement;
- race eligibility;

then the authoritative value must be known/validated by the server.


# 12. Remote ownership summary
- `SubmitStroke/StrokeResult` → DrawingController ↔ LegShapeService.
- `RequeueRequest/RaceEvent` → Results/HUD ↔ RaceService.
- `CosmeticRequest/CosmeticResult/ProfileEvent` → GarageController ↔ CosmeticService/PlayerDataService for equip.
- `CatalogPurchaseRequest/CatalogPurchaseResult/ProfileEvent` → GarageController ↔ CosmeticService/PlayerDataService for exact Coin purchase contract `71`.
- `SettingsRequest/SettingsResult/ProfileEvent` → SettingsController ↔ PlayerDataService.
- `OfferRequest/OfferResult` → StoreController ↔ MonetizationService; platform prompt occurs client-side after eligible result, grant remains server/platform-confirmed. Pass reconciliation follows `71`; Developer Product receipts follow `56`.

No generic RPC or client-authored reward/ownership/settings table is added.

## Launch seed/variant rule
Every heat has one server-generated `HeatSeed` stored in RaceRuntime for reproducible bot/presentation diagnostics. Launch T01–T20 geometry uses exact `TrackDefinition` numeric values: `variantSeed=nil`, no per-heat random obstacle dimensions. HeatSeed may derive bot RNG (`75`) and noncompetitive presentation; moving gameplay obstacles follow their exact phase schedule from `60` identically in all lanes. Future random geometry variants require a new validated config/Decision Log before `variantSeed` becomes non-nil.


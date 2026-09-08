# 31 — SAVE DATA, MIGRATION & RECOVERY
Статус: **CANONICAL PERSISTENCE CONTRACT v1.3.4**.

> **One fact / one owner:** this file is the only source of truth for the serialized player profile. `22` may reference this schema but must not redefine it.

## Canonical profile v1
```lua
{
    Version = 1,

    Coins = 0,
    Wins = 0,
    Podiums = 0,
    RacesFinished = 0,
    MasteryPoints = 0,

    ClearedTracks = {
        -- [trackId] = true after first authoritative finish
    },

    Tutorial = {
        Completed = false,
    },

    OwnedBodies = {Body_Default_01 = true},
    OwnedInk = {Ink_Graphite_01 = true},
    OwnedTrails = {Trail_None = true},
    OwnedFinishFX = {Finish_Pop_01 = true},

    Equipped = {
        Body = "Body_Default_01",
        Ink = "Ink_Graphite_01",
        Trail = "Trail_None",
        FinishFX = "Finish_Pop_01",
    },

    Settings = {
        Music = true,
        SFX = true,
        ReduceMotion = false,
        RivalShapeDetail = "FULL", -- FULL | REDUCED | HIDDEN
        HighContrastProgressMarkers = false,
    },

    OneTimeFlags = {
        FirstHeatBonusGranted = false,
        FirstWinBonusGranted = false,
        FTUEInkSkyGranted = false,
    },

    -- config-driven LiveOps objective state; exact launch buffer = `76`
    LiveEvents = {
        -- [eventId] = {
        --   Version = 1,
        --   Objectives = { [objectiveId] = {Progress=0, Completed=false} }
        -- }
    },

    -- semantic one-time Pass entitlements; numeric PassIds live only in deployment registry `70`
    PassEntitlements = {
        -- [skuKey] = true
    },

    -- bounded idempotency ledger for Coin-priced cosmetic purchases
    RecentCatalogPurchases = {
        -- ordered max 32 entries: {RequestId="guid", ItemId="Body_Stripes_01", AppliedAt=unixSeconds}
    },

    -- Developer Product exactly-once grant ledger. Never prune automatically.
    ProcessedReceipts = {
        -- [purchaseId] = {ProductId=123, GrantedAt=unixSeconds, GrantKey="COINS_450"}
    },

    -- bounded exactly-once ledger for authoritative race reward mutations
    RecentRaceGrants = {
        -- ordered max 64 entries: {GrantId="guid", HeatId="guid", AppliedAt=unixSeconds}
    },

    -- operational concurrency metadata; not player-facing progression
    _SessionLease = {
        LeaseId = nil,
        JobId = nil,
        PlaceId = 0,
        HeartbeatAt = 0,
        TransferToken = nil,
        TransferTargetPlaceId = 0,
        TransferExpiresAt = 0,
    },

    LastSeenAt = 0,
}
```

Launch ownership/catalog IDs are owned by `62`; exact rewards/MP/first-time bonus logic are `61`. On authoritative FTUE completion, the server grants `Ink_Sky_01` exactly once, sets `FTUEInkSkyGranted=true`, sets `Tutorial.Completed=true`, and auto-equips `Ink_Sky_01` after the ownership mutation succeeds.

Seasonal rank fields are **not** part of profile v1 because ranked season is later scope. Add them only through an explicit migration when that feature is approved.

## Ownership
Only `PlayerDataService` writes the profile. Other services request mutations through its API. There is no second save model in network, UI or monetization code.

## Store/key and session-concurrency contract
- DataStore name: `DrawRacers_PlayerProfile_v1`.
- Key: `p:<UserId>`.
- Every production write is an `UpdateAsync` transform that first verifies the current `_SessionLease`/transfer token. No service writes a stale cached whole profile over a newer store value.
- `PlayerDataService` creates a cryptographically-random/GUID `LeaseId` per server ownership attempt.
- Normal lease heartbeat interval = **25s**; a lease is stale after **90s** without heartbeat.
- If another non-stale lease exists and no valid handoff token is present, retry acquisition with bounded backoff for up to the join/load gate, then remain GuestSafe/read-only rather than stealing an active lease.
- A stale lease may be atomically replaced by `UpdateAsync`.

### Cross-place handoff (`EntryFTUEPlace` ↔ `RacePlace`)
To prevent the old and new server from owning the profile simultaneously:
1. old server flushes the pending authoritative mutation;
2. `PlayerDataService:BeginTransfer(targetPlaceId)` writes a random `TransferToken`, target place and **30s** expiry while retaining current lease ownership;
3. server passes that token only through trusted teleport data;
4. destination server loads profile and, only when token/target/expiry match, atomically replaces the old lease with its new LeaseId;
5. every later write from the old server fails its lease check and is discarded/reconciled rather than overwriting destination state;
6. `TeleportInitFailed` before takeover causes the source to clear the transfer marker under its still-valid lease and retry later;
7. an expired transfer marker does not authorize takeover by token. Normal stale-lease rules apply.

The transfer token is authorization for **lease handoff only**. It never contains/grants Coins, ownership, tutorial completion or placement.

## Load
1. Server loads/acquires profile lease before persistent economy/cosmetics become mutable.
2. Normal acquisition attempts use bounded exponential backoff; UI/performance limits are `57`.
3. If profile/lease is not confirmed safely, player enters `GuestSafe`; purchases, persistent reward grants and persistent equip/settings mutations are blocked. No retroactive Coins/status/tutorial are queued.
4. Unknown **newer** `Version` fails closed: do not overwrite it with older code.
5. On safe acquisition, validate/migrate, sanitize equipped IDs, then expose `Ready` state to place routing (`41`).

## Save/write cadence
- Race completion/reward: one authoritative `ApplyRaceGrant` UpdateAsync.
- Cosmetic equip/settings: coalesce rapid UI changes; persist no later than **5s** after last accepted change, while authoritative in-memory state updates immediately.
- Pass entitlement synchronization, Coin catalog purchases and Developer Product receipt grants: persist immediately before confirmation/celebration. Exact Coin/Pass contract = `71`; Developer Product receipt = `56`.
- Lease heartbeat: every **25s** while writable.
- Safety autosave: every **60s + deterministic 0–10s per-player jitter** when dirty.
- `PlayerRemoving`/`BindToClose`: best-effort flush only while this server still owns the lease. Never overwrite after a destination server has taken over.
- Do not write on every frame/input/UI highlight.

## Exactly-once race grant
Each authoritative heat/racer result creates a server-only `GrantId` GUID and `HeatId`. `RewardService` computes the entire delta first, then calls `PlayerDataService:ApplyRaceGrant(GrantId, delta)`. The single UpdateAsync transform:
- verifies writable lease;
- returns no-op if `GrantId` already exists in `RecentRaceGrants`;
- applies Coins, Wins/Podiums/RacesFinished/MasteryPoints, first-clear and one-time bonuses together;
- applies any active `30/76` `RACE_FINISH` LiveEvent objective progress from the same authoritative HeatId, filtered by TrackId; when a target is first reached, marks the objective Completed and applies its Coin reward in this **same transform**; duplicate retry of the race GrantId therefore cannot duplicate objective progress/reward;
- for successful FTUE T06, also sets `Tutorial.Completed`, grants/auto-equips `Ink_Sky_01` and sets `FTUEInkSkyGranted` **in the same transform**;
- **FTUE T06 DNF does not call a persistent race grant at all**: no Coins, MP, first-completion/first-clear flags, Tutorial mutation or cosmetic entitlement; retrying T06 therefore cannot farm persistent state;
- appends `GrantId` and trims the ledger to the newest **64** entries;
- returns the committed delta used by Results/analytics.

A retry of the same GrantId cannot duplicate rewards. A different later heat receives a different GrantId. The 64-entry persisted ring is a crash/retry guard, not gameplay history.

## Generic write strategy
Use `UpdateAsync`, `pcall`, bounded retry/backoff and request-budget awareness. Do not enable Studio API access against production data. Do not assume a failed/timeout write definitely did not happen; re-read/reconcile by lease/GrantId/PurchaseId where outcome is uncertain.

## Soft catalog purchase / Pass entitlement
Coin-priced cosmetic purchase must be one atomic profile mutation that subtracts canonical Coins, inserts ownership and appends `RequestId` to `RecentCatalogPurchases` together; duplicate request/retry cannot double-charge. The ledger is trimmed to the newest **32** entries after each successful catalog purchase; already-owned item remains a no-charge no-op even after an old request marker ages out. Pass entitlement grant stores semantic SkuKey + exact cosmetic grant set idempotently after server-side platform ownership confirmation. Full algorithms and failure matrix: `71_CATALOG_TRANSACTION_AND_PASS_ENTITLEMENT_CONTRACT.md`.


## Migrations
`Version` increases only with an explicit idempotent `vN -> vN+1` migration function and fixtures for old/new data. A migration is shipped to STAGING before PROD. Code rollback and data rollback are separate plans.

## Invariants
- ownership sets only grow except explicit support correction;
- `Coins >= 0`;
- equipped item must exist in catalog and be owned;
- Wins/Podiums/RacesFinished/MasteryPoints do not decrease in ordinary merge;
- Robux grant never depends on a client claim;
- a race `GrantId` can cause at most one persistent race mutation;
- that same race `GrantId` can increment each active LiveEvent `RACE_FINISH` objective at most once and can complete/pay it at most once;
- only the current valid lease owner may mutate the profile;
- a catalog `RequestId` can cause at most one Coin deduction/ownership mutation;
- a Pass `SkuKey` entitlement grant is monotonic/idempotent;
- a `PurchaseId` can cause at most one persistent grant;
- `ProcessedReceipts[purchaseId]` is written in the **same `UpdateAsync` transform** that applies the grant;
- receipt markers are never auto-pruned because an old retry must remain idempotent.

## Developer Product integration
Exact algorithm and failure table: `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md`. `ProcessReceipt` returns `PurchaseGranted` only after the authoritative profile mutation either (a) newly applied the grant and marker, or (b) confirmed the marker already exists.

## Profile-size guardrail
`PlayerDataService` records serialized size estimates in STAGING/diagnostics. At >=50% of the current Roblox per-key size limit, raise an operations alert and stop adding unbounded fields. Receipt archival, if ever required, must be designed before pruning; automatic deletion of receipt IDs is forbidden.

## Recovery
Before release test restore via Data Stores Manager/version history on STAGING. Emergency procedure: disable persistent writes feature flag → inspect versions/receipts → decide code rollback vs data restore separately → re-enable only after reconciliation.

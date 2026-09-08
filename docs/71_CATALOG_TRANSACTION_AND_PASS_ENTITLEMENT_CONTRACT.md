# 71 — CATALOG TRANSACTION & PASS ENTITLEMENT CONTRACT
Статус: **EXACT PURCHASE/OWNERSHIP MUTATION CONTRACT v1.3.4**.

Цель: закрыть две транзакционные дыры, которые нельзя оставлять «на усмотрение программиста»: покупка косметики за Coins и синхронизация one-time Pass entitlement. Developer Product receipts остаются owner `56`.

## 1. Soft-currency catalog purchase — authoritative flow
Client never sends a Coin price or ownership result.

Request remote:
```text
CatalogPurchaseRequest {
  requestId: string,
  itemId: string
}
```
Server path:
`GarageController → CatalogPurchaseRequest → CosmeticService → PlayerDataService:PurchaseCatalogItem → UpdateAsync → ProfileEvent + CatalogPurchaseResult`.

Server resolves canonical `itemId` definition and `SoftPrices[itemId]` from config generated from `61`.

## 2. Atomic Coin purchase mutation
`PlayerDataService:PurchaseCatalogItem(player, requestId, itemId)` performs one authoritative profile mutation:
1. profile writable + lease owned;
2. item exists and is allowed for Coin purchase;
3. already owned → return `AlreadyOwned`, no charge;
4. canonical price >=0 and player Coins >= price;
5. atomically subtract Coins and insert the item into the canonical slot-specific ownership set (`OwnedBodies`, `OwnedInk`, `OwnedTrails` or `OwnedFinishFX`) resolved from item definition;
6. append `RequestId` to profile `RecentCatalogPurchases` in the same transform and trim to newest 32 entries;
7. return committed new Coins/ownership.

If the same RequestId is already present, return the already-committed outcome/no-op without another deduction. If an UpdateAsync timeout leaves outcome uncertain, re-read/reconcile by RequestId before retrying a charge.

Never subtract Coins in one write and grant ownership in another.

## 3. CatalogPurchaseResult
```text
{
  requestId,
  accepted:boolean,
  itemId?,
  reasonCode?,
  coinsAfter?
}
```
Canonical reason codes: `OK`, `ALREADY_OWNED`, `UNKNOWN_ITEM`, `NOT_COIN_ITEM`, `INSUFFICIENT_COINS`, `PROFILE_NOT_WRITABLE`, `RATE_LIMITED`, `SERVER_ERROR`.

UI may celebrate only after accepted result/profile confirmation. Duplicate request cannot double-charge.

## 4. Equip after Coin purchase
Purchase does **not** silently auto-equip unless the user pressed a combined `BUY & EQUIP` presentation CTA explicitly. Launch default CTA for a Coin item is `{PRICE} COINS`; after confirmed purchase the CTA becomes `EQUIP`. This preserves clear state transitions and avoids a purchase race with equip persistence.

## 5. Pass entitlement — launch definition
Launch Passes are exact SkuKeys from `61` and grant exact cosmetic sets from `62`. Passes are permanent one-time cosmetic entitlements and do not use `ProcessReceipt`.

Canonical server mapping:
`SkuKey → PassId (70) → CosmeticGrantSet (61/62)`.

## 6. Pass reconciliation triggers
Server reconciles Pass entitlement:
1. after safe profile load in RacePlace/EntryFTUEPlace when monetization reconciliation is allowed;
2. after platform purchase-prompt completion signal for that Pass;
3. on explicit retry after transient platform error;
4. before showing a paid offer if cached entitlement state is stale.

Client completion signal is only a reason to re-check platform ownership; it is never authority to grant.

## 7. Pass reconcile algorithm
For each known enabled Pass SkuKey:
1. resolve PassId from `70`;
2. query current supported Roblox ownership API server-side;
3. on confirmed owned=true, call `PlayerDataService:ApplyPassEntitlement(skuKey, grantSet)`;
4. atomic profile mutation inserts entitlement marker + all cosmetic ItemIds idempotently;
5. emit `EntitlementReconciled/OwnershipChanged` and analytics after commit;
6. purchase celebration may run only for a newly confirmed entitlement in the current prompt context.

If ownership query errors/timeouts: keep existing persisted ownership, do not revoke, log/retry. Unknown PassId fails closed and blocks prompt.

## 8. Persisted pass state
## 8.1 Launch Pass equip behavior
- Newly confirmed Pass from an active Results/Garage purchase prompt: after entitlement/profile commit, auto-equip every granted cosmetic into its slot in the same safe non-Racing state, then run post-purchase theatre. If state became Racing before confirmation, ownership commits but equip is deferred to next PREP/RESULTS safe boundary.
- Entitlement found during normal join reconciliation for a Pass bought previously: grant missing ownership silently/idempotently; **do not force equip** and do not replay purchase celebration.
- Coin cosmetic purchase launch default still does not auto-equip; CTA changes to `EQUIP` after commit.
- No Pass flow can equip a cosmetic before server-confirmed ownership.


Profile stores semantic SkuKey entitlement markers in `PassEntitlements`, not just numeric PassId. Numeric deployment IDs may change across environment; semantic grant identity remains stable.

Pass reconciliation is monotonic at launch: a transient false/error never removes already-granted cosmetics. Any future platform-required revocation/refund handling is a policy change and requires explicit migration/ops Decision Log.

## 9. GuestSafe
GuestSafe:
- Coin catalog purchase disabled;
- Pass prompts disabled;
- entitlement reconciliation may display already-known in-memory/default safe presentation only, but no new persistent grant is claimed until profile is writable;
- no queued retroactive Coin spend.

## 10. Rate/idempotency rules
- one in-flight catalog purchase per player;
- duplicate requestId returns/reconciles prior outcome where available;
- server ignores client-supplied price/grant list;
- Pass grant set derived from server config only;
- Developer Product exact-once remains `56`.

## 11. Analytics
After committed state only:
- soft purchase success emits economy sink + cosmetic ownership event per `46`;
- insufficient Coins may emit catalog intent diagnostic, not a fake purchase;
- Pass prompt/success funnel uses `46`; success is logged after confirmed entitlement.

## 12. Acceptance matrix
Must PASS:
- Coin purchase enough balance;
- insufficient balance;
- duplicate click/request;
- item already owned;
- stale client-displayed price after config change;
- profile write timeout with uncertain outcome;
- GuestSafe;
- Pass already owned before joining;
- Pass bought during session;
- purchase prompt cancelled;
- platform ownership query error;
- rejoin after purchase before local celebration;
- STAGING/PROD PassId mismatch fails closed;
- no double grant/no double charge.

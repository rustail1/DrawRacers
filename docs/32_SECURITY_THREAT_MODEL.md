# 32 — SECURITY THREAT MODEL
Статус: **SECURITY CONTRACT v1.3.4**.

| Attack | Mitigation |
|---|---|
| SubmitStroke flood | token bucket per player + max payload |
| NaN/Inf/out-of-range Vector2 | type/finite/bounds validation |
| huge point arrays | hard max before allocation/work |
| forged finish | ordered checkpoints + server finish zone |
| teleported racer | server authority + lane/speed/progress sanity |
| fake Coins/reward | no client reward remote; RewardService only |
| equip unowned | server catalog + ownership check |
| buy spoof | Marketplace receipt server path only |
| duplicate receipt | exact `PurchaseId` ledger + same-transaction profile grant per `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md` |
| requeue spam | phase + rate validation |
| malformed config/assets | boot validator, fail closed |
| malicious external library/model | pinned/trusted source, code review, no opaque executable assets |

## Remote rule
Каждый remote проходит: context/permission → type/shape → value/bounds → rate limit → state transition validation. Reject without mutating state.

## Physics rule
Server authority preferred. If any client ownership fallback is ever enabled, it requires explicit Decision Log, exploit tests, speed/lane envelope and no client-authoritative placement.

## Third-party rule
Toolbox/library code не попадает в production как black box. Проверять source, license, compatibility, hidden `require(assetId)`, loadstring-like behavior, network calls, backdoors.

## Logging
Не логировать приватные данные. Security counters агрегируются: invalidStroke, remoteRateLimited, checkpointViolation, impossibleMovement, receiptError.


## Catalog/payment surface v1.3.4
- `CatalogPurchaseRequest`: client supplies only requestId/itemId; server resolves price/ownership and atomically subtracts/grants via `71`.
- Pass prompt completion is never authority; server re-checks platform ownership and applies semantic entitlement via `71`.
- Numeric platform IDs are loaded from `70`; unknown enabled ID fails closed.
- No raw client Coin delta, grant set, SkuKey-to-contents mapping or receipt state is trusted.

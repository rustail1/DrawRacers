# 56 — DEVELOPER PRODUCT RECEIPT & GRANT CONTRACT
Статус: **MONETIZATION DATA-SAFETY CONTRACT v1.3.4**.

Applies to repeatable Roblox **Developer Products** (for example Coin packs if/when enabled). One-time Pass ownership follows the exact entitlement/reconciliation contract in `71_CATALOG_TRANSACTION_AND_PASS_ENTITLEMENT_CONTRACT.md`; it does not use this receipt ledger. Coin-priced cosmetic purchases also live in `71`.

## Invariants
1. Client/UI never grants purchased value.
2. `PromptProductPurchaseFinished` is presentation only, never proof of entitlement.
3. `MarketplaceService.ProcessReceipt` server path is authoritative for Developer Products.
4. One `PurchaseId` causes **at most one** persistent profile mutation.
5. The `PurchaseId` marker and the purchased grant are written in the **same `PlayerDataService` `UpdateAsync` transform**.
6. If persistence outcome is unknown, return “not processed yet” and allow Roblox retry; never guess success.

## Canonical storage
The durable receipt ledger is `Profile.ProcessedReceipts` in `31`. Entry concept:
```lua
ProcessedReceipts[purchaseId] = {
    ProductId = 123456,
    GrantedAt = 1780000000,
    GrantKey = "COINS_500",
}
```
Never auto-prune entries. Profile-size monitoring is required by `31/34`.

## Product definition contract
Each enabled Developer Product has exactly one server definition:
```lua
ProductDefinition = {
    ProductId = 123456,
    GrantKey = "COINS_500",
    Grant = {Coins = 500},
    Enabled = true,
}
```
Unknown/disabled ProductId fails closed and raises a monetization alert.

## Exact `ProcessReceipt` algorithm
1. Validate `receiptInfo.PlayerId`, `ProductId`, `PurchaseId` type/presence.
2. Resolve known enabled `ProductDefinition`. Unknown → log P0/P1 config incident, return `NotProcessedYet`.
3. Find player. If not present or canonical profile is not safely loaded → `NotProcessedYet`.
4. Call `PlayerDataService:ApplyDeveloperProductReceipt(player, receiptInfo, productDef)`.
5. Inside a single profile `UpdateAsync` transform:
   - if `ProcessedReceipts[PurchaseId]` already exists: do **not** grant again; return profile unchanged with result `ALREADY_GRANTED`;
   - otherwise validate grant invariants; apply Coins/entitlement mutation; write `ProcessedReceipts[PurchaseId]`; return updated profile with result `NEWLY_GRANTED`.
6. Only after `UpdateAsync` confirms either `ALREADY_GRANTED` or `NEWLY_GRANTED`, update the in-memory canonical profile from the returned authoritative value.
7. Return `Enum.ProductPurchaseDecision.PurchaseGranted`.
8. On timeout/error/unknown persistence outcome → keep in-memory state conservative, log, return `NotProcessedYet` so the receipt retries.

## Analytics order
Canonical analytics event `PurchaseGranted` is emitted only after step 6. Duplicate callbacks may emit a bounded operational `ReceiptDuplicateConfirmed` counter but must not duplicate economy income events.

## Required QA before enabling a Developer Product
- normal purchase → one grant;
- same `PurchaseId` delivered twice → one grant;
- callback retried after server restart → one grant;
- DataStore failure before transform commit → no confirmed grant, later retry succeeds once;
- simulated timeout after commit but before callback return → retry sees marker, does not duplicate;
- player leaves before safe profile load → callback waits/retries;
- unknown ProductId → no grant;
- malformed receipt → no mutation;
- reconnect after success → grant and marker persist;
- purchase analytics/economy event fires once for the economic mutation.

Any failure here is P0/P1 depending on data/revenue impact and blocks the affected product rollout.

# 45 — MONETIZATION CATALOG
Статус: **COMMERCIAL CONTENT CONTRACT v1.3.4**. Exact launch SKU price hypotheses and grants are fixed in `61`; item identities/art are `62`; platform IDs remain deployment data in `30`.

## Launch / soft-launch catalog primitives
1. **Starter Style Bundle — Pass.** One-time permanent entitlement containing a small coherent cosmetic set; contextual first-payer offer.
2. **Themed Style Bundle — Pass.** Permanent body/ink/trail/finish presentation set; additional themes create catalog breadth without repeat-buying the same SKU.
3. **Premium Presentation Bundle — Pass.** Stronger status/presentation only; no physics power.
4. **Coin packs — Developer Products, conditional.** Enable only if the soft economy is healthy and Coins buy cosmetics/status only. Repeatable receipts must use `56`.
5. **Private Server — later/optional** after measured social demand.

Individual permanent cosmetics may be purchased with Coins; launch Robux direct sales use the bundle Passes above so the implementer does not have to invent duplicate-purchase behavior for permanent Developer Products.

## Later-only
Subscription, rewarded video, seasonal paid progression and paid random items are later-only scope and require an explicit scope decision plus current platform/policy review before implementation.

## Forbidden
Physics speed/torque/friction/radius/hitbox, extra redraw ability, checkpoint skip, paid comeback that changes placement.

## Offer trigger
Canonical earliest paid-offer eligibility: **>=3 completed heats + player preview/equip of at least one free/Coins cosmetic + `55` G5 PASS for the build/cohort**. Show only in post-race/garage context, never during active race. Context beats forced shop.

## Purchase flow
### Pass bundle
Prompt → platform purchase/ownership confirmation using current platform ownership APIs → server synchronizes bundle entitlement/items into `PlayerDataService` idempotently exactly as `71_CATALOG_TRANSACTION_AND_PASS_ENTITLEMENT_CONTRACT.md` → immediate equip/celebration → analytics after confirmed ownership. Rejoin also reconciles owned Pass entitlement so a missed local celebration cannot lose the permanent purchase.

### Developer Product (Coin pack only at launch, if enabled)
Use `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md` exactly: `ProcessReceipt` → same-transaction profile grant + PurchaseId marker → `PurchaseGranted` → analytics. Client UI/prompt completion never grants value.

## Failure
Pending/fail never grants locally. Duplicate receipt cannot duplicate entitlement/currency; `PurchaseGranted` is returned only after the profile transaction confirms an existing or newly written `PurchaseId` marker.


## Launch SKU freeze
Implement exactly the three Pass bundles from `61/62`. Coin Developer Products are pre-defined but disabled until the gate in `61`/`55` is satisfied. Do not invent additional launch SKUs.


## Transaction owners
- Coin-priced cosmetic purchase: `71` only.
- Pass entitlement reconciliation: `71` only.
- Developer Product receipt exact-once: `56` only.

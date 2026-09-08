# 43 — COSMETIC CATALOG & EQUIP RULES
Статус: **COSMETIC CONTRACT v1.3.4**.

## Categories
Body, Ink, Trail, FinishFX, VictoryPose/PodiumFX later. No cosmetic modifies gameplay physics.

## Rarity
Rarity communicates collection/status only; it does not imply power. Suggested tiers: Common, Rare, Epic, Legendary, Event.

## Ownership sources
Soft shop, mastery milestone, event, premium direct purchase/bundle. Every item has exactly one catalog definition and any number of unlock sources referencing it.

## Equip
One item per category. Server validates ownership, profile saves equipped IDs, client previews freely but race presentation uses server-confirmed loadout.

## Fairness test
Every Body uses identical invisible body collider/template. Ink/trail/FX must not obscure obstacles or rivals enough to change competitive readability; excessive FX can be locally reduced.

## Collection pacing
Launch catalog stays small enough that each unlock is visible. Add content by definitions/assets, not new code.


## Launch catalog ownership
The exact public-launch IDs, look, rarity/source and paid bundle grouping are fixed in `62`; exact Coin prices and Robux hypotheses are fixed in `61`. New items after launch follow this rule set and `30` schemas.


## Launch purchase mutation owner
Coin-priced catalog ownership is granted only through atomic transaction contract `71`; Pass-granted ownership is reconciled through `71`; Developer Product grants use `56`. UI cannot directly add ownership.

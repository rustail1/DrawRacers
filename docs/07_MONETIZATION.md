# 07 — MONETIZATION DESIGN — v1.3.4

## Revenue principle
Мы продаём **выражение и статус в публичной соревновательной сцене**, а не шанс победить.

Цепочка:
`игрок увидел ценность визуальной идентичности → захотел выделяться → увидел релевантный оффер → купил → сразу экипировал → следующий lineup/race доказывает ценность перед другими`.

## Social contract
Fair competitive. Если purchase меняет chance-to-win при одинаковом skill — продукт отклоняется.

## 1. First payer target
Не новый игрок на первых секундах.

Exact paid-offer eligibility is owned **only** by `45_MONETIZATION_CATALOG.md`. Strategy invariant: the player must already understand visible cosmetic/status value and G5 must be accepted before paid offers are enabled. Do not duplicate the numeric/behavioral eligibility threshold in this strategy document.

## 2. Core desire
«Хочу, чтобы мой racer выглядел заметнее/смешнее/редче и чтобы другие это видели».

Дополнительная status desire после PMF:
«Хочу presentation, которая показывает мой season/mastery identity».

## 3. First purchase hypothesis
**Starter Style Bundle**:
- distinctive cube body;
- ink/leg visual;
- finish/podium FX;
- exact bundle contents from `61/62`; no bonus Coins in the launch Starter Pass.

Никаких physics benefits.

Trigger: only after the canonical eligibility contract in `45`; post-race/garage context only. Offer frequency/cooldown is tuning in config, not permission to bypass eligibility.

## 4. Price hypotheses
Single source for exact launch price/grant hypotheses: `61_LAUNCH_ECONOMY_PROGRESSION_TABLE.md`.

Working test ladder:
- entry: low-risk first purchase;
- core: themed bundle/strong cosmetic identity;
- premium: richer collection/status expression;
- deep spend: breadth of collections over time, not permanent power.

Price is an experiment, not truth.

## 5. Roblox primitives
### Pass
**Launch owner for permanent Robux cosmetic bundles.** Starter Style / themed style / premium presentation Passes are one-time permanent entitlements and never alter race power. Additional convenience/status Passes are later only if they preserve fairness.

### Developer Products
Launch use is limited to **repeatable cosmetic Coins packs if/when that economy passes its gate**. Any additional repeatable product needs an explicit catalog addition and `56` receipt contract; permanent cosmetic items are not silently implemented as repeatable Developer Products.

### Rewarded Video
Only if platform eligibility and UX justify it. Place in results/lobby, never during active race. Reward = fair cosmetic currency/progress.

### Subscription
Post-PMF only. Example direction: recurring Style Club with monthly cosmetics/status presentation. Do not ship because “Roblox has subscriptions”.

### Paid random items
Not launch scope. If ever considered, treat as separate economy/policy project.

## 6. Context beats Shop
Natural monetization moments:
- previewed locked cosmetic;
- just saw/equipped first free cosmetic;
- completed a themed collection row;
- entered seasonal cosmetic track;
- saw a visually strong item on another racer and opened inspect/garage surface.

Shop remains browse surface, not the only sales path.

## 7. Post-purchase theatre
Within seconds:
1. purchased style appears in preview;
2. one-tap Equip;
3. concise sound/VFX celebration;
4. next lineup visibly presents it;
5. next race renders it without gameplay advantage;
6. grant is idempotent and saved.

## 8. Repeat spend
Repeat need is refreshed by new themes/collections/status expression. Never manufacture pain by degrading free inventory or race quality.

## 9. Explicit forbidden monetization
- +speed;
- +torque/grip;
- longer leg radius;
- smaller hitbox;
- paid redraw advantage;
- paid obstacle/checkpoint skip in public competitive race;
- fake scarcity/discount timers;
- “free version intentionally annoying” inventory limits;
- paywall required to use core drawing.

## 10. Revenue measurement
Primary product questions:
- Does cosmetic desire emerge organically?
- Do offer viewers understand the before→after state?
- Does purchase lead to equip/use?
- Does repeat spend come from new expression rather than frustration?

Metrics:
- first payer conversion;
- offer eligible→shown→prompted→granted;
- equip-after-purchase;
- repeat purchase rate;
- ARPPU/ARPDAU when sample permits;
- spend days/player where relevant.

Guardrails:
- D1/D7/engagement trends;
- race completion;
- rematch;
- perceived fairness/rating;
- free-player cosmetic progression.

## 11. Monetization release gate
Do not optimize monetization before:
- core gate passed;
- multi-race session behavior exists;
- free players already care about cosmetics/status.

Revenue is layered onto proven desire, not used to fabricate it.

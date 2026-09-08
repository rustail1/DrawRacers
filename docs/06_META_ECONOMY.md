# 06 — META, PROGRESSION & ECONOMY — v1.3.4

## Design rule
Meta exists to make the next race more meaningful, not to compensate for weak racing.

## 1. Soft currency — Coins
Primary sources:
- valid heat completion;
- placement bonus;
- first-clear/mastery milestones;
- limited event objectives.

Primary sinks:
- cosmetic bodies;
- ink/leg visual styles;
- trails;
- finish/podium effects;
- victory presentation;
- themed soft-currency bundles.

Coins never buy race physics.

## 2. Three persist lines
### COLLECTION — “что у меня есть”
Visible cosmetics. Goal: ownership and self-expression.

### STATUS — “что я доказал”
Wins, podiums, trophies/mastery, seasonal rank/badges, visible milestones. Status should appear in lineup/results/profile presentation.

### ACCESS — “что я освоил и могу играть”
Harder track pools/challenges/world themes. Unlock via mastery/progression, not paid strength.

## 3. Mastery
Mastery rewards repeated skill expression:
- finish new track family;
- win/podium milestones;
- complete challenge condition;
- demonstrate adaptation on advanced course sets.

Avoid grind-only ×1000 number progression.

## 4. Session ownership target
First healthy session should create at least one visible ownership/status change: free/soft-currency cosmetic equipped, mastery milestone, or visible badge progress.

Exact launch rewards, soft prices, Mastery gains, status thresholds and access tiers: `61_LAUNCH_ECONOMY_PROGRESSION_TABLE.md`. `16` owns global physics/race tuning, not economy item tables.

## 5. Reward philosophy
Winner should feel rewarded, but last place should not conclude “I cannot progress unless already good”. Placement differential is a motivation tool, not a punishment wall.

## 6. No permanent power economy
Explicitly forbidden:
- motor speed;
- torque;
- grip/friction;
- smaller collision body;
- longer max leg radius;
- better redraw latency/cooldown;
- paid checkpoint/obstacle skip in public race.

## 7. Long path
The long path is:
`more skill → harder/more varied course access → more visible status → richer personal collection → new seasonal mastery goals`.

It is not:
`more currency → statistically stronger racer → crush new player`.

## 8. Economy health questions
- Are Coins meaningful without blocking racing?
- Can a free player change visible appearance early?
- Do experienced players still have collection/status goals?
- Does any sink create accidental P2W through collider/visibility advantage?
- Does monetized currency preserve same fair physics?


## 9. Launch progression resolution
At launch, the exact implementation is not left to interpretation:
- reward amounts and DNF participation floor → `61`;
- Mastery Point gains/titles → `61`;
- public access tiers/track-pool selection → `61` + exact pools in `60`;
- cosmetic catalog IDs/art → `62`;
- prices/unlock source → `61`;
- server grant/order/anti-farm → `44`;
- persistent fields → `31`.

Public matchmaking is never split into separate mastery queues; the heat uses the highest track pool allowed by the lowest eligible human tier, as fixed in `61`.

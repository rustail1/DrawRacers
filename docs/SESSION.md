# SESSION.md — CURRENT STATE

Date: 2026-09-09  
Documentation version: **v1.3.4 EXECUTION CONSISTENCY FREEZE**

## Product state
The specification is closed for production: no known documentation-level WHAT/WHY blocker remains for building from an empty repository to a release candidate. v1.3.4 additionally closes the last concrete implementation-choice gaps in UI composition, launch level dimensions, launch economy/progression values and launch art/content identity.

This does **not** pre-prove PTR, retention, social value, cosmetic desire, conversion or revenue. Those outcomes are empirical and use `55`, `57`, `38`, `10/46`.

## Locked product direction
- final product: 8-player live physics drawing race;
- 2-player: integration/acceptance stage only;
- core: draw real legs → move physically → read obstacle → redraw → compare/overtake → finish → fast rematch;
- meta: Collection + Status + Access;
- public cold-start: Bot Fill required;
- monetization: cosmetic/status expression only; zero competitive physics power;
- launch topology: EntryFTUEPlace is start place → safe first-timer T06 → committed tutorial/reward → RacePlace; returning players route directly to RacePlace.

## Newly exact v1.3.4 owners
- UI screen composition / anchors / sizes / source copy → `59`;
- 24 TrackPiece dimensions/ranges + T01–T20 definitions → `60`;
- Coin rewards / MP / access / soft prices / exact launch price hypotheses → `61`;
- title / palette / themes / exact launch cosmetic catalog / launch asset list / discovery A-B-C → `62`;
- place/session routing → `23/30/41`; profile lease + cross-place handoff + exact-once race grants → `31`;
- current final audit → `78`;
- `_HISTORY/` is excluded from normal implementation context.

## Accepted implementation evidence
### A01 — Git repo + Rojo baseline — ACCEPTED (2026-09-09)
Evidence:
- repository `rustail1/DrawRacers`, branch `main`;
- Rokit installs pinned Rojo 7.7.0;
- local `rojo build -o DrawRacersDev.rbxlx` succeeded;
- `rojo serve` listened on `localhost:34872`;
- Roblox Studio connected through Rojo 7.7.0;
- live filesystem → Studio sync verified by creating `src/shared/A01SyncProbe.lua`, observing `ReplicatedStorage/Shared/A01SyncProbe`, then deleting the probe;
- final local `git status` reported `nothing to commit, working tree clean` after Studio lock files were added to `.gitignore`.

### A02 — Shared/config/type + server/client bootstrap roots — ACCEPTED (2026-09-09)
Evidence:
- `src/shared/Config` and `src/shared/Types` exist and sync under `ReplicatedStorage/Shared`;
- `src/server/Bootstrap.server.lua` syncs to `ServerScriptService/Bootstrap`;
- `src/client/Bootstrap.client.lua` syncs to `StarterPlayer/StarterPlayerScripts/Bootstrap`;
- automated A02 structure test passed after implementation (`2 passed`);
- Roblox Studio Play produced `[DrawRacers] server bootstrap ready` and `[DrawRacers] client bootstrap ready`;
- no project bootstrap error was shown in the acceptance screenshot; the remaining orange `user_RojoManagedPlugin...msgpack` native-code-generation warning originates from the Rojo Studio plugin, not from Draw Racers bootstrap scripts.

## Immediate operational step
**A03 — M0 test scene.** A01 and A02 are ACCEPTED. Do not start A04 or gameplay until A03 acceptance passes.

After A03 → A04 are ACCEPTED: **B01 — InputController pointer abstraction**, using the DrawCanvas input rectangle defined in `59`. A04 is mandatory because environment/config/ID placeholders must fail closed before gameplay code begins depending on deployment data.

## ACTIVE gameplay feature
`M0-01 DrawCanvas input + stroke preview = B01+B02` is the only ACTIVE gameplay feature in `FEATURE_LIST.md`.

## Full build chain
A01 ✓ → A02 ✓ → A03 → A04 → B01/B02 → stroke math → one physical leg → motor → two legs → stabilization/lane → authoritative shape → atomic redraw → five-obstacle lab → G0 → adaptation + `60` → G1 → 2-player race/UI → G2 → 8-player slice → STAGING provisioning → PlayerDataService → RewardService → AnalyticsAdapter → canonical BotRacerController FTUE foundation → confirmed Results → CosmeticService → two-place FTUE/routing → Garage/presentation → G3 → T01–T20 + production Bot Fill → G4/G5 → launch Passes → G6 → LiveOps/G7 → final release checks → `78` PASS → release.

## Empirical but procedure-complete
- physics/camera constants: start `16`, tune via `49/55/57`;
- level numbers: start `60`, tune only inside validated ranges unless Decision Log;
- UI layout: start `59`, change only via evidence + owner update;
- economy/prices: start `61`, optimize empirically;
- commercial/live outcomes: `55` + analytics;
- performance: `57`.

## Scope discipline
No Shop, season, party, procedural generator, paid random item or new mechanic may be pulled forward because a gate is weak. Fix the owner layer first. Any WHAT/WHY/scope/fairness change requires Product Owner approval + Decision Log + owner doc + Feature List update.

## v1.3.4 execution freeze additions
Current design/implementation owners now also include `64` platform provisioning, `65` Studio Instance contract, `66` per-task acceptance, `67` level assembly, `68` UI hierarchy, `69` content workflow, `70` deployment IDs, `71` catalog/Pass transactions, `73` exact shape/pivot/collider mapping, `74` heat lifecycle/requeue defaults, `75` bot shape policy, `76` first-30-day LiveOps buffer, and final audit `78`. These are not new gameplay scope.

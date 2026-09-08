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

### A03 — M0 test scene — ACCEPTED (2026-09-09)
Evidence:
- clean synced Studio Play produced `[DrawRacers] A03 M0 test scene ready`;
- the M0 lane rendered with a flat 8-stud-wide physics-lab strip and visible yellow canonical obstacle anchors;
- debug player spawn landed on the lane and the scene booted together with server/client bootstrap without Draw Racers errors;
- A03 config owns the reproducible lane, spawn and representative anchor layout; full obstacle collision geometry remains correctly deferred to B15.

### A04 — deployment/config skeleton + exact Studio roots — ACCEPTED (2026-09-09)
Evidence:
- DEV/STAGING/PROD deployment configs exist with distinct namespaces and all unresolved Roblox Universe/Place/Pass/Product IDs left `nil`, never guessed;
- fail-closed deployment validator and empty asset-registry schema exist in the repository;
- current A04 contract assertions were re-run against the fetched `main` contents and passed `5/5`;
- local `rojo build -o DrawRacersDev.rbxlx` succeeded after A04 changes;
- after terminating the stale Rojo process and reconnecting to the current project, Studio synced the canonical roots, including all six `StarterGui` ScreenGui roots (`RaceHUD`, `DrawHUD`, `ResultsHUD`, `GarageHUD`, `StoreHUD`, `SettingsHUD`);
- visible project bootstrap output remained clean; the orange native-code warning is Rojo-plugin-local and not a Draw Racers runtime error.

### B01 — InputController pointer abstraction — ACCEPTED (2026-09-09)
Evidence:
- Studio harness produced repeated `start → move → end` mouse streams with stable pointer id inside a stroke and incremented id on the next stroke;
- dragging inside the active input target did not rotate the world camera from the same pointer drag in the acceptance capture;
- controller code maps both mouse and touch into the same semantic `start/move/end/cancel` event shape and ignores extra primary input while one pointer is active;
- focus loss/cancel path preserves explicit `cancel` semantics;
- the Luau chained-cast parse bug found during acceptance was fixed and regression-guarded;
- all launch HUD roots now use `ResetOnSpawn=false`, fixing the observed respawn disappearance of the temporary harness/UI.

## Immediate operational step
**B02 — DrawingController local stroke preview.** Implementation is in `main` and awaits Studio acceptance. Acceptance owner row `66`: one continuous preview, exact `DrawInputRect`, and cancel must leave the previous completed local shape intact. B03 must not start until B02 is accepted.

Expected B02 presentation:
- `DrawHUD/SafeRoot/DrawCanvas/DrawInputRect` follows `59/68` hierarchy and desktop/touch sizing;
- drawing produces a continuous local cyan stroke only; no server remote/world geometry exists yet;
- after release, the completed local candidate remains visible and appears in `AcceptedShapeThumbnail`;
- starting a new stroke hides the old main-canvas candidate but keeps the thumbnail; cancel restores the previous completed candidate;
- Output prints `[DrawRacers][B02] local draw preview ready`, completion point count, and cancel-preserved count.

## ACTIVE gameplay feature
`M0-01 DrawCanvas input + stroke preview = B01+B02` is the only ACTIVE gameplay feature in `FEATURE_LIST.md`.

## Full build chain
A01 ✓ → A02 ✓ → A03 ✓ → A04 ✓ → B01 ✓ → B02 → B03/B04/B05 stroke math → one physical leg → motor → two legs → stabilization/lane → authoritative shape → atomic redraw → five-obstacle lab → G0 → adaptation + `60` → G1 → 2-player race/UI → G2 → 8-player slice → STAGING provisioning → PlayerDataService → RewardService → AnalyticsAdapter → canonical BotRacerController FTUE foundation → confirmed Results → CosmeticService → two-place FTUE/routing → Garage/presentation → G3 → T01–T20 + production Bot Fill → G4/G5 → launch Passes → G6 → LiveOps/G7 → final release checks → `78` PASS → release.

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
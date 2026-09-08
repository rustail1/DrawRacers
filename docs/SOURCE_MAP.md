# SOURCE MAP / PROVENANCE

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation stage only. Product power is never sold.

## Course files supplied by user
### L1 — product idea / market
- `kovtun_roblox_gd_L1.pptx`
- `L1_Roblox_Idea_Sheet.txt`
- `L1_Roblox_AI_Idea_Critic_Prompt.txt`

Applied principles: concrete audience; separate demand evidence; negative space; linked verbs; first-five-minutes test; 1/2/5/20 multiplayer test; team-fit; cheapest falsification.

### L2 — process / AI
- `kovtun_roblox_gd_L2.pptx`

Applied: visionary owns WHAT/WHY; feature gates; reference cause not copy; right task granularity; one fact/one place; Feature List + Decision Log + session context; reconnaissance; minimal vertical chain; human Studio acceptance; edge/regression testing.

### L3 — loops / persist / FTUE
- `kovtun_roblox_gd_L3.pptx`

Applied: action/mechanic/feature/loop distinction; core/session/meta/persist; depth > complexity; verb depth maps; cycle outputs feed next cycle; FTUE is miniature real game; timed diagnostics; reference map.

### L4 — monetization
- `kovtun_roblox_gd_L4.pptx`
- `L4_Roblox_Monetization_Sheet.txt`
- `L4_Roblox_AI_Monetization_Critic_Prompt.txt`

Applied: need before offer; state change; fair-play filter; contextual offer; first payer task; price hypothesis; post-purchase theatre; repeat need; Roblox payment primitives are tools not strategy.

### L5 — LiveOps/analytics
- `kovtun_roblox_gd_L5.pptx`
- `L5_Roblox_LiveOps_Sheet.txt`
- `L5_Roblox_LiveOps_AI_Critic_Prompt.txt`

Applied: launch begins living development; four LiveOps directions; update surfaces per loop; measurement plan in mechanics; signal≠problem; prioritize early funnel; measurement contract; config-driven content/event constructor; calendar/buffer; A/B when sample supports.

### Final
- `Roblox_Course_Final_Sheet.txt`
- `Roblox_Course_Final_AI_Critic_Prompt.txt`

Applied as cross-system consistency checklist.

## Game reference research
- User-provided/researched dossier: `Draw Climber → Roblox: полный технический разбор механики, clean-room реализация и план разработки`.
Applied only for observable mechanic/reverse design and clean-room Roblox implementation. Unknown source-code specifics are not treated as facts.

## Fresh external checks (2026-09-02)
- Roblox Creator Hub: monetization, Developer Products, rewarded video, analytics custom events/event types/experiments.
- Roblox Developer Forum announcement: Server Authority full release July 9, 2026.
- Rolimon's/Roblox pages: Draw & Slide; Draw Wheels to Escape; Wheel Drawing Obby; Draw Obby; Draw and compete.

## Reproducible market evidence
`54_MARKET_EVIDENCE_SNAPSHOT.md` is the dated, self-contained market evidence table. It records primary Roblox experience pages plus secondary Rolimon's metrics, and explicitly separates what each reference supports from what it cannot prove. Refresh it before a major greenlight or after a materially changed market.

## Evidence discipline
Labels used by current project decisions:
- SOURCE FACT — directly supported by course/platform/reference.
- OBSERVATION — visible behavior/stat.
- PROJECT DECISION — chosen for this game.
- TUNING / EMPIRICAL VALUE — number/threshold/metric requiring Play Mode or live data.

No unknown Draw Climber internal values are asserted as source facts. Reference precedent is used to lock the high-level mechanic/causal pattern; it is **not** recorded as proof that our exact Roblox execution will be a commercial hit.


## Implementation-method provenance
- Course L2 / development-process slides: source-of-truth separation, WHAT/WHY vs HOW, technical reconnaissance before edits, minimal vertical iteration, human Studio acceptance, regression, Session/Decision Log.
- Current Roblox Creator Hub checked 2026-09-02 for client/server boundary, network ownership, physics assemblies, RemoteEvents, Studio testing modes, AnalyticsService event constraints and DataStoreService.
- Roblox Developer Forum announcement July 9, 2026 confirms Server Authority full release.
- Current Workspace API reference confirms `Workspace.AuthorityMode` / `Enum.AuthorityMode.Server`.


## Additional uploaded Roblox books
- Nathan Tucker, *Make Your Own Roblox Games* (2023): used only for durable general practices such as scope definition, OOP/design-pattern awareness, pooling/caching, profiling, multi-device testing, project management, monetization balance and community/update discipline. API details are treated as potentially stale and are superseded by current Creator Hub.
- Tomas Gonzalez Dominguez, *Mastering Scripting in Roblox Studio*: used only for general modularity, descriptive functions, event cleanup, GUI responsiveness, iterative testing and third-party library security/licensing. Several API/code examples are outdated or inaccurate for current Luau/Roblox; they are NOT authoritative technical references.
- Current Roblox Creator Hub is authoritative for platform APIs, security, DataStores, performance, localization, analytics, safety and publishing.


## Current reference usage rule
See `51_REFERENCE_VALIDATION_STATUS.md`. High-level mechanics/causal loops may be studied and independently implemented. Source code, assets, level layouts, UI expression, branding, audio and proprietary data are outside the copy boundary per `48_IP_CLEANROOM_RELEASE_CHECK.md`.


## Deep-audit verification sources
Current-platform verification performed 2026-09-02 prioritized:
1. official Roblox Creator Hub / Roblox staff announcements for client-server security, DataStore, Server Authority, analytics, testing, performance and monetization;
2. Roblox experience pages for observable reference behavior;
3. Rolimon's only as a secondary dated market-stat tracker.

Key platform pages used in the audit:
- Client/server security: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Network ownership: https://create.roblox.com/docs/scripting/security/network-ownership
- Data stores: https://create.roblox.com/docs/cloud-services/data-stores
- Developer Products: https://create.roblox.com/docs/production/monetization/developer-products
- Studio testing modes: https://create.roblox.com/docs/studio/testing-modes
- MicroProfiler: https://create.roblox.com/docs/performance-optimization/microprofiler/use-microprofiler
- Analytics custom events/fields: https://create.roblox.com/docs/production/analytics/custom-events and https://create.roblox.com/docs/production/analytics/custom-fields
- Server Authority full-release announcement: https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993


## v1.3.4 implementation-closure project decisions
The following are **PROJECT DECISION / implementation contracts**, not claims extracted from competitor code or source material:
- `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md` — exact screen-to-physics coordinate/pivot/collider mapping;
- `74_RACE_LIFECYCLE_TIMEOUT_REQUEUE_DEFAULTS.md` — exact heat timeout/requeue/spectator semantics;
- `75_BOT_SHAPE_POLICY_BEHAVIOR_CATALOG.md` — deterministic bot shape/difficulty policy;
- `76_FIRST_30_DAYS_LIVEOPS_CONTENT_BUFFER.md` — exact launch + first-30-day config buffer.

They exist to remove implementation ambiguity. Their numeric starting values remain subject to the bounded empirical/tuning process in `49/55`, without implying that a reference proved those exact values.

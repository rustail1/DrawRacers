# FEATURE LIST — SCOPE SOURCE OF TRUTH v1.3.4

Statuses: `BACKLOG | ACTIVE | ACCEPTED | CUT | LATER`

**Current milestone:** M0 — Physics Lab  
**Current gameplay feature:** M0-01 — DrawCanvas input + stroke preview = implementation items **B01 + B02**.  
**Exact current implementation item:** **B01 — InputController pointer abstraction**. Bootstrap A01–A04 is ACCEPTED; B02 starts only after B01 acceptance.  
**Rule:** only one gameplay feature may be `ACTIVE` at a time. `SESSION.md` owns the exact current implementation item; `25` owns sequence.

## Bootstrap — required before M0
- ACCEPTED — A01 Git/Rojo baseline
- ACCEPTED — A02 shared/server/client roots
- ACCEPTED — A03 M0 scene
- ACCEPTED — A04 deployment registry + exact Studio root contract (`64/65/70`)

## M0 — Physics Lab
- ACTIVE — DrawCanvas input + stroke preview (`59` layout)
- BACKLOG — Stroke cleaning/simplification/resample
- BACKLOG — Leg collider builder
- BACKLOG — Two-leg hinge locomotion
- BACKLOG — Body stabilization + lane constraint
- BACKLOG — Atomic redraw
- BACKLOG — Five canonical obstacle lab
- BACKLOG — Debug physics/tuning panel
- BACKLOG — G0 record

## M0.5 — Adaptation Acceptance
- BACKLOG — Mixed adaptation test track using `60` geometry
- BACKLOG — Shape-suite protocol
- BACKLOG — Universal-shape failure check
- BACKLOG — G1 record

## M1 — 2-Player Rival Slice
- BACKLOG — TrackPiece contract + TrackBuilder using `30/60`
- BACKLOG — Race state machine
- BACKLOG — Ordered checkpoints / finish authority
- BACKLOG — 2 isolated lanes / no racer collision
- BACKLOG — Rival shape visibility
- BACKLOG — 2-player camera/HUD matching `59`
- BACKLOG — Fast rematch
- BACKLOG — Network/security tests + G2

## M2 — 8-Player Product Vertical Slice
- BACKLOG — 8 lane scaling
- BACKLOG — STAGING two-place provisioning (`64/70`)
- BACKLOG — First 10 authored tracks T01–T10 from `60/67`
- BACKLOG — FTUE
- BACKLOG — Lineup/results/podium exact UI from `59`
- BACKLOG — One-tap requeue
- BACKLOG — Canonical profile/save lifecycle
- BACKLOG — Coins + RewardService with `61` starting table
- BACKLOG — Cosmetic inventory/equip
- BACKLOG — Atomic Coin catalog purchase (`71`)
- BACKLOG — First vertical-slice subset of `62` launch catalog
- BACKLOG — Visible status basics
- BACKLOG — Analytics funnels/events
- BACKLOG — Audio/VFX/haptic semantic presentation (`47/68/69/70`)
- BACKLOG — Settings/accessibility/rival-shape safety controls (`37/39/68`)
- BACKLOG — Mobile performance/network pass + G3

## M3 — Alpha Product Loop / PUBLIC-LAUNCH CONTENT
All items below are **required before public release**, not optional polish.
- BACKLOG — Complete T01–T20 authored tracks and both launch themes (`60/62/67/69`)
- BACKLOG — Mastery Points, access tiers and visible titles (`61`)
- BACKLOG — Garage/collection final layout (`59`) and catalog (`62`)
- BACKLOG — First-session ownership pacing using `61`
- BACKLOG — Required cold-start Bot Fill (`40/74/75`)
- BACKLOG — Full 20 produced launch cosmetics + Trail_None (`62/69/70`)
- BACKLOG — Launch audio/VFX set (`47/62`)
- BACKLOG — G4 session/rematch record
- BACKLOG — Admin/observability (`34`)
- BACKLOG — Save/migration/handoff fault matrix (`31/24`)
- BACKLOG — Content registry/provenance binding (`36/48/69/70`)
- BACKLOG — G5 free cosmetic/status desire record

## M4 — Monetization / Soft Launch
Required for monetized soft launch and intended commercial public release:
- BACKLOG — Three launch Pass SKUs from `61/62`
- BACKLOG — Contextual Starter Style offer
- BACKLOG — Post-purchase theatre
- BACKLOG — Pass entitlement reconciliation (`71`)
- BACKLOG — `56` receipt/idempotency implementation/tests if any Developer Product is enabled
- BACKLOG — Monetization analytics
- BACKLOG — Discovery creative A/B/C from `62` + G6
- BACKLOG — Price/offer experiments after sufficient sample
- LATER — Coin Developer Products activation (predefined but disabled until G5 + explicit enable decision)

## M5 — Release / LiveOps Foundation
Required before full public release:
- BACKLOG — Config-driven public course rotation
- BACKLOG — Cosmetic collection configs
- BACKLOG — Standard LiveOps event constructor/config path
- BACKLOG — Measurement-contract workflow / rollback
- BACKLOG — First 30-day content buffer implementation (`76`)
- BACKLOG — PROD two-place/SKU/asset provisioning (`64/70`)
- BACKLOG — Production release checklist / rollback drill
- BACKLOG — Final device/performance matrix
- BACKLOG — Localization/accessibility pass
- BACKLOG — Safety/moderation pass
- BACKLOG — IP/name/asset provenance clearance
- BACKLOG — G7 content-production record when applicable

## LATER — explicit post-release / data-dependent scope
- LATER — friend/party quality layer
- LATER — private-server-specific features
- LATER — rewarded video
- LATER — subscription
- LATER — seasonal paid progression
- LATER — ranked season/tournament
- LATER — procedural/endless generator
- LATER — console/gamepad drawing UX
- LATER — VictoryPose/PodiumFX category beyond launch FinishFX
- LATER — paid random items

## Explicit CUT unless new Product Owner Decision
- CUT — paid speed/torque/grip/radius/hitbox/redraw advantage
- CUT — racer-vs-racer physical collisions
- CUT — combat/weapons
- CUT — free-form public drawing/art publishing
- CUT — pets as stat power
- CUT — rebirth/stat simulator
- CUT — mandatory gacha
- CUT — giant lobby delaying first race
- CUT — battle pass before explicit post-launch need

## Production completeness — release blockers
Every item must be ACCEPTED or explicitly CUT by Product Owner Decision before public release:
- BACKLOG — Save migrations/recovery (`31`)
- BACKLOG — Security threat-model pass (`32`)
- BACKLOG — 8-player performance/device matrix (`33/57`)
- BACKLOG — Rival drawing safety controls (`39`)
- BACKLOG — Release/rollback playbook validation (`35`)
- BACKLOG — Localization/accessibility (`37/59`)
- BACKLOG — Discovery creative pack (`38/62`)
- BACKLOG — UI screenshot matrix (`59`)
- BACKLOG — Exact launch TrackPiece/content validation (`60`)
- BACKLOG — Economy/progression table implementation (`61`)
- BACKLOG — Launch art/content manifest complete (`62/69/70`)
- BACKLOG — Empirical gates G0–G7 as required (`55`)
- BACKLOG — Coin catalog + Pass entitlement transaction tests (`71`)
- BACKLOG — Developer Product receipt tests if enabled (`56`)
- BACKLOG — Current final documentation audit (`78`) remains PASS after any spec change

Any unlisted feature requires a scope decision before documentation/implementation.
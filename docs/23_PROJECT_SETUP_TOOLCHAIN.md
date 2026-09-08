# 23 — PROJECT SETUP & TOOLCHAIN

Статус: **PROJECT BOOTSTRAP GUIDE v1.3.4**

Цель: создать проект так, чтобы работа через Codex/Rojo/Studio оставалась воспроизводимой и контролируемой.

---

## 1. Repository layout

Recommended filesystem:
```text
repo/
├── src/
│   ├── shared/
│   ├── server/
│   └── client/
├── assets/              # only source/config references safe for repo
├── tests/
├── docs/                # этот Development Bible
├── default.project.json # Rojo mapping
├── AGENTS.md
└── README.md
```

Actual Roblox Instances/3D assets may live in Studio/asset pipeline where appropriate, but scripts/configs should remain searchable/versioned.

---

## 2. Rojo mapping target

Filesystem should map to the DataModel contract in `21_SYSTEM_CLASS_ARCHITECTURE.md` and exact Instance/property/collision contract in `65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md`.

Do not create two competing hierarchies: one in filesystem and another manually in Studio with duplicate scripts.

---

## 3. Version control

Minimum:
- Git repository before production changes;
- small commits matching accepted observable steps;
- no giant unreviewable AI commit;
- commit after human acceptance, not after every failed experiment;
- tags/releases at accepted milestones.

Recommended branch convention for solo work:
```text
main
feature/m0-stroke-input
feature/m0-leg-builder
...
```

Short-lived branches only; do not create process overhead if solo.

---

## 4. Studio project baseline

Before M0 implementation:
- clean place;
- `Workspace.Runtime` containers;
- test lane and obstacle lab area;
- camera test spawn/anchor;
- Output/Developer Console clean baseline;
- Server Authority setting documented for later M1 activation/testing;
- collision groups naming reserved;
- target device emulation presets noted and real-device acceptance matrix linked to `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md`.

---


## 4A. Experience topology — launch contract

The published Roblox experience contains exactly two places:

1. **`EntryFTUEPlace` — start place.** Every normal experience join lands here. After profile load, a first-time player (`Tutorial.Completed=false`) stays and runs controlled T06 FTUE; an already-onboarded player is server-routed to `RacePlace`. Paid offers are disabled here.
2. **`RacePlace` — public continuous-heats place.** Returning/onboarded players race here. A player who reaches it directly with a safely loaded `Tutorial.Completed=false` profile is routed back to `EntryFTUEPlace` before public roster insertion.

Both places are in the same experience and use the same codebase/config schemas/profile definition. `PlaceConfig.PlaceMode` and environment PlaceIds distinguish deployment, not forked gameplay code. Exact lifecycle = `41_MATCHMAKING_SERVER_LIFECYCLE.md`.

STAGING must publish/test both places before M2 FTUE acceptance. A one-place local Studio harness may be used for M0/M1 physics work, but it cannot satisfy the M2 onboarding gate.

## 5. Collision groups

Reserve semantic groups rather than per-player groups if possible:
```text
Track
RacerBody
RacerLeg
RacerGhostVisual
Decoration
Trigger
```

Goal:
- own body/leg interaction explicitly controlled;
- racers do not collide with other racers;
- decoration never affects race physics;
- triggers do not create unintended physical contacts.

Exact matrix is implemented/tested at M0/M1 and documented in the physics Decision Log.

---

## 6. Config strategy

All tunable runtime values must be centralized in Config modules, not scattered literals.

Design defaults originate from `16_BALANCE_TUNING.md` until code config exists. Once config modules are introduced, **live implementation values are read from Config modules**, and `16_BALANCE_TUNING.md` becomes rationale/range/history rather than a second competing runtime table.

Every tuning change records test context.

---

## 7. Type safety

Use Luau type annotations for public module contracts and data payloads where practical.

Strongly type:
- StrokePoint/StrokePayload;
- ShapeSpec;
- TrackDefinition;
- RacePhase;
- RaceResult;
- Profile data;
- Remote payload validators.

Do not over-engineer type frameworks before M0 core works.

---

## 8. Logging/debugging

M0 requires a debug/tuning surface capable of showing at least:
- current shapeVersion;
- simplified point count;
- collider segment count;
- body speed;
- motor angular velocity target;
- stuck state;
- lane deviation;
- current checkpoint/progress.

Debug UI is Studio/dev-only and not part of player HUD.

---

## 9. Test environments

Use multiple Studio modes deliberately:

### Solo/Test
Pure core feel, camera, input, physics.

### Client/Server toggle
Confirm client-only vs server-only objects/state.

### Start Server + 2 Players
Mandatory from M1.

### Start Server + target 8 players
Mandatory at M2 performance/network gate.

### Published two-place STAGING
Mandatory at M2 FTUE gate: new profile join stays in EntryFTUEPlace → T06 → finish persist → RacePlace; returning profile EntryFTUEPlace → RacePlace; direct RacePlace first-timer → EntryFTUEPlace; teleport failure/retry path.

### Device emulation / real mobile
Mandatory for DrawCanvas and final M2 acceptance.

---

## 10. Publishing environments

Required environment topology is `64`: separate DEV/STAGING/PROD experiences, each with EntryFTUEPlace + RacePlace, and all generated IDs owned by `70`. Local Studio remains the fastest iteration surface; published STAGING is mandatory for teleport/DataStore/analytics/platform purchase behavior; PROD is provisioned/bound before I05 and remains non-public until final audit.

Never test real monetization grants by improvising production state without a test plan.

---

## 11. AI context package per task

Codex receives only:
1. `AGENTS.md`;
2. `FEATURE_LIST.md` excerpt/current status;
3. one or two relevant specs;
4. relevant source code;
5. relevant Decision Log;
6. `SESSION.md`;
7. acceptance criteria.

Do not paste all 30 documents into every task.

---

## 12. First repository bootstrap tasks

Before M0-01:
1. Create repo/Rojo project.
2. Create target folders.
3. Add Shared Types/Config skeletons only where needed by active feature.
4. Add `Bootstrap.server.lua` and `Bootstrap.client.lua` minimal roots.
5. Create test place structure.
6. Confirm Rojo sync round-trip.
7. Create `config/deploy/dev.env.lua`, `staging.env.lua`, `prod.env.lua` and `assets/asset_registry.lua` skeletons per `70` with no fake numeric IDs.
8. Commit clean baseline.

Do not instantiate empty M4 services at bootstrap.

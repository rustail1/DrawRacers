# 35 — RELEASE, DEPLOYMENT & OPERATIONS
Статус: **SHIP PLAYBOOK v1.3.4**.

## Environments
Use the exact DEV/STAGING/PROD topology and two-place provisioning contract in `64`; deployment IDs/config are owned only by `70`. Production DataStore access from Studio is prohibited by project policy.

## Branch/release flow
feature branch → local/Studio tests → merge dev → STAGING publish → smoke + multi-client + mobile → release tag → PROD publish.

## Pre-publish gate
- `24_TESTING_QA_MATRIX` passed for changed systems;
- no new errors/warnings in critical path;
- config validation clean;
- 8-player/bot soak + `57` device/performance matrix when race/physics changed;
- enabled monetization SKU mappings (`30/70`) validated for the target environment;
- Coin catalog transaction + Pass entitlement regression (`71`) if catalog/Pass flow changed;
- `56` receipt duplicate/retry/crash-path tests if Developer Products/monetization changed;
- analytics events verified in published staging if instrumentation changed;
- required empirical gate records from `55` reviewed for the changed layer;
- Content Maturity/Compliance answers reviewed when content changed;
- assets moderation-ready and owned by correct creator/group.

## Rollback
Code/place rollback and data rollback are separate procedures. Keep previous known-good place version/config. If profile migration is not backward compatible, rollback plan must be written before release.

## After publish
Monitor first hour and first day: errors, crashes, server performance, early funnel, purchase errors. Freeze unrelated releases while investigating severe regressions.

## Emergency severity
P0: data loss/duplication, exploit economy, mass crash, purchase grant failure → disable affected feature/rollback. P1: race fairness/perf severe → rollback or flag off. P2: presentation/content issue → scheduled patch.


## v1.3.4 final production freeze blockers
Public release is blocked unless all are true:
- UI screenshot matrix in `59` PASS;
- T01–T20/default ranges/content validation in `60` PASS;
- runtime economy/progression config equals approved `61` values or has logged tuning decision;
- launch title/themes/20 produced cosmetics/audio/VFX/discovery asset checklist in `62` complete;
- `48` name/IP/provenance clearance PASS;
- `57` device/performance matrix PASS;
- `78_FINAL_EXECUTION_CONSISTENCY_AUDIT_v1.3.4.md` remains PASS after last spec/build-contract change;
- PROD platform provisioning/registry `64/70` is fully resolved and private smoke-tested.


## Two-place atomic compatibility
Launch topology is `EntryFTUEPlace` + `RacePlace` (`23/41`). A production release is not complete until **both** places are published with schema-compatible code/config.
- publish STAGING versions of both and run routing matrix first;
- deploy profile migrations/backward-compatible code before depending on a new field;
- during rolling publish, either place must safely understand the profile version written by the other;
- verify `EntryFTUEPlaceId`/`RacePlaceId`, PlaceMode and monetization-disabled FTUE config before enabling acquisition;
- rollback restores a compatible pair, not only one place.

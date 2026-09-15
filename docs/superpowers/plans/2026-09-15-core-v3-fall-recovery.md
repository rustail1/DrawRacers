# Core V3 Fall Recovery Implementation Plan

> **For agentic workers:** Execute inline in the current local workspace. Do not use Git or subagents.

**Goal:** Recover one fallen Core V3 racer to its saved spawn without replacing its accepted mechanics or adding locomotion assistance.

**Architecture:** `FallRecovery` owns only threshold detection and the bounded respawn transaction. `RacerRuntime` owns its lifecycle and supplies the existing body/model/leg/lane APIs; no legacy recovery path is reused.

**Tech Stack:** Roblox Luau, Rojo, existing StudioSpecRunner contract.

**Spec:** `docs/DECISION_LOG_CORE_V3_FALL_RECOVERY_2026-09-15.md`

## Global Constraints

- Local files only; no Git, Studio or Play.
- `PivotTo` is allowed only for explicit out-of-bounds recovery.
- No AntiStall, obstacle recovery, mover or +X helper.
- Preserve the same racer, accepted ShapeSpec, shared axle, one hinge and rider anchor.

### Task 1: Regression and recovery owner

**Files:**
- Create: `src/server/Tests/C08CoreV3FallRecoverySpec.lua`
- Create: `src/server/Runtime/CoreV3/FallRecovery.lua`
- Modify: `src/server/Bootstrap.server.lua`
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Modify: `src/server/Runtime/CoreV3/LegCoreConfig.lua`

**Interfaces:**
- Consumes: `RacerRuntime` body/model/leg/lane getters and saved spawn CFrame.
- Produces: `FallRecovery.new(racer, respawnCFrame, laneCenterZ)`, `GetRecoveryCount()`, `Destroy()`.

- [ ] Add C08 asserting one threshold recovery, same model/checkpoint/lane, cleared body velocity, one hinge, same ShapeSpec and RiderAnchor, ACTIVE motor, no +X helper and no loop.
- [ ] Verify expected RED because `FallRecovery` and its RacerRuntime lifecycle are absent.
- [ ] Implement the threshold latch and recovery transaction without forces.
- [ ] Wire lifecycle creation/destruction in `RacerRuntime` and add the bounded config.
- [ ] Run the static C01–C08 gate, `rojo build`, and self-review; leave runtime physics for the human Studio gate.

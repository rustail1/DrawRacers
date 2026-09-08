# B12 Stroke Remotes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the exact `SubmitStroke` / `StrokeResult` request-result boundary between `DrawingController` and authoritative B11 `LegShapeService`, including stale/rate/malformed/payload guards.

**Architecture:** Keep network ownership inside the existing `LegShapeService` owner boundary instead of inventing a new server service. Add exact RemoteEvents in the Rojo DataModel, a shared semantic name registry, a testable per-player submit processor with injected racer resolver/clock, and client request/result handling. D05 `RacerService` is not implemented; production server binding waits for a real resolver while B12 Studio tests inject one.

**Tech Stack:** Roblox Luau strict mode, Rojo 7.7.0, RemoteEvent, shared `StrokeMath`, Python self-contained contract runner `verify.py`.

**Spec:** `docs/superpowers/specs/2026-09-09-b12-stroke-remotes-design.md`

## Global Constraints

- Remote surface is exactly `SubmitStroke` and `StrokeResult`; no generic RPC.
- Client payload is `{sequence=integer, points={{x=number,y=number},...}}` only.
- Server raw-point hard cap = `96`.
- Server submit cooldown = `0.20s`.
- Server payload hard cap = `4096` bytes.
- Client never authors Instances, CFrame, segmentPlan, ShapeVersion, world geometry, rewards, or another racer target.
- B11 remains authoritative for clamp/dedupe/RDP/resample/min-length/radial/segment-plan/build.
- Rejected/stale/rate-limited requests do not remove current accepted shape or increment ShapeVersion.
- B13 atomic physical swap is out of scope.

---

### Task 1: Lock the exact DataModel/network contract

**Files:**
- Create: `tests/test_b12_stroke_remotes.py`
- Create: `src/shared/Net/RemoteNames.lua`
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `default.project.json`

**Interfaces:**
- Produces: `RemoteNames.SubmitStroke == "SubmitStroke"`, `RemoteNames.StrokeResult == "StrokeResult"`.
- Produces: `PhysicsConfig.StrokeProcessing.StrokeSubmitCooldown = 0.20` and `MaxStrokePayloadBytes = 4096`.
- Produces: `ReplicatedStorage.Remotes.SubmitStroke` and `.StrokeResult` as `RemoteEvent` instances.

- [ ] **Step 1: Write the failing Python contract test**

Create `tests/test_b12_stroke_remotes.py` with checks equivalent to:
```python
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]


def test_b12_exact_remote_tree_and_names():
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    remotes = project["tree"]["ReplicatedStorage"]["Remotes"]
    assert remotes["SubmitStroke"]["$className"] == "RemoteEvent"
    assert remotes["StrokeResult"]["$className"] == "RemoteEvent"
    assert set(k for k in remotes if not k.startswith("$")) == {"SubmitStroke", "StrokeResult"}

    names = (ROOT / "src/shared/Net/RemoteNames.lua").read_text(encoding="utf-8")
    assert 'SubmitStroke = "SubmitStroke"' in names
    assert 'StrokeResult = "StrokeResult"' in names
    for forbidden in ["GenericRPC", "SetProperty", "SpawnThing", "RemoteFunction"]:
        assert forbidden not in names


def test_b12_transport_defaults():
    config = (ROOT / "src/shared/Config/PhysicsConfig.lua").read_text(encoding="utf-8")
    assert "StrokeSubmitCooldown = 0.20" in config
    assert "MaxStrokePayloadBytes = 4096" in config
```

- [ ] **Step 2: Run RED**

Run:
```bash
python verify.py
```
Expected: B12 tests fail because the RemoteEvents/name registry/defaults do not yet exist.

- [ ] **Step 3: Add minimal DataModel/config implementation**

`src/shared/Net/RemoteNames.lua`:
```lua
--!strict
return {
    SubmitStroke = "SubmitStroke",
    StrokeResult = "StrokeResult",
}
```

Add under `StrokeProcessing` in `PhysicsConfig.lua`:
```lua
StrokeSubmitCooldown = 0.20,
MaxStrokePayloadBytes = 4096,
```

Change `default.project.json` `ReplicatedStorage.Remotes` to:
```json
"Remotes": {
  "$className": "Folder",
  "SubmitStroke": { "$className": "RemoteEvent" },
  "StrokeResult": { "$className": "RemoteEvent" }
}
```

- [ ] **Step 4: Run GREEN for contract suite**

Run:
```bash
python verify.py
```
Expected: Task-1 B12 tests pass and no previous contract regression appears.

- [ ] **Step 5: Commit**

```bash
git add tests/test_b12_stroke_remotes.py src/shared/Net/RemoteNames.lua src/shared/Config/PhysicsConfig.lua default.project.json
git commit -m "test: lock B12 stroke remote contract"
```

---

### Task 2: Add testable authoritative submit processor inside LegShapeService

**Files:**
- Modify: `src/server/Services/LegShapeService.lua`
- Create: `src/server/Tests/B12StrokeRemoteSpec.lua`
- Modify: `tests/test_b12_stroke_remotes.py`

**Interfaces:**
- Consumes: existing `LegShapeService.ValidateAndBuild(racerRuntime, rawPoints, motorEnabled?)`.
- Produces: `LegShapeService.CreateSubmitProcessor(deps)`.
- Processor method: `processor:Handle(playerKey, payload) -> StrokeResult?`.
- `deps.resolveRacer(playerKey) -> RacerRuntime?`.
- `deps.now() -> number`; defaults to `os.clock` when omitted.

- [ ] **Step 1: Add failing Studio behavior spec and static assertions**

`B12StrokeRemoteSpec.lua` creates one B11 `RacerRuntime`, an injected clock variable, and a processor whose resolver returns that racer only for one test player key. Required cases:
```lua
local accepted = processor:Handle(TEST_PLAYER, {
    sequence = 1,
    points = {
        {x = -0.72, y = 0},
        {x = 0, y = 0.72},
        {x = 0.72, y = 0},
        {x = 0, y = -0.72},
    },
})
assert(accepted and accepted.accepted == true and accepted.sequence == 1)
assert(accepted.shapeVersion == 1)
```

Then assert:
- same `sequence=1` => `STALE_SEQUENCE`, ShapeVersion remains 1;
- valid `sequence=2` inside 0.20s => `RATE_LIMITED`, ShapeVersion remains 1;
- after advancing injected clock by >=0.20s, malformed point string => `MALFORMED_POINTS`;
- NaN/Inf => `NON_FINITE_POINT` or transport `MALFORMED_POINTS` only if type is wrong; never accepted;
- dense array count 97 => `TOO_MANY_POINTS`;
- canonical serialized payload >4096 => `PAYLOAD_TOO_LARGE`;
- unresolved player => `NO_RACER`;
- valid newer request after cooldown => accepted with ShapeVersion exactly 2;
- malformed/missing/non-integer sequence => nil/no fabricated echo result;
- print `[DrawRacers][B12] SubmitStroke/StrokeResult tests PASS`.

Extend Python test to require tokens:
```python
service = (ROOT / "src/server/Services/LegShapeService.lua").read_text(encoding="utf-8")
for token in ["CreateSubmitProcessor", "STALE_SEQUENCE", "RATE_LIMITED", "PAYLOAD_TOO_LARGE", "NO_RACER", "MaxStrokePayloadBytes", "StrokeSubmitCooldown"]:
    assert token in service
for forbidden in ["Instance.new(\"Part\")", "CFrame.new(", "RemoteFunction"]:
    assert forbidden not in service
```

- [ ] **Step 2: Run RED**

Run:
```bash
python verify.py
```
Expected: fail because `CreateSubmitProcessor` and B12 server spec are absent.

- [ ] **Step 3: Implement the minimal processor**

Inside `LegShapeService.lua`, add a bounded validator that:
- validates payload/sequence before iterating points;
- rejects non-dense/non-table point arrays;
- stops counting immediately above 96;
- requires each point table to contain finite numeric `x` and `y` and no authoritative world objects;
- rebuilds a canonical bounded table `{sequence=sequence,points={{x=...,y=...}}}`;
- uses `HttpService:JSONEncode(canonicalPayload)` only after count/type bounding and rejects `#encoded > 4096`;
- checks per-player stale/pending state;
- checks cooldown from injected `now()`;
- converts bounded point tables to `Vector2` only after transport validation;
- invokes `ValidateAndBuild`;
- advances `lastAcceptedSequence` only for accepted B11 result;
- returns only `{sequence, accepted, shapeVersion? , rejectReasonCode?}`.

Do not expose `shapeSpec` in network result.

- [ ] **Step 4: Run contract GREEN**

Run:
```bash
python verify.py
```
Expected: all Python B12 contracts pass.

- [ ] **Step 5: Commit**

```bash
git add src/server/Services/LegShapeService.lua src/server/Tests/B12StrokeRemoteSpec.lua tests/test_b12_stroke_remotes.py
git commit -m "feat: add B12 authoritative stroke submit processor"
```

---

### Task 3: Wire exact RemoteEvents without implementing D05 RacerService

**Files:**
- Modify: `src/server/Services/LegShapeService.lua`
- Modify: `src/server/Tests/B12StrokeRemoteSpec.lua`
- Modify: `src/server/Bootstrap.server.lua`
- Modify: `tests/test_b12_stroke_remotes.py`

**Interfaces:**
- Produces: `LegShapeService.BindRemotes(deps) -> connection`.
- `deps.submitStroke: RemoteEvent`.
- `deps.strokeResult: RemoteEvent`.
- `deps.resolveRacer(player) -> RacerRuntime?`.
- Binding calls `StrokeResult:FireClient(player, result)` only when processor returns a result.

- [ ] **Step 1: Add failing binding assertions**

Python requires:
```python
assert "BindRemotes" in service
assert "OnServerEvent:Connect" in service
assert "FireClient" in service
assert "B12StrokeRemoteSpec" in bootstrap
assert "B12StrokeRemoteSpec.run()" in bootstrap
```

Studio spec verifies actual instances:
```lua
local remotes = ReplicatedStorage:WaitForChild("Remotes")
assert(remotes:WaitForChild("SubmitStroke"):IsA("RemoteEvent"))
assert(remotes:WaitForChild("StrokeResult"):IsA("RemoteEvent"))
assert(remotes:FindFirstChildWhichIsA("RemoteFunction") == nil)
```

- [ ] **Step 2: Run RED**

Run `python verify.py`; expect B12 binding assertions to fail.

- [ ] **Step 3: Implement binding**

`BindRemotes` creates one processor from injected resolver/clock and connects exactly `SubmitStroke.OnServerEvent`. It fires only `StrokeResult`. Do not wire a production resolver in bootstrap yet; bootstrap only runs the Studio behavior spec. D05 later supplies the real Player→Racer mapping.

- [ ] **Step 4: Run GREEN**

Run `python verify.py`; expect all contract checks green.

- [ ] **Step 5: Commit**

```bash
git add src/server/Services/LegShapeService.lua src/server/Tests/B12StrokeRemoteSpec.lua src/server/Bootstrap.server.lua tests/test_b12_stroke_remotes.py
git commit -m "feat: wire B12 stroke RemoteEvents"
```

---

### Task 4: Connect DrawingController request/result semantics

**Files:**
- Modify: `src/client/Controllers/DrawingController.lua`
- Modify: `src/client/Bootstrap.client.lua`
- Modify: `tests/test_b12_stroke_remotes.py`

**Interfaces:**
- `DrawingController.new(inputController, drawHud, submitStroke, strokeResult)`.
- Uses shared `StrokeMath` and `PhysicsConfig` to pre-clean client payload for bandwidth; server repeats all authority checks.
- Client state: `_nextSequence`, `_latestSubmittedSequence`, `_pendingStrokes[sequence]`, `_resultConnection`.

- [ ] **Step 1: Add failing client contract assertions**

Python requires tokens equivalent to:
```python
for token in [
    "SubmitStroke", "StrokeResult", "FireServer", "OnClientEvent",
    "sequence", "points", "StrokeMath.Normalize", "StrokeMath.Clamp",
    "StrokeMath.Dedupe", "StrokeMath.SimplifyRDP", "StrokeMath.Resample",
    "acceptedPoints", "_pendingStrokes",
]:
    assert token in drawing
```

Also assert `Bootstrap.client.lua` obtains both exact remotes and passes them into `DrawingController.new`.

- [ ] **Step 2: Run RED**

Run `python verify.py`; expect client B12 assertions to fail.

- [ ] **Step 3: Implement request path**

On pointer end with >=2 local points:
1. copy pixel points into `pendingPixels`;
2. call `StrokeMath.Normalize(pendingPixels, DrawInputRect.AbsoluteSize)`;
3. clamp to `[-1,1]`;
4. dedupe/RDP/resample using `PhysicsConfig.StrokeProcessing` defaults;
5. convert to semantic point tables `{x=point.X,y=point.Y}`;
6. increment sequence once;
7. save `pendingPixels` under that sequence;
8. `SubmitStroke:FireServer({sequence=sequence, points=payloadPoints})`;
9. clear live layer and restore prior accepted layer; do not promote pending stroke yet.

- [ ] **Step 4: Implement result path**

On `StrokeResult.OnClientEvent(result)`:
- ignore non-table/mismatched/older sequence results;
- if matching accepted: promote stored pending pixel stroke to `acceptedPoints`, render accepted/thumbnail, clear validation toast;
- if rejected: leave `acceptedPoints` unchanged, keep previous accepted render, show `rejectReasonCode` in `ValidationToast`;
- remove handled pending entry;
- if there is still no accepted shape after rejection, restore `EmptyGhost` visibility.

`Destroy()` disconnects `_resultConnection` and clears pending state.

- [ ] **Step 5: Run GREEN**

Run:
```bash
python verify.py
```
Expected: all static contracts, including historical B01–B11, have zero failures.

- [ ] **Step 6: Commit**

```bash
git add src/client/Controllers/DrawingController.lua src/client/Bootstrap.client.lua tests/test_b12_stroke_remotes.py
git commit -m "feat: connect DrawingController to B12 stroke remotes"
```

---

### Task 5: Fresh verification and Studio acceptance handoff

**Files:**
- Review only: all B12 files above.

- [ ] **Step 1: Run full local static suite**

```bash
python verify.py
```
Expected: `Contract checks: <N> passed, 0 failed`.

- [ ] **Step 2: Build Rojo project**

```bash
rojo build -o DrawRacersDev.rbxlx
```
Expected: exit code 0.

- [ ] **Step 3: Studio Play acceptance**

After Rojo sync, Stop → Play. Required server output:
```text
[DrawRacers][B11] authoritative LegShapeService tests PASS
[DrawRacers][B12] SubmitStroke/StrokeResult tests PASS
[DrawRacers] server bootstrap ready
```
No DrawRacers red error is allowed.

- [ ] **Step 4: Manual client semantic check**

Draw one valid stroke. Until an accepted `StrokeResult` arrives, the previously accepted preview remains authoritative. A rejected result must preserve it. Because D05 real player→racer mapping is not implemented, B12 does not claim full public-play network acceptance from a real racer yet; the injected Studio server processor is the B12 behavior gate.

- [ ] **Step 5: Record actual evidence only**

Do not mark B12 accepted from static inspection. Record Studio PASS only after the user supplies the required output/evidence.

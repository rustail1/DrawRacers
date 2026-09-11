# R17.0 + R17.1 Contract Reconciliation and RMB Camera Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconcile DrawRacers docs with the approved R17 reference-first override and make desktop RMB free-look reliably claim/capture/release camera input without stealing LMB drawing.

**Architecture:** Keep the existing `RaceCameraController` as the single client camera owner. R17.0 is documentation/sequence reconciliation only; R17.1 adds bounded mouse-orbit lifecycle state inside that controller, reusing existing UI hit testing and `CameraMath`. No new service/controller/remote is introduced.

**Tech Stack:** Roblox Luau, Rojo, Python contract tests, GitHub Actions/Rokit/Rojo build.

**Spec:** `docs/superpowers/specs/2026-09-11-r17-reference-core-design.md`

## Global Constraints

- Work directly on `main` only; no branch/PR for DrawRacers unless Product Owner changes policy.
- Server remains authoritative for stroke/ShapeSpec; camera remains client-only.
- Network payload/remotes unchanged.
- LMB remains drawing input; RMB is camera orbit only.
- Touch ownership behavior remains unchanged in R17.1.
- No leg/body physics, motor, phase, rider pose, track, or economy changes in this plan.
- Human Studio camera feel remains pending after automated GREEN.

---

### Task 1: R17.0 contract reconciliation

**Files:**
- Create: `docs/DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md`
- Modify: `docs/16_BALANCE_TUNING.md`
- Modify: `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`
- Modify: `docs/25_IMPLEMENTATION_SEQUENCE.md`
- Modify: `docs/SESSION.md`

**Interfaces:**
- Consumes: approved R17 design and current implemented camera/rider owners.
- Produces: one canonical sequence override stating R17 is authorized before B17 while first-point mechanical origin remains unchanged until R17.3/R17.4 evidence.

- [ ] **Step 1: Add R17 Decision Log**

Record:

```text
Status = APPROVED PRODUCT OWNER OVERRIDE / HUMAN EVIDENCE PENDING
R17.0 -> R17.8 ordered before B17 acceptance
RaceCameraController = current M0 production owner under R17
RiderPresentationController = current provisional M0 presentation owner under R17
D09/E03 become later multiplayer/readability extensions
first-point origin remains current until R17.3 evidence + R17.4 explicit decision
C01+ remains unauthorized
```

- [ ] **Step 2: Reconcile numeric/architecture/sequence docs**

`16`: replace “future D09 only” camera wording with current R17 production owner wording; preserve all numeric camera defaults.

`21`: replace future-only amendment with R17 override note; preserve `RacerService` D05 boundary.

`25`: insert R17.0–R17.8 before B17 and redefine D09/E03 as extensions of existing owners, not first introduction.

`SESSION`: record R17 as current work item, keep all human gates pending, and record current implemented Camera/Rider without claiming feel acceptance.

- [ ] **Step 3: Verify docs do not fabricate acceptance**

Search manually/contractually for R17 wording and ensure no `PASS`/`ACCEPTED` is asserted for camera feel, rider pose, leg origin, physics feel, or B17.

- [ ] **Step 4: Commit**

```bash
git add docs/DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md docs/16_BALANCE_TUNING.md docs/21_SYSTEM_CLASS_ARCHITECTURE.md docs/25_IMPLEMENTATION_SEQUENCE.md docs/SESSION.md
git commit -m "docs: authorize R17 reference-core sequence"
```

---

### Task 2: R17.1 RED camera ownership contract

**Files:**
- Modify: `tests/test_camera_rider_presentation.py`

**Interfaces:**
- Consumes: current `RaceCameraController` public/internal lifecycle.
- Produces: regression assertions requiring explicit mouse capture/restore and allowing eligible RMB to bypass blanket `gameProcessed` rejection without weakening UI/text ownership.

- [ ] **Step 1: Add failing regression assertions**

Require the camera controller to contain/use:

```python
assert "GetFocusedTextBox" in camera
assert "MouseBehavior" in camera
assert "Enum.MouseBehavior.LockCurrentPosition" in camera
assert "_previousMouseBehavior" in camera
assert "_beginMouseOrbit" in camera
assert "_endMouseOrbit" in camera
assert "WindowFocusReleased" in camera
```

Also parse the `InputBegan` body and assert the MouseButton2 path is considered before any generic `gameProcessed` return, while touch still has processed/UI protection.

- [ ] **Step 2: Run contract verification and confirm RED**

Run:

```bash
python verify.py
```

Expected: only the new R17.1 camera ownership assertions fail because current camera lacks explicit mouse capture/restore and still has blanket `gameProcessed` rejection.

- [ ] **Step 3: Commit RED**

```bash
git add tests/test_camera_rider_presentation.py
git commit -m "test: cover R17 RMB camera ownership"
```

---

### Task 3: R17.1 minimal camera implementation

**Files:**
- Modify: `src/client/Controllers/RaceCameraController.lua`

**Interfaces:**
- Consumes: `UserInputService`, existing `_pointOwnedByUI`, `findLocalRacerBody`, existing orbit math.
- Produces: `_beginMouseOrbit()`, `_endMouseOrbit()`, and deterministic state restoration for RMB ownership.

- [ ] **Step 1: Add mouse-orbit lifecycle state**

State:

```lua
_previousMouseBehavior = nil :: Enum.MouseBehavior?
```

Add:

```lua
function RaceCameraController:_beginMouseOrbit()
    if self._mouseOrbitHeld then return end
    self._previousMouseBehavior = UserInputService.MouseBehavior
    self._mouseOrbitHeld = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

function RaceCameraController:_endMouseOrbit()
    if not self._mouseOrbitHeld and self._previousMouseBehavior == nil then return end
    self._mouseOrbitHeld = false
    local previous = self._previousMouseBehavior
    self._previousMouseBehavior = nil
    if previous ~= nil then
        UserInputService.MouseBehavior = previous
    end
end
```

- [ ] **Step 2: Make camera ownership eligibility explicit**

Add a helper using existing UI hit testing plus text focus:

```lua
function RaceCameraController:_worldCameraInputAllowed(position: Vector2): boolean
    if UserInputService:GetFocusedTextBox() ~= nil then
        return false
    end
    return not self:_pointOwnedByUI(position)
end
```

Do not add a camera RemoteEvent or generalize `InputController`.

- [ ] **Step 3: Reorder desktop InputBegan logic**

Required logic:

```text
if no local racer -> return
if MouseButton2:
    get mouse position
    if world camera input allowed -> begin mouse orbit
    return
if gameProcessed -> return
if Touch -> preserve existing touch ownership path
```

This intentionally lets eligible RMB survive CoreScript `gameProcessed=true`, while project UI/text focus still blocks it.

- [ ] **Step 4: Restore mouse state on every ownership exit**

Call `_endMouseOrbit()` on:

```text
MouseButton2 InputEnded
WindowFocusReleased
Destroy
local racer disappears while RMB is held
CurrentCamera disappears while RMB is held
```

Do not zero yaw/pitch on release; existing `ORBIT_RETURN_TIME=0.40` smoothing owns visual return.

- [ ] **Step 5: Run targeted/full GREEN**

Run:

```bash
python verify.py
rokit install --no-trust-check
rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx
```

Expected: all contract tests pass and Rojo build succeeds.

- [ ] **Step 6: Commit GREEN**

```bash
git add src/client/Controllers/RaceCameraController.lua
git commit -m "fix: capture desktop RMB camera orbit"
```

---

### Task 4: Final CI/diff audit and Studio handoff

**Files:**
- No production file changes expected.

**Interfaces:**
- Consumes: final `main` head from Tasks 1–3.
- Produces: repository/build evidence plus exact human camera acceptance steps.

- [ ] **Step 1: Verify final diff scope**

Allowed changed areas for this plan:

```text
docs R17 reconciliation/design/plan
tests/test_camera_rider_presentation.py
src/client/Controllers/RaceCameraController.lua
```

No server physics, legs, rider code, remotes, Rojo mapping, or tracks.

- [ ] **Step 2: Verify fresh GitHub Actions run**

Expected:

```text
Contract Verify = success
python verify.py = all PASS
Rokit install = PASS
Rojo build = PASS
```

- [ ] **Step 3: Human Studio acceptance**

After local clean-status/pull/Rojo sync:

```text
1. Play with server gate READY and Local Racer present.
2. Hold RMB over world and move mouse.
   EXPECTED: camera orbits; cursor does not run to screen edge.
3. Release RMB.
   EXPECTED: mouse is restored and camera returns smoothly in ~0.40 s.
4. Hold RMB while pointer is over DrawCanvas/active UI.
   EXPECTED: camera does not claim orbit.
5. Focus chat/TextBox and use RMB/mouse.
   EXPECTED: camera does not claim orbit.
6. Draw with LMB.
   EXPECTED: drawing behavior unchanged.
7. Alt-tab/focus-loss while RMB is held.
   EXPECTED: mouse is not left locked when focus returns.
```

Status after automated GREEN: **READY FOR HUMAN CAMERA ACCEPTANCE**, not R17.1 final PASS.

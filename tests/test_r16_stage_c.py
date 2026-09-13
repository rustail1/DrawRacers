from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_8_moving_redraw_parity_is_stress_verified() -> None:
    b13 = read("src/server/Tests/B13AtomicRedrawSpec.lua")
    b14 = read("src/server/Tests/B14RedrawStressSpec.lua")

    assert "local leftDrive = pair:GetLeftDrive()" in b13
    assert "local rightDrive = pair:GetRightDrive()" in b13
    assert "local leftJoint = leftDrive:GetJoint()" in b13
    assert "local rightJoint = rightDrive:GetJoint()" in b13
    assert "racer:GetLegPair() == pair" in b13
    assert "pair:GetLeftDrive() == leftDrive and pair:GetRightDrive() == rightDrive" in b13
    assert "leftDrive:GetJoint() == leftJoint and rightDrive:GetJoint() == rightJoint" in b13
    assert "successful redraw moved anchored BodyCollider" in b13
    assert "countHinges(model) == 2" in b13

    assert "runMovingRedrawParity" in b14
    assert "for redrawIndex = 1, 10 do" in b14
    assert "pairBeforeRedraw:GetLeftDrive()" in b14
    assert "pairBeforeRedraw:GetRightDrive()" in b14
    assert "leftDriveBefore:GetJoint()" in b14
    assert "rightDriveBefore:GetJoint()" in b14
    assert "pairAfterRedraw == pairBeforeRedraw" in b14
    assert "pairAfterRedraw:GetLeftDrive() == leftDriveBefore" in b14
    assert "pairAfterRedraw:GetRightDrive() == rightDriveBefore" in b14
    assert "leftDriveBefore:GetJoint() == leftJointBefore" in b14
    assert "rightDriveBefore:GetJoint() == rightJointBefore" in b14
    assert "moving redraw must leave exactly two drive models" in b14
    assert "assertNoPending" in b14
    assert "AxleRoot_Retiring" not in b14


def test_r16_9_production_camera_is_side_view_and_observer_is_hidden() -> None:
    camera = read("src/client/Controllers/RaceCameraController.lua")
    presentation = read("src/client/Dev/M0G0PresentationHarness.lua")
    human = read("src/server/Tests/M0HumanHarness.lua")

    assert "local FIELD_OF_VIEW = 60" in camera
    assert "local LOOK_AHEAD = 11" in camera
    assert "local CAMERA_HEIGHT = 10" in camera
    assert "local SIDE_DISTANCE = 23" in camera
    assert "camera.CameraType = Enum.CameraType.Scriptable" in camera
    assert "camera.FieldOfView = FIELD_OF_VIEW" in camera
    assert "camera.CFrame = CFrame.lookAt(cameraPosition" in camera
    assert "_previousFieldOfView" in camera
    assert "camera.FieldOfView = self._previousFieldOfView" in camera
    assert "camera.CameraType" not in presentation
    assert "camera.CFrame" not in presentation

    for token in [
        "proxy.Anchored = true",
        "proxy.CanCollide = false",
        "proxy.CanTouch = false",
        "proxy.CanQuery = false",
        "proxy.Massless = true",
    ]:
        assert token in presentation

    assert "transparency: number" in human
    assert "transparency = part.Transparency" in human
    assert "part.Transparency = 1" in human
    assert "part.Transparency = state.transparency" in human


def test_r16_10_final_harness_covers_unchanged_full_lab_and_live_redraw() -> None:
    scene = read("src/shared/Config/M0SceneConfig.lua")
    modes = read("src/shared/Config/StudioHarnessConfig.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    stage_b = read("src/server/Tests/R16StageBHarness.lua")
    runner = read("src/server/Tests/R16TrialRunner.lua")

    stage_c_path = ROOT / "src/server/Tests/R16StageCHarness.lua"
    assert stage_c_path.exists(), "R16.10 requires a dedicated Studio-only final harness"
    stage_c = stage_c_path.read_text(encoding="utf-8")

    assert 'R16C = "R16C"' in modes
    assert 'R17FINAL = "R17FINAL"' in modes
    assert 'Mode = "G0"' in modes
    assert 'harnessMode == "R16C"' in bootstrap
    assert 'WaitForChild("R16StageCHarness")' in bootstrap

    assert "function R16StageBHarness.RunEvidence(): boolean" in stage_b
    assert "R16StageBHarness.RunEvidence()" in stage_c

    for piece_id in ["FlatShort", "SmallSteps", "SingleWallLow", "GapSmall", "LowTunnelWide"]:
        assert piece_id in stage_c
    for token in [
        'PieceId = "FlatShort"', 'Length = 18',
        'PieceId = "SmallSteps"', 'Height = 1.5',
        'PieceId = "SingleWallLow"', 'Height = 2.6',
        'PieceId = "GapSmall"', 'GapWidth = 3.2',
        'PieceId = "LowTunnelWide"', 'Clearance = 4.25',
    ]:
        assert token in scene

    assert "runWallTrial" in stage_c
    assert '"HOOK_01"' in stage_c
    assert '"LONG_BAR_01"' in stage_c
    assert '"SUBOPTIMAL_01"' in stage_c
    assert "R16TrialRunner.RunPiece" in stage_c
    assert "function R16TrialRunner.RunPiece" in runner
    assert 'contactName = "Wall"' in stage_c
    assert "wallGoodPassed" in stage_c
    assert "wallBadPassed" in stage_c
    assert "wallPassed" in stage_c

    assert "runLiveMovingRedrawTrial" in stage_c
    assert "for redrawIndex = 1, 10 do" in stage_c
    assert "RunService.Heartbeat:Wait()" in stage_c
    assert "LegShapeService.ValidateAndBuild" in stage_c
    assert "movingBody.AssemblyLinearVelocity" in stage_c
    assert "leftDriveBefore" in stage_c and "rightDriveBefore" in stage_c
    assert "leftJointBefore" in stage_c and "rightJointBefore" in stage_c
    assert "pairAfterRedraw == pairBeforeRedraw" in stage_c
    assert "countDriveModels(legsFolder) ~= 2" in stage_c
    assert "countHinges(model) ~= 2" in stage_c
    assert "movingRedrawPassed" in stage_c

    assert 'Instance.new("Part")' not in stage_c
    assert "M0SceneConfig.Pieces[" not in stage_c
    assert "[DrawRacers][R16.10] canonical pass" in stage_c


def test_r16_stage_c_status_records_override_without_fabricating_studio_pass() -> None:
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")

    for path, doc in [("SESSION.md", session), ("FEATURE_LIST.md", features)]:
        assert "R16 Stage C implementation authorized by Product Owner" in doc, path
        assert "R16.8–R16.10" in doc, path
        assert "IMPLEMENTED/AUTOMATED GREEN" in doc, path
        assert "Studio Gate A" in doc and "HUMAN STUDIO PENDING" in doc, path
        assert "Studio Gate B" in doc and "HUMAN STUDIO PENDING" in doc, path
        assert "Studio Gate C" in doc and "HUMAN STUDIO PENDING" in doc, path
        assert "3838a994f5b5164b64f3cdee934e5bc84f7be7a4" in doc, path
        assert "34454820796" in doc, path
        assert "149 passed, 0 failed" in doc, path
        assert "Rojo build PASS" in doc, path
        assert "B17/G0" in doc and "HUMAN_GATE" in doc, path
        assert "R16.11" in doc and "Studio Gate C" in doc, path

    assert "R16.11 must not freeze" in session
    assert "R16.11 must not freeze" in features

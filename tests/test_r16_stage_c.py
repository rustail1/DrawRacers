from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_8_moving_redraw_parity_is_stress_verified() -> None:
    b13 = read("src/server/Tests/B13AtomicRedrawSpec.lua")
    b14 = read("src/server/Tests/B14RedrawStressSpec.lua")

    # B13 remains the atomic/rollback owner and must continue to prove phase + body state.
    assert "angularDistanceDegrees(leftPhaseAfter, leftPhaseBefore)" in b13
    assert "angularDistanceDegrees(rightPhaseAfter, rightPhaseBefore)" in b13
    assert "successful redraw teleported body CFrame" in b13
    assert "successful redraw reset AssemblyLinearVelocity" in b13
    assert "successful redraw reset AssemblyAngularVelocity" in b13

    # R16.8 requires repeated redraws while the body has non-zero motion state, not only
    # anchored abuse/stress replacement checks.
    assert "runMovingRedrawParity" in b14
    assert "for redrawIndex = 1, 10 do" in b14
    assert "movingBody.AssemblyLinearVelocity" in b14
    assert "movingBody.AssemblyAngularVelocity" in b14
    assert "bodyCFrameBeforeRedraw" in b14
    assert "linearBeforeRedraw" in b14
    assert "angularBeforeRedraw" in b14
    assert "leftPhaseBeforeRedraw" in b14
    assert "rightPhaseBeforeRedraw" in b14
    assert "angularDistanceDegrees(leftPhaseAfterRedraw, leftPhaseBeforeRedraw) <= 5.0" in b14
    assert "angularDistanceDegrees(rightPhaseAfterRedraw, rightPhaseBeforeRedraw) <= 5.0" in b14
    assert "moving redraw must leave exactly two leg models" in b14
    assert "moving redraw leaked retiring LeftLeg" in b14
    assert "moving redraw leaked retiring RightLeg" in b14


def test_r16_9_g0_camera_is_reference_side_view_and_observer_is_hidden() -> None:
    presentation = read("src/client/Dev/M0G0PresentationHarness.lua")
    human = read("src/server/Tests/M0HumanHarness.lua")

    assert "local CAMERA_OFFSET = Vector3.new(-6, 5, 16)" in presentation
    assert "local CAMERA_LOOK_AHEAD = Vector3.new(7, 1, 0)" in presentation
    assert "camera.CameraType = Enum.CameraType.Scriptable" in presentation
    assert "camera.CFrame = CFrame.lookAt(cameraPosition, target)" in presentation

    # Presentation helpers must remain visual-only and cannot enter racer physics.
    for token in [
        "proxy.Anchored = true",
        "proxy.CanCollide = false",
        "proxy.CanTouch = false",
        "proxy.CanQuery = false",
        "proxy.Massless = true",
    ]:
        assert token in presentation

    # The Studio observer Character must be absent from the reference camera without
    # deleting it or changing gameplay ownership; transparency is restored on teardown.
    assert "transparency: number" in human
    assert "transparency = part.Transparency" in human
    assert "part.Transparency = 1" in human
    assert "part.Transparency = state.transparency" in human


def test_r16_10_final_harness_covers_unchanged_full_lab_and_live_redraw() -> None:
    scene = read("src/shared/Config/M0SceneConfig.lua")
    modes = read("src/shared/Config/StudioHarnessConfig.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    stage_b = read("src/server/Tests/R16StageBHarness.lua")

    stage_c_path = ROOT / "src/server/Tests/R16StageCHarness.lua"
    assert stage_c_path.exists(), "R16.10 requires a dedicated Studio-only final harness"
    stage_c = stage_c_path.read_text(encoding="utf-8")

    # The final harness must be selectable without changing the normal G0 default.
    assert 'R16C = "R16C"' in modes
    assert 'Mode = "G0"' in modes
    assert 'harnessMode == "R16C"' in bootstrap
    assert 'WaitForChild("R16StageCHarness")' in bootstrap

    # Stage C reuses the exact Stage-B evidence path rather than duplicating/tuning it.
    assert "function R16StageBHarness.RunEvidence(): boolean" in stage_b
    assert "R16StageBHarness.RunEvidence()" in stage_c

    # Every canonical piece must be represented, including the wall that Stage B deliberately
    # deferred. Canonical obstacle dimensions remain unchanged.
    for piece_id in [
        "FlatShort",
        "SmallSteps",
        "SingleWallLow",
        "GapSmall",
        "LowTunnelWide",
    ]:
        assert piece_id in stage_c
    for token in [
        'PieceId = "FlatShort"',
        'Length = 18',
        'PieceId = "SmallSteps"',
        'Height = 1.5',
        'PieceId = "SingleWallLow"',
        'Height = 2.6',
        'PieceId = "GapSmall"',
        'GapWidth = 3.2',
        'PieceId = "LowTunnelWide"',
        'Clearance = 4.25',
    ]:
        assert token in scene

    assert "runWallTrial" in stage_c
    assert '"HOOK_01"' in stage_c
    assert '"LONG_BAR_01"' in stage_c
    assert 'waitForTrackContact(racer, acceptance.WallContactTimeout, "Wall")' in stage_c
    assert "wallPassed" in stage_c

    # Final moving-redraw evidence must happen across real Heartbeats, while retaining all
    # immediate atomic invariants from R16.8.
    assert "runLiveMovingRedrawTrial" in stage_c
    assert "for redrawIndex = 1, 10 do" in stage_c
    assert "RunService.Heartbeat:Wait()" in stage_c
    assert "LegShapeService.ValidateAndBuild" in stage_c
    assert "movingBody.AssemblyLinearVelocity" in stage_c
    assert "bodyCFrameBeforeRedraw" in stage_c
    assert "leftPhaseBeforeRedraw" in stage_c
    assert "rightPhaseBeforeRedraw" in stage_c
    assert "<= 5.0" in stage_c
    assert "movingRedrawPassed" in stage_c

    # Studio-only evidence code may observe the lab but may not create or rewrite obstacle Parts.
    assert 'Instance.new("Part")' not in stage_c
    assert "M0SceneConfig.Pieces[" not in stage_c
    assert "[DrawRacers][R16.10] canonical pass" in stage_c

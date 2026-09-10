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

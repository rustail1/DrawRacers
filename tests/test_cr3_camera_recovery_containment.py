from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_cr3_camera_clamps_presentation_follow_y_without_writing_physics() -> None:
    camera = read("src/client/Controllers/RaceCameraController.lua")
    assert 'GetAttribute("CameraMinFollowY")' in camera
    assert "math.max(body.Position.Y, cameraMinFollowY)" in camera
    assert "Vector3.new(body.Position.X, presentationY, body.Position.Z)" in camera

    for forbidden in [
        "body.CFrame =",
        "body.Position =",
        "body.AssemblyLinearVelocity =",
        "body.AssemblyAngularVelocity =",
        "ApplyImpulse",
        "VectorForce",
    ]:
        assert forbidden not in camera


def test_cr3_g0_sets_camera_floor_and_uses_shallower_recovery_threshold() -> None:
    config = read("src/shared/Config/M0SceneConfig.lua")
    harness = read("src/server/Tests/M0HumanHarness.lua")

    assert "CameraMinFollowY = 0" in config
    assert "RecoveryKillY = -6" in config
    assert 'model:SetAttribute("CameraMinFollowY", M0SceneConfig.CameraMinFollowY)' in harness
    assert "body.Position.Y < M0SceneConfig.RecoveryKillY" in harness
    assert "racer:PrepareForRecovery()" in harness

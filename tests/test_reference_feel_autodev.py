from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_reference_feel_camera_uses_stable_two_axis_dead_zone_anchor() -> None:
    camera_math = read("src/shared/Math/CameraMath.lua")
    camera = read("src/client/Controllers/RaceCameraController.lua")

    assert "function CameraMath.StepDeadZoneAnchor" in camera_math
    assert "HORIZONTAL_DEAD_ZONE" in camera
    assert "VERTICAL_DEAD_ZONE" in camera
    assert "_deadZoneAnchor" in camera
    assert camera.count("CameraMath.StepDeadZoneAnchor(") >= 2

    # Verify the controller reads the stable anchor on both gameplay axes
    # without requiring one exact private-expression spelling.
    assert "local anchor = self._deadZoneAnchor" in camera
    assert "anchor.X" in camera
    assert "anchor.Y" in camera
    assert "self._smoothedPosition" in camera
    assert "self._deadZoneAnchor" in camera.split("CameraMath.SmoothVector", 1)[1]

    assert "ORBIT_YAW_LIMIT" not in camera
    assert "_targetOrbitYaw" in camera
    assert "Enum.UserInputType.MouseButton2" in camera
    assert "Enum.MouseBehavior.LockCurrentPosition" in camera


def test_dead_zone_math_is_boundary_clamp_not_hidden_camera_propulsion() -> None:
    camera_math = read("src/shared/Math/CameraMath.lua")
    helper = camera_math.split("function CameraMath.StepDeadZoneAnchor", 1)[1].split("\nend", 1)[0]

    assert "raw - current" in helper
    assert "math.abs" in helper
    assert "return current" in helper
    assert "math.sign" in helper
    assert "SmoothNumber" not in helper

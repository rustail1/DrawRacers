from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_r17_continuous_orbit_preserves_drag_direction_and_short_return() -> None:
    camera = (ROOT / "src/client/Controllers/RaceCameraController.lua").read_text(encoding="utf-8")
    step_body = camera.split("function RaceCameraController:_step(dt: number)", 1)[1].split(
        "function RaceCameraController:Start()", 1
    )[0]

    branch_marker = "\n\tif orbitInputActive then\n"
    branch_body = step_body.split(branch_marker, 1)[1]
    active_branch, return_tail = branch_body.split("\n\telse\n", 1)
    return_branch = return_tail.split("\n\tend\n", 1)[0]

    assert "self._orbitYaw = CameraMath.SmoothNumber(" in active_branch, (
        "continuous 360-degree drag must smooth the unbounded yaw target directly; "
        "shortest-angle smoothing can reverse direction once target yaw passes 180 degrees"
    )
    assert "self._orbitYaw = CameraMath.SmoothAngleDegrees(" in return_branch, (
        "release should still choose the shortest angular path back to canonical framing"
    )

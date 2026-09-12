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


def test_r17_regrab_rebases_orbit_target_to_current_rendered_view() -> None:
    camera = (ROOT / "src/client/Controllers/RaceCameraController.lua").read_text(encoding="utf-8")

    mouse_begin = camera.split("function RaceCameraController:_beginMouseOrbit()", 1)[1].split(
        "function RaceCameraController:_endMouseOrbit()", 1
    )[0]
    assert "self._targetOrbitYaw = self._orbitYaw" in mouse_begin, (
        "re-grabbing RMB during the smoothed return must start from the currently rendered yaw "
        "instead of continuing toward the stale zero return target"
    )
    assert "self._targetOrbitPitch = self._orbitPitch" in mouse_begin, (
        "re-grabbing RMB during return must also preserve the currently rendered pitch"
    )

    touch_begin = camera.split("if input.UserInputType == Enum.UserInputType.Touch then", 1)[1].split(
        "\n\t\tend\n\tend))", 1
    )[0]
    touch_claim = touch_begin.split("self._touchOrbitInput = input", 1)[0]
    assert "if not self._mouseOrbitHeld then" in touch_claim, (
        "touch re-grab should rebase only when it is starting a new orbit, not when RMB already owns orbit input"
    )
    assert "self._targetOrbitYaw = self._orbitYaw" in touch_claim
    assert "self._targetOrbitPitch = self._orbitPitch" in touch_claim

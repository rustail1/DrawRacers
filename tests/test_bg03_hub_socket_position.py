from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_bg03_production_axle_is_centered_on_cube_side_surface() -> None:
    config = (ROOT / "src/shared/Config/PhysicsConfig.lua").read_text(encoding="utf-8")
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text(encoding="utf-8")
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text(encoding="utf-8")

    assert "local BODY_SIZE = Vector3.new(3, 3, 3)" in runtime
    assert "HubOffsetX = 0.0" in config
    assert "HubOffsetY = 0.0" in config
    assert "LegSocketZAbs = 1.5" in config
    assert "attachment.Position = Vector3.new(geometry.HubOffsetX, geometry.HubOffsetY, 0)" in pair
    assert "return body.CFrame * CFrame.new(geometry.HubOffsetX, geometry.HubOffsetY, 0)" in pair
    assert "socketZ = -geometry.LegSocketZAbs" in pair
    assert "socketZ = geometry.LegSocketZAbs" in pair


def test_bg03_leg_geometry_has_no_hidden_xy_translation_after_socket_mount() -> None:
    leg = (ROOT / "src/server/Runtime/LegAssembly.lua").read_text(encoding="utf-8")

    assert "root.CFrame = params.axleRoot.CFrame" in leg
    assert "CFrame.new(0, 0, params.socketZ)" in leg
    assert "makeSegmentCFrame(root.CFrame, a, b)" in leg
    assert "root.CFrame * CFrame.new(point.X, point.Y, 0)" in leg
    assert "HubOffsetY" not in leg

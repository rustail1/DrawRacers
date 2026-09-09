from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_1_body_orientation_is_upright_not_free_about_z() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    b10 = read("src/server/Tests/B10StabilizationSpec.lua")

    assert "Enum.AlignType.AllAxes" in stabilizer
    assert "orientationAlign.CFrame = CFrame.identity" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" not in stabilizer
    assert "upright body angular deviation" in b10
    assert "x/y translation must remain physically free" in b10
    assert "in-plane rotation around Z must remain unconstrained" not in b10


def test_r16_2_hub_offsets_have_one_numeric_owner() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    b06 = read("src/server/Tests/B06RacerRuntimeSpec.lua")

    for token in [
        "HubOffsetX = 0.0",
        "HubOffsetY = -0.35",
        "HubOffsetZAbs = 1.62",
    ]:
        assert token in config

    assert "local geometry = PhysicsConfig.LegGeometry" in runtime
    assert "geometry.HubOffsetX" in runtime
    assert "geometry.HubOffsetY" in runtime
    assert "geometry.HubOffsetZAbs" in runtime
    assert "Vector3.new(0, -0.75, -1.62)" not in runtime
    assert "Vector3.new(0, -0.75, 1.62)" not in runtime
    assert "local geometry = PhysicsConfig.LegGeometry" in b06
    assert "geometry.HubOffsetY" in b06

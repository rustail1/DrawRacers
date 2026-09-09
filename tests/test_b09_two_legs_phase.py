from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b09_two_leg_same_xy_phase_contract() -> None:
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua").read_text(encoding="utf-8")
    racer = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")

    assert "RightPhaseOffsetDegrees = 180" in config

    for token in [
        'params.side == "Left" or params.side == "Right"',
        '"LeftHub"',
        '"RightHub"',
        '"LeftLeg"',
        '"RightLeg"',
        "initialPhaseDegrees",
        "CFrame.Angles(0, 0, math.rad(initialPhaseDegrees))",
    ]:
        assert token in leg, f"missing B09 side/phase implementation token: {token}"

    for forbidden in [
        "-point.X",
        "-point.Y",
        "point.X * -1",
        "point.Y * -1",
        "Vector2.new(-point.X",
        "Vector2.new(point.X, -point.Y",
    ]:
        assert forbidden not in leg, f"B09 must not mirror/invert shape XY: {forbidden}"

    assert "function RacerRuntime:ApplyShape" in racer
    assert 'side = "Left"' in racer
    assert 'side = "Right"' in racer
    assert racer.count("shapeSpec = shapeSpec") >= 2
    assert "GeometryMath.BuildSegmentPlan" in racer
    assert "RightPhaseOffsetDegrees" in racer


def test_b09_studio_spec_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B09TwoLegPhaseSpec.lua"
    assert spec.is_file(), "missing B09 Studio behavior spec"
    text = spec.read_text(encoding="utf-8")

    for token in [
        "ApplyShape",
        "LeftLeg",
        "RightLeg",
        "GetMappedPoints",
        "RightPhaseOffsetDegrees",
        "two-leg same-XY/phase tests PASS",
    ]:
        assert token in text, f"missing B09 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B09TwoLegPhaseSpec" in bootstrap
    assert "B09TwoLegPhaseSpec.run()" in bootstrap

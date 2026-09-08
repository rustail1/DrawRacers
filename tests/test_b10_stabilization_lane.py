from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b10_config_defaults() -> None:
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    for token in [
        "LaneCorrectionDeadzone = 0.15",
        "LaneNormalError = 0.35",
        "LaneHardBound = 0.75",
        "OrientationResponsiveness = 8",
    ]:
        assert token in config, f"missing B10 config default: {token}"


def test_b10_stabilizer_is_z_only_and_has_no_forward_propulsion() -> None:
    path = ROOT / "src" / "server" / "Runtime" / "RacerStabilizer.lua"
    assert path.is_file(), "missing B10 RacerStabilizer.lua"
    text = path.read_text(encoding="utf-8")

    for token in [
        'Instance.new("AlignPosition")',
        'Instance.new("AlignOrientation")',
        "Enum.ForceLimitMode.PerAxis",
        "Vector3.new(0, 0,",
        "LaneCorrectionDeadzone",
        "LaneHardBound",
        "OrientationResponsiveness",
        'SetAttribute("LaneHardBoundExceeded"',
        "RunService.Heartbeat:Connect",
    ]:
        assert token in text, f"missing B10 stabilizer token: {token}"

    for forbidden in [
        "ApplyImpulse(",
        "AssemblyLinearVelocity =",
        "LinearVelocity",
        "VectorForce",
        "PivotTo(",
        "CFrame = CFrame.new(body.Position.X +",
    ]:
        assert forbidden not in text, f"B10 must not add forward propulsion/teleport: {forbidden}"


def test_b10_racer_runtime_owns_stabilizer_lifetime() -> None:
    racer = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")
    assert 'require(script.Parent:WaitForChild("RacerStabilizer"))' in racer
    assert "RacerStabilizer.new" in racer
    assert "stabilizer = stabilizer" in racer
    assert "self.stabilizer:Destroy()" in racer


def test_b10_studio_spec_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B10StabilizationSpec.lua"
    assert spec.is_file(), "missing B10 Studio behavior spec"
    text = spec.read_text(encoding="utf-8")
    for token in [
        "LaneHardBoundExceeded",
        "LaneCorrectionDeadzone",
        "OrientationResponsiveness",
        "stabilization/lane tests PASS",
    ]:
        assert token in text, f"missing B10 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B10StabilizationSpec" in bootstrap
    assert "B10StabilizationSpec.run()" in bootstrap

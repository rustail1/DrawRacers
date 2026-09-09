from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b10_config_defaults() -> None:
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    for token in [
        "LaneNormalError = 0.03",
        "LaneHardBound = 0.08",
        "LaneMaxForceZ = 60000",
        "LaneResponsiveness = 40",
        "LaneMaxVelocity = 30",
        "OrientationResponsiveness = 40",
        "OrientationMaxTorque = 60000",
        "OrientationMaxAngularVelocity = 30",
    ]:
        assert token in config, f"missing R15 planar config default: {token}"

    assert "LaneCorrectionDeadzone" not in config
    assert "OrientationFreeTiltDegrees" not in config


def test_b10_stabilizer_is_z_only_and_has_no_forward_propulsion() -> None:
    path = ROOT / "src" / "server" / "Runtime" / "RacerStabilizer.lua"
    assert path.is_file(), "missing B10 RacerStabilizer.lua"
    text = path.read_text(encoding="utf-8")

    for token in [
        'Instance.new("AlignPosition")',
        'Instance.new("AlignOrientation")',
        "Enum.ForceLimitMode.PerAxis",
        "Enum.ActuatorRelativeTo.World",
        "Vector3.new(0, 0, config.LaneMaxForceZ)",
        "laneAlign.Enabled = true",
        "Enum.AlignType.PrimaryAxisParallel",
        "orientationAlign.PrimaryAxis = Vector3.zAxis",
        "orientationAttachment.Axis = Vector3.zAxis",
        "orientationAlign.Enabled = true",
        "LaneHardBound",
        "OrientationResponsiveness",
        'SetAttribute("LaneHardBoundExceeded"',
        "RunService.Heartbeat:Connect",
    ]:
        assert token in text, f"missing R15 planar stabilizer token: {token}"

    for forbidden in [
        "ApplyImpulse(",
        "AssemblyLinearVelocity =",
        "LinearVelocity",
        "VectorForce",
        "PivotTo(",
        "CFrame = CFrame.new(body.Position.X +",
        "LaneCorrectionDeadzone",
        "OrientationFreeTiltDegrees",
        "orientationAlign.CFrame = CFrame.identity",
    ]:
        assert forbidden not in text, f"R15 stabilizer must not use soft-lane/forward/teleport behavior: {forbidden}"


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
        "PrimaryAxisParallel",
        "orientationAlign.PrimaryAxis == Vector3.zAxis",
        "lane constraint must remain continuously enabled",
        "planar orientation constraint must remain continuously enabled",
        "in-plane rotation around Z must remain unconstrained",
        "out-of-plane disturbance must keep planar correction active",
        "Enum.ActuatorRelativeTo.World",
        "stabilization/lane tests PASS",
    ]:
        assert token in text, f"missing R15 B10 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B10StabilizationSpec" in bootstrap
    assert "B10StabilizationSpec.run()" in bootstrap

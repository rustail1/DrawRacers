from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b10_config_defaults() -> None:
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    for token in [
        "LaneNormalError = 0.03",
        "LaneHardBound = 0.08",
        "OrientationResponsiveness = 40",
        "OrientationMaxTorque = 60000",
        "OrientationMaxAngularVelocity = 30",
    ]:
        assert token in config, f"missing R15.1 planar config default: {token}"

    for obsolete in [
        "LaneCorrectionDeadzone",
        "OrientationFreeTiltDegrees",
        "LaneMaxForceZ",
        "LaneResponsiveness",
        "LaneMaxVelocity",
    ]:
        assert obsolete not in config, f"R15.1 must not retain obsolete soft-lane tuning: {obsolete}"


def test_b10_stabilizer_uses_mechanical_plane_and_has_no_forward_propulsion() -> None:
    path = ROOT / "src" / "server" / "Runtime" / "RacerStabilizer.lua"
    assert path.is_file(), "missing B10 RacerStabilizer.lua"
    text = path.read_text(encoding="utf-8")

    for token in [
        'Instance.new("PlaneConstraint")',
        'lanePlane.Name = "LanePlane"',
        'laneReference.Name = "LanePlaneReference"',
        "laneReference.Anchored = true",
        "lanePlane.Attachment0 = laneReferenceAttachment",
        "lanePlane.Attachment1 = laneAttachment",
        "laneReferenceAttachment.Axis = Vector3.zAxis",
        "lanePlane.Enabled = true",
        'Instance.new("AlignOrientation")',
        "Enum.AlignType.PrimaryAxisParallel",
        "orientationAlign.PrimaryAxis = Vector3.zAxis",
        "orientationAttachment.Axis = Vector3.zAxis",
        "orientationAlign.Enabled = true",
        "LaneHardBound",
        "OrientationResponsiveness",
        'SetAttribute("LaneHardBoundExceeded"',
        "RunService.Heartbeat:Connect",
    ]:
        assert token in text, f"missing R15.1 planar stabilizer token: {token}"

    for forbidden in [
        'Instance.new("AlignPosition")',
        "MaxAxesForce",
        "ApplyImpulse(",
        "AssemblyLinearVelocity =",
        "LinearVelocity",
        "VectorForce",
        "PivotTo(",
        "CFrame = CFrame.new(body.Position.X +",
        "LaneCorrectionDeadzone",
        "OrientationFreeTiltDegrees",
    ]:
        assert forbidden not in text, f"R15.1 stabilizer must not use soft-lane/forward/teleport behavior: {forbidden}"


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
        "GetLaneConstraint",
        'lanePlane:IsA("PlaneConstraint")',
        "body:ApplyImpulse",
        "maxObservedLaneDeviation",
        "RunService.Heartbeat:Wait()",
        "lateral impulse escaped the hard gameplay plane",
        "planar orientation constraint must remain continuously enabled",
        "in-plane rotation around Z must remain unconstrained",
        "out-of-plane disturbance must keep planar correction active",
        "stabilization/lane tests PASS",
    ]:
        assert token in text, f"missing R15.1 B10 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B10StabilizationSpec" in bootstrap
    assert "B10StabilizationSpec.run()" in bootstrap

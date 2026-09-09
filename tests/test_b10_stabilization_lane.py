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
        assert token in config, f"missing R16 planar/upright config default: {token}"

    for obsolete in [
        "LaneCorrectionDeadzone",
        "OrientationFreeTiltDegrees",
        "LaneMaxForceZ",
        "LaneResponsiveness",
        "LaneMaxVelocity",
    ]:
        assert obsolete not in config, f"R16 must not retain obsolete soft-lane tuning: {obsolete}"


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
        "Enum.AlignType.AllAxes",
        "orientationAlign.CFrame = CFrame.identity",
        "orientationAttachment.Axis = Vector3.xAxis",
        "orientationAttachment.SecondaryAxis = Vector3.yAxis",
        "orientationAlign.Enabled = true",
        "LaneHardBound",
        "OrientationResponsiveness",
        'SetAttribute("LaneHardBoundExceeded"',
        "RunService.Heartbeat:Connect",
    ]:
        assert token in text, f"missing R16 planar/upright stabilizer token: {token}"

    for forbidden in [
        'Instance.new("AlignPosition")',
        "Enum.AlignType.PrimaryAxisParallel",
        "orientationAttachment.Axis = Vector3.zAxis",
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
        assert forbidden not in text, f"R16 stabilizer must not use soft-lane/forward/legacy-axis behavior: {forbidden}"


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
        "Enum.AlignType.AllAxes",
        "orientationAlign.CFrame == CFrame.identity",
        "orientation attachment X axis must stay canonical",
        "orientation attachment Y axis must stay canonical",
        "GetLaneConstraint",
        'lanePlane:IsA("PlaneConstraint")',
        "body:ApplyImpulse",
        "maxObservedLaneDeviation",
        "RunService.Heartbeat:Wait()",
        "lateral impulse escaped the hard gameplay plane",
        "upright body angular deviation",
        "x/y translation must remain physically free",
        "stabilization/lane tests PASS",
    ]:
        assert token in text, f"missing R16 B10 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B10StabilizationSpec" in bootstrap
    assert "B10StabilizationSpec.run()" in bootstrap

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r15_1_stabilizer_uses_mechanical_plane_not_force_follower() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")

    # R15.1: a hard 2.5D gameplay plane must not depend on a finite corrective force.
    assert 'Instance.new("PlaneConstraint")' in stabilizer
    assert 'lanePlane.Name = "LanePlane"' in stabilizer
    assert "lanePlane.Attachment0 = laneReferenceAttachment" in stabilizer
    assert "lanePlane.Attachment1 = laneAttachment" in stabilizer
    assert "laneReferenceAttachment.Axis = Vector3.zAxis" in stabilizer
    assert "lanePlane.Enabled = true" in stabilizer
    assert 'Instance.new("AlignPosition")' not in stabilizer
    assert "MaxAxesForce" not in stabilizer
    assert "LaneMaxForceZ" not in config
    assert "LaneResponsiveness" not in config
    assert "LaneMaxVelocity" not in config

    # R16 keeps the mechanical plane but upgrades body orientation to full upright lock.
    assert "Enum.AlignType.AllAxes" in stabilizer
    assert "orientationAlign.CFrame = CFrame.identity" in stabilizer
    assert "orientationAttachment.Axis = Vector3.zAxis" in stabilizer
    assert "orientationAlign.Enabled = true" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" not in stabilizer

    for token in [
        "LaneNormalError = 0.03",
        "LaneHardBound = 0.08",
        "OrientationResponsiveness = 40",
        "OrientationMaxTorque = 60000",
        "OrientationMaxAngularVelocity = 30",
    ]:
        assert token in config

    assert "LaneCorrectionDeadzone" not in config
    assert "OrientationFreeTiltDegrees" not in config


def test_r15_1_b10_exercises_real_lateral_impulse() -> None:
    spec = read("src/server/Tests/B10StabilizationSpec.lua")
    for token in [
        "GetLaneConstraint",
        'lanePlane:IsA("PlaneConstraint")',
        "body:ApplyImpulse",
        "maxObservedLaneDeviation",
        "RunService.Heartbeat:Wait()",
        "lateral impulse escaped the hard gameplay plane",
        "Enum.AlignType.AllAxes",
        "upright body angular deviation",
        "x/y translation must remain physically free",
    ]:
        assert token in spec

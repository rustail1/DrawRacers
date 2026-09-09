from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r15_stabilizer_is_continuous_z_only_planar_lock() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")

    assert "LaneCorrectionDeadzone" not in stabilizer
    assert "OrientationFreeTiltDegrees" not in stabilizer
    assert "self.laneAlign.Enabled = true" in stabilizer
    assert "Vector3.new(0, 0, config.LaneMaxForceZ)" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" in stabilizer
    assert "orientationAlign.PrimaryAxis = Vector3.zAxis" in stabilizer
    assert "orientationAttachment.Axis = Vector3.zAxis" in stabilizer
    assert "orientationAlign.Enabled = true" in stabilizer

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
        assert token in config

    assert "LaneCorrectionDeadzone" not in config
    assert "OrientationFreeTiltDegrees" not in config


def test_r15_b10_checks_planar_constraint_shape() -> None:
    spec = read("src/server/Tests/B10StabilizationSpec.lua")
    for token in [
        "PrimaryAxisParallel",
        "orientationAlign.PrimaryAxis == Vector3.zAxis",
        "lane constraint must remain continuously enabled",
        "planar orientation constraint must remain continuously enabled",
        "in-plane rotation around Z must remain unconstrained",
        "out-of-plane disturbance must keep planar correction active",
    ]:
        assert token in spec

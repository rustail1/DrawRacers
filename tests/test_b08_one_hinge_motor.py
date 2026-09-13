from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_b08_twin_hinge_motor_contract() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drive = read("src/server/Runtime/LegDriveAssembly.lua")
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    for token in ["TargetTipSpeed", "MinAngularVelocity", "MaxAngularVelocity", "MotorMaxTorque = 35000", "MotorMaxAcceleration = 120", "RightPhaseOffsetDegrees = 180"]:
        assert token in config
    for token in ['Instance.new("HingeConstraint")', "Enum.ActuatorType.Motor", "joint.AngularVelocity", "joint.MotorMaxTorque", "joint.MotorMaxAcceleration", 'joint.Name = "DriveJoint"']:
        assert token in drive
    assert drive.count('Instance.new("HingeConstraint")') == 1
    assert pair.count("LegDriveAssembly.new") == 2
    assert 'Instance.new("HingeConstraint")' not in pair
    assert 'Instance.new("HingeConstraint")' not in leg
    for source in (drive, pair, leg):
        for forbidden in ["AssemblyLinearVelocity =", "ApplyImpulse(", "LinearVelocity =", 'Instance.new("VectorForce")']:
            assert forbidden not in source


def test_b08_studio_harness_is_wired_without_owning_propulsion() -> None:
    harness = read("src/server/Tests/B08OneHingeMotorHarness.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    assert "RacerRuntime.new" in harness
    assert "ApplyShape" in harness
    assert "GetLegPair" in harness
    for forbidden in ["AssemblyLinearVelocity =", "ApplyImpulse(", "VectorForce", "LinearVelocity =", "PivotTo(CFrame.new(startX +"]:
        assert forbidden not in harness
    assert "B08OneHingeMotorHarness" in bootstrap
    assert "B08OneHingeMotorHarness.start()" in bootstrap

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b08_one_hinge_motor_contract() -> None:
    leg = (ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua").read_text(encoding="utf-8")
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")

    for token in [
        "AngularVelocity = -8.0",
        "MotorMaxTorque = 35000",
        "MotorMaxAcceleration = 120",
    ]:
        assert token in config, f"missing B08 config default: {token}"

    for token in [
        "Enum.ActuatorType.Motor",
        "joint.AngularVelocity",
        "joint.MotorMaxTorque",
        "joint.MotorMaxAcceleration",
        '"HingeConstraint"',
    ]:
        assert token in leg, f"missing B08 motor token: {token}"

    for forbidden in [
        "AssemblyLinearVelocity =",
        "ApplyImpulse(",
        "VectorForce",
        "LinearVelocity =",
    ]:
        assert forbidden not in leg, f"B08 must not use hidden propulsion: {forbidden}"


def test_b08_studio_flat_harness_contract() -> None:
    harness = ROOT / "src" / "server" / "Tests" / "B08OneHingeMotorHarness.lua"
    assert harness.is_file(), "missing B08 Studio flat movement harness"
    text = harness.read_text(encoding="utf-8")

    assert "LegAssembly.new" in text
    assert "ROUND_01" in text
    assert "one-hinge flat harness ready" in text
    assert "deltaX=" in text
    assert "RightLeg" not in text

    for forbidden in [
        "AssemblyLinearVelocity =",
        "ApplyImpulse(",
        "VectorForce",
        "LinearVelocity =",
        "PivotTo(CFrame.new(startX +",
    ]:
        assert forbidden not in text, f"B08 harness must not fake movement: {forbidden}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B08OneHingeMotorHarness" in bootstrap
    assert "B08OneHingeMotorHarness.start()" in bootstrap

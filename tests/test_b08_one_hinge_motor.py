from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b08_one_hinge_motor_contract() -> None:
    pair_path = ROOT / "src" / "server" / "Runtime" / "LegPairAssembly.lua"
    leg_path = ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua"
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    assert pair_path.is_file(), "R17 B08 requires LegPairAssembly"
    pair = pair_path.read_text(encoding="utf-8")
    leg = leg_path.read_text(encoding="utf-8")

    for token in [
        "AngularVelocity = -8.0",
        "MotorMaxTorque = 35000",
        "MotorMaxAcceleration = 120",
        "RightPhaseOffsetDegrees = 0",
    ]:
        assert token in config, f"missing B08 config default: {token}"

    for token in [
        "Enum.ActuatorType.Motor",
        "joint.AngularVelocity",
        "joint.MotorMaxTorque",
        "joint.MotorMaxAcceleration",
        'joint.Name = "AxleJoint"',
        'Instance.new("HingeConstraint")',
    ]:
        assert token in pair, f"missing B08 shared motor token: {token}"

    assert pair.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in leg

    for source in (pair, leg):
        for forbidden in [
            "AssemblyLinearVelocity =",
            "ApplyImpulse(",
            "VectorForce",
            "LinearVelocity =",
        ]:
            assert forbidden not in source, f"B08 must not use hidden propulsion: {forbidden}"


def test_b08_studio_flat_harness_contract() -> None:
    harness = ROOT / "src" / "server" / "Tests" / "B08OneHingeMotorHarness.lua"
    assert harness.is_file(), "missing B08 Studio flat movement harness"
    text = harness.read_text(encoding="utf-8")

    assert "RacerRuntime.new" in text
    assert "ApplyShape" in text
    assert "GetLegPair" in text
    assert "AxleJoint" in text
    assert "ROUND_01" in text
    assert "one-hinge flat harness ready" in text
    assert "deltaX=" in text

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

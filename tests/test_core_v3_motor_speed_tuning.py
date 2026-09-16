from pathlib import Path
import math
import re


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def motor_values() -> dict[str, float]:
    config = read("src/server/Runtime/CoreV3/LegCoreConfig.lua")
    motor = config.split("Motor = {", 1)[1].split("},", 1)[0]
    values: dict[str, float] = {}
    for name in [
        "RotationSign",
        "TargetTipSpeed",
        "MinimumDriveRadius",
        "MinAngularVelocity",
        "MaxAngularVelocity",
        "Torque",
        "Acceleration",
    ]:
        match = re.search(rf"\b{name}\s*=\s*(-?\d+(?:\.\d+)?)", motor)
        assert match is not None, f"missing Core V3 motor value {name}"
        values[name] = float(match.group(1))
    return values


def commanded_omega(extent: float, values: dict[str, float]) -> float:
    radius = max(extent, values["MinimumDriveRadius"])
    magnitude = values["TargetTipSpeed"] / radius
    magnitude = max(values["MinAngularVelocity"], min(values["MaxAngularVelocity"], magnitude))
    return magnitude * values["RotationSign"]


def test_core_v3_reference_shapes_receive_fifty_percent_faster_bounded_target() -> None:
    values = motor_values()

    round_omega = commanded_omega(4.5, values)
    small_round_omega = commanded_omega(2.51198, values)
    long_omega = commanded_omega(2.944, values)

    assert math.isclose(round_omega, -6.666667, abs_tol=1e-5)
    assert small_round_omega == -8.0
    assert long_omega == -8.0
    assert abs(small_round_omega) == abs(long_omega) > abs(round_omega)
    assert commanded_omega(0.01, values) == -8.0


def test_core_v3_speed_tuning_preserves_drive_architecture() -> None:
    values = motor_values()
    controller = read("src/server/Runtime/CoreV3/LegCoreController.lua")
    axle = read("src/server/Runtime/CoreV3/SharedAxle.lua")
    c01 = read("src/server/Tests/C01CoreV3SharedAxleSpec.lua")
    c07 = read("src/server/Tests/C07CoreV3FlatLocomotionSpec.lua")

    assert values == {
        "RotationSign": -1.0,
        "TargetTipSpeed": 30.0,
        "MinimumDriveRadius": 1.75,
        "MinAngularVelocity": 1.5,
        "MaxAngularVelocity": 8.0,
        "Torque": 35000.0,
        "Acceleration": 120.0,
    }
    assert "TargetTipSpeed / radius" in controller
    assert "math.clamp(" in controller
    assert axle.count('Instance.new("HingeConstraint")') == 1
    assert "LegCoreConfig.Motor.Torque" in axle
    assert 'force.Force = Vector3.new(0, yForce, 0)' in controller
    for forbidden in ['Instance.new("LinearVelocity")', 'Instance.new("BodyVelocity")']:
        assert forbidden not in controller
    for forbidden in ['Instance.new("VectorForce")', 'Instance.new("LinearVelocity")', 'Instance.new("BodyVelocity")']:
        assert forbidden not in axle
    assert "countHinges(testModel) == 1" in c01
    assert "not hasHorizontalAssist(model)" in c07

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b09_two_leg_same_xy_phase_contract() -> None:
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua").read_text(encoding="utf-8")
    pair = (ROOT / "src" / "server" / "Runtime" / "LegPairAssembly.lua").read_text(encoding="utf-8")
    racer = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")

    assert "RightPhaseOffsetDegrees = 0" in config
    for obsolete in [
        "PhaseLockToleranceDegrees",
        "PhaseLockRecoveryTime",
        "PhaseLockMaxRelativeCorrection",
    ]:
        assert obsolete not in config
        assert obsolete not in racer

    for token in [
        'params.side == "Left" or params.side == "Right"',
        '"LeftLeg"',
        '"RightLeg"',
        "phaseDegrees",
        '"AxleWeld"',
    ]:
        assert token in leg, f"missing B09 rigid-side token: {token}"

    for forbidden in [
        "-point.X",
        "-point.Y",
        "point.X * -1",
        "point.Y * -1",
        "Vector2.new(-point.X",
        "Vector2.new(point.X, -point.Y",
    ]:
        assert forbidden not in leg, f"B09 must not mirror/invert shape XY: {forbidden}"

    for token in [
        'side = "Left"',
        'side = "Right"',
        "shapeSpec = params.shapeSpec",
        "RightPhaseOffsetDegrees",
        'joint.Name = "AxleJoint"',
        "function LegPairAssembly:GetPhaseDegrees()",
    ]:
        assert token in pair, f"missing B09 shared-pair token: {token}"

    assert pair.count('Instance.new("HingeConstraint")') == 1
    assert 'Instance.new("HingeConstraint")' not in leg
    assert "function RacerRuntime:ApplyShape" in racer
    assert "LegPairAssembly.new" in racer
    assert "self.legPair" in racer
    assert "phaseSyncConnection" not in racer
    assert "_StepLegPhaseSync" not in racer
    assert "leftJoint.AngularVelocity" not in racer
    assert "rightJoint.AngularVelocity" not in racer

    apply_shape_spec = racer.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split(
        "function RacerRuntime:ApplyShape", 1
    )[0]
    assert "initialPhaseDegrees" in apply_shape_spec
    assert "oldLegPair:GetPhaseDegrees()" in apply_shape_spec
    assert "stagedLegPair:Commit()" in apply_shape_spec


def test_b09_studio_spec_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B09TwoLegPhaseSpec.lua"
    assert spec.is_file(), "missing B09 Studio behavior spec"
    text = spec.read_text(encoding="utf-8")

    for token in [
        "ApplyShape",
        "LeftLeg",
        "RightLeg",
        "GetMappedPoints",
        "GetLegPair",
        "AxleJoint",
        "RightPhaseOffsetDegrees",
        "co-phase structural difference",
        "two-leg same-XY/co-phase tests PASS",
    ]:
        assert token in text, f"missing B09 Studio acceptance token: {token}"

    assert "_StepLegPhaseSync" not in text

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B09TwoLegPhaseSpec" in bootstrap
    assert "B09TwoLegPhaseSpec.run()" in bootstrap

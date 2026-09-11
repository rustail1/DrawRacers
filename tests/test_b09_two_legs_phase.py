from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_b09_two_leg_same_xy_phase_contract() -> None:
    config = (ROOT / "src" / "shared" / "Config" / "PhysicsConfig.lua").read_text(encoding="utf-8")
    leg = (ROOT / "src" / "server" / "Runtime" / "LegAssembly.lua").read_text(encoding="utf-8")
    racer = (ROOT / "src" / "server" / "Runtime" / "RacerRuntime.lua").read_text(encoding="utf-8")

    for token in [
        "RightPhaseOffsetDegrees = 180",
        "PhaseLockToleranceDegrees = 3.0",
        "PhaseLockRecoveryTime = 0.25",
        "PhaseLockMaxRelativeCorrection = 4.0",
    ]:
        assert token in config, f"missing persistent B09 phase-lock config token: {token}"

    for token in [
        'params.side == "Left" or params.side == "Right"',
        '"LeftHub"',
        '"RightHub"',
        '"LeftLeg"',
        '"RightLeg"',
        "initialPhaseDegrees",
        "CFrame.Angles(0, 0, math.rad(initialPhaseDegrees))",
    ]:
        assert token in leg, f"missing B09 side/phase implementation token: {token}"

    for forbidden in [
        "-point.X",
        "-point.Y",
        "point.X * -1",
        "point.Y * -1",
        "Vector2.new(-point.X",
        "Vector2.new(point.X, -point.Y",
    ]:
        assert forbidden not in leg, f"B09 must not mirror/invert shape XY: {forbidden}"

    assert "function RacerRuntime:ApplyShape" in racer
    assert 'side = "Left"' in racer
    assert 'side = "Right"' in racer
    assert racer.count("shapeSpec = shapeSpec") >= 2
    assert "GeometryMath.BuildSegmentPlan" in racer
    assert "RightPhaseOffsetDegrees" in racer

    # R16.4 is a maintained anti-phase contract, not merely a spawn pose.
    # RacerRuntime owns the pair, so it must keep one bounded Heartbeat phase
    # synchronizer and clean it up with the runtime lifecycle.
    for token in [
        "function RacerRuntime:_StepLegPhaseSync()",
        "RunService.Heartbeat:Connect",
        "phaseSyncConnection",
        "PhaseLockToleranceDegrees",
        "PhaseLockRecoveryTime",
        "PhaseLockMaxRelativeCorrection",
        "leftJoint.AngularVelocity",
        "rightJoint.AngularVelocity",
        "self.phaseSyncConnection:Disconnect()",
    ]:
        assert token in racer, f"missing persistent B09 phase-lock runtime token: {token}"

    # Redraw may preserve the live left/reference phase, but must never copy an
    # already-drifted right phase forward into the replacement pair.
    apply_shape_spec = racer.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split(
        "function RacerRuntime:ApplyShape", 1
    )[0]
    assert "rightPhaseDegrees = leftPhaseDegrees + PhysicsConfig.Motor.RightPhaseOffsetDegrees" in apply_shape_spec
    assert "captureLegPhaseDegrees(\n\t\toldRightLeg" not in apply_shape_spec


def test_b09_studio_spec_is_wired() -> None:
    spec = ROOT / "src" / "server" / "Tests" / "B09TwoLegPhaseSpec.lua"
    assert spec.is_file(), "missing B09 Studio behavior spec"
    text = spec.read_text(encoding="utf-8")

    for token in [
        "ApplyShape",
        "LeftLeg",
        "RightLeg",
        "GetMappedPoints",
        "RightPhaseOffsetDegrees",
        "_StepLegPhaseSync",
        "phase lock correction must keep both motors in canonical locomotion direction",
        "phase difference after sync",
        "two-leg same-XY/phase tests PASS",
    ]:
        assert token in text, f"missing B09 Studio acceptance token: {token}"

    bootstrap = (ROOT / "src" / "server" / "Bootstrap.server.lua").read_text(encoding="utf-8")
    assert "B09TwoLegPhaseSpec" in bootstrap
    assert "B09TwoLegPhaseSpec.run()" in bootstrap

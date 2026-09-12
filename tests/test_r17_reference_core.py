from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r17_3_origin_experiment_contract() -> None:
    path = ROOT / "src/server/Tests/R17OriginExperiment.lua"
    assert path.exists(), "R17.3 requires a Studio-only mechanical-origin comparison harness"
    text = path.read_text(encoding="utf-8")
    for token in [
        'FIRST_POINT', 'BOUNDS_CENTER', 'GEOMETRY_CENTROID',
        'ROUND_01', 'LONG_BAR_01', 'SMALL_ROUND_01', 'HOOK_01', 'ASYM_01', 'SUBOPTIMAL_01',
        'R16ReferenceShapes', 'StrokeMath.AnchorToFirstPoint', 'StrokeMath.ComputeBounds',
        'function R17OriginExperiment.RunEvidence()', '[DrawRacers][R17.3]', 'HUMAN ORIGIN CHOICE PENDING',
    ]:
        assert token in text, f"missing R17.3 origin evidence token: {token}"
    assert 'LegShapeService' not in text
    assert 'RemoteEvent' not in text
    assert 'FireServer' not in text


def test_r17_5_live_phase_evidence_contract() -> None:
    path = ROOT / "src/server/Tests/R17PhaseEvidence.lua"
    assert path.exists(), "R17.5 requires live shared-axle co-phase evidence"
    text = path.read_text(encoding="utf-8")
    for token in [
        'RacerRuntime', 'R16ReferenceShapes', 'RunService.Heartbeat:Wait()',
        'PHASE_TARGET_DEGREES = 0', 'STRUCTURAL_ERROR_LIMIT = 0.15', 'MEASURE_SECONDS = 1.25',
        'structuralPhaseErrorDegrees', 'countHinges', 'GetLegPair', 'GetPhaseDegrees',
        'AxleJoint', 'redrawDelta <= 1.0', 'singleMotorSafe', 'axleTravel',
        'shared-axle co-phase evidence starting', '[DrawRacers][R17.5]',
        'function R17PhaseEvidence.RunEvidence()',
    ]:
        assert token in text, f"missing R17.5 co-phase evidence token: {token}"
    for obsolete in ['injectDrift', '_StepLegPhaseSync', 'PhaseLockRecoveryTime', 'averageMotorVelocity']:
        assert obsolete not in text
    assert 'AngularVelocity = -PhysicsConfig.Motor.AngularVelocity' not in text
    assert 'FireServer' not in text


def test_r17_6_body_feel_evidence_contract() -> None:
    path = ROOT / "src/server/Tests/R17BodyFeelExperiment.lua"
    assert path.exists(), "R17.6 requires isolated reference-feel candidate sweeps"
    text = path.read_text(encoding="utf-8")
    runner = read("src/server/Tests/R16TrialRunner.lua")

    for token in [
        'BODY_DENSITY_CANDIDATES = { 1.00, 0.60, 0.45, 0.35 }',
        'LEG_DENSITY_CANDIDATES = { 1.00, 0.60, 0.40 }',
        'MOTOR_SPEED_CANDIDATES = { -8.0, -10.0, -11.5, -12.5 }',
        'FRICTION_CANDIDATES = { 0.45, 0.25, 0.10 }',
        'R16TrialRunner.RunFlatTelemetry',
        'R16TrialRunner.RunPiece',
        'SmallSteps', 'SingleWallLow',
        'bodyContactTime', 'legContactTime', 'airTime', 'forwardDistance', 'averageSpeed', 'stuckTime',
        'maxBounceHeight', 'solverInstability',
        'bodyDensity', 'legDensity', 'motorAngularVelocity', 'bodyFriction',
        'PhysicsConfig.Motor.MotorMaxTorque', 'PhysicsConfig.Motor.MotorMaxAcceleration',
        '[DrawRacers][R17.6]', 'HUMAN BODY FEEL CHOICE PENDING',
        'function R17BodyFeelExperiment.RunEvidence()',
    ]:
        assert token in text, f"missing R17.6 reference-feel token: {token}"

    for token in [
        'function R16TrialRunner.RunFlatTelemetry',
        'function applyTemporaryTuning',
        'bodyDensity', 'bodyFriction', 'legDensity', 'motorAngularVelocity',
        'GetLegPair', 'GetSegments', 'GetJoint',
        'maxBounceHeight', 'solverInstability',
        'options.tuning',
    ]:
        assert token in runner, f"R16TrialRunner missing temporary tuning support: {token}"

    # Evidence must tune only temporary trial instances, never global config.
    for forbidden in [
        'PhysicsConfig.Motor.AngularVelocity =',
        'PhysicsConfig.Motor.MotorMaxTorque =',
        'PhysicsConfig.PhysicalMaterials.LegSegment.Density =',
        'AssemblyLinearVelocity =',
    ]:
        assert forbidden not in text


def test_r17_7_reference_course_contract() -> None:
    path = ROOT / "src/server/Tests/R17ReferenceCourseHarness.lua"
    assert path.exists(), "R17.7 requires one canonical reference-course matrix"
    text = path.read_text(encoding="utf-8")
    for token in [
        'ROUND_01', 'LONG_BAR_01', 'SMALL_ROUND_01', 'HOOK_01', 'ASYM_01', 'SUBOPTIMAL_01',
        'FlatShort', 'SmallSteps', 'SingleWallLow', 'GapSmall', 'LowTunnelWide',
        'R16TrialRunner.RunFlat', 'R16TrialRunner.RunPiece',
        'progress', 'completedPiece', 'landedAfterGap', 'antiStallSeen',
        '[DrawRacers][R17.7]', 'liveRedrawOwner=R16StageCHarness',
        'function R17ReferenceCourseHarness.RunEvidence()',
    ]:
        assert token in text, f"missing R17.7 course token: {token}"
    assert 'RacerRuntime.new' not in text, "R17.7 must reuse the canonical trial runner"
    assert 'AssemblyLinearVelocity =' not in text


def test_r17_8_final_harness_contract() -> None:
    path = ROOT / "src/server/Tests/R17FinalHarness.lua"
    assert path.exists(), "R17.8 requires a one-click Studio evidence aggregator"
    text = path.read_text(encoding="utf-8")
    config = read("src/shared/Config/StudioHarnessConfig.lua")
    bootstrap = read("src/server/Bootstrap.server.lua")
    client_bootstrap = read("src/client/Bootstrap.client.lua")
    g0_presentation = read("src/client/Dev/M0G0PresentationHarness.lua")
    decision = read("docs/DECISION_LOG_STUDIO_CORE_ITERATION_DEFAULT_2026-09-12.md")

    ordered_tokens = [
        'R16StageCHarness.RunEvidence()',
        'R17OriginExperiment.RunEvidence()',
        'R17PhaseEvidence.RunEvidence()',
        'R17BodyFeelExperiment.RunEvidence()',
        'R17ReferenceCourseHarness.RunEvidence()',
        'M0HumanHarness.start()',
        '[DrawRacers][R17FINAL] HUMAN REVIEW READY',
    ]
    positions = [text.index(token) for token in ordered_tokens]
    assert positions == sorted(positions), "R17FINAL evidence/human handoff order is wrong"

    for token in [
        'R16StageCHarness', 'R17OriginExperiment', 'R17PhaseEvidence',
        'R17BodyFeelExperiment', 'R17ReferenceCourseHarness', 'M0HumanHarness',
        'function R17FinalHarness.start()',
    ]:
        assert token in text, f"missing R17FINAL token: {token}"

    assert 'R17FINAL = "R17FINAL"' in config
    assert 'Mode = "G0"' in config, "normal Studio Play must enter the direct manual core loop"
    assert 'harnessMode == "R17FINAL"' in bootstrap
    assert 'WaitForChild("R17FinalHarness")' in bootstrap
    assert 'StudioHarnessConfig.Mode == "R17FINAL"' in client_bootstrap
    assert 'StudioHarnessConfig.Mode ~= "R17FINAL"' in g0_presentation
    assert "R17FINAL" in decision and "remain selectable" in decision
    assert 'HUMAN REVIEW PASS' not in text
    assert 'HUMAN ORIGIN CHOICE PASS' not in text
    assert 'HUMAN BODY FEEL CHOICE PASS' not in text

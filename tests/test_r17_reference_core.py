from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r17_3_origin_experiment_contract() -> None:
    path = ROOT / "src/server/Tests/R17OriginExperiment.lua"
    assert path.exists(), "R17.3 requires a Studio-only mechanical-origin comparison harness"
    text = path.read_text(encoding="utf-8")

    for token in [
        'FIRST_POINT',
        'BOUNDS_CENTER',
        'GEOMETRY_CENTROID',
        'ROUND_01',
        'LONG_BAR_01',
        'SMALL_ROUND_01',
        'HOOK_01',
        'ASYM_01',
        'SUBOPTIMAL_01',
        'R16ReferenceShapes',
        'StrokeMath.AnchorToFirstPoint',
        'StrokeMath.ComputeBounds',
        'function R17OriginExperiment.RunEvidence()',
        '[DrawRacers][R17.3]',
        'HUMAN ORIGIN CHOICE PENDING',
    ]:
        assert token in text, f"missing R17.3 origin evidence token: {token}"

    assert 'LegShapeService' not in text
    assert 'RemoteEvent' not in text
    assert 'FireServer' not in text


def test_r17_5_live_phase_evidence_contract() -> None:
    path = ROOT / "src/server/Tests/R17PhaseEvidence.lua"
    assert path.exists(), "R17.5 requires live hinge phase evidence"
    text = path.read_text(encoding="utf-8")

    for token in [
        'RacerRuntime',
        'R16ReferenceShapes',
        'RunService.Heartbeat:Wait()',
        'PHASE_TARGET_DEGREES = 180',
        'STEADY_ERROR_LIMIT = 5',
        'EXCURSION_ERROR_LIMIT = 10',
        'MAX_EXCURSION_SECONDS = 0.25',
        'injectDrift',
        'measurePhaseWindow',
        'motorSignSafe',
        'averageMotorVelocity',
        'redraw',
        '[DrawRacers][R17.5]',
        'function R17PhaseEvidence.RunEvidence()',
    ]:
        assert token in text, f"missing R17.5 phase evidence token: {token}"

    assert 'AngularVelocity = -PhysicsConfig.Motor.AngularVelocity' not in text
    assert 'FireServer' not in text
